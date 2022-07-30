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
    type: string
    label: megahit or metaspades.
    doc: metaspades is the first choice unless megahit specified. Defaults to megahit for single or interleaved reads.
    default: 'metaspades'

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

steps:
  metaspades_paired:
    label: paired assembly with metaspades
    when: $(inputs.assembler == 'metaspades' && inputs.reverse_reads != undefined)
    run: ../tools/metaspades/metaspades.cwl
    in:
      assembler: assembler
      memory: memory
      forward_reads: reads1
      reverse_reads: reads2
    out: [ contigs, assembly_graph, params, log ]

# suggested default to megahit for single or interleaved
#  spades_single:
#    label: single assembly defaults to spades
#    when: $(inputs.assembler == 'metaspades' && inputs.reads2 == undefined)
#    run: ../tools/metaspades/spades.cwl
#    in:
#      memory: memory
#      reads: reads1
#    out: [ contigs, assembly_graph, params, log ]

  megahit_paired:
    label: paired assembly with megahit
    when: $(inputs.assembler == 'megahit' && inputs.reverse_reads != undefined)
    run: ../tools/megahit/megahit_paired.cwl
    in:
      assembler: assembler
      memory: memory
      forward_reads: reads1
      reverse_reads: reads2
    out: [ contigs, log, options ]

  megahit_single:
    label: paired assembly with megahit
    when: $(inputs.reads2 == undefined)
    run: ../tools/megahit/megahit_paired.cwl
    in:
      assembler: assembler
      memory: memory
      reads: reads1
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