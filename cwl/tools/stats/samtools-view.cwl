cwlVersion: v1.2
class: CommandLineTool
label: Get reads aligned to contigs from alignment file

doc: |
  samtools-view.cwl is developed for CWL consortium
    Usage:   samtools view [options] <in.bam>|<in.sam>|<in.cram> [region ...]

    Options: -b       output BAM
             -C       output CRAM (requires -T)
             -1       use fast BAM compression (implies -b)
             -u       uncompressed BAM output (implies -b)
             -h       include header in SAM output
             -H       print SAM header only (no alignments)
             -c       print only the count of matching records
             -o FILE  output file name [stdout]
             -U FILE  output reads not selected by filters to FILE [null]
             -t FILE  FILE listing reference names and lengths (see long help) [null]
             -T FILE  reference sequence FASTA FILE [null]
             -L FILE  only include reads overlapping this BED FILE [null]
             -r STR   only include reads in read group STR [null]
             -R FILE  only include reads with read group listed in FILE [null]
             -q INT   only include reads with mapping quality >= INT [0]
             -l STR   only include reads in library STR [null]
             -m INT   only include reads with number of CIGAR operations
                      consuming query sequence >= INT [0]
             -f INT   only include reads with all bits set in INT set in FLAG [0]
             -F INT   only include reads with none of the bits set in INT
                      set in FLAG [0]
             -x STR   read tag to strip (repeatable) [null]
             -B       collapse the backward CIGAR operation
             -s FLOAT integer part sets seed of random number generator [0];
                      rest sets fraction of templates to subsample [no subsampling]
             -@ INT   number of BAM compression threads [0]

requirements:
  ResourceRequirement:
    coresMin: 32
    ramMin: 8000
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
    default: false
  samheader:
    type: boolean
    inputBinding:
      position: 1
      prefix: '-h'
    doc: |
      include header in SAM output
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
  s: 'http://schema.org/'
  sbg: 'https://www.sevenbridges.com'
$schemas:
  - 'http://schema.org/docs/schema_org_rdfa.html'
's:author':
  class: 's:Person'
  's:email': 'mailto:Andrey.Kartashov@cchmc.org'
  's:name': Andrey Kartashov
  's:sameAs':
    - id: 'http://orcid.org/0000-0001-9102-5681'
  's:worksFor':
    - class: 's:Organization'
      's:department':
        - class: 's:Organization'
          's:name': Barski Lab
      's:location': '3333 Burnet Ave, Cincinnati, OH 45229-3026'
      's:name': Cincinnati Children's Hospital Medical Center
's:codeRepository': 'https://github.com/common-workflow-language/workflows'
's:downloadUrl': >-
  https://github.com/common-workflow-language/workflows/blob/master/tools/samtools-view.cwl
's:license': 'http://www.apache.org/licenses/LICENSE-2.0'
