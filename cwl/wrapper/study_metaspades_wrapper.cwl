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

steps:
  fetch_ena:
    in:
      study_accession: study_accession
    out:
      - assembly_jobs
    run: ./fetch_ena.cwl

  metaspades_pipeline:
    scatter:
      - forward_reads
      - reverse_reads
    scatterMethod: dotproduct
    in:
      forward_reads:
        source: fetch_ena/assembly_jobs
        valueFrom: $(self.raw_reads[0])
      reverse_reads:
        source: fetch_ena/assembly_jobs
        valueFrom: $(self.raw_reads[1])
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
