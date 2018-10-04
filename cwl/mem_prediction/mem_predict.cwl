#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

requirements:
  DockerRequirement:
    dockerPull: "migueldboland/cwl-assembly-mem-prediction"
  InlineJavascriptRequirement: {}

baseCommand: ['python', '/mem_predict.py']

inputs:
  lineage:
    type: string
    inputBinding:
      prefix: "--lineage"
  read_count:
    type: long
    inputBinding:
      prefix: "--read-count"
  base_count:
    type: long
    inputBinding:
      prefix: "--base-count"
  compressed_data_size:
    type: long
    inputBinding:
      prefix: "--size"
  lib_layout:
    type: string
    inputBinding:
      prefix: "--layout"
  lib_strategy:
    type: string
    inputBinding:
      prefix: "--strategy"
  lib_source:
    type: string
    inputBinding:
      prefix: "--source"
  assembler:
    type: string
    inputBinding:
      prefix: "--assembler"

outputs:
  memory:
    type: int
