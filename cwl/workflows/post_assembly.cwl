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

outputs:
  contig_backup:
    type: File
    label: original contigs before qc
    outputSource: fasta_processing/original_sequences
  final_contigs:
    type: File
    label: new contigs.fasta file after qc
    outputSource: fasta_processing/trimmed_sequences
  compressed_contigs:
    type: File
    outputSource: fasta_processing/trimmed_sequences_gz
  compressed_contigs_md5:
    type: File
    outputSource: fasta_processing/trimmed_sequences_gz_md5
  stats_output:
    type: Directory
    outputSource: stats_report/logfile


steps:
  fasta_processing:
    run: tools/assembly-qc/fasta_trimming/fasta-trimming.cwl
    label: remove short contigs, host and phix sequences
    in:
      name: prefix
      contigs: assembly
      min_contig_length: min_contig_length
      assembler: assembler
      ref_dbs:
        default: 'human phiX'
    out: [ original_sequences, trimmed_sequences, trimmed_sequences_gz, trimmed_sequences_gz_md5 ]

  stats_report:
    run: tools/stats/stats.cwl
    label: calculate coverage and output statistics
    in:
      sequences: fasta_processing/trimmed_sequences
      reads: reads
      assembler: assembler
    out: [ logfile ]

# remove this to keep everything in metaspades/001 directory structure
# replace with final structure?
#  write_stats_output:
#    in:
#      stats_log: stats_report/logfile
#      alignment: stats_report/samtools_index_output
#      coverage: stats_report/metabat_coverage_output
#      trimmed_sequence: fasta_processing/trimmed_sequences
#      trimmed_sequence_gz: fasta_processing/trimmed_sequences_gz
#      trimmed_sequence_gz_md5: fasta_processing/trimmed_sequences_gz_md5
#      assembler: assembler
#    out: [folders]
#    run:
#      class: ExpressionTool
#      id: 'organise'
#      inputs:
#        stats_log: File
#        alignment: File
#        coverage: File
#        trimmed_sequence: File
#        trimmed_sequence_gz: File
#        trimmed_sequence_gz_md5: File
#        assembler: string
#      outputs:
#        folders: Directory
#      expression: |
#        ${
#          return {'folders': {
#              'class': 'Directory',
#              'basename': '.',
#              'listing': [
#                inputs.stats_log,
#                inputs.alignment,
#                inputs.coverage,
#                inputs.trimmed_sequence,
#                inputs.trimmed_sequence_gz,
#                inputs.trimmed_sequence_gz_md5
#              ]
#          }};
#        }
