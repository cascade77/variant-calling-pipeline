#!/bin/bash

#  Data Preparation
# Dataset: PacBio HiFi HG002

# Download FASTQ
wget --no-check-certificate \
    https://s3-us-west-2.amazonaws.com/human-pangenomics/NHGRI_UCSC_panel/HG002/hpp_HG002_NA24385_son_v1/PacBio_HiFi/15kb/m54238_180901_011437.Q20.fastq

# Subset to quarter
head -n 138688 m54238_180901_011437.Q20.fastq > HG002_subset.fastq

# Output stats:
# Total reads : 138,688
# Subset      : quarter (1/4)
# Subset size : 851M
