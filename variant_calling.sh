
Notice:
- No HPC
- No SLURM
- No errors
- No personal notes
- Clean reproduction instructions

---

# ✅ 2️⃣ Now Create This File: `variant_calling.sh`

Create a new file in GitHub called:

`variant_calling.sh`

Paste this inside:

```bash
#!/bin/bash

# Input files
BAM="aligned.sorted.bam"
REF="GRCh38.fa"

# Run Clair3
singularity exec clair3.sif run_clair3.sh \
  --bam $BAM \
  --ref $REF \
  --threads 16 \
  --platform ont \
  --output clair3_output

# Compress final Clair3 VCF
bgzip clair3_output/merge_output.vcf
tabix -p vcf clair3_output/merge_output.vcf.gz

mv clair3_output/merge_output.vcf.gz clair3.vcf.gz
mv clair3_output/merge_output.vcf.gz.tbi clair3.vcf.gz.tbi

# Run DeepVariant
singularity exec deepvariant.sif run_deepvariant \
  --model_type=ONT \
  --ref=$REF \
  --reads=$BAM \
  --output_vcf=deepvariant.vcf.gz \
  --num_shards=16
