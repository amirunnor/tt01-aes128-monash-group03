`timescale 1ns/1ps
/*
*******************************************************************************************************
File name   : aes_core.sv
Module name : aes_core

Korean:
- AES-128 encryption 전체를 순차적으로 실행하는 core module입니다.
- start 신호가 들어오면 plaintext와 key를 받아서 AES-128 encryption을 수행합니다.
- 내부 FSM이 다음 순서로 동작합니다.
  1) Initial AddRoundKey
  2) Main Round 1~9: SubBytes → ShiftRows → MixColumns → AddRoundKey
  3) Final Round 10: SubBytes → ShiftRows → AddRoundKey
  4) ciphertext 출력, done = 1

English:
- This module is the main AES-128 encryption core.
- When start is asserted, it encrypts the input plaintext using the input key.
- The internal FSM executes:
  1) Initial AddRoundKey
  2) Main Rounds 1~9: SubBytes → ShiftRows → MixColumns → AddRoundKey
  3) Final Round 10: SubBytes → ShiftRows → AddRoundKey
  4) Output ciphertext and assert done

Interface:
- reset is active-high.
- start should be pulsed high for at least one clock cycle.
- busy is high while encryption is running.
- done is asserted for one clock cycle when ciphertext becomes valid.
*******************************************************************************************************
*/

module aes_core (
    input  wire         clk,          // Korean: clock / English: clock
    input  wire         reset,        // Korean: active-high reset / English: active-high reset
    input  wire         start,        // Korean: encryption 시작 신호 / English: start encryption signal

    input  wire [127:0] plaintext,    // Korean: 128-bit plaintext 입력 / English: 128-bit plaintext input
    input  wire [127:0] key,          // Korean: 128-bit AES key 입력 / English: 128-bit AES key input

    output reg          busy,         // Korean: 연산 중이면 1 / English: high while the core is running
    output reg          done,         // Korean: 완료되면 1 clock 동안 1 / English: one-clock-cycle done pulse
    output reg  [127:0] ciphertext    // Korean: 128-bit ciphertext 출력 / English: 128-bit ciphertext output
);

    /*
    Korean:
    - FSM state 정의입니다.
    - ST_IDLE  : start 대기
    - ST_ROUND : Round 1~9 수행
    - ST_FINAL : Round 10 수행
    - ST_DONE  : 완료 pulse 처리 후 IDLE로 복귀

    English:
    - FSM state definitions.
    - ST_IDLE  : wait for start
    - ST_ROUND : execute rounds 1 to 9
    - ST_FINAL : execute round 10
    - ST_DONE  : generate done pulse and return to IDLE
    */
    localparam [1:0] ST_IDLE  = 2'd0;
    localparam [1:0] ST_ROUND = 2'd1;
    localparam [1:0] ST_FINAL = 2'd2;
    localparam [1:0] ST_DONE  = 2'd3;

    reg [1:0] fsm_state;

    /*
    Korean:
    - state_reg는 현재 AES state를 저장합니다.
    - key_reg는 현재 round key를 저장합니다.
    - round_counter는 다음에 실행할 round 번호를 저장합니다.
      Round 1~9에서는 aes_round를 사용하고, Round 10에서는 final_round를 사용합니다.

    English:
    - state_reg stores the current AES state.
    - key_reg stores the current round key.
    - round_counter stores the next round number to execute.
      Rounds 1~9 use aes_round, and Round 10 uses final_round.
    */
    reg [127:0] state_reg;
    reg [127:0] key_reg;
    reg [3:0]   round_counter;

    /*
    Korean:
    - Initial AddRoundKey 결과입니다.
    - AES encryption 시작 시 plaintext XOR original key를 수행합니다.

    English:
    - Result of Initial AddRoundKey.
    - At the start of AES encryption, plaintext is XORed with the original key.
    */
    wire [127:0] initial_state;

    addroundkey u_initial_addroundkey (
        .state_in  (plaintext),
        .round_key (key),
        .state_out (initial_state)
    );

    /*
    Korean:
    - key_expansion은 현재 key_reg와 round_counter를 사용하여 다음 round key를 생성합니다.
    - 예: key_reg = RoundKey0, round_counter = 1이면 next_round_key = RoundKey1

    English:
    - key_expansion generates the next round key using key_reg and round_counter.
    - Example: key_reg = RoundKey0 and round_counter = 1 gives next_round_key = RoundKey1.
    */
    wire [127:0] next_round_key;

    key_expansion u_key_expansion (
        .key_in  (key_reg),
        .round   (round_counter),
        .key_out (next_round_key)
    );

    /*
    Korean:
    - Round 1~9에서 사용할 main round datapath입니다.
    - 입력 state_reg와 next_round_key를 사용해서 한 round 결과를 만듭니다.

    English:
    - Main round datapath used for rounds 1 to 9.
    - It uses state_reg and next_round_key to generate one-round output.
    */
    wire [127:0] main_round_state;

    aes_round u_aes_round (
        .state_in  (state_reg),
        .round_key (next_round_key),
        .state_out (main_round_state)
    );

    /*
    Korean:
    - Round 10에서 사용할 final round datapath입니다.
    - Final round에는 MixColumns가 없습니다.

    English:
    - Final round datapath used for round 10.
    - The final round does not include MixColumns.
    */
    wire [127:0] final_round_state;

    final_round u_final_round (
        .state_in  (state_reg),
        .round_key (next_round_key),
        .state_out (final_round_state)
    );

    /*
    Korean:
    - 순차 FSM입니다.
    - 모든 register update는 clock의 rising edge에서 발생합니다.
    - reset이 1이면 모든 상태를 초기화합니다.

    English:
    - Sequential FSM.
    - All registers are updated on the rising edge of clk.
    - If reset is high, all states are initialized.
    */
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            fsm_state     <= ST_IDLE;
            state_reg     <= 128'h00000000000000000000000000000000;
            key_reg       <= 128'h00000000000000000000000000000000;
            round_counter <= 4'd0;
            ciphertext    <= 128'h00000000000000000000000000000000;
            busy          <= 1'b0;
            done          <= 1'b0;
        end
        else begin
            /*
            Korean:
            - 기본적으로 done은 0으로 내립니다.
            - ST_DONE 상태에서만 1 clock 동안 1이 됩니다.

            English:
            - By default, done is cleared.
            - It is asserted for one clock cycle only in ST_DONE.
            */
            done <= 1'b0;

            case (fsm_state)

                /*
                Korean:
                - IDLE 상태에서는 start를 기다립니다.
                - start가 1이면 initial AddRoundKey 결과를 state_reg에 저장합니다.
                - key_reg에는 original key를 저장합니다.
                - 다음 clock부터 Round 1을 수행해야 하므로 round_counter = 1로 설정합니다.

                English:
                - In IDLE, the core waits for start.
                - If start is high, it stores the Initial AddRoundKey result in state_reg.
                - It stores the original key in key_reg.
                - round_counter is set to 1 so that Round 1 runs next.
                */
                ST_IDLE: begin
                    busy <= 1'b0;

                    if (start) begin
                        state_reg     <= initial_state;
                        key_reg       <= key;
                        round_counter <= 4'd1;
                        busy          <= 1'b1;
                        fsm_state     <= ST_ROUND;
                    end
                end

                /*
                Korean:
                - ST_ROUND에서는 Round 1~9를 수행합니다.
                - 매 clock마다 key_expansion으로 다음 round key를 만들고,
                  aes_round로 현재 state를 한 round 진행시킵니다.
                - round_counter가 9이면 main round가 끝났으므로 다음은 final round입니다.

                English:
                - ST_ROUND executes Rounds 1 to 9.
                - On each clock, key_expansion generates the next round key,
                  and aes_round advances the state by one round.
                - If round_counter is 9, the next state is ST_FINAL.
                */
                ST_ROUND: begin
                    state_reg <= main_round_state;
                    key_reg   <= next_round_key;

                    if (round_counter == 4'd9) begin
                        round_counter <= 4'd10;
                        fsm_state     <= ST_FINAL;
                    end
                    else begin
                        round_counter <= round_counter + 4'd1;
                        fsm_state     <= ST_ROUND;
                    end
                end

                /*
                Korean:
                - ST_FINAL에서는 Round 10을 수행합니다.
                - RoundKey10을 생성하고 final_round를 통과시킵니다.
                - 결과를 ciphertext에 저장합니다.
                - 다음 state는 ST_DONE입니다.

                English:
                - ST_FINAL executes Round 10.
                - It generates RoundKey10 and passes the state through final_round.
                - The result is stored in ciphertext.
                - The next state is ST_DONE.
                */
                ST_FINAL: begin
                    state_reg  <= final_round_state;
                    key_reg    <= next_round_key;
                    ciphertext <= final_round_state;
                    fsm_state  <= ST_DONE;
                end

                /*
                Korean:
                - ST_DONE에서는 done을 1 clock 동안 1로 만듭니다.
                - busy를 0으로 내리고 IDLE로 돌아갑니다.

                English:
                - ST_DONE asserts done for one clock cycle.
                - It clears busy and returns to IDLE.
                */
                ST_DONE: begin
                    busy      <= 1'b0;
                    done      <= 1'b1;
                    fsm_state <= ST_IDLE;
                end

                default: begin
                    fsm_state     <= ST_IDLE;
                    state_reg     <= 128'h00000000000000000000000000000000;
                    key_reg       <= 128'h00000000000000000000000000000000;
                    round_counter <= 4'd0;
                    busy          <= 1'b0;
                    done          <= 1'b0;
                end

            endcase
        end
    end

endmodule
