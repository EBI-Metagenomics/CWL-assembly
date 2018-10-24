class: Workflow
cwlVersion: v1.0

requirements:
  SubworkflowFeatureRequirement: {}
  MultipleInputFeatureRequirement: {}
  InlineJavascriptRequirement: {}
  StepInputExpressionRequirement: {}
  ScatterFeatureRequirement: {}

inputs:
  study_accession:
    type: string
  lineage:
    type: string
  runs:
    type: string[]?
    inputBinding:
      prefix: --runs
      itemSeparator: ","
      separate: false
  min_contig_length:
    type: int
    default: 500


steps:
  pre_assembly:
    in:
      study_accession:
        source: study_accession
      lineage:
        source: lineage
      runs:
        source: runs
    out:
      - assembly_jobs
      - memory_estimates
    run: pre_assembly.cwl

  metaspades:
    scatter:
      - forward_reads
      - reverse_reads
      - interleaved_reads
      - assembly_memory
    scatterMethod: dotproduct
    in:
      assembly_memory:
        source: pre_assembly/memory_estimates
      forward_reads:
        source: pre_assembly/assembly_jobs
        valueFrom: |
          $(self.raw_reads.length==2 ? self.raw_reads[0] : null)
      reverse_reads:
        source: pre_assembly/assembly_jobs
        valueFrom: |
          $(self.raw_reads.length==2 ? self.raw_reads[1] : null)
      interleaved_reads:
        source: pre_assembly/assembly_jobs
        valueFrom: |
          $(self.raw_reads.length==1 ? self.raw_reads[0] : null)
    out:
      - contigs
      - contigs_assembly_graph
      - assembly_graph
      - contigs_before_rr
      - internal_config
      - internal_dataset
      - log
      - params
      - scaffolds
      - scaffolds_assembly_graph
    run: ../assembly/metaspades.cwl
    label: 'metaSPAdes: de novo metagenomics assembler'

  filter_failed_assemblies:
    in:
      assembly_logs: metaspades/log
      jobs: pre_assembly/assembly_jobs
      assemblies: metaspades/contigs
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
        source: metaspades/contigs
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
      assembly_log: metaspades/log
      assembly_job: pre_assembly/assembly_jobs
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

#  success_check:
#    in:
#      assembly_jobs: pre_assembly/assembly_jobs
#    out: success_file
#    run:
#      class: ExpressionTool
#      id: 'success_check'
#      inputs:
#        assembly_jobs: Any




outputs:
  assembly_dir:
    type: Directory[]
    outputSource: organise/folders
  metaspades_logs:
    type: Directory[]
    outputSource: write_metaspades_logs/folders

#outputs:
#  assembly:
#    type: File[]
#    outputSource: metaspades_pipeline/assembly
#  assembly_log:
#    type: File[]
#    outputSource: metaspades_pipeline/assembly_log
#  memory_estimations:
#    type: int[]
#    outputSource: pre_assembly/memory_estimates
#  logfile:
#    type: File[]
#    outputSource: metaspades_pipeline/logfile

$namespaces:
 edam: http://edamontology.org/
 iana: https://www.iana.org/assignments/media-types/
 s: http://schema.org/

