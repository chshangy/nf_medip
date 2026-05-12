process BAM_FILTER {
    tag "${meta.id}"
    label 'bam_filter'

    publishDir "${params.outdir}/bam_filter", mode: 'copy'

    conda "bioconda::samtools=1.20"
    container "quay.io/biocontainers/samtools:1.20--h50ea8bc_1"

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("${meta.id}.filtered.bam"), path("${meta.id}.filtered.bam.bai"), emit: bam_bai

    script:
    def exclude_flags = params.remove_duplicates ? (params.samtools_exclude_flags as Integer) + 1024 : params.samtools_exclude_flags
    """
    samtools view \\
        -@ ${task.cpus} \\
        -b \\
        -q ${params.min_mapq} \\
        -F ${exclude_flags} \\
        ${bam} \\
        -o ${meta.id}.filtered.bam

    samtools index -@ ${task.cpus} ${meta.id}.filtered.bam
    """
}
