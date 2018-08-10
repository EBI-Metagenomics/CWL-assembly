#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: Workflow

inputs:
  sequences:
    type: File
  reads:
    type: File[]
  output_dest:
    type: string
  min_contig_length:
    type: int
  assembler:
    type: string

outputs:
  bwa_index_output:
    type: File
    outputSource: bwa_index/output
  bwa_mem_output:
    type: File
    outputSource: bwa_mem/output
  samtools_view_output:
    type: File
    outputSource: samtools_view/output
  samtools_sort_output:
    type: File
    outputSource: samtools_sort/sorted
  samtools_index_output:
    type: File
    outputSource: samtools_index/alignments_with_index
  metabat_coverage_output:
    type: File
    outputSource: metabat_jgi/output
  logfile:
    type: File
    outputSource: stats_report/logfile

steps:
  readfq:
    run: ./readfq.cwl
    in:
      raw_reads:
        source: reads
    out:
      - id: base_count
  bwa_index:
    run: ./bwa-index.cwl
    in:
      sequences:
        source: sequences
    out:
      - output

  bwa_mem:
    run: ./bwa-mem.cwl
    in:
      reads:
        source:
          - reads
      reference:
        source: bwa_index/output
    out:
      - output

  samtools_view:
    run: ./samtools-view.cwl
    in:
      input:
        source: bwa_mem/output
      uncompressed:
        default: true
      unselected_output_reads:
        default: true
      output_name:
        default: "unsorted.bam"
    out:
      - output

  samtools_sort:
    run: ./samtools-sort.cwl
    in:
      input:
        source: samtools_view/output
      output_name:
        default: "sorted.bam"
    out:
      - sorted

  samtools_index:
    run: ./samtools-index.cwl
    in:
      alignments:
        source: samtools_sort/sorted
    out:
      - alignments_with_index

  metabat_jgi:
    run: ./metabat-jgi-summarise.cwl
    in:
      input:
        source: samtools_index/alignments_with_index
      outputDepth:
        default: "coverage.tab"
    out:
      - output
  stats_report:
    run: ./stats-report.cwl
    in:
      assembler:
        source: assembler
      sequences:
        source: sequences
      output:
        default: "output.json"
      coverage_file:
        source: metabat_jgi/output
      base_count:
        source: readfq/base_count
      min_contig_length:
        source: min_contig_length
    out:
      - logfile

$namespaces:
 edam: http://edamontology.org/
 s: http://schema.org/

$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/docs/schema_org_rdfa.html

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder: "EMBL - European Bioinformatics Institute"