`timescale 1ns/1ps
/*
*******************************************************************************************************
File name   : subbytes.v
Module name : subbytes

Korean:
- AES SubBytes 단계입니다.
- 128-bit state는 16개의 8-bit byte로 이루어져 있습니다.
- 이 모듈은 sbox.v 모듈을 16개 사용해서 모든 byte를 AES S-box 값으로 치환합니다.
- 조합논리(combinational logic)이므로 clk/reset이 필요 없습니다.

English:
- This module implements the AES SubBytes step.
- A 128-bit AES state consists of sixteen 8-bit bytes.
- This module uses 16 instances of sbox.v to substitute every byte using the AES S-box.
- This is combinational logic, so no clock or reset is required.

Byte order note:
- state_in[127:120] is treated as the first byte.
- state_in[7:0]     is treated as the last byte.
*******************************************************************************************************
*/

module subbytes (
    input  wire [127:0] state_in,    // Korean: SubBytes 전 128-bit state / English: 128-bit state before SubBytes
    output wire [127:0] state_out    // Korean: SubBytes 후 128-bit state / English: 128-bit state after SubBytes
);

    /*
    Korean:
    - 각 byte마다 sbox module 하나를 연결합니다.
    - 예: state_in[127:120]이 첫 번째 byte이고, 그 결과는 state_out[127:120]에 저장됩니다.

    English:
    - One sbox instance is connected for each byte.
    - Example: state_in[127:120] is the first byte, and its result goes to state_out[127:120].
    */

    sbox sbox_00 (.in_byte(state_in[127:120]), .out_byte(state_out[127:120]));
    sbox sbox_01 (.in_byte(state_in[119:112]), .out_byte(state_out[119:112]));
    sbox sbox_02 (.in_byte(state_in[111:104]), .out_byte(state_out[111:104]));
    sbox sbox_03 (.in_byte(state_in[103:96]),  .out_byte(state_out[103:96]));

    sbox sbox_04 (.in_byte(state_in[95:88]),   .out_byte(state_out[95:88]));
    sbox sbox_05 (.in_byte(state_in[87:80]),   .out_byte(state_out[87:80]));
    sbox sbox_06 (.in_byte(state_in[79:72]),   .out_byte(state_out[79:72]));
    sbox sbox_07 (.in_byte(state_in[71:64]),   .out_byte(state_out[71:64]));

    sbox sbox_08 (.in_byte(state_in[63:56]),   .out_byte(state_out[63:56]));
    sbox sbox_09 (.in_byte(state_in[55:48]),   .out_byte(state_out[55:48]));
    sbox sbox_10 (.in_byte(state_in[47:40]),   .out_byte(state_out[47:40]));
    sbox sbox_11 (.in_byte(state_in[39:32]),   .out_byte(state_out[39:32]));

    sbox sbox_12 (.in_byte(state_in[31:24]),   .out_byte(state_out[31:24]));
    sbox sbox_13 (.in_byte(state_in[23:16]),   .out_byte(state_out[23:16]));
    sbox sbox_14 (.in_byte(state_in[15:8]),    .out_byte(state_out[15:8]));
    sbox sbox_15 (.in_byte(state_in[7:0]),     .out_byte(state_out[7:0]));

endmodule
