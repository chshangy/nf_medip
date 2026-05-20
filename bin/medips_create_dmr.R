#!/usr/bin/env Rscript

suppressPackageStartupMessages({
    library(MEDIPS)
    library(data.table)
})

parse_args <- function(args) {
    out <- list()
    i <- 1
    while (i <= length(args)) {
        key <- sub("^--", "", args[[i]])
        if (i == length(args) || grepl("^--", args[[i + 1]])) {
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

bool_arg <- function(name, default = FALSE) {
    value <- arg[[name]]
    if (is.null(value)) {
        return(default)
    }
    tolower(as.character(value)) %in% c("true", "t", "1", "yes", "y")
}

int_arg <- function(name, default) {
    value <- arg[[name]]
    if (is.null(value) || value == "null" || value == "") {
        return(default)
    }
    as.integer(value)
}

num_arg <- function(name, default) {
    value <- arg[[name]]
    if (is.null(value) || value == "null" || value == "") {
        return(default)
    }
    as.numeric(value)
}

`%||%` <- function(x, y) {
    if (is.null(x) || identical(x, "") || identical(x, "null")) y else x
}

outdir <- arg$outdir
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

sink(file.path(outdir, "medips_run.log"), split = TRUE)
on.exit(sink(), add = TRUE)

message("Starting MEDIPS analysis")
message("Sample table: ", arg$sample_table)
message("Output directory: ", outdir)

sample_table <- fread(arg$sample_table)
required_cols <- c("sample_name", "file_name", "group", "samples", "batch")
missing_cols <- setdiff(required_cols, names(sample_table))
if (length(missing_cols) > 0) {
    stop("Sample table is missing required columns: ", paste(missing_cols, collapse = ", "))
}

contrast_groups <- strsplit(arg$contrast, ",", fixed = TRUE)[[1]]
if (length(contrast_groups) != 2) {
    stop("--contrast must be formatted as test_group,reference_group")
}
test_group <- contrast_groups[[1]]
reference_group <- contrast_groups[[2]]
contrast_name <- paste(test_group, "vs", reference_group, sep = "_")

sample_table <- sample_table[group %in% c(test_group, reference_group)]
sample_table <- sample_table[order(sample_name)]
if (nrow(sample_table) == 0) {
    stop("No samples remain after filtering to contrast groups")
}
if (!all(c(test_group, reference_group) %in% sample_table$group)) {
    stop("Both contrast groups must be present in the sample table")
}

write.table(
    sample_table,
    file.path(outdir, "medips_sample_table.used.tsv"),
    sep = "\t",
    quote = FALSE,
    row.names = FALSE
)

window_size <- int_arg("window_size", 500)
extend <- int_arg("extend", 0)
shift <- int_arg("shift", 0)
uniq <- num_arg("uniq", 1e-3)
paired <- bool_arg("paired", TRUE)
min_row_sum <- int_arg("min_row_sum", 10)
fdr <- num_arg("fdr", 0.05)
min_abs_log2fc <- num_arg("min_abs_log2fc", 1)
diff_method <- arg$diff_method %||% "edgeR"
diffnorm <- arg$diffnorm %||% "tmm"
p_adj <- arg$p_adj %||% "BH"
pattern <- arg$pattern %||% "CG"
chr_select <- strsplit(arg$chr_select %||% "", ",", fixed = TRUE)[[1]]
chr_select <- chr_select[nzchar(chr_select)]

message("Creating MEDIPS sets")
medips_sets <- list()
for (i in seq_len(nrow(sample_table))) {
    rec <- sample_table[i]
    message("  ", rec$sample_name, ": ", rec$file_name)
    medips_sets[[rec$sample_name]] <- MEDIPS.createSet(
        file = rec$file_name,
        BSgenome = arg$bsgenome,
        extend = extend,
        shift = shift,
        window_size = window_size,
        uniq = uniq,
        chr.select = chr_select,
        paired = paired,
        sample_name = rec$sample_name
    )
}

message("Creating CpG coupling vector")
coupling_set <- MEDIPS.couplingVector(pattern = pattern, refObj = medips_sets[[1]])
save(medips_sets, file = file.path(outdir, "medips_sets.RData"))
save(coupling_set, file = file.path(outdir, "medips_coupling_set.RData"))

reference_samples <- sample_table[group == reference_group]$sample_name
test_samples <- sample_table[group == test_group]$sample_name
reference_sets <- medips_sets[reference_samples]
test_sets <- medips_sets[test_samples]

message("Running MEDIPS.meth")
medips_result <- MEDIPS.meth(
    MSet1 = reference_sets,
    MSet2 = test_sets,
    CSet = coupling_set,
    chr = chr_select,
    p.adj = p_adj,
    diff.method = diff_method,
    CNV = FALSE,
    MeDIP = TRUE,
    minRowSum = min_row_sum,
    diffnorm = diffnorm
)
medips_result <- as.data.frame(medips_result)
save(medips_result, file = file.path(outdir, "medips_result.RData"))

rename_if_present <- function(x, from, to) {
    if (from %in% names(x)) {
        names(x)[names(x) == from] <- to
    }
    x
}

rename_first_present <- function(x, candidates, to) {
    hit <- candidates[candidates %in% names(x)][1]
    if (!is.na(hit) && !to %in% names(x)) {
        names(x)[names(x) == hit] <- to
    }
    x
}

result_all <- medips_result
writeLines(names(result_all), file.path(outdir, "medips_result_columns.txt"))

result_all <- rename_first_present(result_all, c("Chr", "chr", "chrom", "chromosome"), "chr")
result_all <- rename_first_present(result_all, c("Start", "start", "window_start", "window.start"), "window_start")
result_all <- rename_first_present(result_all, c("Stop", "stop", "End", "end", "window_end", "window.end"), "window_end")
result_all <- rename_first_present(result_all, c("CF", "CpG_count", "CpG.count", "coupling", "coupling_factor"), "CpG_count")

has_coordinates <- all(c("chr", "window_start", "window_end") %in% names(result_all))
if (has_coordinates) {
    result_all$region_id <- paste(result_all$chr, result_all$window_start, result_all$window_end, sep = ":")
} else {
    warning("MEDIPS result table did not contain recognized coordinate columns; using row-based region IDs and skipping genomic annotation/bed output.")
    result_all$region_id <- paste0("region_", seq_len(nrow(result_all)))
}

logfc_col <- if ("edgeR.logFC" %in% names(result_all)) "edgeR.logFC" else "score.log2.ratio"
pvalue_col <- if ("edgeR.p.value" %in% names(result_all)) "edgeR.p.value" else "score.p.value"
adjp_col <- if ("edgeR.adj.p.value" %in% names(result_all)) "edgeR.adj.p.value" else "score.adj.p.value"

contrast_logfc_col <- paste0(contrast_name, "_log2FC")
contrast_pvalue_col <- paste0(contrast_name, "_pvalue")
contrast_adjp_col <- paste0(contrast_name, "_adjPval")

if (!is.na(logfc_col) && logfc_col %in% names(result_all)) {
    /*
     * MEDIPS.meth reports log2(MSet1/MSet2). In this workflow MSet1 is the
     * reference group and MSet2 is the test group, so invert the sign to
     * match the user-facing test_vs_reference convention used by QSEA.
     */
    result_all[[contrast_logfc_col]] <- -result_all[[logfc_col]]
}
if (!is.na(pvalue_col) && pvalue_col %in% names(result_all)) {
    result_all[[contrast_pvalue_col]] <- result_all[[pvalue_col]]
}
if (!is.na(adjp_col) && adjp_col %in% names(result_all)) {
    result_all[[contrast_adjp_col]] <- result_all[[adjp_col]]
}

rms_mean_cols <- grep("MSets[12]\\.rms\\.mean$", names(result_all), value = TRUE)
if (length(rms_mean_cols) >= 2) {
    result_all$deltaRMS <- result_all[[rms_mean_cols[2]]] - result_all[[rms_mean_cols[1]]]
} else {
    result_all$deltaRMS <- NA_real_
}

result_all$dmr_significant <- FALSE
if (!is.na(adjp_col) && adjp_col %in% names(result_all)) {
    result_all$dmr_significant <- result_all[[adjp_col]] <= fdr
}
result_all$dmr_filtered <- result_all$dmr_significant
if (!is.na(logfc_col) && logfc_col %in% names(result_all)) {
    result_all$dmr_filtered <- result_all$dmr_filtered & abs(result_all[[logfc_col]]) >= min_abs_log2fc
}

id_cols <- c("region_id")
coord_cols <- c("chr", "window_start", "window_end")
feature_cols <- intersect(c("CpG_count", "CF", "coupling", "coupling_factor"), names(result_all))
base_cols <- intersect(unique(c(id_cols, coord_cols, feature_cols)), names(result_all))
stat_cols <- unique(c(
    base_cols,
    contrast_logfc_col,
    contrast_pvalue_col,
    contrast_adjp_col,
    logfc_col,
    pvalue_col,
    adjp_col,
    "deltaRMS",
    "dmr_significant",
    "dmr_filtered"
))
stat_cols <- stat_cols[stat_cols %in% names(result_all)]

write.table(
    result_all[, stat_cols, drop = FALSE],
    file.path(outdir, "medips_region_stats.tsv"),
    sep = "\t",
    quote = FALSE,
    row.names = FALSE
)

count_cols <- grep("(^|\\.)(counts?|count)(\\.|$)", names(result_all), value = TRUE, ignore.case = TRUE)
rpkm_cols <- grep("(^|\\.)rpkm(\\.|$)", names(result_all), value = TRUE, ignore.case = TRUE)
rms_cols <- grep("(^|\\.)rms(\\.|$)", names(result_all), value = TRUE, ignore.case = TRUE)
mean_cols <- grep("(counts?|count|rpkm|rms).*mean|mean.*(counts?|count|rpkm|rms)", names(result_all), value = TRUE, ignore.case = TRUE)
count_cols <- setdiff(count_cols, c(logfc_col, pvalue_col, adjp_col))
rpkm_cols <- setdiff(rpkm_cols, c(logfc_col, pvalue_col, adjp_col))
rms_cols <- setdiff(rms_cols, c(logfc_col, pvalue_col, adjp_col))
select_existing <- function(cols) {
    intersect(unique(cols), names(result_all))
}

write.table(
    result_all[, select_existing(c(base_cols, count_cols, grep("counts?|count", mean_cols, value = TRUE, ignore.case = TRUE))), drop = FALSE],
    file.path(outdir, "medips_counts_matrix.tsv"),
    sep = "\t",
    quote = FALSE,
    row.names = FALSE
)

write.table(
    result_all[, select_existing(c(base_cols, rpkm_cols, grep("rpkm", mean_cols, value = TRUE, ignore.case = TRUE))), drop = FALSE],
    file.path(outdir, "medips_rpkm_matrix.tsv"),
    sep = "\t",
    quote = FALSE,
    row.names = FALSE
)

write.table(
    result_all[, select_existing(c(base_cols, rms_cols, grep("rms", mean_cols, value = TRUE, ignore.case = TRUE))), drop = FALSE],
    file.path(outdir, "medips_rms_matrix.tsv"),
    sep = "\t",
    quote = FALSE,
    row.names = FALSE
)

write.table(
    result_all,
    file.path(outdir, "medips_all_regions.tsv"),
    sep = "\t",
    quote = FALSE,
    row.names = FALSE
)

annotation_table <- result_all[, base_cols, drop = FALSE]
if (bool_arg("annotate_regions", TRUE) && has_coordinates) {
    suppressPackageStartupMessages({
        library(GenomicRanges)
        library(ChIPseeker)
        library(arg$txdb, character.only = TRUE)
        library(arg$orgdb, character.only = TRUE)
    })

    txdb_obj <- get(arg$txdb)
    orgdb_name <- arg$orgdb
    peaks <- GRanges(
        seqnames = annotation_table$chr,
        ranges = IRanges(
            start = annotation_table$window_start,
            end = annotation_table$window_end
        )
    )
    peaks$region_id <- annotation_table$region_id

    peak_anno <- annotatePeak(
        peaks,
        TxDb = txdb_obj,
        annoDb = orgdb_name,
        tssRegion = c(-abs(int_arg("tss_upstream", 3000)), abs(int_arg("tss_downstream", 3000))),
        verbose = FALSE
    )
    anno_df <- as.data.frame(peak_anno)
    anno_df$region_id <- peaks$region_id
    keep_anno_cols <- intersect(
        c("region_id", "annotation", "geneChr", "geneStart", "geneEnd", "geneLength", "geneStrand", "geneId", "transcriptId", "distanceToTSS", "SYMBOL", "GENENAME"),
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
        annotation_table,
        anno_df,
        by = "region_id",
        all.x = TRUE,
        sort = FALSE
    )
} else if (bool_arg("annotate_regions", TRUE) && !has_coordinates) {
    warning("Skipping MEDIPS annotation because genomic coordinate columns were not recognized.")
}

write.table(
    annotation_table,
    file.path(outdir, "medips_region_annotation.tsv"),
    sep = "\t",
    quote = FALSE,
    row.names = FALSE
)

result_sig <- result_all[result_all$dmr_significant %in% TRUE, , drop = FALSE]
result_dmr <- result_all[result_all$dmr_filtered %in% TRUE, , drop = FALSE]

write.table(
    result_sig,
    file.path(outdir, "medips_dmr_significant.tsv"),
    sep = "\t",
    quote = FALSE,
    row.names = FALSE
)

write.table(
    result_dmr,
    file.path(outdir, "medips_dmr_filtered.tsv"),
    sep = "\t",
    quote = FALSE,
    row.names = FALSE
)

annotation_extra_cols <- setdiff(names(annotation_table), names(result_dmr))
result_dmr_annotated <- result_dmr
if (nrow(result_dmr) > 0 && "region_id" %in% names(result_dmr) && "region_id" %in% names(annotation_table)) {
    annotation_extra <- annotation_table[, c("region_id", annotation_extra_cols), drop = FALSE]
    result_dmr_annotated <- merge(result_dmr, annotation_extra, by = "region_id", all.x = TRUE, sort = FALSE)
    result_dmr_annotated <- result_dmr_annotated[
        match(result_dmr$region_id, result_dmr_annotated$region_id),
        c(names(result_dmr), annotation_extra_cols),
        drop = FALSE
    ]
} else {
    for (col in annotation_extra_cols) {
        result_dmr_annotated[[col]] <- rep(NA_character_, nrow(result_dmr_annotated))
    }
}

write.table(
    result_dmr_annotated,
    file.path(outdir, "medips_dmr_filtered_annotated.tsv"),
    sep = "\t",
    quote = FALSE,
    row.names = FALSE
)

bed <- data.frame()
if (nrow(result_dmr) > 0 && has_coordinates) {
    bed <- data.frame(
        chrom = result_dmr$chr,
        chromStart = result_dmr$window_start,
        chromEnd = result_dmr$window_end,
        name = result_dmr$region_id
    )
}
write.table(
    bed,
    file.path(outdir, "medips_dmr_filtered.bed"),
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    col.names = FALSE
)

summary_lines <- c(
    paste("samples", nrow(sample_table), sep = "\t"),
    paste("test_group", test_group, sep = "\t"),
    paste("reference_group", reference_group, sep = "\t"),
    paste("design", "MEDIPS.meth two-group comparison", sep = "\t"),
    paste("window_size", window_size, sep = "\t"),
    paste("diff_method", diff_method, sep = "\t"),
    paste("diffnorm", diffnorm, sep = "\t"),
    paste("p_adj", p_adj, sep = "\t"),
    paste("regions_total", nrow(result_all), sep = "\t"),
    paste("significant_regions", nrow(result_sig), sep = "\t"),
    paste("filtered_dmrs", nrow(result_dmr), sep = "\t"),
    paste("annotate_regions", bool_arg("annotate_regions", TRUE), sep = "\t")
)
writeLines(summary_lines, file.path(outdir, "medips_summary.txt"))

message("MEDIPS analysis complete")
