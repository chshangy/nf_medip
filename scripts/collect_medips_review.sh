#!/usr/bin/env bash

set -euo pipefail

OUTDIR="${1:-results/fastq_to_bam_test}"
REVIEW_DIR="${2:-review_medips}"
ARCHIVE="${REVIEW_DIR}.tar.gz"
MEDIPS_DIR="${OUTDIR}/medips"
FULL_TABLES="${FULL_TABLES:-0}"

if [[ ! -f "${MEDIPS_DIR}/medips_summary.txt" ]]; then
    echo "ERROR: MEDIPS output directory with medips_summary.txt not found: ${MEDIPS_DIR}" >&2
    echo "Usage: bash scripts/collect_medips_review.sh [outdir] [review_dir]" >&2
    exit 1
fi

rm -rf "${REVIEW_DIR}" "${ARCHIVE}"
mkdir -p "${REVIEW_DIR}"/{medips,logs,summaries}

{
    echo "MEDIPS review bundle"
    echo "Generated: $(date)"
    echo "Host: $(hostname)"
    echo "Working directory: $(pwd)"
    echo "Output directory: ${OUTDIR}"
    echo "MEDIPS directory: ${MEDIPS_DIR}"
} > "${REVIEW_DIR}/README.txt"

for file in \
    medips_sample_table.used.tsv \
    medips_summary.txt \
    medips_dmr_significant.tsv \
    medips_dmr_filtered.tsv \
    medips_dmr_filtered_annotated.tsv \
    medips_dmr_filtered.bed \
    medips_run.log
do
    if [[ -f "${MEDIPS_DIR}/${file}" ]]; then
        cp "${MEDIPS_DIR}/${file}" "${REVIEW_DIR}/medips/"
    fi
done

if [[ "${FULL_TABLES}" == "1" ]]; then
    for file in \
        medips_region_stats.tsv \
        medips_counts_matrix.tsv \
        medips_rpkm_matrix.tsv \
        medips_rms_matrix.tsv \
        medips_region_annotation.tsv \
        medips_all_regions.tsv
    do
        if [[ -f "${MEDIPS_DIR}/${file}" ]]; then
            cp "${MEDIPS_DIR}/${file}" "${REVIEW_DIR}/medips/"
        fi
    done
fi

{
    echo "MEDIPS output inventory"
    echo "-----------------------"
    find "${MEDIPS_DIR}" -maxdepth 1 -type f -printf "%f\t%k KB\n" | sort
} > "${REVIEW_DIR}/summaries/medips_output_inventory.tsv"

{
    echo "MEDIPS table dimensions"
    echo "-----------------------"
    for file in medips_region_stats.tsv medips_counts_matrix.tsv medips_rpkm_matrix.tsv medips_rms_matrix.tsv medips_region_annotation.tsv medips_dmr_significant.tsv medips_dmr_filtered.tsv medips_dmr_filtered_annotated.tsv; do
        if [[ -f "${MEDIPS_DIR}/${file}" ]]; then
            rows=$(($(wc -l < "${MEDIPS_DIR}/${file}") - 1))
            cols=$(awk -F '\t' 'NR==1 {print NF}' "${MEDIPS_DIR}/${file}")
            echo -e "${file}\t${rows}\t${cols}"
        fi
    done
} > "${REVIEW_DIR}/summaries/medips_table_dimensions.tsv"

{
    echo "MEDIPS table previews"
    echo "---------------------"
    for file in medips_summary.txt medips_region_stats.tsv medips_counts_matrix.tsv medips_rpkm_matrix.tsv medips_rms_matrix.tsv medips_region_annotation.tsv medips_dmr_filtered.tsv medips_dmr_filtered_annotated.tsv; do
        if [[ -f "${MEDIPS_DIR}/${file}" ]]; then
            echo
            echo "===== ${file} ====="
            head -n 21 "${MEDIPS_DIR}/${file}"
        fi
    done
} > "${REVIEW_DIR}/summaries/medips_previews.txt"

{
    echo "MEDIPS headers"
    echo "--------------"
    for file in medips_region_stats.tsv medips_counts_matrix.tsv medips_rpkm_matrix.tsv medips_rms_matrix.tsv medips_region_annotation.tsv medips_all_regions.tsv medips_dmr_filtered.tsv medips_dmr_filtered_annotated.tsv; do
        if [[ -f "${MEDIPS_DIR}/${file}" ]]; then
            echo
            echo "===== ${file} ====="
            head -n 1 "${MEDIPS_DIR}/${file}"
        fi
    done
} > "${REVIEW_DIR}/summaries/medips_headers.txt"

if [[ -f ".nextflow.log" ]]; then
    tail -n 300 ".nextflow.log" > "${REVIEW_DIR}/logs/nextflow_tail_300.log"
fi

if [[ -d "logs" ]]; then
    cp logs/nf_medip_medips.out "${REVIEW_DIR}/logs/" 2>/dev/null || true
    cp logs/nf_medip_medips.err "${REVIEW_DIR}/logs/" 2>/dev/null || true
fi

tar -czf "${ARCHIVE}" "${REVIEW_DIR}"
gzip -t "${ARCHIVE}"

echo "MEDIPS review bundle created:"
echo "  ${ARCHIVE}"
echo
if [[ "${FULL_TABLES}" == "1" ]]; then
    echo "Full large MEDIPS tables were included because FULL_TABLES=1."
else
    echo "Large all-region MEDIPS tables were not included. Set FULL_TABLES=1 to include them."
fi
echo
echo "Bundle contents:"
tar -tzf "${ARCHIVE}" | sed 's#^#  #'
