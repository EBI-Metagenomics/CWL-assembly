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
  memory:
    type: [ int?, string? ]
    label: memory requested for assembly
  reads1:
    type: File
    format: edam:format_1930
    label: filtered forward or single fastq file for assembly
  reads2:
    type: File?
    format: edam:format_1930
    label: filtered reverse fastq file for assembly
  assembler:
    type: string?
    label: megahit or metaspades.
    doc: defaults to megahit for single or interleaved reads.

outputs:
  contigs:
    outputSource:
      - metaspades_paired/contigs
      - megahit_paired/contigs
      - megahit_single/contigs
    pickValue: first_non_null
    type: File
  assembly_log:
    outputSource:
      - metaspades_paired/log
      - megahit_paired/log
      - megahit_single/log
    pickValue: first_non_null
    type: File
  params_used:
    outputSource:
      - metaspades_paired/params
      - megahit_paired/options
      - megahit_single/options
    pickValue: first_non_null
    type: File
  assembly_graph:
    outputSource:
      - metaspades_paired/assembly_graph
    type: File?
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

  metaspades_paired:
    label: paired assembly with metaspades
    when: $(inputs.assembler == 'metaspades' && inputs.reverse_reads !== null)
    run: ../tools/metaspades/metaspades.cwl
    in:
      assembler: assembler
      memory: memory
      forward_reads: reads1
      reverse_reads: reads2
    out: [ contigs, assembly_graph, params, log ]

  megahit_paired:
    label: paired-end assembly with megahit
    when: $(inputs.assembler == 'megahit' && inputs.reverse_reads !== null)
    run: ../tools/megahit/megahit_paired.cwl
    in:
      assembler: assembler
      memory: memory
      forward_reads: 
        source: [ reads1 ]
        linkMerge: merge_nested
      reverse_reads: 
        source: [ reads2 ]
        linkMerge: merge_nested
    out: [ contigs, log, options ]

  megahit_single:
    label: single-end assembly with megahit
    when: $(inputs.reads2 == null)
    run: ../tools/megahit/megahit_single.cwl
    in:
      memory: memory
      reads:
        source: [ reads1 ]
        linkMerge: merge_nested
      reads2: reads2
    out: [ contigs, log, options ]


$namespaces:
 edam: http://edamontology.org/
 s: http://schema.org/
$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/version/latest/schemaorg-current-https.rdf

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder: "EMBL - European Bioinformatics Institute"
