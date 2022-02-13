cwlVersion: v1.2
class: CommandLineTool
label: Count fastq files before and after qc

requirements:
  ResourceRequirement:
    ramMin: 200

hints:
  - class: DockerRequirement
    dockerPull: alpine:3.7

baseCommand: [ 'sh', 'count_fastq.sh' ]

inputs:
  rawreads:
    type: File
    format: edam:format_1930  # FASTQ
    label: raw forward file
    inputBinding:
      position: 1
      prefix: -f
  trimmedreads:
    type: File
    format: edam:format_1930  # FASTQ
    label: fastp trimmed forward file
    inputBinding:
      position: 2
      prefix: -g
  cleanedreads:
    type: File
    format: edam:format_1930  # FASTQ
    label: host removed forward file
    inputBinding:
      position: 3
      prefix: -h

outputs:
  qc_counts:
    format: edam:format_3475
    outputBinding:
      glob: qc_stats.tsv
