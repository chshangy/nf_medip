process MULTIQC {
    label 'qc'

    publishDir "${params.outdir}/multiqc", mode: 'copy'

    conda "bioconda::multiqc=1.25.1"
    container "quay.io/biocontainers/multiqc:1.25.1--pyhdfd78af_0"

    input:
    path multiqc_files

    output:
    path "multiqc_report.html", emit: report
    path "multiqc*_data",       emit: data

    script:
    """
    multiqc \\
        --title '${params.multiqc_title}' \\
        --filename multiqc_report.html \\
        .
    """
}
