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

*To be added *

---

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
