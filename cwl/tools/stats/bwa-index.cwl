cwlVersion: v1.2
class: CommandLineTool
label: index contigs
doc: |
  Usage:   bwa index [options] <in.fasta>

  Options: -a STR    BWT construction algorithm: bwtsw or is [auto]
           -p STR    prefix of the index [same as fasta name]
           -b INT    block size for the bwtsw algorithm (effective with -a bwtsw) [10000000]
           -6        index files named as <in.fasta>.64.* instead of <in.fasta>.*

  Warning: `-a bwtsw' does not work for short genomes, while `-a is' and
           `-a div' do not work not for long genomes.

requirements:
  ResourceRequirement:
    coresMin: 32
    ramMin: 8000
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing: [ $(inputs.sequences) ]
hints:
  DockerRequirement:
    dockerPull: quay.io/microbiome-informatics/bwamem2:2.2.1

baseCommand: [ 'bwa', 'index' ]


inputs:
  algorithm:
    type: string?
    label: BWT construction algorithm
    inputBinding:
      prefix: -a
  sequences:
    type: File
    label: contigs fasta file
    inputBinding:
      valueFrom: $(self.basename)
      position: 4
  block_size:
    type: int?
    label: Block size for the bwtsw algorithm (effective with -a bwtsw) (Default 10000000)
    inputBinding:
      prefix: -b


outputs:
  indexed_contigs:
    type: File
    label: indexed contig fasta file
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



# cwltool --outdir tmp bwa-index.cwl bwa-index.yml