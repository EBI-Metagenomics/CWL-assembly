cwlVersion: v1.2
class: CommandLineTool
label: map raw reads to contigs
doc: >
  Usage: bwa mem [options] <idxbase> <in1.fq> [in2.fq]

requirements:
  ResourceRequirement:
    coresMin: 32
    ramMin: 8000
  InlineJavascriptRequirement: {}
hints:
  DockerRequirement:
    dockerPull: quay.io/microbiome-informatics/bwamem2:2.2.1

baseCommand: [ 'bwa-mem2', 'mem' ]

inputs:
  min_std_max_min:
    type: 'int[]?'
    inputBinding:
      position: 1
      prefix: '-I'
      itemSeparator: ','
  minimum_seed_length:
    type: int?
    inputBinding:
      position: 1
      prefix: '-k'
    doc: '-k INT        minimum seed length [19]'
  output_filename:
    type: string?
    default: 'aln-se.sam'
  reads:
    type: File[]
    inputBinding:
      position: 3
  reference:
    type: File
    inputBinding:
      position: 2
    secondaryFiles:
      - '.amb'
      - '.ann'
      - '.pac'
      - '.0123'
      - '.bwt.2bit.64'
  threads:
    type: int?
    inputBinding:
      position: 1
      prefix: '-t'
    doc: '-t INT        number of threads [1]'

outputs:
  alignment:
    type: File
    outputBinding:
      glob: $(inputs.output_filename)

stdout: $(inputs.output_filename)

$namespaces:
 edam: http://edamontology.org/
 s: http://schema.org/
$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/version/latest/schemaorg-current-https.rdf

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder: "EMBL - European Bioinformatics Institute"