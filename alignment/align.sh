#!/bin/bash
set -e

# Download reference genome
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/001/405/GCA_000001405.15_GRCh38/seqs_for_alignment_pipelines.ucsc_ids/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz
gunzip GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz
mv GCA_000001405.15_GRCh38_no_alt_analysis_set.fna GRCh38.fa

# Setup conda environment
conda create -n alignment -c bioconda samtools minimap2 -y
conda activate alignment

# Index reference
samtools faidx GRCh38.fa

# Align HiFi reads
minimap2 -ax map-hifi -t 8 GRCh38.fa \
    m54238_180901_011437.Q20.fastq > aligned.sam

# Convert, sort and index
samtools view -bS aligned.sam | samtools sort -o aligned.sorted.bam
samtools index aligned.sorted.bam

# Alignment statistics
samtools flagstat aligned.sorted.bam
