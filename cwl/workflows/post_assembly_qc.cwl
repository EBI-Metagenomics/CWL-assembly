cwlVersion: v1.2
class: Workflow
label: Filter short contigs and reads matching host/contaminant genomes

requirements:
  SubworkflowFeatureRequirement: {}
  MultipleInputFeatureRequirement: {}
  InlineJavascriptRequirement: {}
  StepInputExpressionRequirement: {}
  ScatterFeatureRequirement: {}

inputs:
  query_seq:
    type: File
  blastdb_dir:
    type: Directory
  database_flag:
    type: string[]
  prefix:
    type: string
  assembler:
    type: string
  min_contig_length:
    type: int
    default: 500

outputs:
  final_contigs:
    type: File
    label: new contigs file after qc unzipped
    outputSource: filter_sequences/filtered_contigs_unzipped
  compressed_contigs:
    type: File
    outputSource: filter_sequences/trimmed_sequences_gz
  compressed_contigs_md5:
    type: File
    outputSource: filter_sequences/trimmed_sequences_gz_md5

steps:
  blast:
    run: ../tools/assembly-qc/blast.cwl
    label: blastn contigs against host or contaminant databases
    scatter: database_flag
    in:
      query_seq: query_seq
      blastdb_dir: blastdb_dir
      database_flag: database_flag
    out: [ alignment ]

  concatenate_blast:
    run: ../utils/cat.cwl
    label: concatenate blast outputs from multiple hosts
    in:
      files: blast/alignment
    out: [ result ]

  filter_sequences:
    run: ../tools/assembly-qc/fasta-trimming.cwl
    label: remove contigs <500 bp and filter out blast matches
    in:
      name: prefix
      contigs: query_seq
      assembler: assembler
      blastn: concatenate_blast/result
    out: [ trimmed_sequences_gz, trimmed_sequences_gz_md5, filtered_contigs_unzipped ]

