cwlVersion: v1.2
class: CommandLineTool
label: Get reads aligned to contigs from alignment file in bam format using samtools view

requirements:
  ResourceRequirement:
    coresMin: 4
    ramMin: 2000
  InlineJavascriptRequirement: {}
hints:
  DockerRequirement:
    dockerPull: quay.io/microbiome-informatics/bwamem2:2.2.1

baseCommand: [ 'samtools', 'view', '-uS' ]

inputs:
  bedoverlap:
    type: File?
    inputBinding:
      position: 1
      prefix: '-L'
    doc: |
      only include reads overlapping this BED FILE [null]
  cigar:
    type: int?
    inputBinding:
      position: 1
      prefix: '-m'
    doc: |
      only include reads with number of CIGAR operations
      consuming query sequence >= INT [0]
    default: false
  collapsecigar:
    type: boolean
    inputBinding:
      position: 1
      prefix: '-B'
    doc: |
      collapse the backward CIGAR operation
    default: false
  count:
    type: boolean
    inputBinding:
      position: 1
      prefix: '-c'
    doc: |
      print only the count of matching records
    default: false
  fastcompression:
    type: boolean
    inputBinding:
      position: 1
      prefix: '-1'
    doc: |
      use fast BAM compression (implies -b)
    default: false
  input:
    type: File
    inputBinding:
      position: 4
    doc: |
      Input bam file.
    default: false
  isbam:
    type: boolean
    inputBinding:
      position: 2
      prefix: '-b'
    doc: |
      output in BAM format
    default: false
  iscram:
    type: boolean
    inputBinding:
      position: 2
      prefix: '-C'
    doc: |
      output in CRAM format
    default: false
  output_name:
    type: string
    inputBinding:
      position: 2
      prefix: '-o'
  randomseed:
    type: float?
    inputBinding:
      position: 1
      prefix: '-s'
    doc: |
      integer part sets seed of random number generator [0];
      rest sets fraction of templates to subsample [no subsampling]
  readsingroup:
    type: string?
    inputBinding:
      position: 1
      prefix: '-r'
    doc: |
      only include reads in read group STR [null]
  readsingroupfile:
    type: File?
    inputBinding:
      position: 1
      prefix: '-R'
    doc: |
      only include reads with read group listed in FILE [null]
  readsinlibrary:
    type: string?
    inputBinding:
      position: 1
      prefix: '-l'
    doc: |
      only include reads in library STR [null]
  readsquality:
    type: int?
    inputBinding:
      position: 1
      prefix: '-q'
    doc: |
      only include reads with mapping quality >= INT [0]
  readswithbits:
    type: int?
    inputBinding:
      position: 1
      prefix: '-f'
    doc: |
      only include reads with all bits set in INT set in FLAG [0]
  readswithoutbits:
    type: int?
    inputBinding:
      position: 1
      prefix: '-F'
    doc: |
      only include reads with none of the bits set in INT set in FLAG [0]
  readtagtostrip:
    type: 'string[]?'
    inputBinding:
      position: 1
    doc: |
      read tag to strip (repeatable) [null]
  referencefasta:
    type: File?
    inputBinding:
      position: 1
      prefix: '-T'
    doc: |
      reference sequence FASTA FILE [null]
  region:
    type: string?
    inputBinding:
      position: 5
    doc: |
      [region ...]
  samheader:
    type: boolean
    inputBinding:
      position: 1
      prefix: '-h'
    doc: |
      include header in SAM output
    default: false
  threads:
    type: int?
    inputBinding:
      position: 1
      prefix: '-@'
    doc: |
      number of BAM compression threads [0]
    default: false
  uncompressed:
    type: boolean
    inputBinding:
      position: 1
      prefix: '-u'
    doc: |
      uncompressed BAM output (implies -b)

outputs:
  unsorted_bam:
    type: File
    outputBinding:
      glob: $(inputs.output_name)

$namespaces:
 edam: http://edamontology.org/
 s: http://schema.org/
$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/version/latest/schemaorg-current-https.rdf

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder: "EMBL - European Bioinformatics Institute"