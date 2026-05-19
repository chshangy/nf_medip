FROM bioconductor/bioconductor_docker:RELEASE_3_21

LABEL org.opencontainers.image.title="nf-medip-qsea"
LABEL org.opencontainers.image.description="QSEA and ChIPseeker runtime for nf_medip"
LABEL org.opencontainers.image.source="https://github.com/chshangy/nf_medip"

RUN Rscript -e 'install.packages(c("data.table", "dplyr", "readr", "tibble"), repos = "https://cloud.r-project.org")'

RUN Rscript -e 'BiocManager::install(c( \
    "qsea", \
    "BSgenome.Hsapiens.UCSC.hg38", \
    "BiocParallel", \
    "ChIPseeker", \
    "TxDb.Hsapiens.UCSC.hg38.knownGene", \
    "org.Hs.eg.db", \
    "GenomicRanges", \
    "IRanges" \
), ask = FALSE, update = FALSE)'

RUN Rscript -e 'library(qsea); library(ChIPseeker); library(TxDb.Hsapiens.UCSC.hg38.knownGene); library(org.Hs.eg.db); sessionInfo()'

