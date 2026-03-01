# variant-calling-pipeline

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



# Person 3: Variant Calling

This section describes the variant calling workflow for PacBio HiFi reads using **Clair3** and **DeepVariant** within **Singularity** containers.  

---

```bash
# 1️⃣ Pull Containers
# Download the Clair3 and DeepVariant containers from Docker Hub
singularity pull clair3.sif docker://hkubal/clair3:latest
singularity pull deepvariant.sif docker://google/deepvariant:1.6.0

# 2️⃣ Identify Clair3 Model Path
# Find where the pre-trained models are stored inside the Clair3 container
singularity exec clair3.sif find / -type d -name "models" 2>/dev/null
singularity exec clair3.sif ls /opt/models
# For PacBio HiFi reads, we use: /opt/models/hifi

# 3️⃣ Run Clair3 for Variant Calling
# Inputs: aligned BAM, reference genome, model path, threads, platform
# Output: VCF files containing variant calls
singularity exec clair3.sif \
run_clair3.sh \
-b aligned.sorted.bam \
-f GRCh38.fa \
-m /opt/models/hifi \
-t 8 \
-p hifi \
-o clair3_output

# Rename outputs for clarity
mv clair3_output/merge_output.vcf.gz clair3.vcf.gz
mv clair3_output/merge_output.vcf.gz.tbi clair3.vcf.gz.tbi

# 4️⃣ Run DeepVariant for Variant Calling
# Inputs: aligned BAM, reference genome
# Output: deepvariant.vcf.gz
singularity exec deepvariant.sif \
/opt/deepvariant/bin/run_deepvariant \
--model_type=PACBIO \
--ref=GRCh38.fa \
--reads=aligned.sorted.bam \
--output_vcf=deepvariant.vcf.gz \
--num_shards=8

# Index the DeepVariant VCF for downstream tools
singularity exec deepvariant.sif tabix -p vcf deepvariant.vcf.gz

# 5️⃣ Optional: Submit as SLURM Job
# Automate variant calling on an HPC cluster
sbatch variant_calling.slurm
squeue -u arooj.sines

# Example SLURM script (variant_calling.slurm):
# ----------------------------------------------
#!/bin/bash
#SBATCH --job-name=variant_calling
#SBATCH --output=variant_calling.out
#SBATCH --error=variant_calling.err
#SBATCH --time=48:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G

module load singularity

# Run Clair3
singularity exec clair3.sif run_clair3.sh \
-b aligned.sorted.bam \
-f GRCh38.fa \
-m /opt/models/hifi \
-t 8 \
-p hifi \
-o clair3_output

mv clair3_output/merge_output.vcf.gz clair3.vcf.gz
mv clair3_output/merge_output.vcf.gz.tbi clair3.vcf.gz.tbi

# Run DeepVariant
singularity exec deepvariant.sif \
/opt/deepvariant/bin/run_deepvariant \
--model_type=PACBIO \
--ref=GRCh38.fa \
--reads=aligned.sorted.bam \
--output_vcf=deepvariant.vcf.gz \
--num_shards=8

# 6️⃣ Output Files (Deliverables for Person 3)
# clair3.vcf.gz
# clair3.vcf.gz.tbi
# deepvariant.vcf.gz
# deepvariant.vcf.gz.tbi
# variant_calling.slurm
```

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
