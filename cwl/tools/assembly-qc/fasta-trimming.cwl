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
    dockerPull: "mgnify/cwl-assembly-fasta-trimming"
#container needs updating: python 3 biopython and blastn

baseCommand: ['python', 'trim_fasta.py']

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
  ref_dbs:
    type: string
    default: 'human phiX'
    label: space separated list of host blastdbs for contamination
    inputBinding:
        position: 5
        prefix: '--filter_dbs'

outputs:
  original_sequences:
    type: File
    glob: $('contigs.fasta.bak')
  trimmed_sequences:
    type: File
    outputBinding:
      glob: $('contigs.fasta')
  trimmed_sequences_gz:
    type: File
    outputBinding:
      glob: $(inputs.name).fasta.gz
  trimmed_sequences_gz_md5:
    type: File
    outputBinding:
      glob: $(inputs.name).fasta.gz.md5



