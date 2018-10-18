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
    type: string[]
  min_contig_length:
    type: int?
    default: 500

steps:
  fetch_ena:
    in:
      study_accession: study_accession
      runs: runs
    out:
      - assembly_jobs
    run: ../ena/fetch_ena.cwl

  predict_mem:
    scatter:
      - read_count
      - base_count
      - lib_layout
      - lib_strategy
      - lib_source
      - compressed_data_size
    scatterMethod: dotproduct
    in:
      lineage:
        source: lineage
      read_count:
        source: fetch_ena/assembly_jobs
        valueFrom: $(self.read_count)
      base_count:
        source: fetch_ena/assembly_jobs
        valueFrom: $(self.base_count)
      lib_layout:
        source: fetch_ena/assembly_jobs
        valueFrom: $(self.library_layout)
      lib_strategy:
        source: fetch_ena/assembly_jobs
        valueFrom: $(self.library_strategy)
      lib_source:
        source: fetch_ena/assembly_jobs
        valueFrom: $(self.library_source)
      assembler:
        default: 'metaspades'
      compressed_data_size:
        source: fetch_ena/assembly_jobs
        valueFrom: |
          ${var ret = 0;
            self.raw_reads.forEach(function(f){
              ret += f['size']
            });
            return ret;
           }
    out:
      - memory
    run: ../mem_prediction/mem_predict.cwl

  metaspades:
    scatter:
      - forward_reads
      - reverse_reads
      - interleaved_reads
      - assembly_memory
    scatterMethod: dotproduct
    in:
      assembly_memory:
        source: predict_mem/memory
      forward_reads:
        source: fetch_ena/assembly_jobs
        valueFrom: |
          $(self.raw_reads.length==2 ? self.raw_reads[0] : null)
      reverse_reads:
        source: fetch_ena/assembly_jobs
        valueFrom: |
          $(self.raw_reads.length==2 ? self.raw_reads[1] : null)
      interleaved_reads:
        source: fetch_ena/assembly_jobs
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
      assemblies: metaspades/contigs
      assembly_logs: metaspades/log
      jobs: fetch_ena/assembly_jobs
    out:
      - assemblies
      - jobs
      - assembly_logs
    run:
      class: ExpressionTool
      id: 'organise'
      inputs:
        assemblies: File[]
        jobs: Any
        assembly_logs: File[]
      outputs:
        assemblies: File[]
        jobs: File[]
        assembly_logs: File[]
      expression: |
        ${
          var succ_assemblies = [];
          var jobs = [];
          var logs = [];
          for (var i = 0; i < inputs.assemblies.length; i++){
              var assembly = inputs.assemblies[i];
              if (assembly.size>0){
                succ_assemblies.append(assembly);
                jobs.append(inputs.jobs[i]);
                logs.append(inputs.assembly_logs[i]);
              }
          }
          return {'assemblies': succ_assemblies, 'jobs': jobs, 'assembly_logs': logs};
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


  organise:
    scatter:
      - assemblies
      - assembly_logs
      - logfiles
      - run_accessions
    scatterMethod: dotproduct
    in:
      assemblies: filter_failed_assemblies/assemblies
      assembly_logs: filter_failed_assemblies/assembly_logs
      logfiles: stats_report/logfile
      study_accession: study_accession
      run_accessions:
        source: filter_failed_assemblies/jobs
        valueFrom: |
          ${return self['run_accession']}
    out: [folders]
    run:
      class: ExpressionTool
      id: 'organise'
      inputs:
        study_accession: string
        assemblies: File
        assembly_logs: File
        logfiles: File
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
                inputs.assembly_logs,
                inputs.logfiles
              ]
          }};
        }

outputs:
  assembly_dir:
    type: Directory[]
    outputSource: organise/folders

#outputs:
#  assembly:
#    type: File[]
#    outputSource: metaspades_pipeline/assembly
#  assembly_log:
#    type: File[]
#    outputSource: metaspades_pipeline/assembly_log
#  memory_estimations:
#    type: int[]
#    outputSource: predict_mem/memory
#  logfile:
#    type: File[]
#    outputSource: metaspades_pipeline/logfile

