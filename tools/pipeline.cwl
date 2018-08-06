class: Workflow
cwlVersion: v1.0
$namespaces:
  edam: 'http://edamontology.org/'
  iana: 'https://www.iana.org/assignments/media-types/'
  s: 'http://schema.org/'
inputs:
  - id: forward_reads
    type: File
  - id: reverse_reads
    type: File
  - id: base_count
    type: int
  - id: output_dest
    type: string
  - id: coverage_report_src
    type: File?
    default: stats/coverage_calculation/coverage_report.py
outputs:
  - id: assembly
    outputSource:
      - metaspades/contigs
    type: File
  - id: assembly_log
    outputSource:
      - metaspades/log
    type: File
  - id: assembly_params
    outputSource:
      - metaspades/params
    type: File
  - id: assembly_scaffolds
    outputSource:
      - metaspades/scaffolds
    type: File
  - id: samtools_index
    outputSource:
      - stats_report/samtools_index_output
    type: File
  - id: coverage_tab
    outputSource:
      - stats_report/metabat_coverage_output
    type: File
  - id: logfile
    outputSource:
      - stats_report/logfile
    type: File
steps:
  - id: metaspades
    in:
      - id: forward_reads
        source: forward_reads
      - id: reverse_reads
        source: reverse_reads
    out:
      - id: assembly_graph
      - id: contigs
      - id: contigs_assembly_graph
      - id: contigs_before_rr
      - id: internal_config
      - id: internal_dataset
      - id: log
      - id: params
      - id: scaffolds
      - id: scaffolds_assembly_graph
    run: assembly/metaspades.cwl
    label: 'metaSPAdes: de novo metagenomics assembler'
  - id: stats_report
    in:
      - id: sequences
        source: metaspades/contigs
      - id: reads
        source:
          - forward_reads
          - reverse_reads
      - id: base_count
        source: base_count
      - id: output_dest
        source: output_dest
      - id: coverage_report_src
        source: coverage_report_src
    out:
      - id: bwa_index_output
      - id: bwa_mem_output
      - id: samtools_view_output
      - id: samtools_sort_output
      - id: samtools_index_output
      - id: metabat_coverage_output
      - id: logfile
    run: stats/coverage.cwl
requirements:
  - class: SubworkflowFeatureRequirement
  - class: MultipleInputFeatureRequirement
$schemas:
  - 'http://edamontology.org/EDAM_1.16.owl'
  - 'https://schema.org/docs/schema_org_rdfa.html'
's:copyrightHolder': EMBL - European Bioinformatics Institute
's:license': 'https://www.apache.org/licenses/LICENSE-2.0'
