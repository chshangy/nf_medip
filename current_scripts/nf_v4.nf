#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

/*
 * Define the processes
 */
 
process FASTQC {
    tag "$sample_id"
    label "low_mem"
    publishDir "${params.outdir}/fastqc", mode:'copy'

    input:
    tuple val(sample_id), path(reads)

    output:
    path("fastqc_${sample_id}")

    script:
    """
    mkdir fastqc_${sample_id}
    fastqc -o fastqc_${sample_id} -f fastq -q ${reads} -t ${task.cpus}
    """
}

process MULTIQC {
    label "low_mem"
    publishDir "${params.outdir}/multiqc", mode:'copy'
	
    input:
    path('*')

    output:
    path('multiqc_report.html')

    script:
    """
    multiqc .
    """
}


 process TRIM {
    label "low_mem"
    publishDir "${params.outdir}/trim", mode:'copy'
    tag "$sample_id" 

    input:
    tuple val(sample_id), path(reads)
	
    output:
    tuple val(sample_id), path("*_val_1.fq.gz"), path("*_val_2.fq.gz"), emit:fq
    path('*report.txt'), emit:report
	

    script:
    """
    # Run Trimming
    trim_galore --cores ${task.cpus} --gzip --paired ${reads[0]} ${reads[1]} --basename ${sample_id}
 
    """
}

process FASTQC_TRIM {
    tag "$sample_id"
    label "low_mem"
    publishDir "${params.outdir}/fastqc_trim", mode:'copy'

    input:
    tuple val(sample_id), path(reads)

    output:
    path("fastqc_${sample_id}")

    script:
    """
    mkdir fastqc_${sample_id}
    fastqc -o fastqc_${sample_id} -f fastq -q ${reads} -t ${task.cpus}
    """
}

process MULTIQC_TRIM {
    label "low_mem"
    publishDir "${params.outdir}/multiqc_trim", mode:'copy'

    input:
    path('*')

    output:
    path('multiqc_report.html')

    script:
    """
    multiqc .
    """
}



process BWA_ALIGN {
    tag "$sample_id"
    label "medium_mem"
    publishDir "${params.outdir}/align", mode:'copy'

    input:
    path genome
    path genome_bwt
    path genome_pac
    path genome_ann
    path genome_amb
    path genome_sa
    tuple val(sample_id), path(read1), path(read2)

    output:
    tuple val(sample_id), path("*_aligned.bam")

    script:
    """
    bwa mem -t ${task.cpus} $genome ${read1} ${read2} | samtools view -Shb -o ${sample_id}_aligned.bam
    """
}


params.reads = "/projects/sychen/projects/patnsb/ebv_kd_medip/batch2/01.RawData/NK1617/*_{1,2}.fq.gz"
params.genome_dir = "/projects/sychen/projects/patnsb/ebv_kd_medip/ref"
params.genome = "${params.genome_dir}/GRCh38.p14.genome.fa"
params.genome_bwt = "${params.genome_dir}/GRCh38.p14.genome.fa.bwt"
params.genome_pac = "${params.genome_dir}/GRCh38.p14.genome.fa.pac"
params.genome_ann = "${params.genome_dir}/GRCh38.p14.genome.fa.ann"
params.genome_amb = "${params.genome_dir}/GRCh38.p14.genome.fa.amb"
params.genome_sa = "${params.genome_dir}/GRCh38.p14.genome.fa.sa"
params.outdir = "/projects/sychen/projects/patnsb/ebv_kd_medip/v3/results_nf"

workflow {
	read_pairs_ch = Channel.fromFilePairs( params.reads, checkIfExists:true )
	fastqc_ch=FASTQC(read_pairs_ch)
	MULTIQC(fastqc_ch.collect())
        trim_ch = TRIM(read_pairs_ch)
	fastqc_trim_ch=FASTQC_TRIM(trim_ch.fq)
	MULTIQC_TRIM(fastqc_trim_ch.collect())
	align_ch=BWA_ALIGN(params.genome, params.genome_bwt, params.genome_pac, params.genome_ann, params.genome_amb, params.genome_sa, trim_ch.fq)
}

