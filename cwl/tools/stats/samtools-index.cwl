cwlVersion: v1.2
class: CommandLineTool
label: Index sorted bam file
doc: |
  samtools-index.cwl is developed for CWL consortium

requirements:
  ResourceRequirement:
    coresMin: 32
    ramMin: 8000
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing: [ $(inputs.alignments) ]
hints:
  DockerRequirement:
    dockerPull: quay.io/microbiome-informatics/bwamem2:2.2.1


baseCommand: [ 'samtools', 'index', '-b']

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
    outputBinding:
      glob: $(inputs.alignments.basename)
    label: The indexed file


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

