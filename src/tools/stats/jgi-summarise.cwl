cwlVersion: v1.2
class: CommandLineTool
label: "jgi_summarize_bam_contig_depths part of metabat binner summarises coverage depth per contig"

hints:
  DockerRequirement:
    dockerPull: "quay.io/microbiome-informatics/metawrap:latest"
requirements:
  InlineJavascriptRequirement: {}

baseCommand: [ jgi_summarize_bam_contig_depths ]

inputs:
  input:
    type: File
    inputBinding:
      position: 1
    doc: |
      One or more bam files
  outputDepth:
    type: string
    inputBinding:
      prefix: --outputDepth
    doc: |
      The file to put the contig by bam depth matrix (default: STDOUT)
  percentIdentity:
    type: int?
    inputBinding:
      prefix: --percentIdentity
    doc: |
      The minimum end-to-end % identity of qualifying reads (default: 97)
  pairedContigs:
    type: File?
    inputBinding:
      prefix: --pairedContigs
    doc: |
      The file to output the sparse matrix of contigs which paired reads span (default: none)
  unmappedFastq:
    type: string?
    inputBinding:
      prefix: --unmappedFastq
    doc: |
      The prefix to output unmapped reads from each bam file suffixed by 'bamfile.bam.fastq.gz'
  noIntraDepthVariance:
    type: boolean?
    inputBinding:
      prefix: --noIntraDepthVariance
    doc: |
      Do not include variance from mean depth along the contig
  showDepth:
    type: boolean?
    inputBinding:
      prefix: --showDepth
    doc: |
      Output a .depth file per bam for each contig base
  minMapQual:
    type: int?
    inputBinding:
      prefix: --minMapQual
    doc: |
      The minimum mapping quality necessary to count the read as mapped (default: 0)
  weightMapQual:
    type: float?
    inputBinding:
      prefix: --weightMapQual
    doc: |
      Weight per-base depth based on the MQ of the read (i.e uniqueness) (default: 0.0 (disabled))
  includeEdgeBases:
    type: boolean?
    inputBinding:
      prefix: --includeEdgeBases
    doc: |
      When calculating depth & variance, include the 1-readlength edges (off by default)
  maxEdgeBases:
    type: int?
    inputBinding:
      prefix: --maxEdgeBases
    doc: |
      When calculating depth & variance, and not --includeEdgeBases, the maximum length (default:75)

# Following options require --referenceFasta
  outputGC:
    type: File?
    inputBinding:
      prefix: --outputGC
    doc: |
      The file to print the gc coverage histogram
  gcWindow:
    type: int?
    inputBinding:
      prefix: --gcWindow
    doc: |
      The sliding window size for GC calculations
  outputReadStats:
    type: File?
    inputBinding:
      prefix: --outputGC
    doc: |
     The file to print the per read statistics
  outputKmers:
    type: int?
    inputBinding:
      prefix: --gcWindow
    doc: |
      The file to print the perfect kmer counts
# Options to control shredding contigs that are under represented by the reads
  shredLength:
    type: int?
    inputBinding:
      prefix: --shredLength
    doc: |
      The maximum length of the shreds
  shredDepth:
    type: int?
    inputBinding:
      prefix: --shredDepth
    doc: |
      The depth to generate overlapping shreds
  minContigLength:
    type: int?
    inputBinding:
      prefix: --minContigLength
    doc: |
      The mimimum length of contig to include for mapping and shredding
  minContigDepth:
    type: int?
    inputBinding:
      prefix: --minContigDepth
    doc: |
      The minimum depth along contig at which to break the contig

outputs:
  cov_depth:
    type: File
    outputBinding:
      glob: $(inputs.outputDepth)

$namespaces:
 edam: http://edamontology.org/
 s: http://schema.org/
$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/version/latest/schemaorg-current-https.rdf

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder: "EMBL - European Bioinformatics Institute"