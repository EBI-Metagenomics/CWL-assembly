cwlVersion: v1.2
class: CommandLineTool
label: "metaSPAdes: de novo metagenomics assembler"

requirements:
  ResourceRequirement:
    coresMin: 8
    ramMin: 420000
hints:
  DockerRequirement:
    dockerPull: quay.io/microbiome-informatics/spades:3.15.3

requirements:
  InlineJavascriptRequirement: {}

baseCommand: [ metaspades.py ]

arguments:
  - valueFrom: $(runtime.outdir)
    prefix: -o
  - valueFrom: $(runtime.tmpdir)
    prefix: --tmp-dir
  - valueFrom: $(runtime.cores)
    prefix: -t
  - --only-assembler

inputs:
  memory:
    type: int?
    label: memory to run assembly
    inputBinding:
        prefix: -m
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
  # Add step to check empty
  contigs:
    type: File
    format: edam:format_1929  # FASTA
    outputBinding:
      glob: contigs.fasta

  # Scaffolds can be missing if assembly produces no contigs
#  scaffolds:
#    type: File?
#    format: edam:format_1929  # FASTA
#    outputBinding:
#      glob: scaffolds.fasta

  assembly_graph:
    type: File
    #format: edam:format_TBD  # FASTG
    outputBinding:
      glob: assembly_graph.fastg

  # Contig paths can be missing if assembly produces no contigs
#  contigs_assembly_graph:
#    type: File?
#    outputBinding:
#      glob: contigs.paths

  # Scaffolds paths can be missing if assembly produces no contigs
#  scaffolds_assembly_graph:
#    type: File?
#    outputBinding:
#      glob: scaffolds.paths

#  contigs_before_rr:
#    label: contigs before repeat resolution
#    type: File
#    format: edam:format_1929  # FASTA
#    outputBinding:
#      glob: before_rr.fasta

  params:
    label: information about SPAdes parameters in this run
    type: File
    format: iana:text/plain
    outputBinding:
      glob: params.txt

  log:
    label: MetaSP log
    type: File
    format: iana:text/plain
    outputBinding:
      glob: spades.log

#  internal_config:
#    label: internal configuration file
#    type: File
#    # format: text/plain
#    outputBinding:
#      glob: dataset.info

#  internal_dataset:
#    label: internal YAML data set file
#    type: File
#    outputBinding:
#      glob: run_spades.yaml

$namespaces:
 edam: http://edamontology.org/
 s: http://schema.org/
$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/version/latest/schemaorg-current-https.rdf

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder: "EMBL - European Bioinformatics Institute"

doc: |
  https://arxiv.org/abs/1604.03071
  http://cab.spbu.ru/files/release3.12.0/manual.html#meta
