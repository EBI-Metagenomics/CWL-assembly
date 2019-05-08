class: Workflow
cwlVersion: v1.0

requirements:
  SubworkflowFeatureRequirement: {}
  MultipleInputFeatureRequirement: {}
  InlineJavascriptRequirement: {}
  StepInputExpressionRequirement: {}
  ScatterFeatureRequirement: {}

inputs:
  assembly_log:
    type: File
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
  assembly_output:
    type: Directory
    outputSource: write_assemblies/folders
  stats_output:
    type: Directory
    outputSource: write_stats_output/folders

steps:
  stats_report:
    in:
      assembler:
        source: assembler
      sequences:
        source: assembly
      reads:
        source: reads
      min_contig_length:
        source: min_contig_length
    out:
      - bwa_index_output
      - bwa_mem_output
      - samtools_view_output
      - samtools_sort_output
      - samtools_index_output
      - metabat_coverage_output
      - logfile
    run: ./stats/stats.cwl

  fasta_processing:
    in:
      sequences:
        source: assembly
      min_contig_length:
        source: min_contig_length
      assembler:
        source: assembler
    out:
      - trimmed_sequences
      - trimmed_sequences_gz
      - trimmed_sequences_gz_md5
    run: ./fasta_trimming/fasta-trimming.cwl

  write_assemblies:
    in:
      assembly_log: assembly_log
      assembly: assembly
      assembler: assembler
    out: [folders]
    run:
      class: ExpressionTool
      id: 'metaspades_logs'
      inputs:
        assembly_log: File
        assembly: File
        assembler: string
      outputs:
        folders: Directory
      expression: |
        ${
          return {'folders': {
              'class': 'Directory',
              'basename': '.',
              'listing': [
                inputs.assembly_log,
                inputs.assembly
              ]
          }};
        }

  write_stats_output:
    in:
      stats_log: stats_report/logfile
      alignment: stats_report/samtools_index_output
      coverage: stats_report/metabat_coverage_output
      trimmed_sequence: fasta_processing/trimmed_sequences
      trimmed_sequence_gz: fasta_processing/trimmed_sequences_gz
      trimmed_sequence_gz_md5: fasta_processing/trimmed_sequences_gz_md5
      assembler: assembler
    out: [folders]
    run:
      class: ExpressionTool
      id: 'organise'
      inputs:
        stats_log: File
        alignment: File
        coverage: File
        trimmed_sequence: File
        trimmed_sequence_gz: File
        trimmed_sequence_gz_md5: File
        assembler: string
      outputs:
        folders: Directory
      expression: |
        ${
          return {'folders': {
              'class': 'Directory',
              'basename': '.',
              'listing': [
                inputs.stats_log,
                inputs.alignment,
                inputs.coverage,
                inputs.trimmed_sequence,
                inputs.trimmed_sequence_gz,
                inputs.trimmed_sequence_gz_md5
              ]
          }};
        }
