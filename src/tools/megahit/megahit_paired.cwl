#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: MEGAHIT version 1.2.9 metagenomic assembler

#change to microbiome informatics container
hints:
  DockerRequirement:
    dockerPull: "quay.io/biocontainers/megahit:1.2.9--h2e03b76_1"
    
requirements:
  InlineJavascriptRequirement: {}
  ResourceRequirement:
    coresMin: 8
    ramMin: 100000

baseCommand: [ 'megahit' ]

inputs:

  memory:
    type: [ int?, string? ]
    label: Memory to run assembly. When 0 < -m < 1, fraction of all available memory of the machine is used, otherwise it specifies the memory in BYTE.
    default: '5000000000'
    inputBinding:
      position: 4
      prefix: "--memory"

  forward_reads:
    type:
      - File?
      - type: array
        items: File
    inputBinding:
      position: 1
      prefix: "-1"

  reverse_reads:
    type:
      - File?
      - type: array
        items: File
    inputBinding:
      position: 2
      prefix: "-2"

  threads:
    type: int
    default: 1
    inputBinding:
      position: 5
      prefix: "--num-cpu-threads"

  assembler:
    type: string?
    default: 'megahit'
    label: defined here for assembly.cwl conditional

outputs:
  contigs:
    type: File
    format: edam:format_1929  # FASTA
    outputBinding:
      glob: megahit_out/final.contigs.fa
  log:
    type: File
    format: iana:text/plain
    outputBinding:
      glob: megahit_out/log

  options:
    type: File
    outputBinding:
      glob: megahit_out/options.json

$namespaces:
 edam: http://edamontology.org/
 s: http://schema.org/
$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/version/latest/schemaorg-current-http.rdf

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder: "EMBL - European Bioinformatics Institute"
