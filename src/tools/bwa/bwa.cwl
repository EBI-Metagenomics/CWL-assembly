cwlVersion: v1.2
class: CommandLineTool
label: Host removal with bwa-mem
doc: |
      Implementation of BWA-mem2 aligner with host sequences and select unmapped reads

requirements:
  InitialWorkDirRequirement:
    listing: [ $(inputs.ref) ]
  ResourceRequirement:
    coresMin: 4
    ramMin: 2000
  InlineJavascriptRequirement: {}
hints:
  DockerRequirement:
    dockerPull: quay.io/microbiome-informatics/bwamem2:2.2.1

baseCommand: [ 'map_host.sh' ]

arguments:
- -t
- $(runtime.cores)
- -o
- $(runtime.outdir)

inputs:
  name:
    type: string
    label: prefix for fastq files
  ref:
    type: File?
    secondaryFiles:
        - '.amb'
        - '.ann'
        - '.pac'
        - '.0123'
        - '.bwt.2bit.64'
    label: host genome fasta file
    inputBinding:
        prefix: -c
        position: 1
  reads1:
    type: File
    format: edam:format_1930  # FASTQ
    label: fastp trimmed forward file
    inputBinding:
      position: 2
      prefix: -f
  reads2:
    type: File?
    format: edam:format_1930  # FASTQ
    label: fastp trimmed reverse file
    inputBinding:
      position: 3
      prefix: -r

outputs:
  outreads1:
    type: File
    format: edam:format_1930
    outputBinding:
      glob: |
        ${ var ext = "";
        if (inputs.reads2) { ext = inputs.name + "_fastp_clean_1.fastq.gz"; }
        else { ext = inputs.name + "_fastp_clean.fastq.gz"; }
        return ext; }
  outreads2:
    type: File?
    format: edam:format_1930
    outputBinding:
      glob: $(inputs.name)_fastp_clean_2.fastq.gz


stdout: bwa_host.log
stderr: bwa_host.err

$namespaces:
 edam: http://edamontology.org/
 s: http://schema.org/
$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/version/latest/schemaorg-current-https.rdf

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder: "EMBL - European Bioinformatics Institute"
