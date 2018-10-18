#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool


requirements:
  InlineJavascriptRequirement: {}
  DockerRequirement:
    dockerPull: "migueldboland/cwl-assembly-fetch-ena"
#    dockerImageId: "migueldboland/cwl-assembly-fetch-ena"
#    dockerFile:
#      $include docker/Dockerfile


baseCommand: ['python', '/fetch_ena.py']

inputs:
  study_accession:
    type: string
    inputBinding:
      position: 1
  runs:
    type: string[]
    inputBinding:
      position: 2
      prefix: "-r"
      itemSeparator: ","


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
