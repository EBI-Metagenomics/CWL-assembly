#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

label: "metaSPAdes: de novo metagenomics assembler"

hints:
  SoftwareRequirement:
    packages:
      spades:
        specs: [ "https://identifiers.org/rrid/RRID:SCR_000131" ]
        version: [ "3.12.0" ]

requirements:
  DockerRequirement:
    dockerPull: "quay.io/biocontainers/spades:3.12.0--1"
  InlineJavascriptRequirement: {}

baseCommand: [ metaspades.py ]

arguments:
  - valueFrom: $(runtime.outdir)
    prefix: -o
#  - valueFrom: $(runtime.tmpdir)
#    prefix: --tmp-dir
  - valueFrom: $(5000)
    prefix: --memory
  - valueFrom: $(runtime.cores)
    prefix: --threads

inputs:
  forward_reads:
    type: File
    inputBinding:
      prefix: "-1"

  reverse_reads:
    type: File
    inputBinding:
      prefix: "-2"

stdout: stdout.txt
stderr: stderr.txt

outputs:
  stdout: stdout
  stderr: stderr
  contigs:
    type: File
    format: edam:format_1929  # FASTA
    outputBinding:
      glob: contigs.fasta

  scaffolds:
    type: File
    format: edam:format_1929  # FASTA
    outputBinding:
      glob: scaffolds.fasta

  #everything:
  #  type: Directory
  #  outputBinding:
  #    glob: .

  assembly_graph:
    type: File
    #format: edam:format_TBD  # FASTG
    outputBinding:
      glob: assembly_graph.fastg

  contigs_assembly_graph:
    type: File
    outputBinding:
      glob: contigs.paths

  scaffolds_assembly_graph:
    type: File
    outputBinding:
      glob: scaffolds.paths

  contigs_before_rr:
    label: contigs before repeat resolution
    type: File
    format: edam:format_1929  # FASTA
    outputBinding:
      glob: before_rr.fasta

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

  internal_config:
    label: internal configuration file
    type: File
    # format: text/plain
    outputBinding:
      glob: dataset.info

  internal_dataset:
    label: internal YAML data set file
    type: File
    outputBinding:
      glob: input_dataset.yaml

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder: "EMBL - European Bioinformatics Institute"

$namespaces:
 edam: http://edamontology.org/
 iana: https://www.iana.org/assignments/media-types/
 s: http://schema.org/
$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/docs/schema_org_rdfa.html

doc: |
  https://arxiv.org/abs/1604.03071
  http://cab.spbu.ru/files/release3.12.0/manual.html#meta
