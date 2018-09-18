#!/usr/bin/env cwl-runner
class: Workflow
cwlVersion: v1.0

requirements:
  SubworkflowFeatureRequirement: {}
  MultipleInputFeatureRequirement: {}
  InlineJavascriptRequirement: {}
  StepInputExpressionRequirement: {}

inputs:
  forward_reads:
    type: File
  reverse_reads:
    type: File
  min_contig_length:
    type: int
  output_dest:
    type: string
    default: 'stats_report.json'
  output_assembly_name:
    type: string

outputs:
  assembly:
    outputSource: megahit/contigs
    type: File
  assembly_log:
    outputSource: megahit/log
    type: File
  samtools_index:
    outputSource: stats_report/samtools_index_output
    type: File
  coverage_tab:
    outputSource: stats_report/metabat_coverage_output
    type: File
  trimmed_sequences:
    outputSource: fasta_processing/trimmed_sequences
    type: File
  trimmed_sequences_gz:
    outputSource: fasta_processing/trimmed_sequences_gz
    type: File
  trimmed_sequences_gz_md5:
    outputSource: fasta_processing/trimmed_sequences_gz_md5
    type: File
  logfile:
    outputSource: stats_report/logfile
    type: File

steps:
  megahit:
    in:
      forward_reads:
        source: forward_reads
      reverse_reads:
        source: reverse_reads
    out:
      - contigs
      - log
    run: assembly/megahit.cwl
    label: 'megaHit: metagenomics assembler'
  stats_report:
    in:
      assembler:
        valueFrom: $('megahit')
      sequences:
        source: megahit/contigs
      reads:
        source: [forward_reads, reverse_reads]
      output_dest:
        source: output_dest
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
    run: stats/stats.cwl
  fasta_processing:
    in:
      sequences:
        source: megahit/contigs
      min_contig_length:
        source: min_contig_length
      output_filename:
        source: output_assembly_name
      assembler:
        valueFrom: $('megahit')
    out:
      - trimmed_sequences
      - trimmed_sequences_gz
      - trimmed_sequences_gz_md5
    run: stats/fasta-trimming.cwl


$schemas:
  - 'http://edamontology.org/EDAM_1.16.owl'
  - 'https://schema.org/docs/schema_org_rdfa.html'

$namespaces:
  edam: 'http://edamontology.org/'
  iana: 'https://www.iana.org/assignments/media-types/'
  s: 'http://schema.org/'

's:copyrightHolder': EMBL - European Bioinformatics Institute
's:license': 'https://www.apache.org/licenses/LICENSE-2.0'

# export TMP=$PWD/tmp cwltoil --user-space-docker-cmd=udocker --debug --outdir $PWD/out --logFile $PWD/log  --workDir $PWD/tmp_toil --retryCount 0 pipeline.cwl pipeline.yml