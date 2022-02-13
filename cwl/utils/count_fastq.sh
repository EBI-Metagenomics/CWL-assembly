#!/bin/bash

usage()
{
cat << EOF
usage: $0 options

Count number of sequences in fastq before and after QC

OPTIONS:
   -f      Raw forward or single-end fastq file (.fastq.gz) [REQUIRED]
   -g      Trimmed forward or single-end fastq file (.fastq.gz) [REQUIRED]
   -h      Host removed forward or single-end fastq file (.fastq.gz) [REQUIRED]
EOF
}

while getopts :f:g:h: option; do
    case "${option}" in
        f) RAW=${OPTARG};;
        g) TRIMMED=${OPTARG};;
        h) CLEAN=${OPTARG};;
        *) echo "invalid option"; exit;;
    esac
done

if [[ -z ${RAW} ]] || [[ -z ${TRIMMED} ]] || [[ -z ${CLEAN} ]]
then
     echo "ERROR : Please supply three input FASTQ files"
     usage
     exit 1
fi

count_fastq () {
   lines=$(zcat $1 | wc -l)
   count=$((lines/4 | bc))
   echo $count
}

raw_count=$(count_fastq $RAW)
trimmed_count=$(count_fastq $TRIMMED)
clean_count=$(count_fastq $CLEAN)

echo -e "raw_count\t$raw_count\ntrimmed_count\t$trimmed_count\nhost_removed_count\t$clean_count" > qc_stats.tsv




