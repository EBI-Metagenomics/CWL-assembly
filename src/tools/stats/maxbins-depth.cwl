cwlVersion: v1.2
class: CommandLineTool
label: Reformat metabat2 coverage depth files for maxbins

requirements:
  ResourceRequirement:
    ramMin: 200

hints:
  - class: DockerRequirement
    dockerPull: quay.io/microbiome-informatics/bwamem2:2.2.1

baseCommand: [ 'maxbins-depth.sh' ]

inputs:
  metabat_depth:
    type: File
    format: edam:format_1964  # TXT
    label: metabat depth txt file
    inputBinding:
      position: 1
      prefix: -d
  run_accession:
    type: string
    label: run accession ID
    inputBinding:
      position: 2
      prefix: -r

outputs:
  master_depth:
    type: File
    format: edam:format_3475
    outputBinding:
      glob: mb2_master_depth.txt
  run_depth:
    type: File
    format: edam:format_3475
    outputBinding:
      glob: "mb2_$(inputs.run_accession).txt"

$namespaces:
 edam: http://edamontology.org/
 s: http://schema.org/
$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/version/latest/schemaorg-current-https.rdf

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder: "EMBL - European Bioinformatics Institute"

