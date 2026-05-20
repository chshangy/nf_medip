# R Methylation Container

This container provides the R/Bioconductor runtime for the QSEA and MEDIPS downstream branches.

It includes:

- `qsea`
- `MEDIPS`
- `BSgenome.Hsapiens.UCSC.hg38`
- `BiocParallel`
- `ChIPseeker`
- `TxDb.Hsapiens.UCSC.hg38.knownGene`
- `org.Hs.eg.db`
- `GenomicRanges`
- `IRanges`
- common table packages such as `data.table`, `dplyr`, `readr`, and `tibble`

## Intended Image

```text
ghcr.io/chshangy/nf-medip-qsea:0.2.0
```

Nextflow/Singularity can pull it with:

```text
docker://ghcr.io/chshangy/nf-medip-qsea:0.2.0
```

## Build Locally With Docker

```bash
docker build -t ghcr.io/chshangy/nf-medip-qsea:0.2.0 containers/qsea
docker push ghcr.io/chshangy/nf-medip-qsea:0.2.0
```

## Build With GitHub Actions

Use the workflow in:

```text
.github/workflows/build-qsea-container.yml
```

The workflow can be run manually and publishes the image to GitHub Container Registry.
