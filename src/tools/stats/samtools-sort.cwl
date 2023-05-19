cwlVersion: v1.2
class: CommandLineTool
label: Sort bam alignment file

requirements:
  ResourceRequirement:
    coresMin: 32
    ramMin: 8000
  InlineJavascriptRequirement: {}
hints:
  DockerRequirement:
    dockerPull: quay.io/microbiome-informatics/bwamem2:2.2.1

baseCommand: [ 'samtools', 'sort' ]

inputs:
  compression_level:
    type: int?
    inputBinding:
      prefix: -l
    doc: |
      Set compression level, from 0 (uncompressed) to 9 (best)
  threads:
    type: int?
    inputBinding:
      prefix: -@
    doc: Set number of sorting and compression threads [1]
  memory:
    type: string?
    inputBinding:
      prefix: -m
    doc: |
      Set maximum memory per thread; suffix K/M/G recognized [768M]
  input:
    type: File
    inputBinding:
      position: 1
    doc: Input bam file.
  output_name:
    type: string
    inputBinding:
      prefix: -o
    doc: Desired output filename.
  sort_by_name:
    type: boolean?
    inputBinding:
      prefix: -n
    doc: Sort by read names (i.e., the QNAME field) rather than by chromosomal coordinates.

outputs:
  sorted_bam:
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