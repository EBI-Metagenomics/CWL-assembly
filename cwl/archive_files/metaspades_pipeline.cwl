class: Workflow
cwlVersion: v1.0

requirements:
  SubworkflowFeatureRequirement: {}
  MultipleInputFeatureRequirement: {}
  InlineJavascriptRequirement: {}
  StepInputExpressionRequirement: {}
  ScatterFeatureRequirement: {}

inputs:
  forward_reads:
    type: File?
  reverse_reads:
    type: File?
  min_contig_length:
    type: int
    default: 500
  assembly_memory:
    type: int
    default: 128

steps:
  metaspades:
    in:
      forward_reads: forward_reads
      reverse_reads: reverse_reads
      assembly_memory: assembly_memory
    out:
      - contigs
      - contigs_assembly_graph
      - assembly_graph
      - contigs_before_rr
      - internal_config
      - internal_dataset
      - log
      - params
      - scaffolds
      - scaffolds_assembly_graph
    run: assembly/metaspades.cwl
    label: 'metaSPAdes: de novo metagenomics assembler'

  post_assembly:
    in:
      assembly_log: metaspades/log
      assembly: metaspades/contigs
      assembler:
        valueFrom: $('metaspades')
      min_contig_length: min_contig_length
      reads:
        source: [forward_reads, reverse_reads]
    out:
      - assembly_output
      - stats_output
    run: ./post_assembly.cwl

outputs:
  assembly_output:
    type: Directory
    outputSource: post_assembly/assembly_output
  stats_output:
    type: Directory
    outputSource: post_assembly/stats_output

$namespaces:
 edam: http://edamontology.org/
 iana: https://www.iana.org/assignments/media-types/
 s: http://schema.org/

