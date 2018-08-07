#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool

requirements:
  DockerRequirement:
    dockerPull: metabat/metabat:latest
  InlineJavascriptRequirement: {}

baseCommand:
- jgi_summarize_bam_contig_depths

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

# Following optiosn require --referenceFasta
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
  output:
    type: File
    outputBinding:
      glob: $(inputs.outputDepth)

doc: |
  Usage: jgi_summarize_bam_contig_depths <options> sortedBam1 [ sortedBam2 ...]
  where options include:
      --outputDepth       arg  The file to put the contig by bam depth matrix (default: STDOUT)
      --percentIdentity   arg  The minimum end-to-end % identity of qualifying reads (default: 97)
      --pairedContigs     arg  The file to output the sparse matrix of contigs which paired reads span (default: none)
      --unmappedFastq     arg  The prefix to output unmapped reads from each bam file suffixed by 'bamfile.bam.fastq.gz'
      --noIntraDepthVariance   Do not include variance from mean depth along the contig
      --showDepth              Output a .depth file per bam for each contig base
      --minMapQual        arg  The minimum mapping quality necessary to count the read as mapped (default: 0)
      --weightMapQual     arg  Weight per-base depth based on the MQ of the read (i.e uniqueness) (default: 0.0 (disabled))
      --includeEdgeBases       When calculating depth & variance, include the 1-readlength edges (off by default)
      --maxEdgeBases           When calculating depth & variance, and not --includeEdgeBases, the maximum length (default:75)
      --referenceFasta    arg  The reference file.  (It must be the same fasta that bams used)

  Options that require a --referenceFasta
      --outputGC          arg  The file to print the gc coverage histogram
      --gcWindow          arg  The sliding window size for GC calculations
      --outputReadStats   arg  The file to print the per read statistics
      --outputKmers       arg  The file to print the perfect kmer counts

  Options to control shredding contigs that are under represented by the reads
      --shredLength       arg  The maximum length of the shreds
      --shredDepth        arg  The depth to generate overlapping shreds
      --minContigLength   arg  The mimimum length of contig to include for mapping and shredding
      --minContigDepth    arg  The minimum depth along contig at which to break the contig


# cwltool --outdir tmp metabat-jgl-summarise.cwl metabat-jgl-summarise.yml