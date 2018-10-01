class: Workflow
cwlVersion: v1.0

requirements:
  SubworkflowFeatureRequirement: {}
  MultipleInputFeatureRequirement: {}
  InlineJavascriptRequirement: {}
  StepInputExpressionRequirement: {}

inputs:
  forward_reads:
    type: File?
  reverse_reads:
    type: File?
  interleaved_reads:
    type: File?
  output_dest:
    type: string
    default: 'stats_report.json'
  min_contig_length:
    type: int
  output_assembly_name:
    type: string
  assembly_memory:
    type: int

outputs:
  assembly:
    outputSource: metaspades/contigs
    type: File
  assembly_log:
    outputSource: metaspades/log
    type: File
  assembly_params:
    outputSource: metaspades/params
    type: File
  assembly_scaffolds:
    outputSource: metaspades/scaffolds
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
  metaspades:
    in:
      forward_reads:
        source: forward_reads
      reverse_reads:
        source: reverse_reads
      interleaved_reads:
        source: interleaved_reads
    requirements:
      ResourceRequirement:
        ramMin: $(inputs.assembly_memory*1024)
    out:
      - assembly_graph
      - contigs
      - contigs_assembly_graph
      - contigs_before_rr
      - internal_config
      - internal_dataset
      - log
      - params
      - scaffolds
      - scaffolds_assembly_graph
    run: assembly/metaspades.cwl
    label: 'metaSPAdes: de novo metagenomics assembler'
  stats_report:
    in:
      assembler:
        valueFrom: $('metaspades')
      sequences:
        source: metaspades/contigs
      reads:
        source: [forward_reads, reverse_reads, interleaved_reads]
        valueFrom: $(self.filter(Boolean))
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
        source: metaspades/contigs
      min_contig_length:
        source: min_contig_length
      output_filename:
        source: output_assembly_name
      assembler:
        valueFrom: $('metaspades')
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

# export TMP=$PWD/tmp; cwltoil --user-space-docker-cmd=docker --debug --outdir $PWD/out --logFile $PWD/log  --workDir $PWD/tmp_toil --retryCount 0 cwl/metaspades_pipeline.cwl cwl/metaspades_pipeline.yml