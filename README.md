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
Handling HPC software availability issues
Creating a Conda environment for reproducibility
Aligning HiFi sequencing reads using minimap2
Converting, sorting, and indexing alignment files using samtools
Generating alignment statistics

###  Step 1  Move to Working Directory
```bash
cd ~/assignment1/data/
```
### Step 2  Download Reference Genome
```bash
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/001/405/GCA_000001405.15_GRCh38/seqs_for_alignment_pipelines.ucsc_ids/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz
```
### Step 3  Extract Genome File
```bash
gunzip GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz
```
### Step 4  Rename Reference File

The file was renamed for simplicity.
```bash
mv GCA_000001405.15_GRCh38_no_alt_analysis_set.fna GRCh38.fa
```
### Step 5  HPC Software Issue

Attempting to index the genome initially failed because samtools was not available on the HPC system.
```bash
samtools faidx GRCh38.fa
```
Checking HPC Module System
```bash
module avail samtools
```
Result:
No module(s) or extension(s) found!

Since direct installation is restricted on HPC systems, an alternative approach was required.

### Step 6  Checking Conda Availability
```bash
conda --version
which conda
ls /opt/conda/bin/conda
ls ~/miniconda3/bin/conda
```
Conda was available and used to create an isolated bioinformatics environment.

### Step 7 Create Conda Environment
```bash
conda create -n alignment -c bioconda samtools minimap2 -y
```
Activate environment:
```bash
conda activate alignment
```
Verify installation:
```bash
samtools --version
minimap2 --version
```
### Step 8  Fix samtools Library Issue

A library dependency error occurred with samtools and was resolved by installing required packages:
```bash
conda install -c bioconda -c conda-forge samtools ncurses -y
```
### Step 9  Index Reference Genome
```bash
samtools faidx GRCh38.fa
```
This generates:
GRCh38.fa.fai
Verification:
```bash
ls -lh GRCh38.fa.fai
```
### Step 10 Sequence Alignment

HiFi reads were aligned to the reference genome using minimap2.
```bash
minimap2 -ax map-hifi -t 8 GRCh38.fa \
m54238_180901_011437.Q20.fastq > aligned.sam
```
### Step 11 Convert, Sort, and Index Alignment

Convert SAM → BAM, sort, and index:
```bash
samtools view -bS aligned.sam | \
samtools sort -o aligned.sorted.bam && \
samtools index aligned.sorted.bam
```
### Step 12  Alignment Statistics

Alignment quality was verified using:
```bash
samtools flagstat aligned.sorted.bam
```
This provides mapping statistics such as:
Total reads
Mapped reads
Properly aligned reads
Alignment percentage <br>
<img width="946" height="456" alt="image" src="https://github.com/user-attachments/assets/64c1dc18-bd83-4660-841d-89eacc4804d1" />

### Output Files

- **GRCh38.fa** — Reference genome  
- **GRCh38.fa.fai** — Reference index  
- **aligned.sam** — Raw alignment  
- **aligned.sorted.bam** — Sorted BAM file  
- **aligned.sorted.bam.bai** — BAM index
## Variant Calling

*To be added *

---

## Benchmarking & Results

*To be added*

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
