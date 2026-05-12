workflow INPUT_CHECK {
    take:
    samplesheet

    main:
    reads = Channel
        .fromPath(samplesheet, checkIfExists: true)
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

    emit:
    reads = reads
}

