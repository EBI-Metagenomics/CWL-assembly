cwlVersion: v1.2
class: CommandLineTool
label: Post assembly quality control
doc: |
      Remove sequences below threshold. Remove host sequences. Compress final fasta file

requirements:
  InlineJavascriptRequirement: {}
  ResourceRequirement:
    coresMin: 32
    ramMin: 8000
hints:
  DockerRequirement:
    dockerPull: "quay.io/microbiome-informatics/assembly-pipeline.python3_scripts:3.7.9"

baseCommand: ['python', '/data/trim_fasta.py']

inputs:
  name:
    type: string
    label: prefix for fasta file
    inputBinding:
      position: 1
      prefix: --run_id
  contigs:
    type: File
    format: edam:format_1929  # FASTQ
    label: assembly contig file
    inputBinding:
      position: 2
      prefix: --contig_file
  min_length:
    type: int?
    default: 500
    label: contig length threshold
    inputBinding:
      position: 3
      prefix: --threshold
  assembler:
    type: string
    label: assembler used
    inputBinding:
       position: 4
       prefix: --assembler
  blastn:
    type: File
    label: concatenated blastn output against contaminant dbs
    inputBinding:
        position: 5
        prefix: '--blast'

outputs:
  #two other optional outputs fasta with <500bp removed & fasta with contaminants removed
  trimmed_sequences_gz:
    type: File
    outputBinding:
      glob: $(inputs.name).fasta.gz
  trimmed_sequences_gz_md5:
    type: File
    outputBinding:
      glob: $(inputs.name).fasta.gz.md5
  filtered_contigs_unzipped:
    type: File
    outputBinding:
       glob: filtered_contigs.fasta

$namespaces:
 edam: http://edamontology.org/
 iana: https://www.iana.org/assignments/media-types/
 s: http://schema.org/
$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/docs/schema_org_rdfa.html


