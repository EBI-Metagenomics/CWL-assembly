# CWL-assembly
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/684724bbc0134960ab41748f4a4b732f)](https://www.codacy.com/app/mb1069/CWL-assembly?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=EBI-Metagenomics/CWL-assembly&amp;utm_campaign=Badge_Grade)
[![Build Status](https://travis-ci.org/EBI-Metagenomics/CWL-assembly.svg?branch=develop)](https://travis-ci.org/EBI-Metagenomics/CWL-assembly)


# Installation
## Create local environment named venv using Miniconda (eg below) or virtualenv
```bash
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86.sh
bash Miniconda2-latest-Linux-x86_64.sh -b -p $PWD/venv
source venv/bin/activate

pip install -U git+https://github.com/EBI-Metagenomics/CWL-assembly.git@develop

# Temporary requirement until fixes for cwltool in toil are released.
pip install git+https://github.com/DataBiosphere/toil.git
```

##
```bash
# If running on a multi-volume cluster, the following is required to avoid cross-volume symlinks / mounts
export TMP=$PWD/tmp 
```
# Running full pipeline from CLI
```bash
assembly_cli metaspades -s ERP010229 -r ERR866589  -d output
```

## Working pipeline examples
### MEGAHIT
```bash
Interleaved: assembly_cli megahit -s SRP074153 -r SRR6257420 -d tmp
Single:      assembly_cli megahit -s ERP012806 -r ERR1078287 -d tmp
```
### Metaspades
```bash
Paired:      assembly_cli metaspades -s ERP010229 -r ERR866589  -d tmp
Interleaved: assembly_cli metaspades -s SRP074153 -r SRR6257420 -d tmp
```

### Spades
```bash
Paired:      assembly_cli spades -s SRP040765 -r SRR1567464  -d tmp
Interleaved: assembly_cli spades -s SRP074153 -r SRR6257420 -d tmp
Single:      assembly_cli spades -s ERP012806 -r ERR1078287 -d tmp
```

# Running cwl pipelines on cluster

## MegaHit
```bash
cwltoil --user-space-docker-cmd=udocker --cleanWorkDir onSuccess --debug --outdir out --tmpdir tmp --workDir toil_work --batchSystem lsf megahit_pipeline.cwl megahit_pipeline.yml
```

## MetaSpades
```bash
cwltoil --user-space-docker-cmd=udocker --debug --outdir out --tmpdir tmp --workDir toil_work --batchSystem lsf  metaspades_pipeline.cwl metaspades_pipeline.yml
```



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
