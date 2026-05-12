process BWA_MEM_SORT {
    tag "${meta.id}"
    label 'align'

    publishDir "${params.outdir}/alignment", mode: 'copy'

    conda "bioconda::bwa=0.7.17 bioconda::samtools=1.16.1"
    container "quay.io/biocontainers/mulled-v2-fe8faa35dbf6dc65a0f7f5d4ea12e31a79f73e40:219b6c272b25e7e642ae3ff0bf0c5c81a5135ab4-0"

    input:
    tuple val(meta), path(reads)
    path fasta
    path bwa_index

    output:
    tuple val(meta), path("${meta.id}.sorted.bam"),     emit: bam
    tuple val(meta), path("${meta.id}.sorted.bam.bai"), emit: bai
    tuple val(meta), path("${meta.id}.flagstat.txt"),   emit: flagstat
    tuple val(meta), path("${meta.id}.idxstats.txt"),   emit: idxstats
    tuple val(meta), path("${meta.id}.stats.txt"),      emit: stats

    script:
    def rg = "@RG\\tID:${meta.id}\\tSM:${meta.id}\\tPL:ILLUMINA"
    def fasta_name = fasta.getName()
    """
    bwa mem \\
        -t ${task.cpus} \\
        -R '${rg}' \\
        ${fasta_name} \\
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
