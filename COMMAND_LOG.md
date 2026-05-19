# Command Log

This file records setup and development commands used for the MeDIP-seq Nextflow pipeline project.

## 2026-05-11: HPC Development Environment Setup

Purpose:

- Create an isolated Conda environment for Nextflow and nf-core pipeline development.
- Avoid installing project tools into the shared `base` environment.
- Keep heavy analysis execution separate from interactive development on the HPC login node.

Server context reported by user:

```text
node --version: v14.21.3
npm --version: 6.14.18
git --version: git version 2.25.1
```

Recommended approach:

- Use a dedicated Conda environment named `medip-nf`.
- Install development tools only in this environment.
- Use Apptainer/Singularity or Nextflow-managed Conda environments for actual pipeline process tools.
- Run heavy Nextflow jobs through the HPC scheduler, not directly on the login node.
- Use PBS as the Nextflow executor on this server.
- Use Singularity via environment modules for containers.
- Do not use Docker for pipeline execution on this shared HPC, even though the `docker` binary is present.

### Script Added

```text
scripts/setup_hpc_dev_env.sh
```

### Basic Usage on the HPC Server

From the project root:

```bash
chmod +x scripts/setup_hpc_dev_env.sh
./scripts/setup_hpc_dev_env.sh
```

The script can also be run from inside the `scripts/` directory:

```bash
cd scripts
bash setup_hpc_dev_env.sh
```

### Troubleshooting: Site Mamba Wrapper Failure

On 2026-05-11, the first run failed on the HPC server with:

```text
Currently, only install, create, list, search, run, info, clean, remove, update, repoquery, activate and deactivate are supported through mamba.

EnvironmentNameNotFound: Could not find conda environment: medip-nf
```

The setup script was updated to:

- Detect when it is launched from inside `scripts/` and move to the project root.
- Use `conda` by default for HPC compatibility.
- Allow `mamba` only when explicitly requested with `USE_MAMBA=1`.
- Check that the environment exists before trying to activate it.

Re-run:

```bash
bash scripts/setup_hpc_dev_env.sh
```

or, from inside `scripts/`:

```bash
bash setup_hpc_dev_env.sh
```

If you specifically want to try `mamba`:

```bash
USE_MAMBA=1 bash setup_hpc_dev_env.sh
```

For this HPC server, plain `conda` is currently recommended because the site `mamba` command appears to report an error without reliably triggering shell fallback behavior.

### Install Codex CLI Too

The setup script skips Codex installation by default. To install Codex CLI using npm inside the `medip-nf` environment:

```bash
INSTALL_CODEX=1 ./scripts/setup_hpc_dev_env.sh
```

Then authenticate:

```bash
conda activate medip-nf
codex login
```

OpenAI currently documents Codex CLI installation with:

```bash
npm install -g @openai/codex
```

Reference:

- OpenAI Help Center: https://help.openai.com/en/articles/11096431-openai-codex-cli-getting-tarted
- OpenAI Codex GitHub repository: https://github.com/openai/codex

### Custom Environment Name

```bash
ENV_NAME=my-medip-env ./scripts/setup_hpc_dev_env.sh
```

### Custom Tool Versions

```bash
PYTHON_VERSION=3.11 JAVA_VERSION=17 NODE_VERSION=20 ./scripts/setup_hpc_dev_env.sh
```

### Check the Environment After Setup

```bash
conda activate medip-nf
python --version
java -version
nextflow -version
nf-core --version
nf-test version
pre-commit --version
git --version
node --version
npm --version
```

### Check HPC Runtime Support

```bash
which sbatch
which qsub
which bsub
which apptainer
which singularity
which docker
```

For most shared HPC systems, Apptainer or Singularity is preferred over Docker.

### Server-specific Runtime Notes

After setup, the server reported:

```text
qsub: /opt/pbs/bin/qsub
qstat: /opt/pbs/bin/qstat
docker: /usr/bin/docker
apptainer: not found
singularity: not found
```

The user confirmed that Singularity is available through environment modules, and Docker should not be used for pipeline execution.

Useful checks:

```bash
module avail singularity
module avail apptainer
module load singularity
singularity --version
```

Recommended Nextflow runtime profile:

```groovy
process {
  executor = 'pbspro'
}

singularity {
  enabled = true
  autoMounts = true
}
```

## 2026-05-11: Initial Nextflow Config

Added a repo-level Nextflow config:

```text
nextflow.config
```

The config includes:

- Project metadata.
- Initial pipeline parameters.
- Runtime reports: timeline, report, trace, and DAG.
- Default process resources.
- Resource labels: `low_mem`, `medium_mem`, `high_mem`, `qc`, `trim`, `align`, and `dmr`.
- Backward-compatible label alias `hign_mem` from the older config typo.
- `local` profile for tiny development tests.
- `hpc_singularity` profile for PBS Pro plus Singularity.
- `hpc_conda` fallback profile for development when containers are temporarily unavailable.

Recommended HPC run pattern:

```bash
conda activate medip-nf
module load singularity/4.2.1
nextflow run . -profile hpc_singularity -resume
```

Notes:

- Docker is disabled in the HPC profiles.
- Singularity is expected to be loaded with `module load singularity/4.2.1`.
- The old per-process Conda activation from `current_scripts/nextflow.config` was not carried forward because the development environment should launch Nextflow, while pipeline tools should be managed by containers or process-level Conda definitions.

## 2026-05-12: Initial DSL2 FASTQ-to-BAM Pipeline

Added the first runnable Nextflow DSL2 pipeline slice:

```text
main.nf
modules/local/fastqc.nf
modules/local/trim_galore.nf
modules/local/bwa_mem_sort.nf
modules/local/multiqc.nf
```

Current workflow:

```text
samplesheet.csv
  -> FastQC on raw FASTQ
  -> Trim Galore paired-end trimming
  -> FastQC on trimmed FASTQ
  -> BWA MEM alignment
  -> samtools sort/index
  -> samtools flagstat/idxstats/stats
  -> MultiQC
```

Required parameters:

```bash
--input test_data/samplesheet.csv
--fasta /path/to/BWA-indexed/reference.fa
```

Recommended HPC test command:

```bash
conda activate medip-nf
module load singularity/4.2.1
nextflow run . \
  -profile hpc_singularity \
  --input test_data/samplesheet.csv \
  --fasta /projects/sychen/projects/patnsb/ebv_kd_medip/ref/GRCh38.p14.genome.fa \
  --outdir results/fastq_to_bam_test \
  -resume
```

Important:

- The reference FASTA must already have BWA index files next to it: `.bwt`, `.pac`, `.ann`, `.amb`, and `.sa`.
- The first implementation uses `bwa`, matching the previously working `current_scripts/nf_v4.nf`.
- This is intentionally a FASTQ-to-BAM first slice. DMR and matrix steps will be added later.

## 2026-05-12: Restart Checkpoint

The user is restarting the Codex app. A compact progress checkpoint was added:

```text
PROGRESS.md
```

Current local project state:

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

Current Git/GitHub status:

- GitHub repository `nf_medip` has been created by the user.
- Local Windows PowerShell currently cannot find `git`.
- User is on the Git for Windows install page.
- Need to finish Git for Windows installation or fix PATH before local `git init`.

Recommended Git troubleshooting after restart:

```powershell
git --version
Test-Path "C:\Program Files\Git\cmd\git.exe"
& "C:\Program Files\Git\cmd\git.exe" --version
```

If Git exists but is not on PATH:

```powershell
$env:Path += ";C:\Program Files\Git\cmd"
git --version
```

Then initialize and push:

```powershell
cd D:\codex_projects\nf_pipelines\nf_medip
git init
git branch -M main
git add .
git commit -m "Initial MeDIP-seq Nextflow pipeline project"
git remote add origin https://github.com/YOUR_USERNAME/nf_medip.git
git push -u origin main
```

## 2026-05-12: PBS Driver Script for FASTQ-to-BAM Test

Added the HPC PBS driver script:

```text
scripts/run_fastq_to_bam.pbs
```

This follows the user's known cluster pattern:

- Submit the main Nextflow process as a PBS job.
- Use `cd "$PBS_O_WORKDIR"` so the job runs from the directory where `qsub` is called.
- Activate the Conda environment with the explicit Miniconda path.
- Load `singularity/4.2.1`.
- Run the `hpc_singularity` profile.

Submit from the Git repo root on the HPC:

```bash
cd /projects/sychen/projects/patnsb/medip/ebv-kd_medip/nf_medip_git
qsub scripts/run_fastq_to_bam.pbs
```

Monitor:

```bash
qstat -u shangying
tail -f logs/nf_medip_fastq_to_bam.out
tail -f logs/nf_medip_fastq_to_bam.err
```

### First Runtime Fix

The first PBS test failed during script compilation:

```text
Error main.nf:85:5: Entry workflow cannot have an emit section
ERROR ~ Script compilation failed
```

Fix:

- Removed the `emit:` block from the entry workflow in `main.nf`.
- The BAM, BAI, and statistics outputs are still published through the module `publishDir` settings.

After pulling the fix on HPC, rerun:

```bash
qsub scripts/run_fastq_to_bam.pbs
```

## 2026-05-12: Downstream Method Selection Plan

The user requested support for both MEDIPS and QSEA for downstream methylation matrix generation and DMR analysis, with user-selectable options.

Confirmed from Bioconductor documentation:

- QSEA is an IP-seq analysis package developed as a successor to MEDIPS for MeDIP-seq.
- QSEA supports transformation of enrichment data to methylation-like beta values and DMR analysis.

References:

- https://bioconductor.org/packages/release/bioc/html/qsea.html
- https://bioconductor.org/packages/release/bioc/vignettes/qsea/inst/doc/qsea_tutorial.html

Updated `nextflow.config` with downstream method parameters:

```text
--methylation_method qsea
--methylation_method medips
--dmr_method qsea
--dmr_method medips
--qsea_window_size
--qsea_fragment_size
--qsea_enrichment_pattern
--qsea_norm_method
--medips_window_size
--medips_extend
--medips_shift
```

Recommended default:

```text
--methylation_method qsea
--dmr_method qsea
```

## 2026-05-12: FASTQ-to-BAM Runtime Fix for Trimmed Read Tuples

The FASTQ-to-BAM PBS run reached the trimming stage, then aborted with:

```text
Input tuple does not match tuple declaration in process `BWA_MEM_SORT`
offending value: [[id:S1E12, single_end:false, strandedness:auto, group:KD],
S1E12_val_1.fq.gz,
S1E12_val_2.fq.gz]
```

Cause:

- `TRIMGALORE_PAIRED` emitted trimmed read pairs as three tuple fields:

```text
meta, read1, read2
```

- `BWA_MEM_SORT` expects the paired reads as one `path(reads)` list:

```text
meta, [read1, read2]
```

Fix:

- Changed `TRIMGALORE_PAIRED` output to emit the trimmed pair as a single path collection:

```nextflow
tuple val(meta), path("${meta.id}_val_*.fq.gz"), emit: reads
```

The same run also showed:

```text
Directive `errorStrategy` doesn't support dynamic value
```

Fix:

- Replaced the dynamic `errorStrategy` closure in `nextflow.config` with static:

```nextflow
errorStrategy = 'terminate'
```

Rerun after pulling the fix:

```bash
qsub scripts/run_fastq_to_bam.pbs
```

## 2026-05-12: FASTQ-to-BAM Runtime Fix for BWA/Samtools Container and Index Staging

The next run reached `BWA_MEM_SORT` and failed with:

```text
.command.sh: line 8: samtools: command not found
[E::bwa_idx_load_from_disk] fail to locate the index files
```

Causes:

- The single-tool BWA Biocontainer does not include `samtools`.
- The BWA index files were not staged with the FASTA inside the task work directory.

Fix:

- Switched the alignment module container to a mulled BWA+samtools image:

```text
quay.io/biocontainers/mulled-v2-fe8faa35dbf6dc65a0f7f5d4ea12e31a79f73e40:219b6c272b25e7e642ae3ff0bf0c5c81a5135ab4-0
```

- Updated `main.nf` to stage:

```text
${params.fasta}
${params.fasta}.amb
${params.fasta}.ann
${params.fasta}.bwt
${params.fasta}.pac
${params.fasta}.sa
```

- Updated `BWA_MEM_SORT` to use the staged FASTA basename in the work directory.

## 2026-05-12: Added Pre-downstream Workflow Stages

Added the next planned workflow stages before region quantification and DMR analysis:

```text
INPUT_CHECK
BAM_FILTER
POST_ALIGNMENT_QC
COVERAGE_SIGNAL
```

New files:

```text
subworkflows/local/input_check.nf
modules/local/bam_filter.nf
modules/local/post_alignment_qc.nf
modules/local/bam_coverage.nf
```

Updated files:

```text
main.nf
modules/local/bwa_mem_sort.nf
nextflow.config
PROGRESS.md
COMMAND_LOG.md
```

Current workflow:

```text
INPUT_CHECK
  -> FASTQC_RAW
  -> TRIMGALORE_PAIRED
  -> FASTQC_TRIM
  -> BWA_MEM_SORT
  -> BAM_FILTER
  -> POST_ALIGNMENT_QC
  -> BAM_COVERAGE
  -> MULTIQC
```

Filtering defaults:

```text
--min_mapq 30
--samtools_exclude_flags 2820
--remove_duplicates false
```

The default exclude flags remove unmapped, secondary, QC-failed, and supplementary reads. Duplicate removal remains optional because duplicate handling in MeDIP-seq can be analysis-dependent.

Coverage defaults:

```text
--coverage_bin_size 50
--coverage_normalize_using CPM
--effective_genome_size null
```

## 2026-05-12: MultiQC Output Directory Fix

The extended FASTQ-to-BAM/QC/coverage run reached the final `MULTIQC` process successfully, but Nextflow failed output validation:

```text
Missing output file(s) `multiqc_data` expected by process `MULTIQC`
```

MultiQC 1.25.1 wrote:

```text
multiqc_report_data
multiqc_report.html
```

Fix:

- Updated `modules/local/multiqc.nf` to accept `multiqc*_data` as the data output directory.

This should allow the run to complete with `-resume` because upstream tasks already succeeded.

## 2026-05-12: Successful FASTQ-to-BAM/QC/Coverage Run

The current workflow completed successfully on the HPC using PBS Pro and Singularity.

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

Run summary from `logs/nf_medip_fastq_to_bam.out`:

```text
Completed at: 12-May-2026 14:50:27
Duration    : 3m 7s
CPU hours   : 41.2 (98.3% cached)
Succeeded   : 7
Cached      : 36
```

This confirms that the first major pipeline layer is working:

```text
raw FASTQ -> trimmed FASTQ -> sorted BAM -> filtered BAM -> post-alignment QC -> bigWig coverage -> MultiQC
```

Next planned implementation area:

```text
region quantification -> QSEA/MEDIPS methylation matrix -> DMR analysis
```

## 2026-05-12: QC Review Bundle Script

Added a helper script to collect reviewable outputs from the successful FASTQ-to-BAM/QC/coverage run:

```text
scripts/collect_fastq_to_bam_qc.sh
```

Usage on HPC from the repo root:

```bash
cd /projects/sychen/projects/patnsb/medip/ebv-kd_medip/nf_medip_git
bash scripts/collect_fastq_to_bam_qc.sh results/fastq_to_bam_test review_fastq_to_bam
```

The script creates:

```text
review_fastq_to_bam.tar.gz
```

The bundle includes:

- MultiQC report and MultiQC data.
- Pipeline info files.
- Combined raw alignment flagstat summaries.
- Combined filtered BAM flagstat summaries.
- Selected samtools stats summaries.
- Inventory of BAM/BAI/bigWig files without including the large files themselves.
- Tail of `.nextflow.log`.
- PBS stdout/stderr logs if present.

The bundle intentionally excludes large FASTQ, BAM, BAI, bigWig, and container image files.

## 2026-05-12: Optional Duplicate Marking

Added optional duplicate marking with `samtools markdup`.

New module:

```text
modules/local/samtools_markdup.nf
```

Updated workflow:

```text
BWA_MEM_SORT
  -> SAMTOOLS_MARKDUP, unless --skip_markduplicates true
  -> BAM_FILTER
  -> POST_ALIGNMENT_QC
  -> BAM_COVERAGE
```

New parameter:

```text
--skip_markduplicates false
```

Existing parameter behavior:

```text
--remove_duplicates false
```

Meaning:

- By default, duplicates are marked and duplicate metrics are produced.
- By default, duplicates are not removed from the filtered BAM.
- If `--remove_duplicates true`, `BAM_FILTER` excludes reads with duplicate flag `1024`.

The module runs:

```text
samtools sort -n
samtools fixmate -m
samtools sort
samtools markdup -s -f metrics
samtools index
samtools flagstat
```

Expected outputs:

```text
results/fastq_to_bam_test/markdup/*.markdup.bam
results/fastq_to_bam_test/markdup/*.markdup.bam.bai
results/fastq_to_bam_test/markdup/*.markdup.metrics.txt
results/fastq_to_bam_test/markdup/*.markdup.flagstat.txt
```

The markdup-enabled run completed successfully on the HPC:

```text
Completed at: 12-May-2026 15:36:52
Duration    : 15m 41s
CPU hours   : 46.5 (85.4% cached)
Succeeded   : 25
Cached      : 24
```

Completed workflow:

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

Recommended duplicate metric check:

```bash
grep -H "DUPLICATE" results/fastq_to_bam_test/markdup/*.markdup.metrics.txt
```

Next step:

```text
Inspect duplicate metrics, then implement QSEA using filtered duplicate-marked BAMs.
```

## 2026-05-12: nf-core Proposal Draft

Prepared a local draft for the nf-core new pipeline proposal:

```text
docs/nf-core-proposal-draft.md
```

Current nf-core proposal process:

- Create a new issue in `nf-core/proposals`.
- Use the "New pipeline" issue template.
- Proposal discussion checks scope, uniqueness, overlap with existing pipelines, and community interest.
- Acceptance requires approval according to the proposal repository automation.

References:

- https://github.com/nf-core/proposals
- https://nf-co.re/docs/tutorials/adding_a_pipeline/test_data
- https://nf-co.re/docs/nf-core-tools/cli/pipelines/create

## 2026-05-12: Combined QSEA Create-set and DMR Module

Added the first QSEA downstream implementation.

New files:

```text
bin/qsea_create_dmr.R
modules/local/qsea_create_dmr.nf
```

Updated files:

```text
main.nf
nextflow.config
subworkflows/local/input_check.nf
PROGRESS.md
COMMAND_LOG.md
```

The QSEA module combines:

```text
filtered duplicate-marked BAMs
  -> qsea sample table
  -> createQseaSet
  -> addCoverage
  -> addCNV
  -> addLibraryFactors
  -> addPatternDensity
  -> addOffset
  -> addEnrichmentParameters
  -> fitNBglm
  -> addContrast
  -> all-region beta/count tables
  -> region-level statistics table
  -> significant and delta-beta-filtered DMR tables
  -> DMR BED
```

QSEA is opt-in for now:

```bash
--analysis_method qsea --contrast KD,control
```

Default:

```text
--analysis_method none
```

Important runtime note:

- The module currently declares a Bioconductor base container:

```text
docker.io/bioconductor/bioconductor_docker:RELEASE_3_21
```

- This image may not include `qsea` and `BSgenome.Hsapiens.UCSC.hg38` by default.
- If the first QSEA test fails due missing R packages, the next step is to create a dedicated QSEA container or switch this step to a Conda-enabled profile using `bioconductor-qsea`.

QSEA output table design was refined so users can join outputs by a stable `region_id`.

Main linked tables:

```text
qsea_region_stats.tsv
qsea_beta_matrix.tsv
qsea_counts_matrix.tsv
qsea_region_annotation.tsv
```

All three include:

```text
region_id
chr
window_start
window_end
CpG_density
```

Purpose:

- `qsea_region_stats.tsv`: DMR statistics, p-values, adjusted p-values, log2FC, deltaBeta, DMR flags.
- `qsea_beta_matrix.tsv`: sample-level and group-mean beta-like methylation values.
- `qsea_counts_matrix.tsv`: sample-level and group-mean counts.
- `qsea_region_annotation.tsv`: ChIPseeker gene annotation for each QSEA window.

The previous comprehensive `qsea_all_regions.tsv` is still written as a convenience/debug output.

Region annotation uses ChIPseeker and is controlled by:

```text
--qsea_annotate_regions true
--qsea_txdb TxDb.Hsapiens.UCSC.hg38.knownGene
--qsea_orgdb org.Hs.eg.db
--qsea_tss_upstream 3000
--qsea_tss_downstream 3000
```

Added a separate PBS driver for explicit QSEA testing:

```text
scripts/run_qsea_test.pbs
```

Submit from the HPC repo root:

```bash
qsub scripts/run_qsea_test.pbs
```

## 2026-05-19: QSEA makeTable Annotation Argument Fix

The custom QSEA container ran successfully and QSEA model fitting completed, but output table generation failed:

```text
Error in makeTable(...):
  annotation must be a named list of GRanges objects
```

Cause:

- The script passed `annotation = NULL` to `makeTable()`.
- QSEA expects the annotation argument to be omitted or supplied as a named list of `GRanges` objects.

Fix:

- Removed `annotation = NULL` from both `makeTable()` calls.
- ChIPseeker-based region annotation remains handled separately in `qsea_region_annotation.tsv`.

Rerun with:

```bash
qsub scripts/run_qsea_test.pbs
```

## 2026-05-19: Successful QSEA Run

The QSEA branch completed successfully.

Run summary:

```text
Completed at: 19-May-2026 15:00:59
Duration    : 16m 22s
CPU hours   : 53.9 (96% cached)
Succeeded   : 1
Cached      : 49
```

Completed workflow:

```text
FASTQC_RAW
TRIMGALORE_PAIRED
FASTQC_TRIM
BWA_MEM_SORT
SAMTOOLS_MARKDUP
BAM_FILTER
POST_ALIGNMENT_QC
BAM_COVERAGE
QSEA_CREATE_DMR
MULTIQC
```

Added QSEA review bundle script:

```text
scripts/collect_qsea_review.sh
```

Usage:

```bash
cd /projects/sychen/projects/patnsb/medip/ebv-kd_medip/nf_medip_git
bash scripts/collect_qsea_review.sh results/fastq_to_bam_test review_qsea
```

The script creates:

```text
review_qsea.tar.gz
```

It includes table dimensions, headers, previews, DMR tables, QSEA logs, Nextflow log tail, and PBS logs.

After QSEA produced millions of windows, the script was updated to exclude large all-region tables by default:

```text
qsea_region_stats.tsv
qsea_beta_matrix.tsv
qsea_counts_matrix.tsv
qsea_region_annotation.tsv
qsea_all_regions.tsv
```

To include full large tables:

```bash
FULL_TABLES=1 bash scripts/collect_qsea_review.sh results/fastq_to_bam_test review_qsea_full
```

## 2026-05-13: QSEA PBS Resource Submission Fix

The first QSEA test reached the `QSEA_CREATE_DMR` process, but PBS rejected the job before execution:

```text
qsub: Job violates queue and/or server resource limits
```

The rejected process was using the initial QSEA label resources:

```text
cpus = 8
memory = 64 GB
time = 72h
queue = long
```

Fix:

- Reduced QSEA process memory to 40 GB.
- Reduced QSEA process walltime to 48 hours.
- Routed QSEA-labeled processes to the `large` queue in the HPC profile.

Updated QSEA resources:

```text
withLabel: qsea {
  cpus = 8
  memory = 40.GB
  time = 48.h
  queue = 'large'
}
```

Rerun after pushing/pulling:

```bash
qsub scripts/run_qsea_test.pbs
```

## 2026-05-19: Restrict Conda to QSEA Process

The first run with `-profile hpc_singularity,qsea_conda` failed in `FASTQC_RAW` before reaching QSEA:

```text
conda: command not found
/bin/activate: No such file or directory
```

Cause:

- The `qsea_conda` profile enabled Conda globally.
- Existing preprocessing modules also have `conda` directives, so Nextflow tried to activate Conda for containerized preprocessing tasks.
- PBS task shells did not have the `conda` executable available on `PATH`.

Fix:

- Keep `conda.enabled = true` for the mixed profile.
- Override non-QSEA labels to `conda = null`, so preprocessing continues to use Singularity containers.
- Keep the QSEA label as Conda-only by setting `container = null`.
- Export `/home/shangying/miniconda3/bin` in `scripts/run_qsea_test.pbs` before launching Nextflow.

Updated:

```text
nextflow.config
scripts/run_qsea_test.pbs
COMMAND_LOG.md
```

## 2026-05-19: Use Explicit Conda Run for QSEA

The QSEA task still failed before R execution:

```text
conda: command not found
/bin/activate: No such file or directory
```

Cause:

- Nextflow-managed Conda activation still requires `conda` to be available inside the PBS task wrapper.
- On this HPC, the task wrapper does not reliably inherit a usable Conda shell environment.

Fix:

- Removed Nextflow's `conda` directive from `QSEA_CREATE_DMR`.
- Kept QSEA container disabled in the `qsea_conda` profile.
- Run QSEA explicitly with:

```bash
/home/shangying/miniconda3/bin/conda run -n qsea-medip Rscript qsea_create_dmr.R ...
```

New parameters:

```text
--qsea_conda_bin /home/shangying/miniconda3/bin/conda
--qsea_conda_env qsea-medip
```

Added environment setup script:

```text
scripts/setup_qsea_conda_env.sh
```

Run once on HPC before rerunning QSEA:

```bash
cd /projects/sychen/projects/patnsb/medip/ebv-kd_medip/nf_medip_git
bash scripts/setup_qsea_conda_env.sh
```

Then submit:

```bash
qsub scripts/run_qsea_test.pbs
```

## 2026-05-19: Switch QSEA Runtime Plan to Singularity Container

The explicit Conda workaround failed because the `qsea-medip` environment did not exist:

```text
EnvironmentLocationNotFound: Not a conda environment: /home/shangying/miniconda3/envs/qsea-medip
```

Decision:

- Use a dedicated QSEA + ChIPseeker container instead of Conda.
- This is better aligned with the rest of the pipeline and with nf-core-style reproducibility.

Added:

```text
containers/qsea/Dockerfile
containers/qsea/README.md
.github/workflows/build-qsea-container.yml
```

Target image:

```text
ghcr.io/chshangy/nf-medip-qsea:0.1.0
```

QSEA process now uses:

```text
docker://ghcr.io/chshangy/nf-medip-qsea:0.1.0
```

The QSEA PBS script now uses only:

```text
-profile hpc_singularity
```

Next steps:

1. Push these files to GitHub.
2. In GitHub, run the `Build QSEA container` workflow manually.
3. Confirm the GHCR package is public or otherwise accessible from the HPC.
4. Pull latest code on HPC.
5. Rerun:

```bash
qsub scripts/run_qsea_test.pbs
```

## 2026-05-13: Pause Checkpoint

The project is paused because the HPC cluster is under maintenance.

Current status:

- GitHub repo is active: <https://github.com/chshangy/nf_medip>
- Preprocessing through duplicate-marked filtered BAM, post-alignment QC, bigWig coverage, and MultiQC is validated on HPC.
- QSEA module has been implemented but not yet successfully run.
- ChIPseeker region annotation has been added to the QSEA R workflow.
- The first QSEA run was blocked by PBS resource limits before R execution.
- QSEA resource fix has been made locally in `nextflow.config`.

Current validated workflow:

```text
INPUT_CHECK
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

Latest successful HPC preprocessing run:

```text
Completed at: 12-May-2026 15:36:52
Duration    : 15m 41s
CPU hours   : 46.5 (85.4% cached)
Succeeded   : 25
Cached      : 24
```

Next actions after maintenance:

```powershell
cd D:\codex_projects\nf_pipelines\nf_medip
git status
git add .
git commit -m "Add QSEA downstream outputs and tune resources"
git push
```

Then on HPC:

```bash
cd /projects/sychen/projects/patnsb/medip/ebv-kd_medip/nf_medip_git
git pull
qsub scripts/run_qsea_test.pbs
```

Expected next possible blocker:

- Missing R/Bioconductor packages inside the current QSEA container.
- If that happens, create a dedicated QSEA + ChIPseeker container or add a Conda-based QSEA execution profile.

## 2026-05-19: QSEA Missing R Package Fix

The QSEA process started but failed inside the generic Bioconductor container:

```text
Error in library(qsea) : there is no package called 'qsea'
```

Cause:

- `docker.io/bioconductor/bioconductor_docker:RELEASE_3_21` does not include the `qsea` package by default.

Fix:

- Added a mixed execution profile:

```text
qsea_conda
```

- The intended run profile is now:

```text
-profile hpc_singularity,qsea_conda
```

Behavior:

- Existing preprocessing modules continue to use Singularity containers.
- The QSEA process disables its container and uses its Conda directive.

QSEA Conda packages:

```text
bioconductor-qsea
bioconductor-bsgenome.hsapiens.ucsc.hg38
bioconductor-biocparallel
bioconductor-chipseeker
bioconductor-txdb.hsapiens.ucsc.hg38.knowngene
bioconductor-org.hs.eg.db
r-base
```

Updated:

```text
modules/local/qsea_create_dmr.nf
nextflow.config
scripts/run_qsea_test.pbs
```

Rerun after pushing/pulling:

```bash
qsub scripts/run_qsea_test.pbs
```


### Second Runtime Fix

The next run failed under Nextflow 26.04.0 with:

```text
Statements cannot be mixed with script declarations -- move statements into a process, workflow, or function
```

Fix:

- Moved top-level `params.input` and `params.fasta` validation into the entry workflow.
- Enabled `overwrite = true` for `trace`, `report`, `timeline`, and `dag` outputs so reruns can reuse the same `--outdir`.

The following run reported the same strict syntax issue for top-level channel creation:

```text
Statements cannot be mixed with script declarations
Channel
    .fromPath(params.input, checkIfExists: true)
```

Fix:

- Moved the `Channel.fromPath(...).splitCsv(...)` sample sheet parsing block into the entry workflow.

The next run reported strict syntax failure for `workflow.onComplete`.

Fix:

- Removed the `workflow.onComplete` callback from `main.nf`.
- Nextflow still records completion status in the standard log/report outputs.

## 2026-05-19: QSEA Review Archive Collection Fix

Observed locally after downloading `review_qsea.tar.gz`:

```bash
tar -tzf review_qsea.tar.gz
```

Result:

```text
review_qsea/
review_qsea/qsea/
review_qsea/logs/
review_qsea/logs/nf_medip_qsea.err
review_qsea/logs/nextflow_tail_300.log
tar.exe: Damaged tar archive (bad header checksum)
tar.exe: Truncated tar archive detected while reading next header
```

Fix:

- Updated `scripts/collect_qsea_review.sh` to locate the real QSEA output directory by checking for `qsea_summary.txt`.
- This supports both `results/.../qsea/qsea_summary.txt` and `results/.../qsea/qsea/qsea_summary.txt`.
- Added `gzip -t "${ARCHIVE}"` so archive corruption is detected before download.
- Updated `modules/local/qsea_create_dmr.nf` so QSEA writes outputs to the process root with `--outdir .`. This makes `publishDir "${params.outdir}/qsea"` publish the final QSEA files directly under `results/.../qsea/` rather than preserving a nested `qsea/` subdirectory.
- Added `qsea_dmr_filtered_annotated.tsv`, which joins filtered DMR statistics with ChIPseeker annotation by `region_id`.

Recommended rerun on HPC:

```bash
qsub scripts/run_qsea_test.pbs
bash scripts/collect_qsea_review.sh results/fastq_to_bam_test review_qsea_light
gzip -t review_qsea_light.tar.gz
tar -tzf review_qsea_light.tar.gz | head -50
ls -lh review_qsea_light.tar.gz
```
