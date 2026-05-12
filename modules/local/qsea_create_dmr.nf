process QSEA_CREATE_DMR {
    tag "${params.contrast}"
    label 'qsea'

    publishDir "${params.outdir}/qsea", mode: 'copy'

    conda "bioconda::bioconductor-qsea bioconda::bioconductor-bsgenome.hsapiens.ucsc.hg38 bioconda::bioconductor-biocparallel conda-forge::r-base"
    container "${params.qsea_container}"

    input:
    val sample_records
    path bam_files
    path qsea_script

    output:
    path "qsea_sample_table.tsv", emit: sample_table
    path "qsea/qseaSet.RData", emit: qsea_set
    path "qsea/qseaSet_blind.RData", emit: qsea_set_blind
    path "qsea/qsea_glm.RData", emit: qsea_glm
    path "qsea/qsea_summary.txt", emit: summary
    path "qsea/qsea_all_regions.tsv", emit: all_regions
    path "qsea/qsea_region_stats.tsv", emit: region_stats
    path "qsea/qsea_beta_matrix.tsv", emit: beta_matrix
    path "qsea/qsea_counts_matrix.tsv", emit: counts_matrix
    path "qsea/qsea_region_annotation.tsv", emit: region_annotation
    path "qsea/qsea_dmr_significant.tsv", emit: dmr_significant
    path "qsea/qsea_dmr_filtered.tsv", emit: dmr_filtered
    path "qsea/qsea_dmr_filtered.bed", emit: dmr_bed
    path "qsea/qsea_design_matrix.tsv", emit: design
    path "qsea/qsea_run.log", emit: log

    script:
    def rows = sample_records.collect { rec ->
        "${rec.sample_name}\t${rec.file_name}\t${rec.group}\t${rec.samples}\t${rec.batch}"
    }.join('\n')
    """
    cat > qsea_sample_table.tsv <<'EOF'
sample_name\tfile_name\tgroup\tsamples\tbatch
${rows}
EOF

    mkdir -p qsea

    Rscript ${qsea_script} \\
        --sample_table qsea_sample_table.tsv \\
        --outdir qsea \\
        --bsgenome ${params.qsea_bsgenome} \\
        --contrast ${params.contrast} \\
        --chr_select ${params.qsea_chr_select} \\
        --window_size ${params.qsea_window_size} \\
        --fragment_length ${params.qsea_fragment_length} \\
        --fragment_sd ${params.qsea_fragment_sd} \\
        --cnv_window_size ${params.qsea_cnv_window_size} \\
        --min_cpg_density ${params.qsea_min_cpg_density} \\
        --max_cpg_density ${params.qsea_max_cpg_density} \\
        --min_row_sum ${params.qsea_min_row_sum} \\
        --fdr ${params.fdr} \\
        --delta_beta ${params.delta_beta} \\
        --use_batch ${params.qsea_use_batch} \\
        --annotate_regions ${params.qsea_annotate_regions} \\
        --txdb ${params.qsea_txdb} \\
        --orgdb ${params.qsea_orgdb} \\
        --tss_upstream ${params.qsea_tss_upstream} \\
        --tss_downstream ${params.qsea_tss_downstream} \\
        --threads ${task.cpus}
    """
}
