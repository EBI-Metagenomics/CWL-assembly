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
  coassembly:
    type: string

outputs:
  logfile:
    type: File
    outputSource: stats_report/logfile
  coverage_tab:
    type: File
    outputSource: metabat_jgi/cov_depth

steps:
  base_count:
    run: ../tools/stats/base_count.cwl
    label: get raw read base count
    scatter: raw_reads
    in:
      raw_reads: 
        source: reads
        valueFrom: $(self.filter(Boolean))
    out: [ base_counts ] #two counts if paired end
  bwa_index:
    run: ../tools/stats/bwa-index.cwl
    when: $(inputs.coassembly == 'no')
    label: index cleaned contigs file
    in:
      coassembly: coassembly
      sequences: sequences
    out: [ indexed_contigs ]
  bwa_mem:
    run: ../tools/stats/bwa-mem.cwl
    when: $(inputs.coassembly == 'no')
    label: map raw reads to indexed contigs
    in:
      coassembly: coassembly
      reads: reads
      reference:
        source: bwa_index/indexed_contigs
    out: [ alignment ]
  samtools_view:
    run: ../tools/stats/samtools-view.cwl
    when: $(inputs.coassembly == 'no')
    in:
      coassembly: coassembly
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
    when: $(inputs.coassembly == 'no')
    in:
      coassembly: coassembly
      input: samtools_view/unsorted_bam
      output_name:
        default: "sorted.bam"
    out: [ sorted_bam ]
  metabat_jgi:
    run: ../tools/stats/metabat-jgi-summarise.cwl
    when: $(inputs.coassembly == 'no')
    in:
      coassembly: coassembly
      input: samtools_sort/sorted_bam
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
