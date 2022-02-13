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


outputs:
  assembly_jobs:
    type: Any[]
    outputSource: fetch_ena/assembly_jobs
  memory_estimates:
    type: int[]
    outputSource: predict_mem/memory


steps:
  fetch_ena:
    in:
      study_accession: study_accession
      runs: runs
    out:
      - assembly_jobs
    run: ./ena/fetch_ena.cwl

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
    run: ./mem_prediction/mem_predict.cwl

$namespaces:
 edam: http://edamontology.org/
 iana: https://www.iana.org/assignments/media-types/
 s: http://schema.org/