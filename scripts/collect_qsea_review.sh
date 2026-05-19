#!/usr/bin/env bash

set -euo pipefail

OUTDIR="${1:-results/fastq_to_bam_test}"
REVIEW_DIR="${2:-review_qsea}"
ARCHIVE="${REVIEW_DIR}.tar.gz"
QSEA_ROOT="${OUTDIR}/qsea"
FULL_TABLES="${FULL_TABLES:-0}"

if [[ -f "${QSEA_ROOT}/qsea_summary.txt" ]]; then
    QSEA_DIR="${QSEA_ROOT}"
elif [[ -f "${QSEA_ROOT}/qsea/qsea_summary.txt" ]]; then
    QSEA_DIR="${QSEA_ROOT}/qsea"
else
    QSEA_SUMMARY="$(find "${QSEA_ROOT}" -mindepth 1 -maxdepth 3 -type f -name qsea_summary.txt -print -quit 2>/dev/null || true)"
    if [[ -n "${QSEA_SUMMARY}" ]]; then
        QSEA_DIR="$(dirname "${QSEA_SUMMARY}")"
    else
        QSEA_DIR=""
    fi
fi

if [[ -z "${QSEA_DIR:-}" || ! -d "${QSEA_DIR}" ]]; then
    echo "ERROR: QSEA output directory with qsea_summary.txt not found under: ${QSEA_ROOT}" >&2
    echo "Usage: bash scripts/collect_qsea_review.sh [outdir] [review_dir]" >&2
    exit 1
fi

rm -rf "${REVIEW_DIR}" "${ARCHIVE}"
mkdir -p "${REVIEW_DIR}"/{qsea,logs,summaries}

{
    echo "QSEA review bundle"
    echo "Generated: $(date)"
    echo "Host: $(hostname)"
    echo "Working directory: $(pwd)"
    echo "Output directory: ${OUTDIR}"
    echo "QSEA directory: ${QSEA_DIR}"
} > "${REVIEW_DIR}/README.txt"

for file in \
    qsea_sample_table.used.tsv \
    qsea_summary.txt \
    qsea_design_matrix.tsv \
    qsea_dmr_significant.tsv \
    qsea_dmr_filtered.tsv \
    qsea_dmr_filtered.bed \
    qsea_run.log
do
    if [[ -f "${QSEA_DIR}/${file}" ]]; then
        cp "${QSEA_DIR}/${file}" "${REVIEW_DIR}/qsea/"
    fi
done

if [[ "${FULL_TABLES}" == "1" ]]; then
    for file in \
        qsea_region_stats.tsv \
        qsea_beta_matrix.tsv \
        qsea_counts_matrix.tsv \
        qsea_region_annotation.tsv \
        qsea_all_regions.tsv
    do
        if [[ -f "${QSEA_DIR}/${file}" ]]; then
            cp "${QSEA_DIR}/${file}" "${REVIEW_DIR}/qsea/"
        fi
    done
fi

{
    echo "QSEA output inventory"
    echo "---------------------"
    find "${QSEA_DIR}" -maxdepth 1 -type f -printf "%f\t%k KB\n" | sort
} > "${REVIEW_DIR}/summaries/qsea_output_inventory.tsv"

{
    echo "QSEA table dimensions"
    echo "---------------------"
    for file in qsea_region_stats.tsv qsea_beta_matrix.tsv qsea_counts_matrix.tsv qsea_region_annotation.tsv qsea_dmr_significant.tsv qsea_dmr_filtered.tsv; do
        if [[ -f "${QSEA_DIR}/${file}" ]]; then
            rows=$(($(wc -l < "${QSEA_DIR}/${file}") - 1))
            cols=$(awk -F '\t' 'NR==1 {print NF}' "${QSEA_DIR}/${file}")
            echo -e "${file}\t${rows}\t${cols}"
        fi
    done
} > "${REVIEW_DIR}/summaries/qsea_table_dimensions.tsv"

{
    echo "QSEA table previews"
    echo "-------------------"
    for file in qsea_summary.txt qsea_region_stats.tsv qsea_beta_matrix.tsv qsea_counts_matrix.tsv qsea_region_annotation.tsv qsea_dmr_filtered.tsv; do
        if [[ -f "${QSEA_DIR}/${file}" ]]; then
            echo
            echo "===== ${file} ====="
            head -n 21 "${QSEA_DIR}/${file}"
        fi
    done
} > "${REVIEW_DIR}/summaries/qsea_previews.txt"

{
    echo "QSEA headers"
    echo "------------"
    for file in qsea_region_stats.tsv qsea_beta_matrix.tsv qsea_counts_matrix.tsv qsea_region_annotation.tsv qsea_all_regions.tsv qsea_dmr_filtered.tsv; do
        if [[ -f "${QSEA_DIR}/${file}" ]]; then
            echo
            echo "===== ${file} ====="
            head -n 1 "${QSEA_DIR}/${file}"
        fi
    done
} > "${REVIEW_DIR}/summaries/qsea_headers.txt"

if [[ -f ".nextflow.log" ]]; then
    tail -n 300 ".nextflow.log" > "${REVIEW_DIR}/logs/nextflow_tail_300.log"
fi

if [[ -d "logs" ]]; then
    cp logs/nf_medip_qsea.out "${REVIEW_DIR}/logs/" 2>/dev/null || true
    cp logs/nf_medip_qsea.err "${REVIEW_DIR}/logs/" 2>/dev/null || true
fi

tar -czf "${ARCHIVE}" "${REVIEW_DIR}"

gzip -t "${ARCHIVE}"

echo "QSEA review bundle created:"
echo "  ${ARCHIVE}"
echo
if [[ "${FULL_TABLES}" == "1" ]]; then
    echo "Full large QSEA tables were included because FULL_TABLES=1."
else
    echo "Large all-region QSEA tables were not included. Set FULL_TABLES=1 to include them."
fi
echo
echo "Bundle contents:"
tar -tzf "${ARCHIVE}" | sed 's#^#  #'
