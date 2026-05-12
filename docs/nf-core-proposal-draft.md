# nf-core New Pipeline Proposal Draft: medipseq

## Proposed Pipeline Name

`nf-core/medipseq`

Alternative names if the community prefers broader assay coverage:

- `nf-core/dipseq`
- `nf-core/methylipseq`

## One-line Summary

A Nextflow pipeline for MeDIP-seq and related methylated DNA immunoprecipitation sequencing data, from raw FASTQ or BAM files through QC, alignment, methylation-enrichment modeling, beta-like methylation estimation, and DMR analysis.

## Proposer

- Name: Shangying Chen
- GitHub: `@chshangy`
- Initial development repository: <https://github.com/chshangy/nf_medip>

## Scientific Motivation

Methylated DNA Immunoprecipitation Sequencing (MeDIP-seq) is an antibody-enrichment sequencing assay used to profile methylated DNA. It differs from bisulfite-based methylation assays because it measures enrichment over genomic regions rather than direct single-base methylation states.

A dedicated MeDIP-seq pipeline would help users process enrichment-based methylation sequencing data reproducibly and would fill a gap between existing methylation and ChIP-seq style workflows.

## Why This Is Distinct From Existing nf-core Pipelines

`nf-core/methylseq` is designed for bisulfite-style methylation sequencing workflows such as WGBS, RRBS, EM-seq, and related assays. Those workflows use bisulfite-aware aligners and methylation callers that infer cytosine-level methylation states.

MeDIP-seq is different:

- Reads are not bisulfite-converted.
- Standard DNA aligners such as BWA or Bowtie2 are appropriate.
- Signal is enrichment-based and region/window-level.
- CpG density and antibody enrichment biases must be considered.
- Downstream methods such as QSEA and MEDIPS are more appropriate than bisulfite methylation callers.

The proposed pipeline should therefore be a separate workflow rather than an extension of `nf-core/methylseq`.

## Target Users

- Researchers analyzing MeDIP-seq, hMeDIP-seq, or related DNA immunoprecipitation sequencing data.
- Cancer epigenomics and viral/host methylation studies.
- Labs with MeDIP-seq datasets that need a reproducible path from raw FASTQ to DMRs.
- Users who want nf-core-style execution on HPC systems with Singularity/Apptainer, Docker, or Conda.

## Initial Scope

The first production goal is MeDIP-seq analysis from FASTQ or BAM inputs to analysis-ready BAMs, coverage tracks, QSEA/MEDIPS outputs, and DMR tables.

Supported input modes:

- Paired-end FASTQ sample sheet.
- Optional pre-aligned BAM input in a later milestone.

Initial workflow:

```text
INPUT_CHECK
FASTQ_QC
TRIMMING
ALIGNMENT
MARK_DUPLICATES
BAM_FILTERING
POST_ALIGNMENT_QC
COVERAGE_SIGNAL
QSEA or MEDIPS
DMR_ANALYSIS
ANNOTATION
REPORTING
```

## Core Outputs

Early processing outputs:

- Raw-read FastQC reports.
- Trimmed FASTQ files and trimming reports.
- Sorted and indexed BAM files.
- Duplicate-marked BAM files and duplicate metrics.
- Filtered BAM files.
- Post-alignment samtools QC metrics.
- Normalized bigWig coverage tracks.
- MultiQC report.

Downstream outputs:

- QSEA beta-like methylation matrix.
- QSEA DMR table and BED file.
- MEDIPS enrichment/count matrix or differential enrichment output.
- MEDIPS DMR table and BED file.
- DMR annotation against genes, promoters, CpG islands, and optional custom BED files.
- Final summary report.

## Downstream Method Design

The pipeline should allow the user to choose the downstream method:

```bash
--analysis_method qsea
--analysis_method medips
--analysis_method both
```

Recommended default:

```bash
--analysis_method qsea
```

Rationale:

- QSEA is designed for quantitative sequencing enrichment analysis of MeDIP-seq and related IP-seq data.
- QSEA can estimate methylation levels from enrichment data and produce beta-like matrices.
- MEDIPS is a known MeDIP-seq package and should be provided as an alternative branch for users familiar with that framework.

Important documentation point:

- QSEA outputs can be described as beta-like methylation estimates.
- MEDIPS outputs should be described more conservatively as enrichment/count/differential coverage results unless a clearly defined transformation is implemented.

## Proposed Tools

Preprocessing:

- FastQC.
- Trim Galore / Cutadapt.
- BWA MEM initially; BWA-MEM2 or Bowtie2 could be added later.
- samtools.
- samtools markdup initially; Picard MarkDuplicates may be added as an option.
- deepTools bamCoverage.
- MultiQC.

Downstream:

- QSEA.
- MEDIPS.
- Bioconductor annotation packages and/or ChIPseeker.
- bedtools for interval operations where needed.

## Current Development Status

Initial development is underway at:

<https://github.com/chshangy/nf_medip>

Current tested stages:

```text
INPUT_CHECK
FASTQ_QC
TRIMMING
ALIGNMENT
BAM_FILTERING
POST_ALIGNMENT_QC
COVERAGE_SIGNAL
MULTIQC
```

Tested on an HPC system using:

- PBS Pro executor.
- Singularity 4.2.1.
- Nextflow 26.04.0 on the server.

The first FASTQ-to-BAM/QC/coverage layer completed successfully on six paired-end MeDIP-seq samples.

Duplicate marking with samtools markdup has been added locally and is the next stage to validate.

## Test Data Plan

The current development test uses a private real MeDIP-seq dataset and cannot be uploaded to nf-core test datasets.

For nf-core readiness, we will prepare a minimal public/synthetic test dataset:

- Two control samples.
- Two treatment samples.
- Small FASTQ subsets.
- Small reference region or miniature test genome.
- Tiny annotation BED where needed.

The goal is to keep CI fast while still exercising:

- FASTQ input validation.
- Trimming.
- Alignment.
- Duplicate marking.
- Filtering.
- Coverage.
- QSEA or a small downstream smoke test.
- MEDIPS or a small downstream smoke test.
- MultiQC report generation.

## Planned Milestones

### Milestone 1: FASTQ-to-BAM Processing

- Sample sheet validation.
- Raw FastQC.
- Trim Galore.
- BWA alignment.
- Sorted/indexed BAM.
- samtools QC.
- MultiQC.

Status: completed and tested on HPC.

### Milestone 2: Duplicate Marking and Final BAM QC

- Add samtools markdup.
- Report duplicate metrics.
- Keep duplicate removal optional.

Status: implemented locally; awaiting HPC validation.

### Milestone 3: QSEA Branch

- Use filtered/duplicate-marked BAM files.
- Generate beta-like methylation matrix.
- Run group comparison and DMR analysis.
- Export DMR tables and BED files.
- Add QSEA QC outputs.

### Milestone 4: MEDIPS Branch

- Use filtered/duplicate-marked BAM files.
- Generate MEDIPS enrichment/count outputs.
- Run differential enrichment / DMR analysis.
- Export DMR tables and BED files.

### Milestone 5: Annotation and Reports

- Annotate DMRs.
- Add promoter/CpG island/gene context.
- Add final report sections and method text.

### Milestone 6: nf-core Compatibility

- Rebuild or migrate into the official nf-core template.
- Add nf-test tests.
- Add CI.
- Add docs, schema, citations, methods description.
- Run nf-core lint.
- Prepare tiny public test data.

## Open Questions for nf-core Community

- Preferred final pipeline name: `medipseq`, `dipseq`, or another name?
- Should hMeDIP-seq and other DNA IP-seq assays be included in the initial scope?
- Should `nf-core/methylseq` documentation cross-link to this pipeline once mature?
- Should BWA MEM, BWA-MEM2, or Bowtie2 be the default aligner?
- Should duplicate marking be enabled by default but removal disabled by default?
- Should QSEA be the default downstream method?
- Should MEDIPS be included in the first release or added after QSEA is stable?

## References

- nf-core proposal process: <https://github.com/nf-core/proposals>
- nf-core new pipeline documentation: <https://nf-co.re/docs/tutorials/adding_a_pipeline/test_data>
- nf-core pipeline creation documentation: <https://nf-co.re/docs/nf-core-tools/cli/pipelines/create>
- QSEA Bioconductor package: <https://bioconductor.org/packages/release/bioc/html/qsea.html>
- MEDIPS Bioconductor package: <https://bioconductor.org/packages/release/bioc/html/MEDIPS.html>

