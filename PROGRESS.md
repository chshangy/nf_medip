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

1. Confirm Git for Windows is installed and available in PowerShell.
2. Add a `.gitignore`.
3. Initialize Git and push to the GitHub `nf_medip` repo.
4. Pull/clone on HPC.
5. Run `nextflow config -profile hpc_singularity`.
6. Run the FASTQ-to-BAM test.

