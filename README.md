# CWL-assembly
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/684724bbc0134960ab41748f4a4b732f)](https://www.codacy.com/app/mb1069/CWL-assembly?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=EBI-Metagenomics/CWL-assembly&amp;utm_campaign=Badge_Grade)
[![Build Status](https://travis-ci.org/EBI-Metagenomics/CWL-assembly.svg?branch=develop)](https://travis-ci.org/EBI-Metagenomics/CWL-assembly)


# Running pipelines on cluster
## Setting up env
source /hps/nobackup2/production/metagenomics/mdb/CWL-assembly/toil-3.16.0-dev/bin/activateL-assembly/
cd /hps/nobackup2/production/metagenomics/mdb/CWL-assembly/cwl/assembly
export TMP=$PWD/tmp
mkdir tmp toil_work out
## MegaHit
cwltoil --user-space-docker-cmd=udocker --cleanWorkDir onSuccess --debug --outdir out --tmpdir tmp --workDir toil_work --batchSystem lsf megahit_pipeline.cwl megahit_pipeline.yml

##MetaSpades
cwltoil --user-space-docker-cmd=udocker --debug --outdir out --tmpdir tmp --workDir toil_work --batchSystem lsf  metaspades_pipeline.cwl metaspades_pipeline.yml