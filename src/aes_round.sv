`timescale 1ns/1ps
/*
*******************************************************************************************************
File name   : aes_round.sv
Module name : aes_round

Korean:
- AES main round 1~9에서 사용하는 round datapath module입니다.
- 한 round는 아래 순서로 진행됩니다.
  1) SubBytes
  2) ShiftRows
  3) MixColumns
  4) AddRoundKey
- 이 모듈은 조합논리(combinational logic)입니다.
- clock/reset은 여기서 사용하지 않고, 나중에 aes_core.sv의 FSM이 round 진행을 제어합니다.

English:
- This module implements the AES main round datapath used for rounds 1 to 9.
- One main round performs:
  1) SubBytes
  2) ShiftRows
  3) MixColumns
  4) AddRoundKey
- This module is combinational logic.
- Clock/reset are not used here. Later, aes_core.sv FSM will control the round sequence.

Important:
- This module is NOT used for final round 10, because AES final round does not include MixColumns.
*******************************************************************************************************
*/

module aes_round (
    input  wire [127:0] state_in,    // Korean: round 시작 전 state / English: state before this AES round
    input  wire [127:0] round_key,   // Korean: 현재 round에서 사용할 round key / English: round key used in this round
    output wire [127:0] state_out    // Korean: round 완료 후 state / English: state after this AES round
);

    /*
    Korean:
    - 각 AES operation 사이의 중간 wire입니다.
    - state_in → SubBytes → ShiftRows → MixColumns → AddRoundKey → state_out

    English:
    - Intermediate wires between AES operations.
    - state_in → SubBytes → ShiftRows → MixColumns → AddRoundKey → state_out
    */
    wire [127:0] subbytes_out;
    wire [127:0] shiftrows_out;
    wire [127:0] mixcolumns_out;

    /*
    Korean:
    - 1단계: SubBytes
    - 128-bit state 안의 16개 byte를 각각 S-box로 치환합니다.

    English:
    - Step 1: SubBytes
    - Substitute all 16 bytes in the 128-bit state using the AES S-box.
    */
    subbytes u_subbytes (
        .state_in  (state_in),
        .state_out (subbytes_out)
    );

    /*
    Korean:
    - 2단계: ShiftRows
    - 4x4 AES state matrix에서 row 단위로 byte 위치를 이동합니다.

    English:
    - Step 2: ShiftRows
    - Shift byte positions row-by-row in the 4x4 AES state matrix.
    */
    shiftrows u_shiftrows (
        .state_in  (subbytes_out),
        .state_out (shiftrows_out)
    );

    /*
    Korean:
    - 3단계: MixColumns
    - 각 32-bit column 내부의 4개 byte를 finite field arithmetic으로 섞습니다.

    English:
    - Step 3: MixColumns
    - Mix the 4 bytes inside each 32-bit column using finite-field arithmetic.
    */
    mixcolumns u_mixcolumns (
        .state_in  (shiftrows_out),
        .state_out (mixcolumns_out)
    );

    /*
    Korean:
    - 4단계: AddRoundKey
    - MixColumns 결과와 현재 round key를 XOR합니다.

    English:
    - Step 4: AddRoundKey
    - XOR the MixColumns result with the current round key.
    */
    addroundkey u_addroundkey (
        .state_in  (mixcolumns_out),
        .round_key (round_key),
        .state_out (state_out)
    );

endmodule
