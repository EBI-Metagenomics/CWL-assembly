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
  coassembly:
    type: string

outputs:
  reads_qc_html:
    type: File[]
    outputSource: trim_reads/qchtml
  reads_qc_json:
    type: File[]
    outputSource: trim_reads/qcjson
  qc_reads1:
    type: File[]
    format: edam:format_1930
    outputSource: host_removal/outreads1
  qc_reads2:
    type: File[]?
    format: edam:format_1930
    outputSource: reads2_reset/outreads2_final
  qc_summary:
    type: File[]
    format: edam:format_3475
    outputSource: qc_stats/qc_counts

steps:
  reads2_assessment:
    label: input adjustement depending on single- or paired-end reads
    run: ../utils/fill_reads2.cwl
    in:
      reads2: reads2
    out: [ reads2_filled ]

  trim_reads:
    label: filter short reads and adapter sequences
    run: ../tools/fastp/fastp.cwl
    scatter: [reads1, reads2, name]
    scatterMethod: dotproduct
    in:
      reads1: reads1
      reads2: reads2_assessment/reads2_filled
      minLength: min_length
      name: 
        source: reads1
        valueFrom: "$(self.basename)"
    out: [ outreads1, outreads2, qcjson, qchtml ]

#add ability to filter by more than one host genome
  host_removal:
    label: filter single host genome reads
    run: ../tools/bwa/bwa.cwl
    scatter: [reads1, reads2, name]
    scatterMethod: dotproduct
    in:
      coassembly: coassembly
      ref: host_genome
      reads1: trim_reads/outreads1
      reads2 : trim_reads/outreads2
      name: 
        source: reads1
        valueFrom: "$(self.basename)"
    out: [ outreads1, outreads2 ]

  reads2_reset:
    label: restore original value for reads2 if empty
    run: ../utils/restore_reads2.cwl
    in:
      reads2: host_removal/outreads2
    out: [ outreads2_final ]

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
