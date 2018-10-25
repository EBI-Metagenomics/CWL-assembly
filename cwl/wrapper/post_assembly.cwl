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
  study_accession:
    type: string

outputs:
  assembly_dirs:
    type: Directory[]
    outputSource: write_metaspades_logs/folders
  assembly_logfiles:
    type: Directory[]
    outputSource: organise/folders

steps:
  filter_failed_assemblies:
    in:
      assembly_logs: assembly_logs
      jobs: assembly_jobs
      assemblies: assemblies
    out:
      - assemblies
      - jobs
      - assembly_logs
    run:
      class: ExpressionTool
      id: 'organise'
      inputs:
        assembly_logs: File[]
        jobs: Any
        assemblies: File[]
      outputs:
        assemblies: File[]
        jobs: File[]
        assembly_logs: File[]
      expression: |
        ${
          var assemblies = [];
          var jobs = [];
          var logs = [];
          for (var i = 0; i < inputs.assemblies.length; i++){
              var assembly = inputs.assemblies[i];
              if (assembly.size>0){
                assemblies.push(assembly);
                jobs.push(inputs.jobs[i]);
                logs.push(inputs.assembly_logs[i]);
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
        default: metaspades
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
    run: ../stats/stats.cwl

  fasta_processing:
    scatter:
      - sequences
    in:
      sequences:
        source: assemblies
      min_contig_length:
        source: min_contig_length
      assembler:
        default: metaspades
    out:
      - trimmed_sequences
      - trimmed_sequences_gz
      - trimmed_sequences_gz_md5
    run: ../fasta_trimming/fasta-trimming.cwl

  write_metaspades_logs:
    scatter:
      - assembly_log
      - assembly_job
    scatterMethod: dotproduct
    in:
      assembly_log: assembly_logs
      assembly_job: assembly_jobs
      study_accession: study_accession
    out: [folders]
    run:
      class: ExpressionTool
      id: 'metaspades_logs'
      inputs:
        assembly_log: File
        assembly_job: Any
        study_accession: string
      outputs:
        folders: Directory
      expression: |
        ${
          var study_dir = inputs.study_accession.substring(0,7) + '/' + inputs.study_accession + '/' ;
          var run_accession = inputs.assembly_job['run_accession'];
          var assembly_dir = study_dir + run_accession.substring(0,7) + '/' + run_accession + '/metaspades/001/';
          return {'folders': {
              'class': 'Directory',
              'basename': assembly_dir,
              'listing': [
                inputs.assembly_log
              ]
          }};
        }

  organise:
    scatter:
      - assemblies
      - stats_logs
      - run_accessions
      - alignments
      - coverage
      - trimmed_sequences
      - trimmed_sequences_gz
      - trimmed_sequences_gz_md5
    scatterMethod: dotproduct
    in:
      assemblies: filter_failed_assemblies/assemblies
      stats_logs: stats_report/logfile
      alignments: stats_report/samtools_index_output
      coverage: stats_report/metabat_coverage_output
      study_accession: study_accession
      run_accessions:
        source: filter_failed_assemblies/jobs
        valueFrom: |
          ${return self['run_accession']}
      trimmed_sequences: fasta_processing/trimmed_sequences
      trimmed_sequences_gz: fasta_processing/trimmed_sequences_gz
      trimmed_sequences_gz_md5: fasta_processing/trimmed_sequences_gz_md5
    out: [folders]
    run:
      class: ExpressionTool
      id: 'organise'
      inputs:
        assemblies: File
        stats_logs: File
        alignments: File
        coverage: File
        trimmed_sequences: File
        trimmed_sequences_gz: File
        trimmed_sequences_gz_md5: File
        study_accession: string
        run_accessions: string
      outputs:
        folders: Directory
      expression: |
        ${
          var study_dir = inputs.study_accession.substring(0,7) + '/' + inputs.study_accession + '/' ;
          var assembly_dir = study_dir + inputs.run_accessions.substring(0,7) + '/' + inputs.run_accessions + '/metaspades/001/';
          return {'folders': {
              'class': 'Directory',
              'basename': assembly_dir,
              'listing': [
                inputs.assemblies,
                inputs.stats_logs,
                inputs.alignments,
                inputs.coverage,
                inputs.trimmed_sequences,
                inputs.trimmed_sequences_gz,
                inputs.trimmed_sequences_gz_md5
              ]
          }};
        }
