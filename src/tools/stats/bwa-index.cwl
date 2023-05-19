cwlVersion: v1.2
class: CommandLineTool
label: index contigs fasta with bwa

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

baseCommand: [ 'bwa-mem2', 'index' ]


inputs:
  algorithm:
    type: string?
    label: BWT construction algorithm
    inputBinding:
      prefix: -a
  sequences:
    type: File
    label: contigs fasta file
    format: edam:format_1929 # FASTA
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
      - '.amb'
      - '.ann'
      - '.bwt'
      - '.pac'
      - '.sa'
      - '.0123'
      - '.bwt.2bit.64'
    outputBinding:
      glob: $(inputs.sequences.basename)

$namespaces:
 edam: http://edamontology.org/
 s: http://schema.org/
$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/version/latest/schemaorg-current-https.rdf

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder: "EMBL - European Bioinformatics Institute"



