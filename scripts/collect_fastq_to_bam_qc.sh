#!/usr/bin/env bash

set -euo pipefail

OUTDIR="${1:-results/fastq_to_bam_test}"
REVIEW_DIR="${2:-review_fastq_to_bam}"
ARCHIVE="${REVIEW_DIR}.tar.gz"

if [[ ! -d "${OUTDIR}" ]]; then
    echo "ERROR: Output directory not found: ${OUTDIR}" >&2
    echo "Usage: bash scripts/collect_fastq_to_bam_qc.sh [outdir] [review_dir]" >&2
    exit 1
fi

rm -rf "${REVIEW_DIR}" "${ARCHIVE}"
mkdir -p "${REVIEW_DIR}"/{summaries,multiqc,pipeline_info,logs}

{
    echo "FASTQ-to-BAM QC review bundle"
    echo "Generated: $(date)"
    echo "Host: $(hostname)"
    echo "Working directory: $(pwd)"
    echo "Output directory: ${OUTDIR}"
    echo
    echo "Directory overview"
    echo "------------------"
    find "${OUTDIR}" -maxdepth 2 -type d | sort
} > "${REVIEW_DIR}/README.txt"

{
    echo "Top-level output files"
    echo "----------------------"
    find "${OUTDIR}" -maxdepth 3 -type f \
        ! -name "*.bam" \
        ! -name "*.bai" \
        ! -name "*.fq.gz" \
        ! -name "*.fastq.gz" \
        ! -name "*.bw" \
        ! -name "*.bigWig" \
        ! -name "*.img" \
        -printf "%p\t%k KB\n" | sort
} > "${REVIEW_DIR}/summaries/output_files.tsv"

{
    echo "Alignment BAMs"
    echo "--------------"
    find "${OUTDIR}/alignment" -maxdepth 1 -type f \( -name "*.bam" -o -name "*.bai" \) -printf "%p\t%k KB\n" 2>/dev/null | sort || true
    echo
    echo "Filtered BAMs"
    echo "-------------"
    find "${OUTDIR}/bam_filter" -maxdepth 1 -type f \( -name "*.bam" -o -name "*.bai" \) -printf "%p\t%k KB\n" 2>/dev/null | sort || true
    echo
    echo "Coverage files"
    echo "--------------"
    find "${OUTDIR}/coverage" -maxdepth 1 -type f \( -name "*.bw" -o -name "*.bigWig" \) -printf "%p\t%k KB\n" 2>/dev/null | sort || true
} > "${REVIEW_DIR}/summaries/large_output_inventory.txt"

if [[ -d "${OUTDIR}/post_alignment_qc" ]]; then
    for file in "${OUTDIR}"/post_alignment_qc/*.filtered.flagstat.txt; do
        [[ -e "${file}" ]] || continue
        sample="$(basename "${file}" .filtered.flagstat.txt)"
        {
            echo "===== ${sample} filtered flagstat ====="
            cat "${file}"
            echo
        } >> "${REVIEW_DIR}/summaries/filtered_flagstat_combined.txt"
    done

    for file in "${OUTDIR}"/post_alignment_qc/*.filtered.stats.txt; do
        [[ -e "${file}" ]] || continue
        sample="$(basename "${file}" .filtered.stats.txt)"
        {
            echo "===== ${sample} selected samtools stats ====="
            grep -E '^SN' "${file}" | grep -E 'raw total sequences|filtered sequences|sequences|reads mapped|reads mapped and paired|reads duplicated|insert size average|average length|error rate' || true
            echo
        } >> "${REVIEW_DIR}/summaries/filtered_samtools_stats_selected.txt"
    done
fi

if [[ -d "${OUTDIR}/alignment" ]]; then
    for file in "${OUTDIR}"/alignment/*.flagstat.txt; do
        [[ -e "${file}" ]] || continue
        sample="$(basename "${file}" .flagstat.txt)"
        {
            echo "===== ${sample} raw aligned flagstat ====="
            cat "${file}"
            echo
        } >> "${REVIEW_DIR}/summaries/aligned_flagstat_combined.txt"
    done
fi

if [[ -d "${OUTDIR}/multiqc" ]]; then
    cp -r "${OUTDIR}/multiqc"/* "${REVIEW_DIR}/multiqc/" 2>/dev/null || true
fi

if [[ -d "${OUTDIR}/pipeline_info" ]]; then
    find "${OUTDIR}/pipeline_info" -maxdepth 1 -type f \
        ! -name "*.html" \
        -exec cp {} "${REVIEW_DIR}/pipeline_info/" \; 2>/dev/null || true
    find "${OUTDIR}/pipeline_info" -maxdepth 1 -type f \
        -name "*.html" \
        -exec cp {} "${REVIEW_DIR}/pipeline_info/" \; 2>/dev/null || true
fi

if [[ -f ".nextflow.log" ]]; then
    tail -n 300 ".nextflow.log" > "${REVIEW_DIR}/logs/nextflow_tail_300.log"
fi

if [[ -d "logs" ]]; then
    cp logs/nf_medip_fastq_to_bam.out "${REVIEW_DIR}/logs/" 2>/dev/null || true
    cp logs/nf_medip_fastq_to_bam.err "${REVIEW_DIR}/logs/" 2>/dev/null || true
fi

tar -czf "${ARCHIVE}" "${REVIEW_DIR}"

echo "Review bundle created:"
echo "  ${ARCHIVE}"
echo
echo "Bundle contents:"
tar -tzf "${ARCHIVE}" | sed 's#^#  #'

