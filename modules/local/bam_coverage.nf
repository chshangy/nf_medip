process BAM_COVERAGE {
    tag "${meta.id}"
    label 'coverage'

    publishDir "${params.outdir}/coverage", mode: 'copy'

    conda "bioconda::deeptools=3.5.5"
    container "quay.io/biocontainers/deeptools:3.5.5--pyhdfd78af_0"

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("${meta.id}.filtered.bw"), emit: bigwig

    script:
    def effective_genome_size = params.effective_genome_size ? "--effectiveGenomeSize ${params.effective_genome_size}" : ""
    """
    bamCoverage \\
        --bam ${bam} \\
        --outFileName ${meta.id}.filtered.bw \\
        --outFileFormat bigwig \\
        --numberOfProcessors ${task.cpus} \\
        --binSize ${params.coverage_bin_size} \\
        --normalizeUsing ${params.coverage_normalize_using} \\
        ${effective_genome_size}
    """
}

