#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

requirements:
  DockerRequirement:
    dockerPull: "migueldboland/cwl-assembly-fasta-trimming"
  InlineJavascriptRequirement: {}

baseCommand: ['python', '/trim_fasta.py']

inputs:
  sequences:
    type: File
    inputBinding:
      position: 1
  min_contig_length:
    type: int
    inputBinding:
      position: 2
  assembler:
    type: string
    inputBinding:
      position: 4

outputs:
  trimmed_sequences:
    type: File
    outputBinding:
      glob: $('contigs.fasta')
  trimmed_sequences_gz:
    type: File
    outputBinding:
      glob: $('contigs.fasta.gz')
  trimmed_sequences_gz_md5:
    type: File
    outputBinding:
      glob: $('contigs.fasta.gz.md5')

doc: |
  usage: trim_fasta.py [-h] fasta min_contig_length contig_filename

  Remove contigs of length < min_contig_length from a fasta file.

  positional arguments:
    fasta              Path to fasta file to trim
    min_contig_length  Minimum contig length, set to 0 for no trimming
    contig_filename    Filename (without ANY extension) to give to contig files

  optional arguments:
    -h, --help         show this help message and exit


