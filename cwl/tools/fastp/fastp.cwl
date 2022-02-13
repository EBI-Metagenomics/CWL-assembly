cwlVersion: v1.2
class: CommandLineTool
label: Reporting and preprocessing of Fastq files with fastp.
doc: |
      Implementation of paired-end Fastq preprocessing and quality reporting with fastp.

requirements:
  ResourceRequirement:
    coresMin: 32
    ramMin: 8000
hints:
  DockerRequirement:
    dockerPull: microbiomeinformatics/fastp:v0.20.1

baseCommand: [ fastp ]

arguments:
- -w
- $(runtime.cores)
- --out1
- $(inputs.name)_fastp_1.fastq.gz
- --out2
- $(inputs.name)_fastp_2.fastq.gz
- --json
- $(inputs.name)_fastp.qc.json
- --html
- $(inputs.name)_fastp.qc.html

inputs:
  name:
    type: string
    label: prefix for fasta file
  reads1:
    type: File
    format: edam:format_1930  # FASTQ
    label: forward fastq file
    inputBinding:
      position: 1
      prefix: --in1
  reads2:
    type: File?
    format: edam:format_1930  # FASTQ
    label: reverse fastq file
    inputBinding:
      position: 2
      prefix: --in2
  minLength:
    type: int?
    default: 50
    label: filter reads shorter than this value
    inputBinding:
      position: 3
      prefix: -l
  polya_trim:
    type: int?
    label: additional polyA tail trimming to metatranscriptomes
    inputBinding:
      position: 4
      prefix: '--trim_poly_x --poly_x_min_len'

outputs:
  outreads1:
    type: File
    format: edam:format_1930
    outputBinding:
      glob: $(inputs.name)_fastp_1.fastq.gz
  outreads2:
    type: File?
    format: edam:format_1930
    outputBinding:
      glob: $(inputs.name)_fastp_2.fastq.gz
  qcjson:
    type: File
    outputBinding:
      glob: $(inputs.name)_fastp.qc.json
  qchtml:
    type: File
    outputBinding:
      glob: $(inputs.name)_fastp.qc.html

stdout: fastp.log
stderr: fastp.err

$namespaces:
 edam: http://edamontology.org/
 s: http://schema.org/
$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/version/latest/schemaorg-current-https.rdf

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder: "EMBL - European Bioinformatics Institute"
