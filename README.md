# CWL-assembly
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/684724bbc0134960ab41748f4a4b732f)](https://www.codacy.com/app/mb1069/CWL-assembly?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=EBI-Metagenomics/CWL-assembly&amp;utm_campaign=Badge_Grade)
[![Build Status](https://travis-ci.org/EBI-Metagenomics/CWL-assembly.svg?branch=develop)](https://travis-ci.org/EBI-Metagenomics/CWL-assembly)

## Description

This repository contains two workflows for metagenome and metatranscriptome assembly of short read data. MetaSPAdes is used as default for paired-end data, and MEGAHIT for single-end data and co-assemblies. MEGAHIT can be specified as the default assembler in the yaml file if preferred. Steps include:

  * _QC_: removal of short reads, low quality regions, adapters and host decontamination
  * _Assembly_: with metaSPADES or MEGAHIT
  * _Post-assembly_: Host and PhiX decontamination, contig length filter (500bp), stats generation

## Requirements - How to install

This pipeline requires a conda environment with cwltool, blastn, and metaspades. If created with `requirements.yml`, the environment will be called `cwl_assembly`. 

```
conda env create -f requirements.yml
conda activate cwl_assembly
pip install cwltool==3.1.20230601100705
```

## Databases

You will need to pre-download fasta files for host decontamination and generate the following databases accordingly:
  * bwa index
  * blast index
    
Specify the locations in the yaml file when running the pipeline.

## Main pipeline executables

  * `src/workflows/metagenome_pipeline.cwl`
  * `src/workflows/metatranscriptome_pipeline.cwl`

## Example command

```cwltool --singularity --outdir ${OUTDIR} ${CWL} ${YML}```

`$CWL` is going to be one of the executables mentioned above
`$YML` should be a config yaml file including entries among what follows. In the case of single-end assemblies, choose parameters `reads1` (and `reads2` in the case of paired-end). For co-assemblies, please use `multiple_reads_1` for multiple single-end samples, jointly with `multiple_reads_2` for multiple paired-end combinations. 

```
reads1:
  class: File
  format: http://edamontology.org/format_1930
  path: /path/to/reads1

reads2: # OPTIONAL
  class: File
  format: http://edamontology.org/format_1930
  path: /path/to/reads2

multiple_reads_1:
  - class: File
    format: http://edamontology.org/format_1930
    path: /path/to/fastq_1.gz
  - class: File
    format: http://edamontology.org/format_1930
    path: /path/to/fastq_2.gz

multiple_reads_2: # OPTIONAL
  - class: File
    format: http://edamontology.org/format_1930
    path: /path/to/fastq_1.gz
  - class: File
    format: http://edamontology.org/format_1930
    path: /path/to/fastq_2.gz

assembler: 'megahit' OR 'metaspades'

prefix: # ASSEMBLY PREFIX e.g. 'SRR6257420'

min_contig_length: 50

host_genome:
  class: File
  format: http://edamontology.org/format_1929
  path: /path/to/host_genome

database_flag: 
  - #STRING INDICATING THE GENOME FOR HOST DECONTAMINATION e.g. 'phiX'

coassembly: 'no' # OR 'yes'

blastdb_dir:
  class: Directory
  path: /path/to/blast_databases

assembly_version: # STRING FOR ASSEMBLY NAME / VERSION e.g. '001'

raw_dir_name: # STRING FOR RAW FILES OUTPUT DIRECTORY e.g. 'raw'
```

## Example output directory structure
```
Root directory
    ├── megahit
    │   └── 001 -------------------------------- Assembly root directory
    │       ├── assembly_stats.json ------------ Human-readable assembly stats file
    │       ├── coverage.tab ------------------- Coverage file
    │       ├── log ---------------------------- CwlToil+megahit output log
    |       ├── options.json ------------------- Megahit input options
    │       ├── SRR6257420.fasta.gz ------------ Archived and trimmed assembly
    │       └── SRR6257420.fasta.gz.md5 -------- MD5 hash of above archive
    ├── metaspades
    │   └── 001 -------------------------------- Assembly root directory
    │       ├── assembly_graph.fastg ----------- Assembly graph
    │       ├── assembly_stats.json ------------ Human-readable assembly stats file
    │       ├── coverage.tab ------------------- Coverage file
    |       ├── params.txt --------------------- Metaspades input options
    │       ├── spades.log --------------------- Metaspades output log
    │       ├── SRR6257420.fasta.gz ------------ Archived and trimmed assembly
    │       └── SRR6257420.fasta.gz.md5 -------- MD5 hash of above archive
    │ 
    └── raw ------------------------------------ Raw data directory
        ├── SRR6257420.fastq.qc_stats.tsv ------ Stats for cleaned fastq
        ├── SRR6257420_fastp_clean_1.fastq.gz -- Cleaned paired-end file_1
        └── SRR6257420_fastp_clean_2.fastq.gz -- Cleaned paired-end file_2
```
