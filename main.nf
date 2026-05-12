#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { FASTQC as FASTQC_RAW } from './modules/local/fastqc'
include { FASTQC as FASTQC_TRIM } from './modules/local/fastqc'
include { TRIMGALORE_PAIRED } from './modules/local/trim_galore'
include { BWA_MEM_SORT } from './modules/local/bwa_mem_sort'
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

    ch_reads = Channel
        .fromPath(params.input, checkIfExists: true)
        .splitCsv(header: true)
        .map { row ->
            def meta = [
                id          : row.sample,
                single_end  : false,
                strandedness: row.strandedness ?: 'auto',
                group       : row.group ?: 'NA'
            ]

            if (!row.sample) {
                error "Samplesheet row is missing 'sample'"
            }
            if (!row.fastq_1 || !row.fastq_2) {
                error "Sample '${row.sample}' is missing fastq_1 or fastq_2"
            }

            tuple(meta, [ file(row.fastq_1, checkIfExists: true), file(row.fastq_2, checkIfExists: true) ])
        }

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

    ch_multiqc_files = ch_multiqc_files
        .mix(BWA_MEM_SORT.out.flagstat.map { meta, file -> file })
        .mix(BWA_MEM_SORT.out.idxstats.map { meta, file -> file })
        .mix(BWA_MEM_SORT.out.stats.map { meta, file -> file })
        .collect()

    MULTIQC(ch_multiqc_files)
}
