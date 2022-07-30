cwlVersion: v1.2
class: CommandLineTool
label: Count fastq files before and after qc

requirements:
  ResourceRequirement:
    ramMin: 200

hints:
  - class: DockerRequirement
    dockerPull: quay.io/microbiome-informatics/bwamem2:2.2.1

baseCommand: [ 'count_fastq.sh' ]

inputs:
  rawreads:
    type: File
    format: edam:format_1930  # FASTQ
    label: raw forward file
    inputBinding:
      position: 1
      prefix: -f
  trimmedreads:
    type: File
    format: edam:format_1930  # FASTQ
    label: fastp trimmed forward file
    inputBinding:
      position: 2
      prefix: -g
  cleanedreads:
    type: File
    format: edam:format_1930  # FASTQ
    label: host removed forward file
    inputBinding:
      position: 3
      prefix: -h

outputs:
  qc_counts:
    type: File
    format: edam:format_3475
    outputBinding:
      glob: qc_stats.tsv

$namespaces:
 edam: http://edamontology.org/
 s: http://schema.org/
$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/version/latest/schemaorg-current-https.rdf

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder: "EMBL - European Bioinformatics Institute"

