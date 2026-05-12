#!/usr/bin/env Rscript

parse_args <- function(args) {
    out <- list()
    i <- 1
    while (i <= length(args)) {
        key <- args[[i]]
        if (!startsWith(key, "--")) {
            stop("Unexpected argument: ", key)
        }
        key <- sub("^--", "", key)
        if (i == length(args) || startsWith(args[[i + 1]], "--")) {
            out[[key]] <- TRUE
            i <- i + 1
        } else {
            out[[key]] <- args[[i + 1]]
            i <- i + 2
        }
    }
    out
}

arg <- parse_args(commandArgs(trailingOnly = TRUE))

required <- c("sample_table", "outdir", "bsgenome", "contrast")
missing <- setdiff(required, names(arg))
if (length(missing) > 0) {
    stop("Missing required arguments: ", paste(missing, collapse = ", "))
}

num_arg <- function(name, default) {
    if (is.null(arg[[name]]) || is.na(arg[[name]]) || arg[[name]] == "") {
        return(default)
    }
    as.numeric(arg[[name]])
}

int_arg <- function(name, default) {
    as.integer(num_arg(name, default))
}

bool_arg <- function(name, default = FALSE) {
    if (is.null(arg[[name]])) {
        return(default)
    }
    tolower(as.character(arg[[name]])) %in% c("true", "t", "1", "yes", "y")
}

outdir <- arg$outdir
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

sink(file.path(outdir, "qsea_run.log"), split = TRUE)
on.exit(sink(), add = TRUE)

message("Starting QSEA analysis")
message("Sample table: ", arg$sample_table)
message("Output directory: ", outdir)

suppressPackageStartupMessages({
    library(qsea)
    library(BiocParallel)
})

workers <- int_arg("threads", 1)
if (.Platform$OS.type == "unix" && workers > 1) {
    register(MulticoreParam(workers = workers))
} else {
    register(SerialParam())
}

sample_table <- read.table(
    arg$sample_table,
    header = TRUE,
    sep = "\t",
    quote = "",
    comment.char = "",
    stringsAsFactors = FALSE,
    check.names = FALSE
)

required_cols <- c("sample_name", "file_name", "group", "samples", "batch")
missing_cols <- setdiff(required_cols, colnames(sample_table))
if (length(missing_cols) > 0) {
    stop("Sample table is missing columns: ", paste(missing_cols, collapse = ", "))
}

if (!all(file.exists(sample_table$file_name))) {
    missing_bams <- sample_table$file_name[!file.exists(sample_table$file_name)]
    stop("BAM files not found: ", paste(missing_bams, collapse = ", "))
}

contrast <- strsplit(arg$contrast, ",", fixed = TRUE)[[1]]
contrast <- trimws(contrast)
if (length(contrast) != 2) {
    stop("--contrast must be formatted as test,reference, for example KD,control")
}
test_group <- contrast[[1]]
reference_group <- contrast[[2]]

if (!all(c(test_group, reference_group) %in% sample_table$group)) {
    stop(
        "Contrast groups not found in sample table. Requested: ",
        paste(c(test_group, reference_group), collapse = ", "),
        "; available: ",
        paste(unique(sample_table$group), collapse = ", ")
    )
}

sample_table <- sample_table[sample_table$group %in% c(test_group, reference_group), , drop = FALSE]
sample_table$group <- factor(sample_table$group)
sample_table$group <- relevel(sample_table$group, ref = reference_group)
sample_table$batch <- factor(sample_table$batch)

write.table(
    sample_table,
    file.path(outdir, "qsea_sample_table.used.tsv"),
    sep = "\t",
    quote = FALSE,
    row.names = FALSE
)

chr_select <- if (!is.null(arg$chr_select) && arg$chr_select != "") {
    trimws(strsplit(arg$chr_select, ",", fixed = TRUE)[[1]])
} else {
    paste0("chr", c(1:22, "X", "Y"))
}

window_size <- int_arg("window_size", 500)
fragment_length <- int_arg("fragment_length", 200)
fragment_sd <- int_arg("fragment_sd", 20)
cnv_window_size <- num_arg("cnv_window_size", 2000000)
min_cpg_density <- num_arg("min_cpg_density", 1)
max_cpg_density <- num_arg("max_cpg_density", 15)
min_row_sum <- int_arg("min_row_sum", 5)
fdr <- num_arg("fdr", 0.05)
delta_beta <- num_arg("delta_beta", 0.2)
use_batch <- bool_arg("use_batch", TRUE) && length(unique(sample_table$batch)) > 1

message("Creating qseaSet")
qsea_set <- createQseaSet(
    sampleTable = sample_table,
    BSgenome = arg$bsgenome,
    chr.select = chr_select,
    window_size = window_size
)

message("Adding coverage")
qsea_set <- addCoverage(qsea_set, uniquePos = TRUE, paired = TRUE, parallel = workers > 1)

message("Adding CNV")
qsea_set <- addCNV(
    qsea_set,
    file_name = "file_name",
    window_size = cnv_window_size,
    paired = TRUE,
    parallel = workers > 1,
    MeDIP = TRUE
)

message("Adding library factors, CpG density, offset, and enrichment parameters")
qsea_set <- addLibraryFactors(qsea_set)
qsea_set <- addPatternDensity(
    qsea_set,
    "CG",
    name = "CpG",
    fragment_length = fragment_length,
    fragment_sd = fragment_sd
)
qsea_set <- addOffset(qsea_set, enrichmentPattern = "CpG")

cpg_density <- getRegions(qsea_set)$CpG_density
window_idx <- which(cpg_density > min_cpg_density & cpg_density < max_cpg_density)
signal <- (max_cpg_density - cpg_density[window_idx]) * 0.55 / max_cpg_density + 0.25

qsea_set_blind <- addEnrichmentParameters(
    qsea_set,
    enrichmentPattern = "CpG",
    windowIdx = window_idx,
    signal = signal
)

save(qsea_set, file = file.path(outdir, "qseaSet.RData"))
save(qsea_set_blind, file = file.path(outdir, "qseaSet_blind.RData"))

sample_data <- qsea_set_blind@sampleTable
design <- if (use_batch) {
    model.matrix(~ batch + group, sample_data)
} else {
    model.matrix(~ group, sample_data)
}

write.table(
    design,
    file.path(outdir, "qsea_design_matrix.tsv"),
    sep = "\t",
    quote = FALSE,
    row.names = TRUE
)

message("Fitting QSEA GLM")
qsea_glm <- fitNBglm(
    qsea_set_blind,
    design,
    norm_method = "beta",
    minRowSum = min_row_sum
)

contrast_name <- paste0(test_group, "_vs_", reference_group)
qsea_glm <- addContrast(
    qsea_set_blind,
    qsea_glm,
    coef = ncol(design),
    name = contrast_name
)

save(qsea_glm, file = file.path(outdir, "qsea_glm.RData"))

regions <- getRegions(qsea_set_blind)
keep_all <- rep(TRUE, length(regions))

message("Building all-region QSEA table")
result_all <- makeTable(
    qs = qsea_set_blind,
    glm = qsea_glm,
    keep = keep_all,
    annotation = NULL,
    samples = getSampleNames(qsea_set_blind),
    groupMeans = getSampleGroups(qsea_set_blind),
    norm_method = c("counts", "beta")
)

if (all(c("chr", "window_start", "window_end") %in% names(result_all))) {
    result_all$region_id <- paste(result_all$chr, result_all$window_start, result_all$window_end, sep = ":")
} else {
    result_all$region_id <- paste0("region_", seq_len(nrow(result_all)))
}

beta_mean_cols <- grep("_beta_means$", names(result_all), value = TRUE)
if (length(beta_mean_cols) >= 2) {
    result_all <- result_all[complete.cases(result_all[, beta_mean_cols, drop = FALSE]), ]
    result_all$deltaBeta <- result_all[, beta_mean_cols[2]] - result_all[, beta_mean_cols[1]]
} else {
    result_all$deltaBeta <- NA_real_
}

write.table(
    result_all,
    file.path(outdir, "qsea_all_regions.tsv"),
    sep = "\t",
    quote = FALSE,
    row.names = FALSE
)

beta_cols <- grep("_beta$|_beta_means$", names(result_all), value = TRUE)
count_cols <- grep("_counts$|_counts_means$", names(result_all), value = TRUE)
coord_cols <- intersect(c("chr", "window_start", "window_end", "CpG_density"), names(result_all))
id_cols <- "region_id"
test_cols <- grep(paste0("^", contrast_name, "_"), names(result_all), value = TRUE)
stat_cols <- unique(c(id_cols, coord_cols, test_cols, "deltaBeta"))

write.table(
    result_all[, stat_cols, drop = FALSE],
    file.path(outdir, "qsea_region_stats.tsv"),
    sep = "\t",
    quote = FALSE,
    row.names = FALSE
)

write.table(
    result_all[, c(id_cols, coord_cols, beta_cols), drop = FALSE],
    file.path(outdir, "qsea_beta_matrix.tsv"),
    sep = "\t",
    quote = FALSE,
    row.names = FALSE
)

write.table(
    result_all[, c(id_cols, coord_cols, count_cols), drop = FALSE],
    file.path(outdir, "qsea_counts_matrix.tsv"),
    sep = "\t",
    quote = FALSE,
    row.names = FALSE
)

annotation_table <- result_all[, c(id_cols, coord_cols), drop = FALSE]
annotation_table$annotation <- NA_character_
annotation_table$gene_chr <- NA_character_
annotation_table$gene_start <- NA_integer_
annotation_table$gene_end <- NA_integer_
annotation_table$gene_length <- NA_integer_
annotation_table$gene_strand <- NA_character_
annotation_table$gene_id <- NA_character_
annotation_table$transcript_id <- NA_character_
annotation_table$distance_to_tss <- NA_integer_
annotation_table$symbol <- NA_character_
annotation_table$gene_name <- NA_character_

if (bool_arg("annotate_regions", TRUE)) {
    message("Annotating regions with ChIPseeker")
    suppressPackageStartupMessages({
        library(ChIPseeker)
        library(GenomicRanges)
    })

    txdb_pkg <- arg$txdb
    orgdb_pkg <- arg$orgdb
    if (is.null(txdb_pkg) || txdb_pkg == "") {
        stop("--txdb is required when region annotation is enabled")
    }

    suppressPackageStartupMessages(library(txdb_pkg, character.only = TRUE))
    txdb <- get(txdb_pkg)

    anno_db <- NULL
    if (!is.null(orgdb_pkg) && orgdb_pkg != "") {
        suppressPackageStartupMessages(library(orgdb_pkg, character.only = TRUE))
        anno_db <- orgdb_pkg
    }

    peaks <- GRanges(
        seqnames = result_all$chr,
        ranges = IRanges::IRanges(
            start = as.integer(result_all$window_start) + 1L,
            end = as.integer(result_all$window_end)
        ),
        region_id = result_all$region_id
    )

    peak_anno <- annotatePeak(
        peaks,
        TxDb = txdb,
        annoDb = anno_db,
        tssRegion = c(
            -abs(int_arg("tss_upstream", 3000)),
            abs(int_arg("tss_downstream", 3000))
        ),
        verbose = FALSE
    )

    anno_df <- as.data.frame(peak_anno)
    anno_df$region_id <- peaks$region_id

    keep_anno_cols <- intersect(
        c(
            "region_id",
            "annotation",
            "geneChr",
            "geneStart",
            "geneEnd",
            "geneLength",
            "geneStrand",
            "geneId",
            "transcriptId",
            "distanceToTSS",
            "SYMBOL",
            "GENENAME"
        ),
        names(anno_df)
    )

    anno_df <- anno_df[, keep_anno_cols, drop = FALSE]
    names(anno_df) <- sub("^geneChr$", "gene_chr", names(anno_df))
    names(anno_df) <- sub("^geneStart$", "gene_start", names(anno_df))
    names(anno_df) <- sub("^geneEnd$", "gene_end", names(anno_df))
    names(anno_df) <- sub("^geneLength$", "gene_length", names(anno_df))
    names(anno_df) <- sub("^geneStrand$", "gene_strand", names(anno_df))
    names(anno_df) <- sub("^geneId$", "gene_id", names(anno_df))
    names(anno_df) <- sub("^transcriptId$", "transcript_id", names(anno_df))
    names(anno_df) <- sub("^distanceToTSS$", "distance_to_tss", names(anno_df))
    names(anno_df) <- sub("^SYMBOL$", "symbol", names(anno_df))
    names(anno_df) <- sub("^GENENAME$", "gene_name", names(anno_df))

    annotation_table <- merge(
        annotation_table[, c(id_cols, coord_cols), drop = FALSE],
        anno_df,
        by = "region_id",
        all.x = TRUE,
        sort = FALSE
    )
}

write.table(
    annotation_table,
    file.path(outdir, "qsea_region_annotation.tsv"),
    sep = "\t",
    quote = FALSE,
    row.names = FALSE
)

pvalue_col_all <- paste0(contrast_name, "_pvalue")
if (!pvalue_col_all %in% names(result_all)) {
    pvalue_col_all <- grep("_pvalue$", names(result_all), value = TRUE)[1]
}

result_all$dmr_significant <- FALSE
if (!is.na(pvalue_col_all) && pvalue_col_all %in% names(result_all)) {
    result_all$dmr_significant <- result_all[[pvalue_col_all]] <= fdr
}
if ("deltaBeta" %in% names(result_all)) {
    result_all$dmr_filtered <- result_all$dmr_significant & abs(result_all$deltaBeta) >= delta_beta
} else {
    result_all$dmr_filtered <- FALSE
}

dmr_flag_cols <- c("region_id", "dmr_significant", "dmr_filtered")
region_stats_with_flags <- result_all[, unique(c(stat_cols, dmr_flag_cols)), drop = FALSE]
write.table(
    region_stats_with_flags,
    file.path(outdir, "qsea_region_stats.tsv"),
    sep = "\t",
    quote = FALSE,
    row.names = FALSE
)

message("Selecting DMRs")
sig <- isSignificant(qsea_glm, fdr_th = fdr, direction = "both")
result_sig <- makeTable(
    qs = qsea_set_blind,
    glm = qsea_glm,
    keep = sig,
    annotation = NULL,
    samples = getSampleNames(qsea_set_blind),
    groupMeans = getSampleGroups(qsea_set_blind),
    norm_method = c("counts", "beta")
)

if (nrow(result_sig) > 0 && length(beta_mean_cols) >= 2) {
    if (all(c("chr", "window_start", "window_end") %in% names(result_sig))) {
        result_sig$region_id <- paste(result_sig$chr, result_sig$window_start, result_sig$window_end, sep = ":")
    } else {
        result_sig$region_id <- paste0("region_", seq_len(nrow(result_sig)))
    }
    sig_beta_mean_cols <- grep("_beta_means$", names(result_sig), value = TRUE)
    result_sig <- result_sig[complete.cases(result_sig[, sig_beta_mean_cols, drop = FALSE]), ]
    result_sig$deltaBeta <- result_sig[, sig_beta_mean_cols[2]] - result_sig[, sig_beta_mean_cols[1]]
}

pvalue_col <- paste0(contrast_name, "_pvalue")
if (!pvalue_col %in% names(result_sig)) {
    pvalue_col <- grep("_pvalue$", names(result_sig), value = TRUE)[1]
}

result_dmr <- result_sig
if (!is.na(pvalue_col) && pvalue_col %in% names(result_dmr)) {
    result_dmr <- result_dmr[result_dmr[[pvalue_col]] <= fdr, , drop = FALSE]
}
if ("deltaBeta" %in% names(result_dmr)) {
    result_dmr <- result_dmr[abs(result_dmr$deltaBeta) >= delta_beta, , drop = FALSE]
}

write.table(
    result_sig,
    file.path(outdir, "qsea_dmr_significant.tsv"),
    sep = "\t",
    quote = FALSE,
    row.names = FALSE
)

write.table(
    result_dmr,
    file.path(outdir, "qsea_dmr_filtered.tsv"),
    sep = "\t",
    quote = FALSE,
    row.names = FALSE
)

bed <- data.frame()
if (nrow(result_dmr) > 0 && all(c("chr", "window_start", "window_end") %in% names(result_dmr))) {
    bed <- data.frame(
        chrom = result_dmr$chr,
        chromStart = result_dmr$window_start,
        chromEnd = result_dmr$window_end,
        name = result_dmr$region_id
    )
}

write.table(
    bed,
    file.path(outdir, "qsea_dmr_filtered.bed"),
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    col.names = FALSE
)

summary_lines <- c(
    paste("samples", nrow(sample_table), sep = "\t"),
    paste("test_group", test_group, sep = "\t"),
    paste("reference_group", reference_group, sep = "\t"),
    paste("design", ifelse(use_batch, "~ batch + group", "~ group"), sep = "\t"),
    paste("windows_total", length(regions), sep = "\t"),
    paste("windows_with_cpg_density_for_enrichment", length(window_idx), sep = "\t"),
    paste("significant_regions", nrow(result_sig), sep = "\t"),
    paste("filtered_dmrs", nrow(result_dmr), sep = "\t"),
    paste("annotate_regions", bool_arg("annotate_regions", TRUE), sep = "\t")
)
writeLines(summary_lines, file.path(outdir, "qsea_summary.txt"))

message("QSEA analysis complete")
