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
    type: string?
    label: run id to use as prefix for output contigs
  reads1:
    type: File?
    label: zipped fastq file forward or single reads
  reads2:
    type: File?
    label: zipped fastq reverse reads
  multiple_reads_1:
    type: File[]?
    label: list of zipped fastq file forward or single reads
  multiple_reads_2:
    type: File[]?
    label: list of zipped fastq reverse reads
  host_genome:
    type: File?
    secondaryFiles:
        - '.amb'
        - '.ann'
        - '.pac'
        - '.0123'
        - '.bwt.2bit.64'
    format: edam:format_1929
    label: host genome fasta file
    default: 'hg38.fa'
  memory:
    type: [ int?, string? ]
    label: memory for assembly in GB for metaspades and bytes for megahit
  min_contig_length:
    type: int
    label: minimum contig length
    default: 500
  assembler:
    type: string?
    label: metaspades or megahit
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
  coassembly: 
    type: string
    default: 'no'

outputs:
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
    when: $(inputs.coassembly === 'no')
    label: quality control of raw reads
    in:
      coassembly: coassembly
      prefix: prefix
      reads1: reads1
      reads2: reads2
      minLength:
        default: 50
      host_genome: host_genome
    out: [ reads_qc_html, reads_qc_json, qc_reads1, qc_reads2, qc_summary ]

  multiple_reads_quality_control:
    run: metagenome_multiplereads_qc.cwl
    when: $(inputs.coassembly === 'yes')
    label: quality control of raw reads
    in:
      coassembly: coassembly
      reads1: multiple_reads_1
      reads2: multiple_reads_2
      minLength:
        default: 50
      host_genome: host_genome
    out: [ reads_qc_html, reads_qc_json, qc_reads1, qc_reads2, qc_summary ]

  assembly:
    run: assembly.cwl
    when: $(inputs.coassembly === 'no')
    label: assembly with metaspades or megahit. Single always defaults to megahit
    in:
      coassembly: coassembly
      memory: memory
      reads1: quality_control/qc_reads1
      reads2: quality_control/qc_reads2
      assembler: assembler
    out: [ contigs, assembly_log, params_used, assembly_graph, assembler_final ]

  coassembly:
    run: coassembly.cwl
    when: $(inputs.coassembly === 'yes')
    label: assembly with metaspades or megahit. Single always defaults to megahit
    in:
      coassembly: coassembly
      memory: memory
      multiple_reads_1: multiple_reads_quality_control/qc_reads1
      multiple_reads_2: multiple_reads_quality_control/qc_reads2
      assembler: assembler
    out: [ contigs, assembly_log, params_used, assembler_final ]

  post_assembly:
    run: post_assembly.cwl
    when: $(inputs.coassembly === 'no')
    label: run contig filtering, host removal and stats generation
    in:
      prefix: prefix
      assembly: assembly/contigs
      assembler: assembly/assembler_final
      min_contig_length: min_contig_length
      reads:
        source: [reads1, reads2]
        valueFrom: $(self.filter(Boolean))
      assembly_log: assembly/assembly_log
      blastdb_dir: blastdb_dir
      database_flag: database_flag
      coassembly: coassembly
    out: [ final_contigs, compressed_contigs, compressed_contigs_md5, stats_output, coverage_tab]

  post_coassembly:
    run: post_assembly.cwl
    when: $(inputs.coassembly === 'yes')
    label: run contig filtering, host removal and stats generation
    in:
      prefix: prefix 
      assembly: coassembly/contigs      
      assembler: coassembly/assembler_final
      min_contig_length: min_contig_length
      reads: 
        source: [ multiple_reads_1, multiple_reads_2 ]
        linkMerge: merge_flattened
        valueFrom: $(self.filter(Boolean))
      assembly_log: coassembly/assembly_log
      blastdb_dir: blastdb_dir
      database_flag: database_flag
      coassembly: coassembly
      multiple_reads_1: multiple_reads_1
      multiple_reads_2: multiple_reads_2
    out: [ final_contigs, compressed_contigs, compressed_contigs_md5, stats_output]

  reads_folder:
    run: ../utils/return_directory.cwl
    in:
      file_list:
        - quality_control/qc_reads1
        - quality_control/qc_reads2
        - quality_control/qc_summary
#        - multiple_reads_quality_control/qc_reads1
#        - multiple_reads_quality_control/qc_reads2
#        - multiple_reads_quality_control/qc_summary
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
        - post_coassembly/compressed_contigs
        - post_coassembly/compressed_contigs_md5
        - post_coassembly/stats_output
        - coassembly/assembly_log
        - coassembly/params_used
        - assembly/assembly_log
        - assembly/params_used
        - assembly/assembly_graph
      dir_name:
        source: [assembly/assembler_final, coassembly/assembler_final, assembly_version]
        valueFrom: |
                  ${
                      if ( self[0] === null ) {
                        return self[1] + '/' + self[2];
                      } else {
                        return self[0] + '/' + self[2];
                      };
                  }
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
