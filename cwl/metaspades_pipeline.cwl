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
  assembler:
    type: string
    default: "metaspades"


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

  post_assembly:
    in:
      assembly_logs: metaspades/log
      assembly_jobs: pre_assembly/assembly_jobs
      assemblies: metaspades/contigs
      assembler:
        valueFrom: $('metaspades')
      min_contig_length: min_contig_length
      study_accession: study_accession
    out:
      - assembly_outputs
      - stats_outputs
    run: ./post_assembly.cwl

outputs:
  assembly_outputs:
    type: Directory[]
    outputSource: post_assembly/assembly_outputs
  stats_outputs:
    type: Directory[]
    outputSource: post_assembly/stats_outputs

$namespaces:
 edam: http://edamontology.org/
 iana: https://www.iana.org/assignments/media-types/
 s: http://schema.org/

