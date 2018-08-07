#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

requirements:
  DockerRequirement:
    dockerPull: quay.io/biocontainers/bwa:0.7.17--ha92aebf_3
  InitialWorkDirRequirement:
    listing: [ $(inputs.sequences) ]
#TODO: Enable after this issue is fixed: https://github.com/common-workflow-language/cwltool/issues/80
#hints:
#  - $import: bwa-docker.yml

baseCommand:
- bwa
- index

inputs:
  algorithm:
    type: string?
    inputBinding:
      prefix: -a
    doc: |
      BWT construction algorithm: bwtsw or is (Default: auto)
  sequences:
    type: File
    inputBinding:
      valueFrom: $(self.basename)
      position: 4
  block_size:
    type: int?
    inputBinding:

      prefix: -b
    doc: |
      Block size for the bwtsw algorithm (effective with -a bwtsw) (Default: 10000000)

outputs:
  output:
    type: File
    secondaryFiles:
      - .amb
      - .ann
      - .bwt
      - .pac
      - .sa
    outputBinding:
      glob: $(inputs.sequences.basename)

$namespaces:
  sbg: 'https://www.sevenbridges.com'

doc: |
  Usage:   bwa index [options] <in.fasta>

  Options: -a STR    BWT construction algorithm: bwtsw or is [auto]
           -p STR    prefix of the index [same as fasta name]
           -b INT    block size for the bwtsw algorithm (effective with -a bwtsw) [10000000]
           -6        index files named as <in.fasta>.64.* instead of <in.fasta>.*

  Warning: `-a bwtsw' does not work for short genomes, while `-a is' and
           `-a div' do not work not for long genomes.


# cwltool --outdir tmp bwa-index.cwl bwa-index.yml