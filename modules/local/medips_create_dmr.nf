process MEDIPS_CREATE_DMR {
    tag "${params.contrast}"
    label 'medips'

    publishDir "${params.outdir}/medips", mode: 'copy'

    container "${params.medips_container}"

    input:
    val sample_records
    path bam_files
    path medips_script

    output:
    path "medips_sample_table.tsv", emit: sample_table
    path "medips_sample_table.used.tsv", emit: sample_table_used
    path "medips_sets.RData", emit: medips_sets
    path "medips_coupling_set.RData", emit: coupling_set
    path "medips_result.RData", emit: result_object
    path "medips_summary.txt", emit: summary
    path "medips_all_regions.tsv", emit: all_regions
    path "medips_region_stats.tsv", emit: region_stats
    path "medips_counts_matrix.tsv", emit: counts_matrix
    path "medips_rpkm_matrix.tsv", emit: rpkm_matrix
    path "medips_rms_matrix.tsv", emit: rms_matrix
    path "medips_region_annotation.tsv", emit: region_annotation
    path "medips_dmr_significant.tsv", emit: dmr_significant
    path "medips_dmr_filtered.tsv", emit: dmr_filtered
    path "medips_dmr_filtered_annotated.tsv", emit: dmr_filtered_annotated
    path "medips_dmr_filtered.bed", emit: dmr_bed
    path "medips_run.log", emit: log

    script:
    def rows = sample_records.sort { a, b -> a.sample_name <=> b.sample_name }.collect { rec ->
        "${rec.sample_name}\t${rec.file_name}\t${rec.group}\t${rec.samples}\t${rec.batch}"
    }.join('\n')
    """
    cat > medips_sample_table.tsv <<'EOF'
sample_name\tfile_name\tgroup\tsamples\tbatch
${rows}
EOF

    Rscript ${medips_script} \\
        --sample_table medips_sample_table.tsv \\
        --outdir . \\
        --bsgenome ${params.medips_bsgenome} \\
        --contrast ${params.contrast} \\
        --chr_select ${params.medips_chr_select} \\
        --window_size ${params.medips_window_size} \\
        --extend ${params.medips_extend} \\
        --shift ${params.medips_shift} \\
        --uniq ${params.medips_uniq} \\
        --paired ${params.medips_paired} \\
        --min_row_sum ${params.medips_min_row_sum} \\
        --fdr ${params.fdr} \\
        --min_abs_log2fc ${params.min_abs_log2fc} \\
        --diff_method ${params.medips_diff_method} \\
        --diffnorm ${params.medips_diffnorm} \\
        --p_adj ${params.medips_p_adj} \\
        --pattern ${params.medips_pattern} \\
        --annotate_regions ${params.medips_annotate_regions} \\
        --txdb ${params.medips_txdb} \\
        --orgdb ${params.medips_orgdb} \\
        --tss_upstream ${params.medips_tss_upstream} \\
        --tss_downstream ${params.medips_tss_downstream}
    """
}
