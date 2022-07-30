cwlVersion: v1.2
class: CommandLineTool
label: Calculate assembly statistics

requirements:
  ResourceRequirement:
    coresMin: 8
    ramMin: 2000
  InlineJavascriptRequirement: {}
hints:
  DockerRequirement:
    dockerPull: "quay.io/microbiome-informatics/assembly-pipeline.python3_scripts:3.7.9"

baseCommand: ['/opt/miniconda/bin/python', '/data/gen_stats_report.py']

inputs:
  sequences:
    type: File
    label: cleaned contig file
    inputBinding:
      position: 2
      prefix: --sequences
  coverage_file:
    type: File
    label: coverage depth file
    inputBinding:
      position: 3
      prefix: --coverage_file
  assembler:
    type: string
    label: assembler used metaspades, spades or megahit
    inputBinding:
      position: 4
      prefix: --assembler
  assembly_log:
    type: File
    label: logfile from assembly
    inputBinding:
       position: 5
       prefix: --logfile
  base_count:
    type: File[]
    label: raw reads base count output of readfq
    inputBinding:
      position: 6
      prefix: --base_count

outputs:
  logfile:
    type: File
    outputBinding:
      glob: $('assembly_stats.json')


$namespaces:
 edam: http://edamontology.org/
 s: http://schema.org/
$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/version/latest/schemaorg-current-https.rdf

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder: "EMBL - European Bioinformatics Institute"
