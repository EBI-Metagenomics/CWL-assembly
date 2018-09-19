#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

# For Megahit version 1.1.3
label: "megahit: metagenomics assembler"

doc : |
  https://github.com/voutcn/megahit/wiki

hints:
  SoftwareRequirement:
    packages:
      spades:
        specs: [ "https://identifiers.org/rrid/RRID:SCR_000131" ]
        version: [ "3.12.0" ]

requirements:
  DockerRequirement:
    dockerPull: "quay.io/biocontainers/megahit:1.1.3--py36_0"
  InlineJavascriptRequirement: {}

baseCommand: megahit

arguments:
#  - valueFrom: $(runtime.tmpdir)
#    prefix: --tmp-dir
  - valueFrom: $(5 * 1000000) # GB to B conversion
    prefix: --memory
  - valueFrom: $(runtime.cores)
    prefix: --num-cpu-threads

inputs:
  #  INPUT OPTIONS
  # TODO exclusive 1 & 2 || 12
  
  forward_reads:
    type: File
    inputBinding:
      position: 1
      prefix: "-1"
      itemSeparator: ","

  reverse_reads:
    type: File
    inputBinding:
      position: 2
      prefix: "-2"
      itemSeparator: ","

  input-cmd:
    type: boolean?
    inputBinding:
      position: 5
      prefix: "--input-cmd"

  min-count:
    type: int?
    inputBinding:
      position: 6
      prefix: "--min-count"

  k-list:
    type: string[]?
    inputBinding:
      position: 7
      prefix: "--k-list"
      itemSeparator: ","

  k-min:
    type: int?
    inputBinding:
      position: 8
      prefix: "--k-min"
  
  k-max:
    type: int?
    inputBinding:
      position: 9
      prefix: "--k-min"  

  k-step:
    type: int?
    inputBinding:
      position: 10
      prefix: "--k-min"


  no-mercy:
    type: boolean?
    inputBinding:
      position: 11
      prefix: "--no-mercy"

  bubble-level:
    type: int?
    inputBinding:
      position: 12
      prefix: "--bubble-level"

  merge-level:
    type: string?
    inputBinding:
      position: 14
      prefix: "--merge-level"

  prune-level:
    type: int?
    inputBinding:
      position: 15
      prefix: "--prune-level"

  prune-depth:
    type: int?
    inputBinding:
      position: 16
      prefix: "--prune-depth"

  low-local-ratio:
    type: float?
    inputBinding:
      position: 17
      prefix: "--low-local-ratio"

  max-tip-len:
    type: int?
    inputBinding:
      position: 18
      prefix: "--max-tip-len"

  no-local:
    type: boolean?
    inputBinding:
      position: 19
      prefix: "--kmin-1pass"
  
  presets:
    type: string?
    inputBinding:
      position: 20
      prefix: "--presets"

  use-gpu:
    type: boolean?
    inputBinding:
      position: 23
      prefix: "--use-gpu"

  gpu-mem:
    type: boolean?
    inputBinding:
      position: 24
      prefix: "--gpu-mem"

  # OUTPUT OPTIONS

  o:
    type: string?
    inputBinding:
      position: 26
      prefix: "-o"

  out-prefix:
    type: string?
    inputBinding:
      position: 27
      prefix: "--out-prefix"

  min-contig-len:
    type: int?
    inputBinding:
      position: 28
      prefix: "--min-contig-len"

  keep-tmp-files:
    type: boolean?
    inputBinding:
      position: 29
      prefix: "--keep-tmp-files"

#  tmp-dir:
#    type: Directory?
#    inputBinding:
#      position: 30
#      prefix: "--tmp-dir"

  # OTHER ARGUMENTS

  continue:
    type: boolean?
    inputBinding:
      position: 31
      prefix: "--continue"

  verbose:
    type: boolean?
    inputBinding:
      position: 32
      prefix: "--verbose"

outputs:
  contigs:
    type: File
    format: edam:format_1929  # FASTA
    outputBinding:
      glob: $(inputs.o || "megahit_out")/final.contigs.fa
  log:
    type: File
    format: iana:text/plain
    outputBinding:
      glob: $(inputs.o || "megahit_out")/log

$namespaces:
 edam: http://edamontology.org/
 iana: https://www.iana.org/assignments/media-types/
 s: http://schema.org/
$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/docs/schema_org_rdfa.html
