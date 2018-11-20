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
    type: string?
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
    default: "megahit"


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
    run: ./pre_assembly.cwl

  megahit:
    scatter:
      - forward_reads
      - reverse_reads
      - interleaved_reads
      - single_reads
      - assembly_memory
    scatterMethod: dotproduct
    in:
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
          $(self.raw_reads.length==1 && self.library_layout=='PAIRED' ? self.raw_reads[0] : null)
      single_reads:
        source: pre_assembly/assembly_jobs
        valueFrom: |
          $(self.raw_reads.length==1 && self.library_layout=='SINGLE' ? self.raw_reads[0] : null)
      assembly_memory:
        source: pre_assembly/memory_estimates
    out:
      - contigs
      - log
    run: assembly/megahit.cwl
    label: 'megaHit: metagenomics assembler'

#  metaspades:
#    scatter:
#      - forward_reads
#      - reverse_reads
#      - interleaved_reads
#      - assembly_memory
#    scatterMethod: dotproduct
#    in:
#      assembly_memory:
#        source: pre_assembly/memory_estimates
#      forward_reads:
#        source: pre_assembly/assembly_jobs
#        valueFrom: |
#          $(self.raw_reads.length==2 ? self.raw_reads[0] : null)
#      reverse_reads:
#        source: pre_assembly/assembly_jobs
#        valueFrom: |
#          $(self.raw_reads.length==2 ? self.raw_reads[1] : null)
#      interleaved_reads:
#        source: pre_assembly/assembly_jobs
#        valueFrom: |
#          $(self.raw_reads.length==1 ? self.raw_reads[0] : null)
#    out:
#      - contigs
#      - contigs_assembly_graph
#      - assembly_graph
#      - contigs_before_rr
#      - internal_config
#      - internal_dataset
#      - log
#      - params
#      - scaffolds
#      - scaffolds_assembly_graph
#    run: assembly/metaspades.cwl
#    label: 'metaSPAdes: de novo metagenomics assembler'

  post_assembly:
    in:
      assembly_logs: megahit/log
      assembly_jobs: pre_assembly/assembly_jobs
      assemblies: megahit/contigs
      assembler:
        valueFrom: $('megahit')
      min_contig_length: min_contig_length
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

