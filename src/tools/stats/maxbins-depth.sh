#!/bin/bash

usage()
{
cat << EOF
usage: $0 options

Reformat metabat depth file for maxbins input

OPTIONS:
   -d      metabat coverage depth file [REQUIRED]
   -r      run accession [REQUIRED]
EOF
}

while getopts :d:r: option; do
    case "${option}" in
        d) METABAT=${OPTARG};;
        r) RUN=${OPTARG};;
        *) echo "invalid option"; exit;;
    esac
done

if [[ -z ${METABAT} ]] || [[ -z ${RUN}]]
then
     echo "ERROR : Please supply two inputs: metabat2 coverage depth file and run accession"
     usage
     exit 1
fi

cut -f 1,2,3,4 ${METABAT} > mb2_master_depth.txt
tail -n +2 ${METABAT} | cut -f 1,4 > "mb2_${RUN}.txt"







