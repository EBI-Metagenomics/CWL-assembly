#!/bin/bash

usage()
{
cat << EOF
usage: $0 options

Remove host DNA sequences from FASTQ files. Output are zipped fastq files.

OPTIONS:
   -t      Number of threads (recommended: 16)
   -c      Referece genome for host decontamination (default: human_hg38)
   -f      Forward or single-end fastq file (.fastq or .fastq.gz) [REQUIRED]
   -r	     Reverse fastq file (.fastq or .fastq.gz) [OPTIONAL]
   -x      Output forward file (.fastq.gz) [REQUIRED]
   -y      Output reverse file (.fastq.gz) [OPTIONAL]
EOF
}

while getopts :t:c:f:r: option; do
    case "${option}" in
        t) THREADS=${OPTARG};;
        c) REF=${OPTARG};;
        f) FASTQ_R1=${OPTARG};;
        r) FASTQ_R2=${OPTARG};;
        *) echo "invalid option"; exit;;
    esac
done

# check if all required arguments are supplied
if [[ -z ${FASTQ_R1} ]]
then
     echo "ERROR : Please supply input FASTQ files"
     usage
     exit 1
fi

if [[ -z ${REF} ]]
then
    REF="hg38.fa"
fi

if [ ${THREADS} -eq 1 ]
then
    THREADS_SAM=1
else
    THREADS_SAM=$((${THREADS}-1))
fi

name=${FASTQ_R1%_*}

if [[ ! -z ${FASTQ_R2} ]]
then
  echo "mapping files to host genome"
  bwa mem -M -t $THREADS $REF $FASTQ_R1 $FASTQ_R2 | samtools view -@ $THREADS_SAM -f 12 -F 256 -uS - -o ${name}_both_unmapped.bam
	samtools sort -@ $THREADS_SAM -n ${name}_both_unmapped.bam -o ${name}_both_unmapped_sorted.bam
	bedtools bamtofastq -i ${name}_both_unmapped_sorted.bam -fq ${name}_clean_1.fastq -fq2 ${name}_clean_2.fastq
	echo "compressing output files"
	gzip ${name}_clean_1.fastq
	gzip ${name}_clean_2.fastq
  echo "cleaning tmp files"
  rm -rf ${name}_both_unmapped.bam ${name}_both_unmapped_sorted.bam
  #remove ${FASTQ_R1} ${FASTQ_R2}
else
  echo mapping files to host genome""
  bwa mem -M -t $THREADS $REF $FASTQ_R1 | samtools view -@ $THREADS_SAM -f 4 -F 256 -uS - -o ${name}_unmapped.bam
  samtools sort -@ $THREADS_SAM -n ${name}_unmapped.bam -o ${name}_unmapped_sorted.bam
  bedtools bamtofastq -i ${name}_unmapped_sorted.bam -fq ${name}_clean.fastq
	echo "compressing output file"
	gzip ${name}_clean.fastq
  echo "cleaning tmp files"
  rm -rf ${name}_unmapped.bam ${name}_unmapped_sorted.bam
  #remove $FASTQ_R1
fi
