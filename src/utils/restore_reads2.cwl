cwlVersion: v1.2
class: ExpressionTool

requirements:
  InlineJavascriptRequirement: {}
  StepInputExpressionRequirement: {}
  ScatterFeatureRequirement: {}
  SubworkflowFeatureRequirement: {}
  MultipleInputFeatureRequirement: {}

inputs:
  reads2: 
    type:
    - "null"
    - type: array
      items: ["null", "File"]

outputs:
  outreads2_final: File[]?

expression: |
  ${ 
    if ( inputs.reads2[0] === null ) {
      return {"outreads2_final": null};
    } else {
      return {"outreads2_final": inputs.reads2};
    }; 
  }

$namespaces:
 edam: http://edamontology.org/
 s: http://schema.org/
$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/version/latest/schemaorg-current-http.rdf
