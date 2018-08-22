# CWL-assembly
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/684724bbc0134960ab41748f4a4b732f)](https://www.codacy.com/app/mb1069/CWL-assembly?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=EBI-Metagenomics/CWL-assembly&amp;utm_campaign=Badge_Grade)
[![Build Status](https://travis-ci.org/EBI-Metagenomics/CWL-assembly.svg?branch=develop)](https://travis-ci.org/EBI-Metagenomics/CWL-assembly)


# Installation
## Create local environment named venv using Miniconda (eg below) or virtualenv
```bash
wget https://repo.continuum.io/miniconda/Miniconda2-latest-Linux-x86.sh
bash Miniconda2-latest-Linux-x86_64.sh -b -p $PWD/venv
source venv/bin/activate

pip install git+https://github.com/EBI-Metagenomics/CWL-assembly.git@develop

# Temporary requirement until fixes for cwltool in toil are released.
pip install git+https://github.com/DataBiosphere/toil.git
```

##
```bash
# If running on a multi-volume cluster, the following is required to avoid cross-volume symlinks / mounts
export TMP=$PWD/tmp 
```

## Working pipeline examples on LSF cluster
### MegaHit
```bash
Interleaved: assembly_cli megahit -s SRP074153 -r SRR6257420 -d out --batch_system lsf --docker-cmd udocker -m 16 -c 16
Single:      assembly_cli megahit -s ERP012806 -r ERR1078287 -d out --batch_system lsf --docker-cmd udocker -m 16 -c 16
```
### MetaSPAdes
```bash
Paired:      assembly_cli metaspades -s ERP010229 -r ERR866603  -d out --batch_system lsf --docker-cmd udocker -m 16 -c 16
Interleaved: assembly_cli metaspades -s SRP074153 -r SRR6257420 -d out --batch_system lsf --docker-cmd udocker -m 16 -c 16
```

### SPAdes
```bash
Paired:      assembly_cli spades -s SRP040765 -r SRR1567464  -d out --batch_system lsf --docker-cmd udocker -m 16 -c 16
Interleaved: assembly_cli spades -s SRP074153 -r SRR6257420 -d out --batch_system lsf --docker-cmd udocker -m 16 -c 16
Single:      assembly_cli spades -s ERP012806 -r ERR1078287 -d out --batch_system lsf --docker-cmd udocker -m 16 -c 16
```

## Handling docker dependencies
If using udocker, images need to be pre-loaded at install time to avoid a known issue with udocker pull.
On your machine:
```bash
docker pull migueldboland/cwl-assembly-readfq:latest && docker save migueldboland/cwl-assembly-readfq:latest -o readfq.tar
docker pull migueldboland/cwl-assembly-fasta-trimming:latest && docker save migueldboland/cwl-assembly-fasta-trimming:latest -o fasta-trimming.tar
docker pull migueldboland/cwl-assembly-stats-report:latest && docker save migueldboland/cwl-assembly-stats-report:latest -o stats-report.tar
docker pull quay.io/biocontainers/samtools:1.9--h46bd0b3_0 && docker save quay.io/biocontainers/samtools:1.9--h46bd0b3_0 -o samtools.tar
docker pull quay.io/biocontainers/bwa:0.7.17--ha92aebf_3 && docker save quay.io/biocontainers/bwa:0.7.17--ha92aebf_3 -o bwa.tar
docker pull quay.io/biocontainers/spades:3.12.0--1 && docker save quay.io/biocontainers/spades:3.12.0--1 -o spades.tar
docker pull quay.io/biocontainers/megahit:1.1.3--py36_0 && docker save quay.io/biocontainers/megahit:1.1.3--py36_0 -o megahit.tar
docker pull metabat/metabat:latest && docker save metabat/metabat:latest -o metabat.tar
```
On target machine:
```bash
docker load -i readfq.tar
docker load -i fasta-trimming.tar
docker load -i stats-report.tar
docker load -i samtools.tar
docker load -i bwa.tar
docker load -i spades.tar
docker load -i megahit.tar
docker load -i metabat.tar
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
