# CWL-assembly
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/684724bbc0134960ab41748f4a4b732f)](https://www.codacy.com/app/mb1069/CWL-assembly?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=EBI-Metagenomics/CWL-assembly&amp;utm_campaign=Badge_Grade)
[![Build Status](https://travis-ci.org/EBI-Metagenomics/CWL-assembly.svg?branch=develop)](https://travis-ci.org/EBI-Metagenomics/CWL-assembly)

## Description

This repository contains two workflows for metagenome and metatranscriptome assembly of short read data. MetaSPAdes is used as default for paired end data, and MEGAHIT for single end data. MEGAHIT can be specified as the default assembler in the yaml file if preferred. Steps include:

QC - removal of short reads, low quality regions, adapters and host decontamination
Assembly - with metaSPADES or MEGAHIT
Post-assembly - Host and PhiX decontamination, contig length filter (500bp), stats generation.

Multiple input read files can also be specified for co-assembly.

## Requirements

This pipeline requires and environment with cwltool, blastn, metaspades and megahit.

## Databases

Predownload fasta files for host decontamination and generate:
    - bwa index folder
    - blast index folder
    
Specify the locations in the yaml file when running the pipeline.


## Main pipeline executables

src/workflows/metagenome_pipeline.cwl
src/workflows/metatranscriptome_pipeline.cwl

# Example output directory structure
```
SRP0741
    └── SRP074153               Project directory containing all assemblies under that project
        ├── downloads.yml       Raw data download caching logfile, to avoid duplicate downloads of raw data
        ├── SRR6257
        │   └── SRR6257420      Run directory
        │       └── megahit
        │           ├── 001     Assembly directory
        │           │   ├── SRR6257420.fasta               Trimmed assembly
        │           │   ├── SRR6257420.fasta.gz            Archive trimmed assembly
        │           │   ├── SRR6257420.fasta.gz.md5        MD5 hash of above archive
        │           │   ├── coverage.tab                   Coverage file
        │           │   ├── final.contigs.fa               Raw assembly
        │           │   ├── job_config.yml                 CWL job configuration
        │           │   ├── megahit.log                    Assembler output log
        │           │   ├── output.json                    Human-readable Assembly stats file
        │           │   ├── sorted.bam                     BAM file of assembly
        │           │   ├── sorted.bam.bai                 Secondary BAM file
        │           │   └── toil.log                       cwlToil output log
        │           └── metaspades Assembly of equivalent data using another assembler (eg metaspades, spades...)
        │               └── ... 
        │ 
        ├── raw                 Raw data directory
        │   └── SRR6257420.fastq.gz                        Raw data files
        │
        └── tmp                 Temporary directory for assemblies
            └── SRR6257
                └── SRR6257420
                    └── megahit
                        └── 001
```
