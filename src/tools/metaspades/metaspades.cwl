cwlVersion: v1.2
class: CommandLineTool
label: "metaSPAdes: de novo metagenomics assembler"

requirements:
  ResourceRequirement:
    coresMin: 8
    ramMin: $(inputs.memory)
  InlineJavascriptRequirement: {}

baseCommand: [ metaspades.py ]

arguments:
  - valueFrom: $(runtime.outdir)
    prefix: -o
  - valueFrom: '8'
    prefix: -t
  - --only-assembler

inputs:
  memory:
    type: int
    default: 150
    label: memory in gb
    inputBinding:
      prefix: -m
      position: 4
  forward_reads:
    type: File
    format: edam:format_1930  # FASTQ
    label: forward file after qc
    inputBinding:
      prefix: "-1"
  reverse_reads:
    type: File
    format: edam:format_1930  # FASTQ
    label: reverse file after qc
    inputBinding:
      prefix: "-2"

outputs:
  contigs:
    type: File
    format: edam:format_1929  # FASTA
    outputBinding:
      glob: contigs.fasta

  assembly_graph:
    type: File
    format: edam:format_3823 # fastg
    outputBinding:
      glob: assembly_graph.fastg

  params:
    label: information about SPAdes parameters in this run
    type: File
    format: iana:text/plain
    outputBinding:
      glob: params.txt

  log:
    label: spades log file
    type: File
    format: iana:text/plain
    outputBinding:
      glob: spades.log

$namespaces:
 edam: http://edamontology.org/
 s: http://schema.org/
$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/version/latest/schemaorg-current-https.rdf

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder: "EMBL - European Bioinformatics Institute"
