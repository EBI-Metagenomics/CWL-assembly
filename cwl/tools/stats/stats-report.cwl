cwlVersion: v1.2
class: CommandLineTool
label: Calculate assembly statistics
doc: |
  usage: gen_coverage_report.py [-h] output coverage_file base_count

  Script to calculate coverage from coverage.tab file and output report

  positional arguments:
    output         Output file
    coverage_file  Coverage.tab file
    base_count     Sum of base count for all input files

  optional arguments:
    -h, --help     show this help message and exit

requirements:
  ResourceRequirement:
    coresMin: 8
    ramMin: 2000
  InlineJavascriptRequirement: {}
hints:
  DockerRequirement:
    dockerPull: "quay.io/microbiome-informatics/assembly-pipeline.python3_scripts:3.7.9"

baseCommand: ['python', '/data/gen_stats_report.py']

inputs:
  sequences:
    type: File
    label: cleaned contig file
    inputBinding:
      position: 2
      prefix: --sequences
  coverage_file:
    type: File
    label: coverage depth file
    inputBinding:
      position: 3
      prefix: --coverage_file
  assembler:
    type: string
    label: assembler used metaspades, spades or megahit
    inputBinding:
      position: 4
      prefix: --assembler
  assembly_log:
    type: File
    label: logfile from assembly
    inputBinding:
       position: 5
       prefix: --logfile
  base_count:
    type: File[]
    label: raw reads base count output of readfq
    inputBinding:
      position: 6
      prefix: --base_count

outputs:
  logfile:
    type: File
    outputBinding:
      glob: $('assembly_stats.json')



