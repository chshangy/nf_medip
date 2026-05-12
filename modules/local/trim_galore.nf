process TRIMGALORE_PAIRED {
    tag "${meta.id}"
    label 'trim'

    publishDir "${params.outdir}/trim_galore", mode: 'copy'

    conda "bioconda::trim-galore=0.6.10"
    container "quay.io/biocontainers/trim-galore:0.6.10--hdfd78af_0"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}_val_*.fq.gz"), emit: reads
    tuple val(meta), path("${meta.id}_*.txt"), emit: reports

    script:
    """
    trim_galore \\
        --cores ${task.cpus} \\
        --gzip \\
        --paired \\
        --basename ${meta.id} \\
        ${reads[0]} \\
        ${reads[1]}
    """
}
