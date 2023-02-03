cwlVersion: v1.2
class: Workflow
label: calculate assembly statistics e.g. coverage and contig lengths

requirements:
  SubworkflowFeatureRequirement: {}
  ScatterFeatureRequirement: {}
  MultipleInputFeatureRequirement: {}
  InlineJavascriptRequirement: {}
  ResourceRequirement:
    coresMin: 8
    ramMin: 8000

inputs:
  sequences:
    type: File
    label: cleaned contig fasta
  reads:
    type: File[]
    label: zipped raw reads fastq forward/reverse or single
  assembler:
    type: string
    label: assembler used metaspades spades or megahit
  assembly_log:
    type: File
    label: logfile from assembly
  run_accession:
    type: string
    label: run accession (ERR/SRR/DRR)
  metatranscriptome:
    type: boolean
    label : is the run metatranscriptomic?
    default: true

outputs:
  logfile:
    type: File
    outputSource: stats_report/logfile
  # The files below are specific to binners required for the following MAG generation workflow.
  metabat_coverage:
    type: File
    outputSource: metabat_jgi/cov_depth
  maxbins_coverage:
    type: File?
    outputSource: maxbins_depth/master_depth
  maxbins_run_depth:
    type: File?
    outputSource: maxbins_depth/run_depth
  concoct_depth:
    type: File?
    outputSource: concoct_depth/concoct_depth
  concoct_bed:
    type: File?
    outputSource: concoct_depth/assembly_bed
  concoct_10k_fasta:
    type: File?
    outputSource: concoct_depth/assembly_10k_fasta

steps:
  base_count:
    run: ../tools/stats/base_count.cwl
    label: get raw read base count
    scatter: raw_reads
    in:
      raw_reads: reads
    out: [ base_counts ] #two counts if paired end
  bwa_index:
    run: ../tools/stats/bwa-index.cwl
    label: index cleaned contigs file
    in:
      sequences: sequences
    out: [ indexed_contigs ]
  bwa_mem:
    run: ../tools/stats/bwa-mem.cwl
    label: map raw reads to indexed contigs
    in:
      reads: reads
      reference:
        source: bwa_index/indexed_contigs
    out: [ alignment ]
  samtools_view:
    run: ../tools/stats/samtools-view.cwl
    in:
      input: bwa_mem/alignment
      uncompressed:
        default: true
      unselected_output_reads:
        default: true
      output_name:
        default: "unsorted.bam"
    out: [ unsorted_bam ]
  samtools_sort:
    run: ../tools/stats/samtools-sort.cwl
    in:
      input: samtools_view/unsorted_bam
      output_name:
        default: "sorted.bam"
    out: [ sorted_bam ]
  metabat_jgi:
    run: ../tools/stats/jgi-summarise.cwl
    in:
      input: samtools_sort/sorted_bam
      outputDepth:
        default: "metabat_depth.txt"
    out: [ cov_depth ]
  maxbins_depth:
    run: ../tools/stats/maxbins-depth.cwl
    when: $(!Boolean(inputs.metatranscriptome))
    in:
      metabat_depth: metabat_jgi/cov_depth
      run_accession: run_accession
    out: [ master_depth, run_depth ]
  concoct_depth:
    run: ../tools/stats/concoct-depth.cwl
    when: $(!Boolean(inputs.metatranscriptome))
    in:
      bam: samtools_sort/sorted_bam
      contigs: sequences
    out: [ concoct_depth, assembly_bed, assembly_10k_fasta ]
  stats_report:
    run: ../tools/stats/stats-report.cwl
    in:
      assembler: assembler
      sequences: sequences
      output:
        default: "assembly_stats.json"
      coverage_file: metabat_jgi/cov_depth
      base_count: base_count/base_counts
      assembly_log: assembly_log
    out: [ logfile ]

$namespaces:
 edam: http://edamontology.org/
 s: http://schema.org/

$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/docs/schema_org_rdfa.html

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder: "EMBL - European Bioinformatics Institute"