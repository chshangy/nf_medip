#!/usr/bin/env bash

set -euo pipefail

ENV_NAME="${ENV_NAME:-qsea-medip}"
CONDA_BIN="${CONDA_BIN:-/home/shangying/miniconda3/bin/conda}"

if [[ ! -x "${CONDA_BIN}" ]]; then
    echo "ERROR: Conda executable not found: ${CONDA_BIN}" >&2
    exit 1
fi

eval "$("${CONDA_BIN}" shell.bash hook)"

if conda env list | awk '{print $1}' | grep -qx "${ENV_NAME}"; then
    echo "Conda environment '${ENV_NAME}' already exists. Updating it."
    conda install -y -n "${ENV_NAME}" \
        -c conda-forge -c bioconda \
        r-base \
        bioconductor-qsea \
        bioconductor-bsgenome.hsapiens.ucsc.hg38 \
        bioconductor-biocparallel \
        bioconductor-chipseeker \
        bioconductor-txdb.hsapiens.ucsc.hg38.knowngene \
        bioconductor-org.hs.eg.db
else
    echo "Creating Conda environment '${ENV_NAME}'."
    conda create -y -n "${ENV_NAME}" \
        -c conda-forge -c bioconda \
        r-base \
        bioconductor-qsea \
        bioconductor-bsgenome.hsapiens.ucsc.hg38 \
        bioconductor-biocparallel \
        bioconductor-chipseeker \
        bioconductor-txdb.hsapiens.ucsc.hg38.knowngene \
        bioconductor-org.hs.eg.db
fi

conda run -n "${ENV_NAME}" Rscript -e "library(qsea); library(ChIPseeker); library(TxDb.Hsapiens.UCSC.hg38.knownGene); library(org.Hs.eg.db); sessionInfo()"

echo "QSEA Conda environment is ready: ${ENV_NAME}"

