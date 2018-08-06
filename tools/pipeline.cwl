class: Workflow
cwlVersion: v1.0
$namespaces:
  edam: 'http://edamontology.org/'
  iana: 'https://www.iana.org/assignments/media-types/'
  s: 'http://schema.org/'

inputs:
  forward_reads:
    type: File
  reverse_reads:
    type: File
  base_count:
    type: int
  output_dest:
    type: string
  coverage_report_src:
    type: File
    default:
      - class: File
        path: stats/coverage_calculation/coverage_report.py

outputs:
  assembly:
    outputSource: metaspades/contigs
    type: File
  assembly_log:
    outputSource: metaspades/log
    type: File
  assembly_params:
    outputSource: metaspades/params
    type: File
  assembly_scaffolds:
    outputSource: metaspades/scaffolds
    type: File
  samtools_index:
    outputSource: stats_report/samtools_index_output
    type: File
  coverage_tab:
    outputSource: stats_report/metabat_coverage_output
    type: File
  logfile:
    outputSource: stats_report/logfile
    type: File

steps:
  metaspades:
    in:
      forward_reads:
        source: forward_reads
      reverse_reads:
        source: reverse_reads
    out:
      - assembly_graph
      - contigs
      - contigs_assembly_graph
      - contigs_before_rr
      - internal_config
      - internal_dataset
      - log
      - params
      - scaffolds
      - scaffolds_assembly_graph
    run: assembly/metaspades.cwl
    label: 'metaSPAdes: de novo metagenomics assembler'
  stats_report:
    in:
      sequences:
        source: metaspades/contigs
      reads:
        source: [forward_reads, reverse_reads]
      base_count:
        source: base_count
      output_dest:
        source: output_dest
      coverage_report_src:
        source: coverage_report_src
    out:
      - bwa_index_output
      - bwa_mem_output
      - samtools_view_output
      - samtools_sort_output
      - samtools_index_output
      - metabat_coverage_output
      - logfile
    run: stats/coverage.cwl

requirements:
  - class: SubworkflowFeatureRequirement
  - class: MultipleInputFeatureRequirement
$schemas:
  - 'http://edamontology.org/EDAM_1.16.owl'
  - 'https://schema.org/docs/schema_org_rdfa.html'
's:copyrightHolder': EMBL - European Bioinformatics Institute
's:license': 'https://www.apache.org/licenses/LICENSE-2.0'
