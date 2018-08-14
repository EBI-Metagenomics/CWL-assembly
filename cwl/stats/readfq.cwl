#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

requirements:
  DockerRequirement:
    dockerPull: "migueldboland/cwl-assembly-readfq"
  InlineJavascriptRequirement: {}

baseCommand:
  - /kseq_fastq_base

inputs:
  raw_reads:
    type: File[]
    inputBinding:
      position: 1

stdout: base_count.txt

outputs:
  base_count:
    type: int
    outputBinding:
      glob: base_count.txt
      loadContents: true
      outputEval: "$(parseInt(self[0].contents))"


doc: |
  usage: kseq_fastq_base input.fastq.gz [input2.fastq.gz input3.fastq.gz ...]

  Script to calculate base count of fastq files.

  positional arguments:
    input.fastq.gz         Raw read files



