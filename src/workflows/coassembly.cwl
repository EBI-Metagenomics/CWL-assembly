cwlVersion: v1.2
class: Workflow
label: assembly for single and paired end reads

requirements:
  SubworkflowFeatureRequirement: {}
  MultipleInputFeatureRequirement: {}
  InlineJavascriptRequirement: {}
  StepInputExpressionRequirement: {}
  ScatterFeatureRequirement: {}

inputs:
  assembler:
    type: string?
    label: preferred assembler
  memory:
    type: [ int?, string? ]
    label: memory requested for assembly
  multiple_reads_1:
    type: File[]
    format: edam:format_1930
    label: multiple filtered forward or single fastq file for assembly
  multiple_reads_2:
    type: File[]?
    format: edam:format_1930
    label: multiple filtered reverse fastq file for assembly

outputs:
  contigs:
    outputSource:
      - megahit_multiple_paired/contigs
      - megahit_multiple_single/contigs
    pickValue: first_non_null
    type: File
  assembly_log:
    outputSource:
      - megahit_multiple_paired/log
      - megahit_multiple_single/log
    pickValue: first_non_null
    type: File
  params_used:
    outputSource:
      - megahit_multiple_paired/options
      - megahit_multiple_single/options
    pickValue: first_non_null
    type: File
  assembler_final: 
    outputSource: return_assembler/assembler_out
    type: string

steps:
  return_assembler:
    label: return assembler
    run: ../utils/detect_assembler.cwl
    in:
      assembler: assembler
    out: [ assembler_out ]

  megahit_multiple_paired:
    label: multiple paired assembly with megahit
    when: $(inputs.reverse_reads !== null)
    run: ../tools/megahit/megahit_paired.cwl
    in:
      memory: memory
      forward_reads: multiple_reads_1
      reverse_reads: multiple_reads_2
    out: [ contigs, log, options ]

  megahit_multiple_single:
    label: multiple paired assembly with megahit
    when: $(inputs.reads2 == null)
    run: ../tools/megahit/megahit_single.cwl
    in:
      memory: memory
      reads: multiple_reads_1
      reads2: multiple_reads_2
    out: [ contigs, log, options ]


$namespaces:
 edam: http://edamontology.org/
 s: http://schema.org/
$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/version/latest/schemaorg-current-https.rdf

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder: "EMBL - European Bioinformatics Institute"
