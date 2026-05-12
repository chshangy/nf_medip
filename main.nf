#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { INPUT_CHECK } from './subworkflows/local/input_check'
include { FASTQC as FASTQC_RAW } from './modules/local/fastqc'
include { FASTQC as FASTQC_TRIM } from './modules/local/fastqc'
include { TRIMGALORE_PAIRED } from './modules/local/trim_galore'
include { BWA_MEM_SORT } from './modules/local/bwa_mem_sort'
include { BAM_FILTER } from './modules/local/bam_filter'
include { POST_ALIGNMENT_QC } from './modules/local/post_alignment_qc'
include { BAM_COVERAGE } from './modules/local/bam_coverage'
include { MULTIQC } from './modules/local/multiqc'

/*
 * Parse samplesheet.csv.
 *
 * Required columns:
 *   sample,fastq_1,fastq_2
 *
 * Optional columns are kept in metadata:
 *   strandedness,group
 */

workflow {
    main:
    if (!params.input) {
        error "Please provide a sample sheet with --input"
    }

    if (!params.fasta) {
        error "Please provide the BWA-indexed reference FASTA with --fasta"
    }

    INPUT_CHECK(params.input)
    ch_reads = INPUT_CHECK.out.reads

    ch_fasta = Channel.value(file(params.fasta, checkIfExists: true))
    ch_bwa_index = Channel.value([
        file("${params.fasta}.amb", checkIfExists: true),
        file("${params.fasta}.ann", checkIfExists: true),
        file("${params.fasta}.bwt", checkIfExists: true),
        file("${params.fasta}.pac", checkIfExists: true),
        file("${params.fasta}.sa", checkIfExists: true)
    ])

    FASTQC_RAW(ch_reads)

    if (params.skip_trimming) {
        ch_reads_for_alignment = ch_reads
        ch_multiqc_files = FASTQC_RAW.out.zip
            .map { meta, file -> file }
            .mix(FASTQC_RAW.out.html.map { meta, file -> file })
    } else {
        TRIMGALORE_PAIRED(ch_reads)
        FASTQC_TRIM(TRIMGALORE_PAIRED.out.reads)
        ch_reads_for_alignment = TRIMGALORE_PAIRED.out.reads

        ch_multiqc_files = FASTQC_RAW.out.zip
            .map { meta, file -> file }
            .mix(FASTQC_RAW.out.html.map { meta, file -> file })
            .mix(FASTQC_TRIM.out.zip.map { meta, file -> file })
            .mix(FASTQC_TRIM.out.html.map { meta, file -> file })
            .mix(TRIMGALORE_PAIRED.out.reports.map { meta, file -> file })
    }

    BWA_MEM_SORT(ch_reads_for_alignment, ch_fasta, ch_bwa_index)
    BAM_FILTER(BWA_MEM_SORT.out.bam_bai)
    POST_ALIGNMENT_QC(BAM_FILTER.out.bam_bai)
    BAM_COVERAGE(BAM_FILTER.out.bam_bai)

    ch_multiqc_files = ch_multiqc_files
        .mix(BWA_MEM_SORT.out.flagstat.map { meta, file -> file })
        .mix(BWA_MEM_SORT.out.idxstats.map { meta, file -> file })
        .mix(BWA_MEM_SORT.out.stats.map { meta, file -> file })
        .mix(POST_ALIGNMENT_QC.out.flagstat.map { meta, file -> file })
        .mix(POST_ALIGNMENT_QC.out.idxstats.map { meta, file -> file })
        .mix(POST_ALIGNMENT_QC.out.stats.map { meta, file -> file })
        .collect()

    MULTIQC(ch_multiqc_files)
}
