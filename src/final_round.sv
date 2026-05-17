`timescale 1ns/1ps
/*
*******************************************************************************************************
File name   : final_round.sv
Module name : final_round

Korean:
- AES final round, 즉 Round 10에서 사용하는 datapath module입니다.
- AES-128의 final round는 main round와 다르게 MixColumns를 수행하지 않습니다.
- final round 순서는 아래와 같습니다.
  1) SubBytes
  2) ShiftRows
  3) AddRoundKey
- 이 모듈은 조합논리(combinational logic)입니다.
- clock/reset은 여기서 사용하지 않고, 나중에 aes_core.sv의 FSM이 final round 실행 시점을 제어합니다.

English:
- This module implements the AES final round datapath, used for Round 10.
- Unlike the main rounds, the AES-128 final round does not perform MixColumns.
- The final round sequence is:
  1) SubBytes
  2) ShiftRows
  3) AddRoundKey
- This module is combinational logic.
- Clock/reset are not used here. Later, aes_core.sv FSM will control when the final round is executed.
*******************************************************************************************************
*/

module final_round (
    input  wire [127:0] state_in,    // Korean: final round 시작 전 state / English: state before final round
    input  wire [127:0] round_key,   // Korean: RoundKey10 입력 / English: RoundKey10 input
    output wire [127:0] state_out    // Korean: 최종 ciphertext / English: final ciphertext
);

    /*
    Korean:
    - final round에서는 MixColumns가 없으므로 중간 wire는 두 개만 필요합니다.
    - state_in → SubBytes → ShiftRows → AddRoundKey → state_out

    English:
    - Since the final round does not include MixColumns, only two intermediate wires are needed.
    - state_in → SubBytes → ShiftRows → AddRoundKey → state_out
    */
    wire [127:0] subbytes_out;
    wire [127:0] shiftrows_out;

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
    - AES state matrix의 row들을 왼쪽으로 순환 shift합니다.

    English:
    - Step 2: ShiftRows
    - Cyclically shift the rows of the AES state matrix to the left.
    */
    shiftrows u_shiftrows (
        .state_in  (subbytes_out),
        .state_out (shiftrows_out)
    );

    /*
    Korean:
    - 3단계: AddRoundKey
    - ShiftRows 결과와 final round key, 즉 RoundKey10을 XOR합니다.
    - 이 결과가 최종 ciphertext입니다.

    English:
    - Step 3: AddRoundKey
    - XOR the ShiftRows result with the final round key, RoundKey10.
    - The result is the final ciphertext.
    */
    addroundkey u_addroundkey (
        .state_in  (shiftrows_out),
        .round_key (round_key),
        .state_out (state_out)
    );

endmodule
