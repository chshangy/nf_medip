#!/usr/bin/env bash

set -euo pipefail

OUTDIR="${1:-results/fastq_to_bam_test}"
REVIEW_DIR="${2:-review_qsea}"
ARCHIVE="${REVIEW_DIR}.tar.gz"
QSEA_DIR="${OUTDIR}/qsea"

if [[ ! -d "${QSEA_DIR}" ]]; then
    echo "ERROR: QSEA directory not found: ${QSEA_DIR}" >&2
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
    qsea_region_stats.tsv \
    qsea_beta_matrix.tsv \
    qsea_counts_matrix.tsv \
    qsea_region_annotation.tsv \
    qsea_dmr_significant.tsv \
    qsea_dmr_filtered.tsv \
    qsea_dmr_filtered.bed \
    qsea_run.log
do
    if [[ -f "${QSEA_DIR}/${file}" ]]; then
        cp "${QSEA_DIR}/${file}" "${REVIEW_DIR}/qsea/"
    fi
done

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
            head -n 6 "${QSEA_DIR}/${file}"
        fi
    done
} > "${REVIEW_DIR}/summaries/qsea_previews.txt"

if [[ -f ".nextflow.log" ]]; then
    tail -n 300 ".nextflow.log" > "${REVIEW_DIR}/logs/nextflow_tail_300.log"
fi

if [[ -d "logs" ]]; then
    cp logs/nf_medip_qsea.out "${REVIEW_DIR}/logs/" 2>/dev/null || true
    cp logs/nf_medip_qsea.err "${REVIEW_DIR}/logs/" 2>/dev/null || true
fi

tar -czf "${ARCHIVE}" "${REVIEW_DIR}"

echo "QSEA review bundle created:"
echo "  ${ARCHIVE}"
echo
echo "Bundle contents:"
tar -tzf "${ARCHIVE}" | sed 's#^#  #'

