`timescale 1ns/1ps
/*
*******************************************************************************************************
File name   : shiftrows.sv
Module name : shiftrows

Korean:
- AES ShiftRows 단계입니다.
- AES state는 4x4 byte matrix로 생각합니다.
- 하지만 Verilog에서는 128-bit vector로 저장하므로 byte 위치를 정확히 재배치해야 합니다.
- 이 모듈은 조합논리(combinational logic)이므로 clk/reset이 필요 없습니다.

English:
- This module implements the AES ShiftRows step.
- The AES state is treated as a 4x4 byte matrix.
- In Verilog, it is stored as a 128-bit vector, so the byte positions must be rearranged carefully.
- This is combinational logic, so no clock or reset is required.

Byte order used in this project:
- state_in[127:120] = byte 0
- state_in[119:112] = byte 1
- ...
- state_in[7:0]     = byte 15

AES fills the matrix column by column:
    [ b0   b4   b8   b12 ]
    [ b1   b5   b9   b13 ]
    [ b2   b6   b10  b14 ]
    [ b3   b7   b11  b15 ]

ShiftRows operation:
- Row 0 shifts left by 0
- Row 1 shifts left by 1
- Row 2 shifts left by 2
- Row 3 shifts left by 3

After ShiftRows:
    [ b0   b4   b8   b12 ]
    [ b5   b9   b13  b1  ]
    [ b10  b14  b2   b6  ]
    [ b15  b3   b7   b11 ]

Then it is converted back to column-major 128-bit order:
    b0, b5, b10, b15, b4, b9, b14, b3, b8, b13, b2, b7, b12, b1, b6, b11
*******************************************************************************************************
*/

module shiftrows (
    input  wire [127:0] state_in,    // Korean: ShiftRows 전 128-bit state / English: 128-bit state before ShiftRows
    output wire [127:0] state_out    // Korean: ShiftRows 후 128-bit state / English: 128-bit state after ShiftRows
);

    /*
    Korean:
    - 먼저 128-bit state를 16개의 byte로 분리합니다.
    - b0가 가장 왼쪽/MSB byte이고, b15가 가장 오른쪽/LSB byte입니다.

    English:
    - First, split the 128-bit state into 16 bytes.
    - b0 is the leftmost/MSB byte, and b15 is the rightmost/LSB byte.
    */
    wire [7:0] b0;
    wire [7:0] b1;
    wire [7:0] b2;
    wire [7:0] b3;
    wire [7:0] b4;
    wire [7:0] b5;
    wire [7:0] b6;
    wire [7:0] b7;
    wire [7:0] b8;
    wire [7:0] b9;
    wire [7:0] b10;
    wire [7:0] b11;
    wire [7:0] b12;
    wire [7:0] b13;
    wire [7:0] b14;
    wire [7:0] b15;

    assign b0  = state_in[127:120];
    assign b1  = state_in[119:112];
    assign b2  = state_in[111:104];
    assign b3  = state_in[103:96];
    assign b4  = state_in[95:88];
    assign b5  = state_in[87:80];
    assign b6  = state_in[79:72];
    assign b7  = state_in[71:64];
    assign b8  = state_in[63:56];
    assign b9  = state_in[55:48];
    assign b10 = state_in[47:40];
    assign b11 = state_in[39:32];
    assign b12 = state_in[31:24];
    assign b13 = state_in[23:16];
    assign b14 = state_in[15:8];
    assign b15 = state_in[7:0];

    /*
    Korean:
    - 아래 assign은 ShiftRows 이후의 byte 순서를 128-bit vector로 다시 묶는 부분입니다.
    - AES는 column-major order를 사용하므로 output 순서는 단순한 row 순서가 아닙니다.

    English:
    - The assignment below packs the shifted bytes back into a 128-bit vector.
    - AES uses column-major order, so the output order is not simple row order.
    */
    assign state_out = {
        b0,  b5,  b10, b15,
        b4,  b9,  b14, b3,
        b8,  b13, b2,  b7,
        b12, b1,  b6,  b11
    };

endmodule
