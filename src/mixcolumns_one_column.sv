`timescale 1ns/1ps
/*
*******************************************************************************************************
File name   : mixcolumns_one_column.sv
Module name : mixcolumns_one_column

Korean:
- AES MixColumns 연산을 "한 column"에 대해서 수행하는 모듈입니다.
- 입력 col_in은 4개의 byte, 즉 32-bit column입니다.
- AES finite field 연산에서 x2 곱셈은 xtime() 함수로 구현합니다.
- 이 코드는 프로젝트 설명서에 제공된 MixColumns column 연산 구조를 기반으로 합니다.
- 조합논리(combinational logic)이므로 clk/reset이 필요 없습니다.

English:
- This module performs AES MixColumns for one 32-bit column.
- col_in contains four bytes.
- Multiplication by 2 in the AES finite field is implemented by the xtime() function.
- This structure follows the MixColumns one-column code given in the project brief.
- This is combinational logic, so no clock or reset is required.
*******************************************************************************************************
*/

module mixcolumns_one_column (
    input  wire [31:0] col_in,   // Korean: 입력 column = {s0,s1,s2,s3} / English: input column = {s0,s1,s2,s3}
    output wire [31:0] col_out   // Korean: MixColumns 후 column / English: column after MixColumns
);

    wire [7:0] s0;
    wire [7:0] s1;
    wire [7:0] s2;
    wire [7:0] s3;

    wire [7:0] m0;
    wire [7:0] m1;
    wire [7:0] m2;
    wire [7:0] m3;

    /*
    Korean:
    - column의 4개 byte를 분리합니다.
    - col_in[31:24]가 column의 첫 번째 byte입니다.

    English:
    - Split the 32-bit column into four bytes.
    - col_in[31:24] is the first byte of the column.
    */
    assign s0 = col_in[31:24];
    assign s1 = col_in[23:16];
    assign s2 = col_in[15:8];
    assign s3 = col_in[7:0];

    /*
    Korean:
    - AES MixColumns matrix multiplication을 XOR와 xtime()으로 구현한 식입니다.
    - (xtime(x) ^ x)는 AES finite field에서 x3 곱셈과 같습니다.
    - xtime(x)는 x2 곱셈입니다.

    English:
    - These equations implement AES MixColumns matrix multiplication using XOR and xtime().
    - (xtime(x) ^ x) is multiplication by 3 in the AES finite field.
    - xtime(x) is multiplication by 2.
    */
    assign m0 = xtime(s0) ^ (xtime(s1) ^ s1) ^ s2 ^ s3;
    assign m1 = s0 ^ xtime(s1) ^ (xtime(s2) ^ s2) ^ s3;
    assign m2 = s0 ^ s1 ^ xtime(s2) ^ (xtime(s3) ^ s3);
    assign m3 = (xtime(s0) ^ s0) ^ s1 ^ s2 ^ xtime(s3);

    assign col_out = {m0, m1, m2, m3};

    /*
    Korean:
    - xtime 함수는 AES finite field에서 byte에 2를 곱하는 함수입니다.
    - MSB가 1이면 reduction polynomial 때문에 8'h1b를 XOR합니다.
    - MSB가 0이면 그냥 왼쪽으로 1 bit shift합니다.

    English:
    - xtime multiplies a byte by 2 in the AES finite field.
    - If the MSB is 1, XOR with 8'h1b because of the AES reduction polynomial.
    - If the MSB is 0, simply shift left by 1 bit.
    */
    function [7:0] xtime;
        input [7:0] b;
        begin
            if (b[7] == 1'b1)
                xtime = (b << 1) ^ 8'h1b;
            else
                xtime = (b << 1);
        end
    endfunction

endmodule
