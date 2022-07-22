cwlVersion: v1.2
class: CommandLineTool
label: fastq base count
doc: |
  usage: take second line (seq) for every four lines and count characters. This equals base count per input fastq file.

requirements:
  ResourceRequirement:
    coresMin: 1
    ramMin: 2000
  ShellCommandRequirement: {}
  InlineJavascriptRequirement: {}


hints:
  - class: DockerRequirement
    dockerPull: "quay.io/microbiome-informatics/bwamem2:2.2.1"

inputs:
  raw_reads:
    type: File

baseCommand: [ 'pigz' ]

arguments:
  - valueFrom: $(inputs.raw_reads)
    position: 2
    prefix: '-dc'
    shellQuote: false
  - valueFrom: '|'
    shellQuote: false
    position: 3
  - valueFrom: 'awk'
    shellQuote: false
    position: 4
  - valueFrom : 'NR%4==2{c++; l+=length($0)} END { print l }'
    shellQuote: true
    position: 5

outputs:
  base_counts:
    type: stdout

stdout: $(inputs.raw_reads).base_counts




