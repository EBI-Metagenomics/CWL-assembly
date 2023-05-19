cwlVersion: v1.2
class: CommandLineTool
label: Preprocessing of fastq files with fastp
doc: |
      Trim low quality reads and adapters from raw fastq file. Option to trim polyA tails for metatranscriptomes

requirements:
  ResourceRequirement:
    coresMin: 4
    ramMin: 5000
  InlineJavascriptRequirement: {}
hints:
  DockerRequirement:
    dockerPull: quay.io/microbiome-informatics/fastp:0.23.1

baseCommand: [ fastp ]

arguments:
  - valueFrom: $(runtime.cores)
    prefix: -w
  - valueFrom: $(inputs.name)_fastp.qc.json
    prefix: --json
  - valueFrom: $(inputs.name)_fastp.qc.html
    prefix: --html
  - valueFrom: |
      ${ var ext = "";
      if (inputs.reads2) { ext = inputs.name + "_fastp_1.fastq.gz"; }
      else { ext = inputs.name + "_fastp.fastq.gz"; }
      return ext; }
    prefix: --out1
  - valueFrom: |
      ${ var ext = "";
      if (inputs.reads2) { ext = inputs.name + "_fastp_2.fastq.gz"; }
      else { ext = null ; }
      return ext; }
    prefix: --out2

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
      glob: |
        ${ var ext = "";
        if (inputs.reads2) { ext = inputs.name + "_fastp_1.fastq.gz"; }
        else { ext = inputs.name + "_fastp.fastq.gz"; }
        return ext; }
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
