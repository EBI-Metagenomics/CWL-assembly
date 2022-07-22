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
   -o      Output directory
EOF
}

while getopts :t:c:f:r:o: option; do
    case "${option}" in
        t) THREADS=${OPTARG};;
        c) REF=${OPTARG};;
        f) FASTQ_R1=${OPTARG};;
        r) FASTQ_R2=${OPTARG};;
        o) OUTPUTDIR=${OPTARG};;
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
mkdir $OUTPUTDIR

if [[ ! -z ${FASTQ_R2} ]]
then
  echo "mapping files to host genome"
  bwa-mem2 mem -M -t $THREADS $REF $FASTQ_R1 $FASTQ_R2 | samtools view -@ $THREADS_SAM -f 12 -F 256 -uS - -o $OUTPUTDIR/${name}_both_unmapped.bam
	samtools sort -@ $THREADS_SAM -n $OUTPUTDIR/${name}_both_unmapped.bam -o $OUTPUTDIR/${name}_both_unmapped_sorted.bam
	samtools fastq -1 $OUTPUTDIR/${name}_clean_1.fastq -2 $OUTPUTDIR/${name}_clean_2.fastq -0 /dev/null -s /dev/null -n $OUTPUTDIR/${name}_both_unmapped_sorted.bam
	echo "compressing output files"
	gzip $OUTPUTDIR/${name}_clean_1.fastq
	gzip $OUTPUTDIR/${name}_clean_2.fastq
else
  echo mapping files to host genome""
  bwa-mem2 mem -M -t $THREADS $REF $FASTQ_R1 | samtools view -@ $THREADS_SAM -f 4 -F 256 -uS - -o $OUTPUTDIR/${name}_unmapped.bam
  samtools sort -@ $THREADS_SAM -n $OUTPUTDIR/${name}_unmapped.bam -o $OUTPUTDIR/${name}_unmapped_sorted.bam
  samtools $OUTPUTDIR/${name}_unmapped_sorted.bam > $OUTPUTDIR/${name}_clean.fastq
	echo "compressing output file"
	gzip $OUTPUTDIR/${name}_clean.fastq
fi
