process BWA_MEM_SORT {
    tag "${meta.id}"
    label 'align'

    publishDir "${params.outdir}/alignment", mode: 'copy'

    conda "bioconda::bwa=0.7.17 bioconda::samtools=1.20"
    container "quay.io/biocontainers/bwa:0.7.17--hed695b0_7"

    input:
    tuple val(meta), path(reads)
    val fasta

    output:
    tuple val(meta), path("${meta.id}.sorted.bam"),     emit: bam
    tuple val(meta), path("${meta.id}.sorted.bam.bai"), emit: bai
    tuple val(meta), path("${meta.id}.flagstat.txt"),   emit: flagstat
    tuple val(meta), path("${meta.id}.idxstats.txt"),   emit: idxstats
    tuple val(meta), path("${meta.id}.stats.txt"),      emit: stats

    script:
    def rg = "@RG\\tID:${meta.id}\\tSM:${meta.id}\\tPL:ILLUMINA"
    """
    bwa mem \\
        -t ${task.cpus} \\
        -R '${rg}' \\
        ${fasta} \\
        ${reads[0]} \\
        ${reads[1]} \\
        | samtools sort \\
            -@ ${task.cpus} \\
            -o ${meta.id}.sorted.bam \\
            -

    samtools index -@ ${task.cpus} ${meta.id}.sorted.bam
    samtools flagstat -@ ${task.cpus} ${meta.id}.sorted.bam > ${meta.id}.flagstat.txt
    samtools idxstats ${meta.id}.sorted.bam > ${meta.id}.idxstats.txt
    samtools stats -@ ${task.cpus} ${meta.id}.sorted.bam > ${meta.id}.stats.txt
    """
}

