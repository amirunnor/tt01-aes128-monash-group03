`timescale 1ns/1ps
/*
*******************************************************************************************************
File name   : mixcolumns.sv
Module name : mixcolumns

Korean:
- AES MixColumns 단계입니다.
- 128-bit AES state는 4개의 column으로 구성됩니다.
- 각 column은 32-bit입니다.
- 이 모듈은 mixcolumns_one_column.sv를 4개 사용하여 전체 128-bit state에 MixColumns를 적용합니다.
- 조합논리(combinational logic)이므로 clk/reset이 필요 없습니다.

English:
- This module implements the AES MixColumns step.
- A 128-bit AES state consists of four 32-bit columns.
- This module uses four mixcolumns_one_column instances to apply MixColumns to the full state.
- This is combinational logic, so no clock or reset is required.

Byte/column order used in this project:
- state_in[127:96] = column 0
- state_in[95:64]  = column 1
- state_in[63:32]  = column 2
- state_in[31:0]   = column 3

Example:
- If state_in begins with 12 c9 94 a8, then column 0 is [12 c9 94 a8].
*******************************************************************************************************
*/

module mixcolumns (
    input  wire [127:0] state_in,    // Korean: MixColumns 전 128-bit state / English: 128-bit state before MixColumns
    output wire [127:0] state_out    // Korean: MixColumns 후 128-bit state / English: 128-bit state after MixColumns
);

    /*
    Korean:
    - AES state는 column-major order로 저장되어 있으므로,
      128-bit state를 32-bit column 4개로 나눕니다.

    English:
    - Since the AES state is stored in column-major order,
      the 128-bit state is split into four 32-bit columns.
    */
    wire [31:0] col0_in;
    wire [31:0] col1_in;
    wire [31:0] col2_in;
    wire [31:0] col3_in;

    wire [31:0] col0_out;
    wire [31:0] col1_out;
    wire [31:0] col2_out;
    wire [31:0] col3_out;

    assign col0_in = state_in[127:96];
    assign col1_in = state_in[95:64];
    assign col2_in = state_in[63:32];
    assign col3_in = state_in[31:0];

    /*
    Korean:
    - 각 column마다 같은 MixColumns 연산을 적용합니다.
    - AES MixColumns는 column끼리 섞지 않고, 각 column 내부의 4 byte만 섞습니다.

    English:
    - Apply the same MixColumns operation to each column.
    - AES MixColumns does not mix different columns together; it only mixes the 4 bytes inside each column.
    */
    mixcolumns_one_column u_mix_col0 (
        .col_in  (col0_in),
        .col_out (col0_out)
    );

    mixcolumns_one_column u_mix_col1 (
        .col_in  (col1_in),
        .col_out (col1_out)
    );

    mixcolumns_one_column u_mix_col2 (
        .col_in  (col2_in),
        .col_out (col2_out)
    );

    mixcolumns_one_column u_mix_col3 (
        .col_in  (col3_in),
        .col_out (col3_out)
    );

    /*
    Korean:
    - 4개의 결과 column을 다시 128-bit state로 합칩니다.

    English:
    - Concatenate the four output columns back into a 128-bit state.
    */
    assign state_out = {col0_out, col1_out, col2_out, col3_out};

endmodule
