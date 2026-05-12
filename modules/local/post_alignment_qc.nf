process POST_ALIGNMENT_QC {
    tag "${meta.id}"
    label 'qc'

    publishDir "${params.outdir}/post_alignment_qc", mode: 'copy'

    conda "bioconda::samtools=1.20"
    container "quay.io/biocontainers/samtools:1.20--h50ea8bc_1"

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("${meta.id}.filtered.flagstat.txt"), emit: flagstat
    tuple val(meta), path("${meta.id}.filtered.idxstats.txt"), emit: idxstats
    tuple val(meta), path("${meta.id}.filtered.stats.txt"),    emit: stats

    script:
    """
    samtools flagstat -@ ${task.cpus} ${bam} > ${meta.id}.filtered.flagstat.txt
    samtools idxstats ${bam} > ${meta.id}.filtered.idxstats.txt
    samtools stats -@ ${task.cpus} ${bam} > ${meta.id}.filtered.stats.txt
    """
}

