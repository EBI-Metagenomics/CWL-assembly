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

outputs:
  logfile:
    type: File
    outputSource: stats_report/logfile

steps:
  base_count:
    run: ../tools/stats/base_count.cwl
    label: get raw read base count
    scatter: reads
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
  samtools_index:
    run: ../tools/stats/samtools-index.cwl
    in:
      alignments: samtools_sort/sorted_bam
    out: [ alignments_with_index ]
  metabat_jgi:
    run: ../tools/stats/metabat-jgi-summarise.cwl
    in:
      input: samtools_index/alignments_with_index
      outputDepth:
        default: "coverage.tab"
    out: [ cov_depth ]
  stats_report:
    run: ../tools/stats/stats-report.cwl
    in:
      assembler: assembler
      sequences: sequences
      output:
        default: "assembly_stats.json"
      coverage_file: metabat_jgi/cov_depth
      base_count: base_count/base_counts
    out: [ logfile ]

$namespaces:
 edam: http://edamontology.org/
 s: http://schema.org/

$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/docs/schema_org_rdfa.html

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder: "EMBL - European Bioinformatics Institute"