#!/bin/bash

# =============================================================
# Benchmarking: Clair3 and DeepVariant vs GIAB Truth Set
# Tool: hap.py
# Sample: HG002 | Reference: GRCh38 | Truth: v4.2.1
# =============================================================

# --- Input Files ---
TRUTH_VCF="HG002_GRCh38_1_22_v4.2.1_benchmark.vcf.gz"
CONFIDENT_BED="HG002_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed"
REFERENCE="GRCh38.fa"
CLAIR3_VCF="clair3.vcf.gz"
DEEPVARIANT_VCF="deepvariant.vcf.gz"

# --- Run Clair3 Benchmark ---
echo "Running Clair3 benchmark..."
hap.py \
    ${TRUTH_VCF} \
    ${CLAIR3_VCF} \
    -f ${CONFIDENT_BED} \
    -r ${REFERENCE} \
    -o clair3_benchmark \
    --threads 8 \
    --quiet

# --- Run DeepVariant Benchmark ---
echo "Running DeepVariant benchmark..."
hap.py \
    ${TRUTH_VCF} \
    ${DEEPVARIANT_VCF} \
    -f ${CONFIDENT_BED} \
    -r ${REFERENCE} \
    -o deepvariant_benchmark \
    --threads 8 \
    --quiet

echo "Benchmarking complete!"
echo "Output files:"
echo "  clair3_benchmark.summary.csv"
echo "  deepvariant_benchmark.summary.csv"
