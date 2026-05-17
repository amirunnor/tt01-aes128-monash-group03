`timescale 1ns/1ps
/*
*******************************************************************************************************
File name   : addroundkey.v
Module name : addroundkey

Korean:
- AES의 AddRoundKey 단계입니다.
- 현재 128-bit state와 128-bit round key를 bitwise XOR 합니다.
- 조합논리(combinational logic)이므로 clk/reset이 필요 없습니다.

English:
- This module implements the AES AddRoundKey step.
- It performs a bitwise XOR between the 128-bit state and the 128-bit round key.
- This is pure combinational logic, so no clock or reset is required.
*******************************************************************************************************
*/

module addroundkey (
    input  wire [127:0] state_in,   // Korean: 현재 AES state 입력 / English: current AES state input
    input  wire [127:0] round_key,  // Korean: 현재 round key 입력 / English: current round key input
    output wire [127:0] state_out   // Korean: XOR 결과 출력 / English: XOR result output
);

    // Korean:
    // AddRoundKey는 AES에서 가장 단순한 단계입니다.
    // 각 bit를 round key와 XOR 합니다.
    //
    // English:
    // AddRoundKey is the simplest AES operation.
    // Each bit of the state is XORed with the corresponding key bit.
    assign state_out = state_in ^ round_key;

endmodule
