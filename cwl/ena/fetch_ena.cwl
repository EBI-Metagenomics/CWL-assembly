#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool


requirements:
  InlineJavascriptRequirement: {}
  DockerRequirement:
#    dockerPull: "migueldboland/cwl-assembly-fetch-ena"
    dockerImageId: "migueldboland/cwl-assembly-fetch-ena"
    dockerFile:
      $include docker/Dockerfile


baseCommand: ['python', '/pre_assembly.py']

inputs:
  study_accession:
    type: string
    inputBinding:
      position: 1
      prefix: -s
  runs:
    type: string[]?
    inputBinding:
      position: 2
      prefix: -r
      itemSeparator: ","
#  database:
#    type: string?
#    inputBinding:
#      position: 3
#      prefix: -d
#  no_db:
#    type: boolean?
#    inputBinding:
#      position: 4
#      prefix: --no-db
#  assembler:
#    type: string
#    inputBinding:
#      position: 5
#      prefix: -a
#  assembler_version:
#    type: string
#    inputBinding:
#      position: 5
#      prefix: -av
#  ignore_version:
#    type: boolean?
#    inputBinding:
#      position: 6
#      prefix: -iv
#  force:
#    type: boolean?
#    inputBinding:
#      position: 7
#      prefix: -f

outputs:
  assembly_jobs:
    type:
      type: array
      items:
        type: record
        fields:
            - name: run_accession
              type: string
            - name: raw_reads
              type: File[]
            - name: library_strategy
              type: string
            - name: library_layout
              type: string
            - name: library_source
              type: string
            - name: read_count
              type: long
            - name: base_count
              type: long
