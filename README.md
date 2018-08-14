# CWL-assembly
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/684724bbc0134960ab41748f4a4b732f)](https://www.codacy.com/app/mb1069/CWL-assembly?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=EBI-Metagenomics/CWL-assembly&amp;utm_campaign=Badge_Grade)
[![Build Status](https://travis-ci.org/EBI-Metagenomics/CWL-assembly.svg?branch=develop)](https://travis-ci.org/EBI-Metagenomics/CWL-assembly)


# Installation
## Create local environment
```bash
bash setup_env.sh
source /hps/nobackup2/production/metagenomics/mdb/CWL-assembly/venv/bin/activateL-assembly/
cd /hps/nobackup2/production/metagenomics/mdb/CWL-assembly/cwl/assembly
export TMP=$PWD/tmp
mkdir tmp toil_work out
```

## Build docker containers
```bash
docker build -t readfq:latest $TRAVIS_BUILD_DIR/cwl/stats/readfq/
docker build -t stats_report:latest $TRAVIS_BUILD_DIR/cwl/stats/stats_report/
docker build -t fasta_trimming:latest $TRAVIS_BUILD_DIR/cwl/stats/fasta_trimming/
```


# Running full pipeline from CLI
```bash
python2 src/pipeline.py metaspades -s ERP010229 -r ERR866589  -d output
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