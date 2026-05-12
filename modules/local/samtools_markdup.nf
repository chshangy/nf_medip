process SAMTOOLS_MARKDUP {
    tag "${meta.id}"
    label 'markdup'

    publishDir "${params.outdir}/markdup", mode: 'copy'

    conda "bioconda::samtools=1.20"
    container "quay.io/biocontainers/samtools:1.20--h50ea8bc_1"

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("${meta.id}.markdup.bam"), path("${meta.id}.markdup.bam.bai"), emit: bam_bai
    tuple val(meta), path("${meta.id}.markdup.metrics.txt"), emit: metrics
    tuple val(meta), path("${meta.id}.markdup.flagstat.txt"), emit: flagstat

    script:
    """
    samtools sort \\
        -@ ${task.cpus} \\
        -n \\
        -o ${meta.id}.namesort.bam \\
        ${bam}

    samtools fixmate \\
        -@ ${task.cpus} \\
        -m \\
        ${meta.id}.namesort.bam \\
        ${meta.id}.fixmate.bam

    samtools sort \\
        -@ ${task.cpus} \\
        -o ${meta.id}.positionsort.bam \\
        ${meta.id}.fixmate.bam

    samtools markdup \\
        -@ ${task.cpus} \\
        -s \\
        -f ${meta.id}.markdup.metrics.txt \\
        ${meta.id}.positionsort.bam \\
        ${meta.id}.markdup.bam

    samtools index -@ ${task.cpus} ${meta.id}.markdup.bam
    samtools flagstat -@ ${task.cpus} ${meta.id}.markdup.bam > ${meta.id}.markdup.flagstat.txt
    """
}

