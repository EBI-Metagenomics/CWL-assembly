#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool

requirements:
  DockerRequirement:
    dockerPull: quay.io/biocontainers/samtools:1.9--h46bd0b3_0
  InitialWorkDirRequirement:
    listing: [ $(inputs.alignments) ]

baseCommand: [samtools, index, -b]


inputs:
  alignments:
    type: File
    inputBinding:
      position: 2
      valueFrom: $(self.basename)
    label: Input bam file.

outputs:
  alignments_with_index:
    type: File
    secondaryFiles: .bai
    outputBinding:
      glob: $(inputs.alignments.basename)


    doc: The index file


$namespaces:
  s: http://schema.org/

$schemas:
- http://schema.org/docs/schema_org_rdfa.html


s:downloadUrl: https://github.com/common-workflow-language/workflows/blob/master/tools/samtools-index.cwl
s:codeRepository: https://github.com/common-workflow-language/workflows
s:license: http://www.apache.org/licenses/LICENSE-2.0

s:author:
  class: s:Person
  s:name: Andrey Kartashov
  s:email: mailto:Andrey.Kartashov@cchmc.org
  s:sameAs:
  - id: http://orcid.org/0000-0001-9102-5681
  s:worksFor:
  - class: s:Organization
    s:name: Cincinnati Children's Hospital Medical Center
    s:location: 3333 Burnet Ave, Cincinnati, OH 45229-3026
    s:department:
    - class: s:Organization
      s:name: Barski Lab
doc: |
  samtools-index.cwl is developed for CWL consortium

