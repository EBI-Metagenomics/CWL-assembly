#!/bin/bash

usage()
{
cat << EOF
usage: $0 options

Calculate coverage depth for concoct

OPTIONS:
   -b      bam alignment file [REQUIRED]
   -t      threads [REQUIRED]
   -c      assembly contigs [REQUIRED]
EOF
}

while getopts :b:t:c: option; do
    case "${option}" in
        b) BAM=${OPTARG};;
        t) THREADS=${OPTARG};;
        c) CONTIGS=${OPTARG};;
        *) echo "invalid option"; exit;;
    esac
done


echo "indexing .bam alignment file..."
samtools index -@ $threads -b BAM

echo "cutting up contigs into 10kb fragments for CONCOCT..."
cut_up_fasta.py ${CONTIGS} -c 10000 --merge_last -b assembly_10K.bed -o 0 > assembly_10K.fa
        if [[ $? -ne 0 ]]; then error "Something went wrong with cutting up contigs. Exiting."; fi

echo "estimating contig fragment coverage..."
CMD="concoct_coverage_table.py assembly_10K.bed ${BAM} > concoct_depth.txt"
  $(eval $CMD)
  if [[ $? -ne 0 ]]; then error "Something went wrong with estimating fragment abundance. Exiting..."; fi







