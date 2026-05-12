# Project Progress

Last updated: 2026-05-12

## Current Goal

Build a Nextflow DSL2 MeDIP-seq pipeline that starts with raw FASTQ files and initially produces sorted/indexed BAM files, then later extend to methylation-enrichment matrices and DMR analysis. The long-term goal is to develop toward nf-core community standards.

## Current Repository State

Important files:

```text
PROJECT_PLAN.md
COMMAND_LOG.md
PROGRESS.md
nextflow.config
main.nf
scripts/setup_hpc_dev_env.sh
test_data/samplesheet.csv
test_data/samplesheet.updated.csv
modules/local/fastqc.nf
modules/local/trim_galore.nf
modules/local/bwa_mem_sort.nf
modules/local/multiqc.nf
current_scripts/nf_v4.nf
current_scripts/nextflow.config
current_scripts/job_nf.pbs
```

## Completed

- Wrote project objective and roadmap in `PROJECT_PLAN.md`.
- Created HPC development environment setup script: `scripts/setup_hpc_dev_env.sh`.
- Created `COMMAND_LOG.md` to record setup and workflow commands.
- Created initial `nextflow.config`.
- Configured intended HPC runtime:
  - Scheduler: PBS Pro.
  - Container runtime: Singularity.
  - Singularity module: `singularity/4.2.1`.
  - Docker disabled for HPC execution.
- Created first DSL2 FASTQ-to-BAM pipeline slice:
  - `main.nf`
  - `modules/local/fastqc.nf`
  - `modules/local/trim_galore.nf`
  - `modules/local/bwa_mem_sort.nf`
  - `modules/local/multiqc.nf`
- Added the next pre-downstream workflow stages:
  - `subworkflows/local/input_check.nf`
  - `modules/local/bam_filter.nf`
  - `modules/local/post_alignment_qc.nf`
  - `modules/local/bam_coverage.nf`
- Added optional duplicate marking with `samtools markdup`:
  - `modules/local/samtools_markdup.nf`
- Successfully tested duplicate marking on the HPC with PBS Pro and Singularity.
- Added first combined QSEA create-set and DMR module:
  - `bin/qsea_create_dmr.R`
  - `modules/local/qsea_create_dmr.nf`
- Successfully tested the current workflow on the HPC with PBS Pro and Singularity.
- Started downstream design for user-selectable QSEA and MEDIPS analysis.

## HPC Environment Status

The `medip-nf` Conda environment was created successfully on the HPC server.

Confirmed tool versions:

```text
Python 3.11.15
OpenJDK 17.0.18
Nextflow 24.10.3
nf-core/tools 4.0.2
nf-test 0.9.5
pre-commit 4.6.0
git 2.54.0
node v20.20.2
npm 10.8.2
```

HPC scheduler/container notes:

```text
qsub/qstat available: PBS Pro
singularity available by module: singularity/3.11.0 and singularity/4.2.1
docker binary exists but should not be used
```

Recommended HPC setup before testing:

```bash
conda activate medip-nf
module load singularity/4.2.1
```

## Current Pipeline Test Command

Run from the HPC project root:

```bash
cd /projects/sychen/projects/patnsb/medip/ebv-kd_medip/nf_medip
conda activate medip-nf
module load singularity/4.2.1

nextflow run . \
  -profile hpc_singularity \
  --input test_data/samplesheet.csv \
  --fasta /projects/sychen/projects/patnsb/ebv_kd_medip/ref/GRCh38.p14.genome.fa \
  --outdir results/fastq_to_bam_test \
  -resume
```

Before the full run, validate config parsing:

```bash
nextflow config -profile hpc_singularity
```

## Latest Successful HPC Test

The pipeline ran successfully on 2026-05-12, first without duplicate marking and then again with `samtools markdup` enabled.

Completed stages:

```text
FASTQC_RAW
TRIMGALORE_PAIRED
FASTQC_TRIM
BWA_MEM_SORT
BAM_FILTER
POST_ALIGNMENT_QC
BAM_COVERAGE
MULTIQC
```

HPC summary:

```text
Completed at: 12-May-2026 14:50:27
Duration    : 3m 7s
CPU hours   : 41.2 (98.3% cached)
Succeeded   : 7
Cached      : 36
```

Latest run with duplicate marking:

```text
Completed at: 12-May-2026 15:36:52
Duration    : 15m 41s
CPU hours   : 46.5 (85.4% cached)
Succeeded   : 25
Cached      : 24
```

Completed stages in latest run:

```text
FASTQC_RAW
TRIMGALORE_PAIRED
FASTQC_TRIM
BWA_MEM_SORT
SAMTOOLS_MARKDUP
BAM_FILTER
POST_ALIGNMENT_QC
BAM_COVERAGE
MULTIQC
```

Expected result directories:

```text
results/fastq_to_bam_test/fastqc/
results/fastq_to_bam_test/trim_galore/
results/fastq_to_bam_test/alignment/
results/fastq_to_bam_test/bam_filter/
results/fastq_to_bam_test/post_alignment_qc/
results/fastq_to_bam_test/coverage/
results/fastq_to_bam_test/multiqc/
results/fastq_to_bam_test/pipeline_info/
```

## Known Issues / Next Things To Check

- `test_data/samplesheet.csv` in the local Windows workspace was locked by another process, so it could not be overwritten.
- A corrected companion file was created:

```text
test_data/samplesheet.updated.csv
```

- The user said the FASTQ files and sample sheet are now prepared on the server. Confirm the server-side `test_data/samplesheet.csv` paths point to:

```text
/projects/sychen/projects/patnsb/medip/ebv-kd_medip/nf_medip/raw
```

- The local Windows machine currently does not recognize `git` in PowerShell.
- User created GitHub repo:

```text
nf_medip
```

- Need to install or fix Git for Windows PATH before committing/pushing from local.
- If Git for Windows is installed, test:

```powershell
Test-Path "C:\Program Files\Git\cmd\git.exe"
& "C:\Program Files\Git\cmd\git.exe" --version
```

- If that works, temporarily add Git to PATH:

```powershell
$env:Path += ";C:\Program Files\Git\cmd"
git --version
```

## Likely First Pipeline Runtime Issue

The current `BWA_MEM_SORT` module uses a BWA container and pipes to `samtools sort`.

If the container does not include `samtools`, the HPC run may fail at alignment. If that happens, fix by either:

- switching to a container that includes both BWA and samtools, or
- splitting alignment and samtools sorting/statistics into separate modules.

## Immediate Next Step After Restart

1. Inspect duplicate metrics from `results/fastq_to_bam_test/markdup/`.
2. Confirm filtered BAMs are generated from marked BAMs and duplicate removal remains disabled by default.
3. Test the QSEA downstream branch using filtered/duplicate-marked BAMs.
4. Resolve QSEA runtime dependency/container strategy if needed.
5. Add MEDIPS after QSEA is working.

## Downstream Analysis Direction

The downstream methylation matrix and DMR workflow should start after the filtered BAM and coverage stage, and should support both:

- QSEA.
- MEDIPS.

Planned user-facing method parameters:

```text
--analysis_method qsea
--analysis_method medips
--analysis_method both
--methylation_method qsea
--methylation_method medips
--dmr_method qsea
--dmr_method medips
```

Recommended default:

```text
--analysis_method none
```

Rationale:

- QSEA is designed for MeDIP-seq/IP-seq data analysis and is described by Bioconductor as a successor to MEDIPS.
- QSEA can generate methylation-like beta estimates from MeDIP-seq enrichment data.
- MEDIPS remains useful as a known MeDIP-seq method and should be available as an alternative.

For development, `analysis_method` currently defaults to `none` so the validated preprocessing workflow remains stable. QSEA is enabled explicitly with:

```bash
--analysis_method qsea --contrast KD,control
```

Main linked QSEA output tables:

```text
qsea_region_stats.tsv
qsea_beta_matrix.tsv
qsea_counts_matrix.tsv
qsea_region_annotation.tsv
```

All tables use `region_id` so users can join region statistics, beta-like methylation values, counts, and ChIPseeker gene annotation.
