cwlVersion: v1.2
class: ExpressionTool

requirements:
  InlineJavascriptRequirement: {}

inputs:
  assembler: string?
outputs:
  assembler_out: string

expression: |
  ${ if ( inputs.assembler !== null ) {
      return {"assembler_out": inputs.assembler};
    } else {
      return {"assembler_out": "megahit"};
    }; }
