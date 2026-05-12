process FASTQC {
    tag "${meta.id}"
    label 'qc'

    publishDir "${params.outdir}/fastqc", mode: 'copy'

    conda "bioconda::fastqc=0.12.1"
    container "quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*_fastqc.html"), emit: html
    tuple val(meta), path("*_fastqc.zip"),  emit: zip

    script:
    """
    fastqc \\
        --threads ${task.cpus} \\
        --quiet \\
        ${reads}
    """
}

