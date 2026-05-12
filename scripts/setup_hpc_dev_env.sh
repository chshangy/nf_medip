#!/usr/bin/env bash

set -euo pipefail

ENV_NAME="${ENV_NAME:-medip-nf}"
PYTHON_VERSION="${PYTHON_VERSION:-3.11}"
JAVA_VERSION="${JAVA_VERSION:-17}"
NODE_VERSION="${NODE_VERSION:-20}"
INSTALL_CODEX="${INSTALL_CODEX:-0}"
USE_MAMBA="${USE_MAMBA:-0}"
LOG_DIR="${LOG_DIR:-setup_logs}"
LOG_FILE="${LOG_DIR}/setup_hpc_dev_env_$(date +%Y%m%d_%H%M%S).log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ "$(basename "$(pwd)")" == "scripts" && "$(pwd)" == "${SCRIPT_DIR}" ]]; then
    cd "${PROJECT_ROOT}"
fi

mkdir -p "${LOG_DIR}"

exec > >(tee -a "${LOG_FILE}") 2>&1

echo "MeDIP-seq nf-core development environment setup"
echo "Started: $(date)"
echo "Working directory: $(pwd)"
echo "Environment name: ${ENV_NAME}"
echo

if ! command -v conda >/dev/null 2>&1; then
    echo "ERROR: conda was not found in PATH."
    echo "Load your site's Anaconda/Miniconda module first, or install Miniconda/Mambaforge in your home directory."
    exit 1
fi

eval "$(conda shell.bash hook)"

if [[ "${USE_MAMBA}" == "1" ]] && command -v mamba >/dev/null 2>&1; then
    PREFERRED_FRONTEND="mamba"
else
    PREFERRED_FRONTEND="conda"
fi

echo "Preferred package manager: ${PREFERRED_FRONTEND}"
if [[ "${USE_MAMBA}" != "1" ]]; then
    echo "Mamba is disabled by default for HPC compatibility. Set USE_MAMBA=1 to opt in."
fi
echo

if conda env list | awk '{print $1}' | grep -qx "${ENV_NAME}"; then
    echo "Conda environment '${ENV_NAME}' already exists. Updating it."
    if [[ "${PREFERRED_FRONTEND}" == "mamba" ]]; then
        mamba install -y -n "${ENV_NAME}" \
            -c conda-forge -c bioconda \
            "python=${PYTHON_VERSION}" \
            "openjdk=${JAVA_VERSION}" \
            nextflow \
            nf-core \
            nf-test \
            pre-commit \
            git \
            "nodejs=${NODE_VERSION}" || {
                echo "mamba install failed. Falling back to conda install."
                conda install -y -n "${ENV_NAME}" \
                    -c conda-forge -c bioconda \
                    "python=${PYTHON_VERSION}" \
                    "openjdk=${JAVA_VERSION}" \
                    nextflow \
                    nf-core \
                    nf-test \
                    pre-commit \
                    git \
                    "nodejs=${NODE_VERSION}"
            }
    else
        conda install -y -n "${ENV_NAME}" \
            -c conda-forge -c bioconda \
            "python=${PYTHON_VERSION}" \
            "openjdk=${JAVA_VERSION}" \
            nextflow \
            nf-core \
            nf-test \
            pre-commit \
            git \
            "nodejs=${NODE_VERSION}"
    fi
else
    echo "Creating Conda environment '${ENV_NAME}'."
    if [[ "${PREFERRED_FRONTEND}" == "mamba" ]]; then
        mamba create -y -n "${ENV_NAME}" \
            -c conda-forge -c bioconda \
            "python=${PYTHON_VERSION}" \
            "openjdk=${JAVA_VERSION}" \
            nextflow \
            nf-core \
            nf-test \
            pre-commit \
            git \
            "nodejs=${NODE_VERSION}" || {
                echo "mamba create failed. Falling back to conda create."
                conda create -y -n "${ENV_NAME}" \
                    -c conda-forge -c bioconda \
                    "python=${PYTHON_VERSION}" \
                    "openjdk=${JAVA_VERSION}" \
                    nextflow \
                    nf-core \
                    nf-test \
                    pre-commit \
                    git \
                    "nodejs=${NODE_VERSION}"
            }
    else
        conda create -y -n "${ENV_NAME}" \
            -c conda-forge -c bioconda \
            "python=${PYTHON_VERSION}" \
            "openjdk=${JAVA_VERSION}" \
            nextflow \
            nf-core \
            nf-test \
            pre-commit \
            git \
            "nodejs=${NODE_VERSION}"
    fi
fi

if ! conda env list | awk '{print $1}' | grep -qx "${ENV_NAME}"; then
    echo "ERROR: Environment '${ENV_NAME}' was not created successfully."
    echo "Try running the fallback command manually:"
    echo "  conda create -y -n ${ENV_NAME} -c conda-forge -c bioconda python=${PYTHON_VERSION} openjdk=${JAVA_VERSION} nextflow nf-core nf-test pre-commit git nodejs=${NODE_VERSION}"
    exit 1
fi

conda activate "${ENV_NAME}"

echo
echo "Core development tool versions"
echo "------------------------------"
python --version || true
java -version || true
nextflow -version || true
nf-core --version || true
nf-test version || true
pre-commit --version || true
git --version || true
node --version || true
npm --version || true

if [[ "${INSTALL_CODEX}" == "1" ]]; then
    echo
    echo "Installing OpenAI Codex CLI into the active Conda environment."
    npm install -g @openai/codex
    codex --version || true
else
    echo
    echo "Skipping Codex CLI installation."
    echo "To install it later, activate the environment and run:"
    echo "  npm install -g @openai/codex"
    echo "  codex login"
fi

echo
echo "HPC scheduler/container availability check"
echo "------------------------------------------"
for cmd in sbatch squeue qsub qstat bsub bjobs apptainer singularity docker; do
    if command -v "${cmd}" >/dev/null 2>&1; then
        echo "${cmd}: $(command -v "${cmd}")"
        "${cmd}" --version 2>/dev/null | head -n 2 || true
    else
        echo "${cmd}: not found"
    fi
done

echo
echo "Optional module-based Singularity/Apptainer check"
echo "-------------------------------------------------"
if command -v module >/dev/null 2>&1; then
    echo "Environment modules are available."
    echo "Try one of these if singularity/apptainer was not found above:"
    echo "  module avail singularity"
    echo "  module avail apptainer"
    echo "  module load singularity"
    echo "  module load apptainer"
else
    echo "Environment modules command was not found in this shell."
fi

echo
echo "Recommended runtime for this HPC project:"
echo "  Nextflow executor: pbs"
echo "  Container runtime: singularity/apptainer, loaded via module if needed"
echo "  Docker: avoid on this shared HPC even if the docker binary exists"

echo
echo "Setup complete."
echo "Log file: ${LOG_FILE}"
echo
echo "Next time, activate this environment with:"
echo "  conda activate ${ENV_NAME}"
