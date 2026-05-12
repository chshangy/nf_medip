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
