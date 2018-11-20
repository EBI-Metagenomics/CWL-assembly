class: Workflow
cwlVersion: v1.0

requirements:
  SubworkflowFeatureRequirement: {}
  MultipleInputFeatureRequirement: {}
  InlineJavascriptRequirement: {}
  StepInputExpressionRequirement: {}
  ScatterFeatureRequirement: {}

inputs:
  assembly_logs:
    type: File[]
  assembly_jobs:
    type: Any[]
  assemblies:
    type: File[]
  assembler:
    type: string
  min_contig_length:
    type: int
    default: 500

outputs:
  assembly_outputs:
    type: Directory[]
    outputSource: write_assemblies/folders
  stats_outputs:
    type: Directory[]
    outputSource: write_stats_output/folders

steps:
  filter_failed_assemblies:
    in:
      assembly_logs_in: assembly_logs
      jobs_in: assembly_jobs
      assemblies_in: assemblies
    out:
      - assemblies
      - jobs
      - assembly_logs
    run:
      class: ExpressionTool
      id: 'organise'
      inputs:
        assembly_logs_in: File[]
        jobs_in: Any
        assemblies_in: File[]
      outputs:
        assemblies: File[]
        jobs: File[]
        assembly_logs: File[]
      expression: |
        ${
          var assemblies = [];
          var jobs = [];
          var logs = [];
          for (var i = 0; i < inputs.assemblies_in.length; i++){
              var assembly = inputs.assemblies_in[i];
              if (assembly.size>0){
                assemblies.push(assembly);
                jobs.push(inputs.jobs_in[i]);
                logs.push(inputs.assembly_logs_in[i]);
              }
          }
          return {'assemblies': assemblies, 'jobs': jobs, 'assembly_logs': logs};
        }

  stats_report:
    scatter:
      - sequences
      - reads
    scatterMethod: dotproduct
    in:
      assembler:
        source: assembler
      sequences:
        source: filter_failed_assemblies/assemblies
      reads:
        source: filter_failed_assemblies/jobs
        valueFrom: $(self.raw_reads)
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
    scatter:
      - sequences
    in:
      sequences:
        source: assemblies
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
    scatter:
      - assembly_log
      - assembly_job
      - assembly
    scatterMethod: dotproduct
    in:
      assembly_log: assembly_logs
      assembly_job: assembly_jobs
      assembly: assemblies
      assembler: assembler
    out: [folders]
    run:
      class: ExpressionTool
      id: 'metaspades_logs'
      inputs:
        assembly_log: File
        assembly_job: Any
        assembly: File
        assembler: string
      outputs:
        folders: Directory
      expression: |
        ${
          var study_accession = inputs.assembly_job['secondary_study_accession'];
          var study_dir = study_accession.substring(0,7) + '/' + study_accession + '/' ;
          var run_accession = inputs.assembly_job['run_accession'];
          var assembly_dir = study_dir + run_accession.substring(0,7) + '/' + run_accession + '/' + inputs.assembler + '/001/';
          return {'folders': {
              'class': 'Directory',
              'basename': assembly_dir,
              'listing': [
                inputs.assembly_log,
                inputs.assembly
              ]
          }};
        }

  write_stats_output:
    scatter:
      - stats_log
      - study_accession
      - run_accession
      - alignment
      - coverage
      - trimmed_sequence
      - trimmed_sequence_gz
      - trimmed_sequence_gz_md5
    scatterMethod: dotproduct
    in:
      stats_log: stats_report/logfile
      alignment: stats_report/samtools_index_output
      coverage: stats_report/metabat_coverage_output
      study_accession:
        source: filter_failed_assemblies/jobs
        valueFrom: |
          ${return self['secondary_study_accession']}
      run_accession:
        source: filter_failed_assemblies/jobs
        valueFrom: |
          ${return self['run_accession']}
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
        study_accession: string
        run_accession: string
        assembler: string
      outputs:
        folders: Directory
      expression: |
        ${
          var study_dir = inputs.study_accession.substring(0,7) + '/' + inputs.study_accession + '/' ;
          var assembly_dir = study_dir + inputs.run_accession.substring(0,7) + '/' + inputs.run_accession + '/' + inputs.assembler + '/001/';
          return {'folders': {
              'class': 'Directory',
              'basename': assembly_dir,
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
