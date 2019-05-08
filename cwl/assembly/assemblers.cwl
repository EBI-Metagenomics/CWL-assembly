## TODO write forking between assemblers if
#
#
#
#class: Workflow
#cwlVersion: v1.0
#
#requirements:
#  MultipleInputFeatureRequirement: {}
#  InlineJavascriptRequirement: {}
#  StepInputExpressionRequirement: {}
#  ScatterFeatureRequirement: {}
#
#inputs:
#  assembly_jobs:
#    type: Any[]
#  memory_estimates:
#    type: int[]
#  assembler:
#    type: string
#
#outputs:
#  assemblies:
#    type: File[]
#    outputSource: collect_outputs/assemblies
#  logs:
#    type: File[]
#    outputSource: collect_outputs/logs
#steps:
#  metaspades:
#    scatter:
#      - forward_reads
#      - reverse_reads
#      - interleaved_reads
#      - assembly_memory
#    scatterMethod: dotproduct
#    in:
#      assembler: assembler
#      assembly_memory:
#        source: memory_estimates
#        valueFrom: |
#          $(inputs.assembler === 'metaspades' ? self : null)
#      forward_reads:
#        source: assembly_jobs
#        valueFrom: |
#          $(inputs.assembler === 'metaspades' && self.raw_reads.length==2 ? self.raw_reads[0] : null)
#      reverse_reads:
#        source: assembly_jobs
#        valueFrom: |
#          $(inputs.assembler === 'metaspades' && self.raw_reads.length==2 ? self.raw_reads[1] : null)
#      interleaved_reads:
#        source: assembly_jobs
#        valueFrom: |
#          $(inputs.assembler === 'metaspades' && self.raw_reads.length==1 ? self.raw_reads[0] : null)
#    out:
#      - contigs
#      - log
#    run: ../assembly/metaspades.cwl
#
#  megahit:
#    scatter:
#      - forward_reads
#      - reverse_reads
#      - interleaved_reads
#      - assembly_memory
#    scatterMethod: dotproduct
#    in:
#      assembler: assembler
#      assembly_memory:
#        source: memory_estimates
#        valueFrom: |
#          $(inputs.assembler === 'megahit' ? self : null)
#      forward_reads:
#        source: assembly_jobs
#        valueFrom: |
#          $(inputs.assembler === 'megahit' && self.raw_reads.length==2 ? self.raw_reads[0] : null)
#      reverse_reads:
#        source: assembly_jobs
#        valueFrom: |
#          $(inputs.assembler === 'megahit' && self.raw_reads.length==2 ? self.raw_reads[1] : null)
#      interleaved_reads:
#        source: assembly_jobs
#        valueFrom: |
#          $(inputs.assembler === 'megahit' && self.raw_reads.length==1 ? self.raw_reads[0] : null)
#    out:
#      - contigs
#      - log
#    run: ../assembly/megahit.cwl
#
#  collect_outputs:
#    in:
#      assemblies:
#        - metaspades/contigs
#        - megahit/contigs
#      logs:
#        - metaspades/log
#        - megahit/log
#    out:
#      - assemblies
#      - logs
#    run:
#      class: ExpressionTool
#      id: 'organise'
#      inputs:
#        assemblies: Any[]
#        logs: Any[]
#      outputs:
#        assemblies: File[]
#        logs: File[]
#      expression: |
#        ${
#          return {
#            'assemblies': inputs.assemblies,
#            'logs': inputs.logs
#          }
#        }
#
#
#
