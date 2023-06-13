cwlVersion: v1.2
class: CommandLineTool
label: "blastn against host and phiX contamination"

requirements:
  EnvVarRequirement:
    envDef:
      envName: BLASTDB
      envValue: $(inputs.blastdb_dir.path)
  InlineJavascriptRequirement: {}
  ResourceRequirement:
    coresMin: 4
    ramMin: 5000

baseCommand: ["blastn"]

arguments:
  - prefix: -task
    position: 1
    valueFrom: 'megablast'
  - prefix: -word_size
    position: 2
    valueFrom: '28'
  - prefix: -best_hit_overhang
    position: 3
    valueFrom: '0.1'
  - prefix: -best_hit_score_edge
    position: 4
    valueFrom: '0.1'
  - prefix: -dust
    position: 5
    valueFrom: 'yes'
  - prefix: -evalue
    position: 6
    valueFrom: '0.0001'
  - prefix: -min_raw_gapped_score
    position: 7
    valueFrom: '100'
  - prefix: -penalty
    position: 7
    valueFrom: '-5'
  - prefix: -perc_identity
    position: 8
    valueFrom: '80.0'
  - prefix: -soft_masking
    position: 9
    valueFrom: 'true'
  - prefix: -window_size
    position: 10
    valueFrom: '100'
  - prefix: -outfmt
    position: 11
    valueFrom: '6 qseqid ppos'

inputs:

  query_seq:
    type: File
    format: edam:format_1929 # FASTA
    inputBinding:
      prefix: "-query"

  blastdb_dir:
    type: Directory

  database_flag:
    type: string
    inputBinding:
      prefix: "-db"
      valueFrom: $(inputs.blastdb_dir.path)/$(inputs.database_flag)

outputs:
  alignment:
    type: stdout

stdout: $(inputs.database_flag.split('/').pop()).blast.out


$namespaces:
 edam: http://edamontology.org/
 s: http://schema.org/
$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/version/latest/schemaorg-current-http.rdf

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder: "EMBL - European Bioinformatics Institute"
