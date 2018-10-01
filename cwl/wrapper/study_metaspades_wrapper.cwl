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

steps:
  fetch_ena:
    in:
      study_accession: study_accession
    out:
      - assembly_jobs
    run: ./fetch_ena.cwl

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
            self.raw_reads.forEach(f => {
              ret += 0
            });
            return ret;
           }
    out:
      - memory
    run: ../mem_prediction/mem_predict.cwl

  metaspades_pipeline:
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

      min_contig_length:
        default: 500
      output_assembly_name:
        source: study_accession
    out:
      - assembly
      - assembly_log
    run: ../metaspades_pipeline.cwl


outputs:
  assembly:
    type: File[]
    outputSource: metaspades_pipeline/assembly
  assembly_log:
    type: File[]
    outputSource: metaspades_pipeline/assembly_log
  memory_estimationes:
    type: int[]
    outputSource: predict_mem/memory

