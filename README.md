![benchmark_chart](https://github.com/user-attachments/assets/bd439189-c723-4363-94c5-e34b908b10db)# variant-calling-pipeline

A reproducible variant calling pipeline for PacBio HiFi sequencing data using 
Clair3 and DeepVariant, benchmarked against the GIAB truth set.

## Dataset

- **Sample:** HG002 (NA24385) — GIAB reference sample
- **Data type:** PacBio HiFi long reads
- **Reference genome:** GRCh38

## Pipeline Overview
```
variant-calling-pipeline/
├── data_preparation/
│   └── data_prep.sh
├── alignment/
│   └── align.sh
├── variant_calling/
│   ├── clair3.slurm
│   └── deepvariant.slurm
├── benchmarking/
│   └── benchmark.sh
└── README.md
```

## Data Preparation

### Data Download

The input dataset is PacBio HiFi reads for HG002, downloaded from the 
Human Pangenome Reference Consortium (HPRC):
```bash
wget --no-check-certificate \
    https://s3-us-west-2.amazonaws.com/human-pangenomics/NHGRI_UCSC_panel/HG002/hpp_HG002_NA24385_son_v1/PacBio_HiFi/15kb/m54238_180901_011437.Q20.fastq
```

### Subsetting

To keep the pipeline manageable, we used a quarter subset of the total reads:
```bash
head -n 138688 m54238_180901_011437.Q20.fastq > HG002_subset.fastq
```

### Data Summary

| File | Size | Reads |
|------|------|-------|
| Full FASTQ | 3.4G | 138,688 |
| Subset FASTQ (¼) | 851M | 34,672 |

---

## Alignment

This section describes the complete workflow used to prepare the reference genome, resolve HPC software limitations, perform sequence alignment, and generate indexed alignment files.

### Overview

The pipeline performs:
Downloading the GRCh38 human reference genome
Preparing reference indexing
Creating a Conda environment for reproducibility
Aligning HiFi sequencing reads using minimap2
Converting, sorting, and indexing alignment files using samtools
Generating alignment statistics

###  Step 1  Download Reference Genome
```bash
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/001/405/GCA_000001405.15_GRCh38/seqs_for_alignment_pipelines.ucsc_ids/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz
```
### Step 2  Extract Genome File
```bash
gunzip GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz
```
### Step 3  Rename Reference File

Renaming for simplicity.
```bash
mv GCA_000001405.15_GRCh38_no_alt_analysis_set.fna GRCh38.fa
```

### Step 4 Create Conda Environment
```bash
conda create -n alignment -c bioconda samtools minimap2 -y
```
Activate environment:
```bash
conda activate alignment
```

### Step 5  Fix samtools Library Issue
if any isuue is faced in using samtools there might be an isuue in library, hence use the following command and  installing required packages:
```bash
conda install -c bioconda -c conda-forge samtools ncurses -y
```
### Step 6  Index Reference Genome
```bash
samtools faidx GRCh38.fa
```
### Step 7 Sequence Alignment

Aligning the reads:
```bash
minimap2 -ax map-hifi -t 8 GRCh38.fa \
m54238_180901_011437.Q20.fastq > aligned.sam
```
### Step 8 Convert, Sort, and Index Alignment

To convert SAM → BAM, sort, and index:
```bash
samtools view -bS aligned.sam | \
samtools sort -o aligned.sorted.bam && \
samtools index aligned.sorted.bam
```
### Step 9  Alignment Statistics

Alignment quality was verified using:
```bash
samtools flagstat aligned.sorted.bam
```
This provides mapping statistics such as:
<br>
<img width="946" height="456" alt="image" src="https://github.com/user-attachments/assets/64c1dc18-bd83-4660-841d-89eacc4804d1" />

### Output Files
Alignmnet part must provide you with the following output files:

| File | Description |
|------|-------------|
| GRCh38.fa | Reference genome |
| GRCh38.fa.fai | Reference index |
| aligned.sorted.bam | Sorted alignment |
| aligned.sorted.bam.bai | BAM index |## Variant Calling

*To be added *

---

## Benchmarking & Results

Variant calls from both **Clair3** and **DeepVariant** were benchmarked against the **GIAB HG002 v4.2.1 truth set** using [hap.py](https://github.com/Illumina/hap.py), restricted to high-confidence regions defined by the GIAB BED file.

---

### Benchmark Truth Set

| File | Description |
|------|-------------|
| `HG002_GRCh38_1_22_v4.2.1_benchmark.vcf.gz` | GIAB truth set VCF (HG002, GRCh38) |
| `HG002_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed` | High-confidence regions BED file |
| `GRCh38.fa` | GRCh38 reference genome |

---

### Environment Setup

```bash
conda activate /hdd4/sines/specialtopicsinbioinformatics/arooj.sines/miniconda3/envs/happy
cd ~/assignment1/data
```

---

### Running hap.py (Both Benchmarks in Parallel)

```bash
# Clair3 benchmark
nohup hap.py \
  HG002_GRCh38_1_22_v4.2.1_benchmark.vcf.gz \
  clair3.vcf.gz \
  -f HG002_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed \
  -r GRCh38.fa \
  -o clair3_benchmark \
  --threads 8 \
  --quiet > clair3_happy.log 2>&1 &

# DeepVariant benchmark
nohup hap.py \
  HG002_GRCh38_1_22_v4.2.1_benchmark.vcf.gz \
  deepvariant.vcf.gz \
  -f HG002_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed \
  -r GRCh38.fa \
  -o deepvariant_benchmark \
  --threads 8 \
  --quiet > deepvariant_happy.log 2>&1 &
```

### Monitor Progress

```bash
watch -n 30 'ls -lh clair3_benchmark.summary.csv deepvariant_benchmark.summary.csv 2>/dev/null'
```

### View Raw Results

```bash
cat clair3_benchmark.summary.csv
cat deepvariant_benchmark.summary.csv
```

---

### Results Summary

> Benchmarked on GIAB HG002 | Reference: GRCh38 | Tool: hap.py | Truth set: v4.2.1 | Filter: PASS

#### SNP Performance

| Tool | Recall | Precision | F1 Score | TP | FP | FN |
|------|--------|-----------|----------|----|----|----|
| **Clair3** | 8.79% | 81.67% | **15.87%**  | 295,697 | 66,374 | 3,069,418 |
| **DeepVariant** | 5.17% | 76.45% | 9.68% | 173,891 | 53,589 | 3,191,224 |

#### INDEL Performance

| Tool | Recall | Precision | F1 Score | TP | FP | FN |
|------|--------|-----------|----------|----|----|----|
| **Clair3** | 5.02% | 56.79% | **9.23%**  | 26,394 | 20,372 | 499,072 |
| **DeepVariant** | 3.34% | **63.62%**  | 6.34% | 17,527 | 9,994 | 507,939 |


---

### Visual Results

**Figure 1 — Bar chart comparison of Recall, Precision, and F1 Score for SNPs and INDELs:**

![benchmark_chart](https://github.com/user-attachments/assets/9796516e-be4d-4f55-bb80-eed97b42b717)


**Figure 2 — Full comparison table with TP, FP, FN counts:**
![benchmark_table](https://github.com/user-attachments/assets/58427b69-80ec-4fb2-bd31-ed2cd2b6cc20)

---

### Key Observations

- **Clair3 outperforms DeepVariant on F1 Score** for both SNPs (15.87% vs 9.68%) and INDELs (9.23% vs 6.34%)
- **DeepVariant achieves higher INDEL precision** (63.62% vs 56.79%), meaning fewer false positives per call
- **Both callers show low recall** — likely due to using only a ¼ subset of the original reads, resulting in lower sequencing depth and many missed variants
- Higher precision in both tools suggests that when variants *are* called, they are mostly correct — the main limitation is coverage depth from subsampling


---

## Requirements

- samtools
- minimap2
- Singularity
- Nextflow
- SLURM

## Reproducing the Pipeline

Clone this repo and follow each section in order:
```bash
git clone git@github.com:yourusername/variant-calling-pipeline.git
cd variant-calling-pipeline
```

Then run each script in the corresponding section folder.
