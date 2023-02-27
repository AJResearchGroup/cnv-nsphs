# CNV Project Pipeline

This repository contains a Nextflow pipeline to recreate the CNV analyses in the NSPHS.
All code in this directory processes sensitive data and should therefore only be run on Bianca (or another secure cluster).

## CNV Calling
CNV calling is realized in the folder `cnv_calling`.
The workflow specification is `cnv_calling.nf`.

Run the workflow directory using
```
nextflow run [-resume] [-profile {standard,slurm}] [--bams <alignment files>] [--reference <reference folder>] cnv_calling/cnv_calling.nf
```
The configuration and directives are specific to Bianca and SLURM.
The `standard` profile runs the pipeline on the machine you are logged in to.
The `slurm` profile submits each process as a SLURM job.

## CNV Matrix Assembly
After calling, sample-level CNVs and associated copy numbers are aligned to non-overlapping 200-bp windows and assembled into a matrix with rows representing harmonized CNV regions and columns samples.
This matrix is then collapsed by merging adjacent bins with consistent copy numbers.

Run the workflow using
```
nextflow run  [-resume] [-profile {standard,slurm}] [--raw_variants <files with raw cnv calls>] [--qc-variants <files with QC'ed cnv calls>] [--translation_key <translation-key file>] cnv_matrix/cnv_matrix.nf
```

## CNV-Association Study
With the completed CNV matrix, call associations with protein measurements as follows:

```
nextflow run [-resume] [-profile {standard,slurm}] [--cnv_matrix <cnv-matrix file>] [--phenotypes <phenotype file>] [--covariates <covariate file>] [--chromosomes <chromosome ids>] [--gwas_out <ouput folder>] gwas/gwas.nf
```

## Running the whole Pipeline
You can run the whole pipeline as one command as follows. This will put all results in `cnv_calls`.
```
nextflow run [-resume] [-profile {standard,slurm}] [--bams <alignment files>] [--reference <reference folder>] [--phenotypes <phenotype file>] [--covariates <covariate file>] [--chromosomes <chromosome ids>] [--translation_key <translation-key file>] [--out <output directory>]cnv_project.nf
```