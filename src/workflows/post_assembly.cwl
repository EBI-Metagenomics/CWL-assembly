cwlVersion: v1.2
class: Workflow
label: postprocessing assembly contig file and generate statistics

requirements:
  SubworkflowFeatureRequirement: {}
  MultipleInputFeatureRequirement: {}
  InlineJavascriptRequirement: {}
  StepInputExpressionRequirement: {}
  ScatterFeatureRequirement: {}

inputs:
  prefix:
    type: string
  assembly:
    type: File
  assembler:
    type: string
  min_contig_length:
    type: int
    default: 500
  reads:
    type: File[]
  assembly_log:
    type: File
    label: logfile from assembly
  blastdb_dir:
    type: Directory
  database_flag:
    type: string[]
  coassembly:
    type: string

outputs:
  final_contigs:
    type: File
    label: new contigs.fasta file after qc
    outputSource: fasta_processing/final_contigs
  compressed_contigs:
    type: File
    outputSource: fasta_processing/compressed_contigs
  compressed_contigs_md5:
    type: File
    outputSource: fasta_processing/compressed_contigs_md5
  stats_output:
    type: File
    outputSource: stats_report/logfile
  coverage_tab:
    type: File
    outputSource: stats_report/coverage_tab

steps:
  fasta_processing:
    run: post_assembly_qc.cwl
    label: remove short contigs, host and phix sequences
    in:
      query_seq: assembly
      blastdb_dir: blastdb_dir
      database_flag: database_flag
      prefix: prefix
      min_contig_length: min_contig_length
      assembler: assembler
    out: [ final_contigs, compressed_contigs, compressed_contigs_md5 ]

  stats_report:
    run: stats.cwl
    label: calculate coverage and output statistics
    in:
      sequences: fasta_processing/final_contigs
      reads: reads
      assembler: assembler
      assembly_log: assembly_log
      coassembly: coassembly
    out: [ logfile , coverage_tab]

