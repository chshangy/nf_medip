# MeDIP-seq Nextflow Pipeline Project Plan

## 1. Project Objective

The objective of this project is to develop a reproducible Nextflow pipeline for the processing and analysis of Methylated DNA Immunoprecipitation Sequencing (MeDIP-seq) data.

The pipeline should support analysis from raw sequencing reads through quality control, alignment, methylation-enrichment signal generation, region-level methylation matrix construction, and differential methylated region (DMR) analysis.

After implementation, validation, and community review, the long-term goal is to prepare the pipeline for submission to the nf-core community.

## 2. Scientific Scope

MeDIP-seq is an enrichment-based DNA methylation profiling assay. Unlike bisulfite sequencing, it does not directly measure methylation at single-base resolution. The pipeline should therefore focus on region-level methylation enrichment and DMR detection.

The pipeline should support:

- Raw FASTQ processing.
- Single-end and paired-end MeDIP-seq data.
- Optional pre-aligned BAM input.
- Optional matrix-only input for downstream DMR analysis.
- Region-level methylation signal quantification.
- Normalized methylation enrichment matrices.
- Optional beta-like matrices, clearly documented as enrichment-derived estimates rather than true bisulfite-style beta values.
- Group-wise DMR analysis.
- Annotation and reporting of DMRs.

The first production-ready version should prioritize 5mC MeDIP-seq. Support for hMeDIP-seq, DIP-seq, or other antibody-enrichment assays can be added later if the workflow and documentation are general enough.

## 3. Relationship to Existing nf-core Pipelines

The nf-core community already maintains `nf-core/methylseq`, which is designed for bisulfite-style methylation sequencing workflows such as WGBS, RRBS, EM-seq, and related assays.

This proposed pipeline is different because MeDIP-seq is antibody-enrichment based. It requires analysis methods closer to ChIP-seq and DNA enrichment workflows, with MeDIP-specific normalization, CpG-density awareness, and region-level DMR analysis.

Before requesting nf-core inclusion, the project should open a proposal in the nf-core proposals repository and explain clearly why this workflow is distinct from `nf-core/methylseq`.

## 4. Proposed Pipeline Name

Working name:

```text
nf-core/medipseq
```

The final name should be confirmed with the nf-core community during the proposal stage.

## 5. Main Input Modes

### 5.1 FASTQ Input

Primary input mode for full analysis from raw data.

Example sample sheet:

```csv
sample,fastq_1,fastq_2,group,replicate,antibody,input_control,genome
sample1,path/sample1_R1.fastq.gz,path/sample1_R2.fastq.gz,case,1,5mC,,GRCh38
sample2,path/sample2_R1.fastq.gz,path/sample2_R2.fastq.gz,control,1,5mC,,GRCh38
```

### 5.2 BAM Input

Secondary input mode for users who already have aligned data.

Example sample sheet:

```csv
sample,bam,bai,group,replicate,genome
sample1,path/sample1.bam,path/sample1.bam.bai,case,1,GRCh38
sample2,path/sample2.bam,path/sample2.bam.bai,control,1,GRCh38
```

### 5.3 Matrix Input

Optional downstream-only mode for users who already have a methylation-enrichment or beta-like matrix.

Example sample sheet:

```csv
sample,matrix,group,replicate
sample1,path/matrix.tsv,case,1
sample2,path/matrix.tsv,control,1
```

## 6. Proposed Workflow Architecture

The pipeline should use Nextflow DSL2 and follow nf-core template conventions.

Recommended subworkflows:

```text
INPUT_CHECK
FASTQ_QC
TRIMMING
ALIGNMENT
BAM_FILTERING
POST_ALIGNMENT_QC
COVERAGE_SIGNAL
REGION_QUANTIFICATION
METHYLATION_MATRIX
DMR_ANALYSIS
ANNOTATION
REPORTING
```

Each major analysis stage should be modular, testable, and documented independently.

## 7. Core Analysis Steps

### 7.1 Input Validation

Validate the sample sheet before running expensive analysis.

Checks should include:

- Required columns are present.
- FASTQ, BAM, BAI, and matrix files exist.
- Sample names are unique.
- Group labels are valid.
- Replicate values are valid.
- Paired-end FASTQs are complete when required.
- Contrasts requested by the user exist in the sample sheet.

### 7.2 Raw Read Quality Control

Recommended tools:

- FastQC.
- MultiQC.

Outputs:

```text
results/fastqc/
results/multiqc/
```

Important metrics:

- Per-base sequence quality.
- Adapter content.
- GC content.
- Sequence duplication.
- Overrepresented sequences.

### 7.3 Read Trimming

Recommended first implementation:

- fastp.

Alternative:

- Trim Galore.

Outputs:

```text
results/fastp/
```

Parameters:

```text
--skip_trimming
--trim_tool fastp
```

### 7.4 Alignment

Recommended first implementation:

- BWA-MEM2.

Alternative:

- Bowtie2.

MeDIP-seq reads are standard genomic DNA reads, not bisulfite-converted reads, so bisulfite-aware aligners are not appropriate for the default workflow.

Outputs:

```text
results/alignment/
```

Expected files:

```text
sample.sorted.bam
sample.sorted.bam.bai
```

### 7.5 BAM Filtering and Deduplication

Recommended tools:

- samtools.
- Picard MarkDuplicates.

Filtering options:

- Remove unmapped reads.
- Filter by mapping quality.
- Remove secondary alignments where appropriate.
- Mark or remove duplicates.
- Index final BAM files.

Parameters:

```text
--min_mapq 30
--remove_duplicates
--keep_duplicates
```

Outputs:

```text
results/bam_filter/
results/picard/
results/samtools/
```

### 7.6 Post-alignment QC

Recommended metrics:

- Mapping rate.
- Proper-pair rate.
- Duplicate rate.
- Insert size distribution.
- Library complexity.
- Genome coverage.
- Sample correlation.
- PCA or clustering.
- CpG enrichment.

Recommended tools:

- samtools.
- Picard.
- deepTools.
- MEDIPS.

Outputs:

```text
results/qc/
results/deeptools/
results/medips_qc/
```

### 7.7 Coverage and Signal Track Generation

Generate normalized tracks for visualization in genome browsers.

Recommended tools:

- deepTools `bamCoverage`.
- Optional bedGraph conversion.

Outputs:

```text
results/tracks/
```

Expected files:

```text
sample.bw
sample.bedgraph
```

Parameters:

```text
--bin_size 50
--normalize_using CPM
--effective_genome_size
```

### 7.8 Region-level Quantification

Because MeDIP-seq is enrichment based, the main quantitative output should be a region-level matrix.

Supported region modes:

- Fixed-width genome windows.
- CpG islands.
- Promoters.
- Gene bodies.
- User-provided BED regions.

Outputs:

```text
results/counts/
```

Expected files:

```text
region_counts.tsv
normalized_enrichment_matrix.tsv
```

Parameters:

```text
--regions fixed_windows
--window_size 500
--annotation_bed
--cpg_bed
--promoter_bed
```

### 7.9 Methylation Matrix Generation

The pipeline should produce multiple matrix types where possible:

- Raw region counts.
- Library-size normalized region counts.
- CpG-density adjusted enrichment values.
- Optional beta-like scaled values.

The documentation must clearly state that beta-like values from MeDIP-seq are not equivalent to beta values from methylation arrays, WGBS, or RRBS.

Outputs:

```text
results/matrix/
```

### 7.10 DMR Analysis

Recommended first implementation:

- MEDIPS.

MEDIPS is designed for MeDIP-seq and related DNA immunoprecipitation sequencing data. It supports MeDIP-specific quality control and differential coverage analysis.

Future optional methods:

- edgeR on region counts.
- DESeq2 on region counts.
- csaw-style window-based differential enrichment.

Outputs:

```text
results/dmr/
```

Expected DMR table columns:

```text
chrom
start
end
region_id
mean_group1
mean_group2
log2FC
pvalue
padj
direction
n_cpg
annotation
nearest_gene
```

Parameters:

```text
--contrast case,control
--dmr_method medips
--fdr 0.05
--min_abs_log2fc 1
--min_cpgs 3
```

### 7.11 DMR Annotation

Recommended tools:

- ChIPseeker.
- HOMER.
- bedtools.
- Bioconductor annotation packages.

Annotation categories:

- Promoter.
- Exon.
- Intron.
- Intergenic.
- CpG island.
- CpG shore.
- CpG shelf.
- Repeat regions, if supplied.

Outputs:

```text
results/annotation/
```

### 7.12 Reporting

The pipeline should generate a consolidated report using MultiQC and custom report sections.

Report sections:

- Run summary.
- Input sample summary.
- Read QC.
- Trimming summary.
- Alignment summary.
- Duplicate summary.
- MeDIP-specific QC.
- Sample correlation and PCA.
- Region quantification summary.
- DMR summary.
- Tool versions.
- Methods description.

Outputs:

```text
results/multiqc/
results/pipeline_info/
```

## 8. Expected Output Directory Structure

Proposed output structure:

```text
results/
  fastqc/
  fastp/
  alignment/
  bam_filter/
  picard/
  samtools/
  deeptools/
  tracks/
  medips_qc/
  counts/
  matrix/
  dmr/
  annotation/
  multiqc/
  pipeline_info/
```

## 9. Key Parameters

Initial parameter set:

```text
--input
--outdir
--genome
--fasta
--gtf
--aligner
--skip_fastqc
--skip_trimming
--trim_tool
--min_mapq
--remove_duplicates
--regions
--window_size
--annotation_bed
--cpg_bed
--promoter_bed
--normalize_using
--matrix_type
--contrast
--dmr_method
--fdr
--min_abs_log2fc
--min_cpgs
```

## 10. Implementation Milestones

### Milestone 1: nf-core Template and Repository Setup

- Create the pipeline using `nf-core pipelines create`.
- Keep the initial template commit intact.
- Work on the `dev` branch.
- Add project documentation.
- Define the sample sheet schema.
- Add initial parameter schema.

### Milestone 2: FASTQ to BAM Workflow

- Add FastQC.
- Add trimming.
- Add alignment.
- Add sorted and indexed BAM generation.
- Add basic MultiQC reporting.

### Milestone 3: BAM Filtering and Alignment QC

- Add mapping quality filtering.
- Add duplicate marking or removal.
- Add samtools statistics.
- Add Picard metrics.
- Add insert-size and library-complexity metrics.

### Milestone 4: MeDIP-specific QC and Signal Tracks

- Add normalized bigWig generation.
- Add sample correlation.
- Add PCA or clustering.
- Add CpG enrichment metrics.
- Add MEDIPS QC where practical.

### Milestone 5: Region Quantification and Matrix Generation

- Add fixed-window quantification.
- Add user BED quantification.
- Add CpG island or promoter region quantification.
- Generate raw count and normalized enrichment matrices.
- Add optional beta-like matrix generation with careful documentation.

### Milestone 6: DMR Analysis

- Add MEDIPS-based DMR analysis.
- Support pairwise contrasts.
- Generate DMR tables and BED files.
- Add summary plots.

### Milestone 7: Annotation and Final Reports

- Add DMR annotation.
- Add DMR distribution plots.
- Add final MultiQC custom sections.
- Complete usage and output documentation.

### Milestone 8: Testing and nf-core Readiness

- Add minimal test profile.
- Add full test profile.
- Add nf-test tests.
- Add small test dataset.
- Run `nf-core pipelines lint`.
- Run `pre-commit run --all-files`.
- Run local pipeline tests with Docker or Singularity.
- Open nf-core proposal.
- Address community review.

## 11. Testing Plan

### 11.1 Minimal Test

Purpose:

- Confirm that the pipeline runs end-to-end.
- Use tiny FASTQ files and a small reference region.

Command:

```bash
nextflow run . -profile test,docker --outdir results
```

### 11.2 Full Test

Purpose:

- Test more realistic execution.
- Include multiple biological groups and replicates.
- Confirm DMR output generation.

Command:

```bash
nextflow run . -profile test_full,docker --outdir results_full
```

### 11.3 nf-test

Use nf-test for:

- Module tests.
- Subworkflow tests.
- Full pipeline snapshot tests.

Command:

```bash
nf-test test
```

### 11.4 nf-core Linting

Run regularly:

```bash
nf-core pipelines lint
```

Also run:

```bash
pre-commit run --all-files
```

## 12. nf-core Submission Plan

Recommended nf-core path:

1. Open an issue in the nf-core proposals repository.
2. Explain the scientific scope and distinction from `nf-core/methylseq`.
3. Create the pipeline using the nf-core template.
4. Develop under a personal GitHub account first.
5. Keep all development on `dev`.
6. Add small test data to `nf-core/test-datasets` after discussion.
7. Make sure CI, linting, nf-test, and documentation are complete.
8. Request transfer to the nf-core organization when the pipeline is mature.
9. Complete community review.
10. Prepare the first stable release.

## 13. Documentation Requirements

The pipeline should include:

- `README.md`.
- `docs/usage.md`.
- `docs/output.md`.
- `docs/README.md`.
- `CITATIONS.md`.
- `assets/methods_description_template.yml`.
- Parameter schema documentation.
- Sample sheet documentation.
- Test profile documentation.

Documentation must clearly describe:

- What MeDIP-seq can and cannot measure.
- How methylation enrichment matrices are generated.
- How beta-like matrices differ from true methylation beta values.
- Which DMR methods are supported.
- What each output file means.

## 14. Risks and Decisions to Resolve

Open technical decisions:

- Whether BWA-MEM2 or Bowtie2 should be the default aligner.
- Whether duplicate reads should be removed by default.
- Which region mode should be the default: fixed windows, CpG islands, or user BED.
- Whether MEDIPS alone is sufficient for the first DMR implementation.
- Whether input-control libraries should be supported in the first release.
- How to define beta-like values in a scientifically conservative way.

Recommended initial defaults:

- Default aligner: BWA-MEM2.
- Default region mode: fixed windows.
- Default window size: 500 bp.
- Default DMR method: MEDIPS.
- Default duplicate handling: mark duplicates and allow optional removal.
- Default matrix output: raw counts and normalized enrichment, not beta-like values.

## 15. First Version Success Criteria

The first useful version should be considered complete when it can:

- Accept a valid FASTQ sample sheet.
- Run QC, trimming, alignment, filtering, and reporting.
- Generate sorted and indexed BAM files.
- Generate normalized coverage tracks.
- Generate region-level count and normalized enrichment matrices.
- Run DMR analysis for at least one pairwise contrast.
- Annotate DMRs.
- Produce a complete MultiQC report.
- Pass the test profile.
- Pass nf-core linting with no critical errors.
- Provide clear usage and output documentation.

