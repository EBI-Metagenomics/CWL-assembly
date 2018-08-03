#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: Workflow

inputs:
  - id: sequences
    type: File
  - id: reads
    type: File[]

outputs:
  - id: bwa_index
    type: File
    outputSource: bwa_index/output
  - id: bwa_mem
    type: File
    outputSource: bwa_mem/output
  - id: samtools_view
    type: File
    outputSource: samtools_view/output
  - id: samtools_sort
    type: File
    outputSource: samtools_sort/sorted
  - id: samtools_index
    type: File
    outputSource: samtools_index/index

steps:
  - id: bwa_index
    run: ./bwa-index.cwl
    in:
      - id: sequences
        source: sequences
    out:
      - id: output

  - id: bwa_mem
    run: ./bwa-mem.cwl
    in:
      - id: reads
        source:
          - reads
      - id: reference
        source: bwa_index/output
    out:
      - id: output

  - id: samtools_view
    run: ./samtools-view.cwl
    in:
      - id: input
        source: bwa_mem/output
      - id: uncompressed
        default: true
      - id: unselected_output_reads
        default: true
      - id: output_name
        default: "unsorted.bam"
    out:
      - id: output

  - id: samtools_sort
    run: ./samtools-sort.cwl
    in:
      - id: input
        source: samtools_view/output
      - id: output_name
        default: "sorted.bam"
    out:
      - id: sorted

  - id: samtools_index
    run: ./samtools-index.cwl
    in:
      - id: input
        source: samtools_sort/sorted
    out:
      - id: index
#
#  - id: metabat_jgi
#    run: ./metabat-jgi-summarise.cwl
#    in:
#      - id: input
#        source: samtools_index/index
#      - id: outputDepth
#        default: "coverage.tab"
#    out:
#      - id: output







# TODO finish samtools index
# TODO finish metabat coverage depth
# TODO write a nice UI for output?
$namespaces:
 edam: http://edamontology.org/
 s: http://schema.org/

$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/docs/schema_org_rdfa.html

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder: "EMBL - European Bioinformatics Institute"