cwlVersion: v1.2
class: Workflow
label: preprocessing for metagenomic short reads

requirements:
  SubworkflowFeatureRequirement: {}
  MultipleInputFeatureRequirement: {}
  InlineJavascriptRequirement: {}
  StepInputExpressionRequirement: {}
  ScatterFeatureRequirement: {}
  ResourceRequirement:
    coresMin: 8
    ramMin: 8000

inputs:
  prefix:
    type: string
    label: run id to use for processed files
  reads1:
    type: File[]
    format: edam:format_1930
    label: fastq single or forward file for qc
  reads2:
    type: File[]?
    format: edam:format_1930
    label: fastq reverse file for qc
  min_length:
    type: int?
    label: Length filter for short reads
    default: 50
  host_genome:
    type: File?
    secondaryFiles:
        - '.amb'
        - '.ann'
        - '.bwt'
        - '.pac'
        - '.sa'
        - '.0123'
        - '.bwt.2bit.64'
    format: edam:format_1929
    label: host genome fasta file
    default: hg38.fa

outputs:
  reads_qc_html:
    type: File
    outputSource: trim_reads/qchtml
  reads_qc_json:
    type: File
    outputSource: trim_reads/qcjson
  qc_reads1:
    type: File
    format: edam:format_1930
    outputSource: host_removal/outreads1
  qc_reads2:
    type: File?
    format: edam:format_1930
    outputSource: host_removal/outreads2
  qc_summary:
    type: File
    format: edam:format_3475
    outputSource: qc_stats/qc_counts

steps:
  trim_reads:
    label: filter short reads and adapter sequences
    run: ../tools/fastp/fastp.cwl
    scatter: [reads1, reads2]
    scatterMethod: dotproduct
    in:
      reads1: reads1
      reads2: reads2
      minLength: min_length
      name: prefix
    out: [ outreads1, outreads2, qcjson, qchtml ]

#add ability to filter by more than one host genome
  host_removal:
    label: filter single host genome reads
    run: ../tools/bwa/bwa.cwl
    scatter: [reads1, reads2]
    scatterMethod: dotproduct
    in:
      name: prefix
      ref: host_genome
      reads1: trim_reads/outreads1
      reads2 : trim_reads/outreads2
    out: [ outreads1, outreads2 ]

  qc_stats:
    label: get counts pre and post filtering
    run: ../utils/count_fastq.cwl
    scatter: [rawreads, trimmedreads, cleanedreads]
    scatterMethod: dotproduct
    in:
      rawreads: reads1
      trimmedreads: trim_reads/outreads1
      cleanedreads: host_removal/outreads1
    out: [ qc_counts ]


$namespaces:
 edam: http://edamontology.org/
 s: http://schema.org/
$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/version/latest/schemaorg-current-https.rdf

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder: "EMBL - European Bioinformatics Institute"
s:dateCreated: 2021-02-11