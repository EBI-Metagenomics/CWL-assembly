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
  interleaved_reads:
    type: File?
  single_reads:
    type: File?
  assembly_memory:
    type: int
    default: 128
  min_contig_length:
    type: int
    default: 500
  assembler:
    type: string
    default: "megahit"


steps:
  megahit:
    in:
      forward_reads: forward_reads
      reverse_reads: reverse_reads
      interleaved_reads: interleaved_reads
      single_reads: single_reads
      assembly_memory: assembly_memory
    out:
      - contigs
      - log
    run: assembly/megahit.cwl
    label: 'megaHit: metagenomics assembler'

  post_assembly:
    in:
      assembly_log: megahit/log
      assembly: megahit/contigs
      assembler: assembler
      min_contig_length: min_contig_length
      reads:
        source: [forward_reads, reverse_reads, interleaved_reads, single_reads]
        valueFrom: $(self.filter(Boolean))
    out:
      - stats_output
    run: ./post_assembly.cwl

outputs:
  contigs:
    type: File
    outputSource: megahit/contigs
  stats_outputs:
    type: Directory
    outputSource: post_assembly/stats_output

$namespaces:
 edam: http://edamontology.org/
 iana: https://www.iana.org/assignments/media-types/
 s: http://schema.org/

