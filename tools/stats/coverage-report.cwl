#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

requirements:
  - class: DockerRequirement
    dockerPull: python:3.6-slim

inputs:
  src:
    type: File
    default: coverage_calculation/coverage_report.py
    inputBinding:
      position: 1
  base_count:
    type: int
    inputBinding:
      position: 2
  coverage_file:
    type: File
    inputBinding:
      position: 3
  output:
    type: string
    inputBinding:
      position: 4

outputs:
  logfile:
    type: File
    outputBinding:
      glob: $(inputs.output)

baseCommand:
  - python

doc: |
  usage: coverage_report.py [-h] output coverage_file base_count

  Script to calculate coverage from coverage.tab file and output report

  positional arguments:
    output         Output file
    coverage_file  Coverage.tab file
    base_count     Sum of base count for all input files

  optional arguments:
    -h, --help     show this help message and exit


