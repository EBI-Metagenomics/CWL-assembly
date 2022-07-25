cwlVersion: v1.2
class: Workflow
label: metagenome quality control, assembly and post processing

requirements:
  SubworkflowFeatureRequirement: {}
  MultipleInputFeatureRequirement: {}
  InlineJavascriptRequirement: {}
  StepInputExpressionRequirement: {}

inputs:
  prefix:
    type: string
    label: run id to use as prefix for output contigs
  reads1:
    type: File
    label: zipped fastq file forward or single reads
  reads2:
    type: File?
    label: zipped fastq reverse reads
  host_genome:
    type: File?
    secondaryFiles:
        - '.amb'
        - '.ann'
        - '.bwt'
        - '.pac'
        - '.sa'
        - '.0123'
        - '.bwt.2bit.64'
    format: edam:format_1929
    label: host genome fasta file
    default: 'hg38.fa'
  memory:
    type: int
    label: memory for assembly in GB
    default: 150
  min_contig_length:
    type: int
    label: minimum contig length
    default: 500
  assembler:
    type: string
    label: assembler metaspades - spades used a defualt for single or megahit
    default: 'metaspades'
  assembly_version:
    type: string
    label: directory name for output e.g. 001 for first assembly of run 002 for second etc
  blastdb_dir:
    type: Directory
  database_flag:
    type: string[]
  raw_dir_name:
    type: string?
    default: 'raw'
  assembly_dir_name:
    type: string?
    default: $(inputs.assembler)/$(inputs.assembly_version)

outputs:
#  cleaned_reads1:
#    type: File
#    label: cleaned reads forward or single
#    outputSource: quality_control/qc_reads1
#  cleaned_reads2:
#    type: File?
#    label: cleaned reads reverse
#    outputSource: quality_control/qc_reads2
#  qc_summary:
#    type: File
#    label: read qc summary
#    outputSource: quality_control/qc_summary
#  assembly_log:
#    type: File
#    label: log file from assembler
#    outputSource: assembly/assembly_log
#  assembly_params:
#    type: File
#    label: params from assembler
#    outputSource: assembly/params_used
#  assembly_graph:
#    type: File?
#    label: assembly graph if metaspades used
#    outputSource: assembly/assembly_graph
#  assembly_contigs:
#    type: File
#    label: original contig file from assembler
#    outputSource: post_assembly/contig_backup
#  cleaned_contigs:
#    type: File
#    label: contig file after qc
#    outputSource: post_assembly/final_contigs
#  compressed_contigs:
#    type: File
#    label: compressed contig file after qc renamed with prefix
#    outputSource: post_assembly/compressed_contigs
#  compressed_contigs_md5:
#    type: File
#    label: md5 for compressed contig file after qc renamed with prefix
#    outputSource: post_assembly/compressed_contigs_md5
#  assembly_stats:
#    type: File
#    label: coverage and general statistics of assembly required for ENA upload
#    outputSource: post_assembly/stats_output
   reads_folder:
     type: Directory
     label: folder with cleaned reads and qc summary
     outputSource: reads_folder/out
   assembly_folder:
     type: Directory
     label: folder with assembly and stats data
     outputSource: assembly_folder/out

steps:
  quality_control:
    run: metagenome_qc.cwl
    label: quality control of raw reads
    in:
      prefix: prefix
      reads1: reads1
      reads2: reads2
      minLength:
        default: 50
      host_genome: host_genome
    out: [ reads_qc_html, reads_qc_json, qc_reads1, qc_reads2, qc_summary ]

  assembly:
    run: assembly.cwl
    label: assembly with metaspades (spaded for single) or megahit
    in:
      memory: memory
      reads1: quality_control/qc_reads1
      reads2: quality_control/qc_reads2
      min_length: min_contig_length
      assembler: assembler
    out: [ contigs, assembly_log, params_used, assembly_graph ]

  post_assembly:
    run: post_assembly.cwl
    label: run contig filtering, host removel and stats generation
    in:
      prefix: prefix
      assembly: assembly/contigs
      assembler: assembler
      min_contig_length: min_contig_length
      reads:
        source: [reads1, reads2]
        valueFrom: $(self.filter(Boolean))
      assembly_log: assembly/assembly_log
      blastdb_dir: blastdb_dir
      database_flag: database_flag
    out: [ final_contigs, compressed_contigs, compressed_contigs_md5, stats_output, coverage_tab]

  reads_folder:
    run: ../utils/return_directory.cwl
    in:
      file_list:
        - quality_control/qc_reads1
        - quality_control/qc_reads2
        - quality_control/qc_summary
      dir_name: raw_dir_name
    out: [ out ]

  assembly_folder:
    run: ../utils/return_directory.cwl
    in:
      file_list:
        - post_assembly/compressed_contigs
        - post_assembly/compressed_contigs_md5
        - post_assembly/stats_output
        - post_assembly/coverage_tab
        - assembly/assembly_log
        - assembly/params_used
        - assembly/assembly_graph
      dir_name: assembly_dir_name
    out: [ out ]

$schemas:
  - 'http://edamontology.org/EDAM_1.16.owl'
  - 'https://schema.org/docs/schema_org_rdfa.html'

$namespaces:
  edam: 'http://edamontology.org/'
  iana: 'https://www.iana.org/assignments/media-types/'
  s: 'http://schema.org/'

's:copyrightHolder': EMBL - European Bioinformatics Institute
's:license': 'https://www.apache.org/licenses/LICENSE-2.0'