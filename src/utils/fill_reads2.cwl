cwlVersion: v1.2
class: ExpressionTool

requirements:
  InlineJavascriptRequirement: {}

inputs:
  reads2: File[]?
outputs:
  reads2_filled: File[]

expression: |
  ${ if ( inputs.reads2 !== null ) {
      return {"reads2_filled": inputs.reads2};
    } else {
      return {"reads2_filled": Array(2).fill(null)};
    }; }
