cwlVersion: v1.2
class: CommandLineTool
label: Calculates concoct coverage depth with 10K contig chunks

requirements:
  ResourceRequirement:
    ramMin: 200

hints:
  - class: DockerRequirement
    dockerPull: quay.io/microbiome-informatics/bwamem2:2.2.1

baseCommand: [ 'concoct-depth.sh' ]

inputs:
  bam:
    type: File
    format: edam:format_2572  # BAM
    label: contig bam alignment file
    inputBinding:
      position: 1
      prefix: -b
  threads:
    type: int
    label: number of threads
    inputBinding:
      position: 2
      prefix: -t
    default: 4
  contigs:
    type: File
    format: edam:format_1929  # FASTA
    label: contig fasta file
    inputBinding:
      position: 3
      prefix: -c

outputs:
  concoct_depth:
    type: File
    format: edam:format_1964  # TXT
    outputBinding:
      glob: concoct_depth.txt
  assembly_bed:
    type: File
    format: edam:format_3003 # BED
    outputBinding:
      glob: assembly_10K.bed
  assembly_10k_fasta:
    type: File
    format: edam:format_1929
    outputBinding:
      glob: assembly_10K.fa

$namespaces:
 edam: http://edamontology.org/
 s: http://schema.org/
$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/version/latest/schemaorg-current-https.rdf

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder: "EMBL - European Bioinformatics Institute"

