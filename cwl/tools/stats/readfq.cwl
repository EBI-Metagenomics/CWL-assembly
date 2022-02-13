cwlVersion: v1.2
class: CommandLineTool
label: readfq base count
doc: |
  usage: kseq_fastq_base input.fastq.gz [input2.fastq.gz input3.fastq.gz ...]

  Script to calculate base count of fastq files.

  positional arguments:
    input.fastq.gz         Raw read files

requirements:
  ResourceRequirement:
    coresMin: 32
    ramMin: 8000
  InlineJavascriptRequirement: {}
hints:
  DockerRequirement:
    dockerPull: "mgnify/cwl-assembly-readfq"
#update container

baseCommand: [ kseq_fastq_base ]


inputs:
  raw_reads:
    type: File[]
    inputBinding:
      position: 1

outputs:
  base_count:
    type: int
    outputBinding:
      glob: base_count.txt
      loadContents: true
      outputEval: "$(parseInt(self[0].contents))"

stdout: base_count.txt




