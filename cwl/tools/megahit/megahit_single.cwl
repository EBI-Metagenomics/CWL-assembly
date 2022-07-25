#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

# For Megahit version 1.2.9
label: "megahit: metagenomics assembler"

hints:
  DockerRequirement:
    dockerPull: "quay.io/microbiome-informatics/megahit:1.2.9"

requirements:
  InlineJavascriptRequirement: {}
  ResourceRequirement:
    coresMin: 8
    ramMin: $(inputs.memory)

baseCommand: [ 'megahit' ]

arguments:
  - valueFrom: '8'
    prefix: --num-cpu-threads

inputs:
  #arrays allow for co-assembly
  memory:
    type: int?
    default: 143051
    label: memory to run assembly converted to mebibytes for cwl. Default is 150GB
    inputBinding:
      prefix: --memory
      position: 4
      valueFrom: |
        ${
            if (self == null) {
                return runtime.cores;
            } else {
                return self * 954 ;
            }
        }
  min-contig-len:
    type: int?
    default: 500
    inputBinding:
      prefix: "--min-contig-len"
      position: 2
  reads:
    type:
      - File?
      - type: array
        items: File
    inputBinding:
      prefix: "-r"
      itemSeparator: ","
      position: 4


outputs:
  contigs:
    type: File
    format: edam:format_1929  # FASTA
    outputBinding:
      glob: final.contigs.fa
  log:
    type: File
    format: iana:text/plain
    outputBinding:
      glob: log

  options:
    type: File
    outputBinding:
      glob: options.json

stdout: megahit_host.log
stderr: megahit_host.err

$namespaces:
 edam: http://edamontology.org/
 iana: https://www.iana.org/assignments/media-types/
 s: http://schema.org/
$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/docs/schema_org_rdfa.html

doc : |
  https://github.com/voutcn/megahit/wiki