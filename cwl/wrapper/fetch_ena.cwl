#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

baseCommand: ['python2', '/Users/mdb/work/CWL_assembly_pipeline/cwl/wrapper/fetch_ena.py']

inputs:
  study_accession:
    type: string
    inputBinding:
      position: 1



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
