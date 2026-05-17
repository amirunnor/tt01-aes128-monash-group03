`timescale 1ns/1ps
/*
*******************************************************************************************************
File name   : aes_top.sv
Module name : aes_top

Korean:
- AES-128 전체 design의 최종 top-level wrapper입니다.
- 외부에서 clk, reset, start, plaintext, key를 입력받고 내부 aes_core에 연결합니다.
- 내부 aes_core가 AES-128 encryption을 수행하고 busy, done, ciphertext를 출력합니다.
- Quartus 최종 top-level entity는 이 aes_top으로 설정하는 것을 권장합니다.

English:
- This is the final top-level wrapper for the AES-128 design.
- It receives clk, reset, start, plaintext, and key from outside and connects them to aes_core.
- The internal aes_core performs AES-128 encryption and outputs busy, done, and ciphertext.
- For final Quartus compilation, it is recommended to set aes_top as the top-level entity.
*******************************************************************************************************
*/

module aes_top (
    input  wire         clk,          // Korean: clock 입력 / English: clock input
    input  wire         reset,        // Korean: active-high reset / English: active-high reset
    input  wire         start,        // Korean: encryption 시작 신호 / English: start signal

    input  wire [127:0] plaintext,    // Korean: 128-bit plaintext / English: 128-bit plaintext
    input  wire [127:0] key,          // Korean: 128-bit AES key / English: 128-bit AES key

    output wire         busy,         // Korean: AES 연산 중이면 1 / English: high while AES is running
    output wire         done,         // Korean: encryption 완료 시 1 clock 동안 1 / English: one-clock done pulse
    output wire [127:0] ciphertext    // Korean: 128-bit ciphertext / English: 128-bit ciphertext
);

    /*
    Korean:
    - aes_top은 실제 AES 계산을 직접 하지 않습니다.
    - 내부 aes_core를 instantiate해서 외부 interface와 연결하는 wrapper 역할입니다.
    - 이 구조를 사용하면 Quartus/Tiny Tapeout에서 최상위 입출력 포트를 명확하게 관리할 수 있습니다.

    English:
    - aes_top does not directly perform AES computation.
    - It instantiates aes_core and connects the external interface to the core.
    - This structure keeps the top-level I/O clean for Quartus and Tiny Tapeout.
    */
    aes_core u_aes_core (
        .clk        (clk),
        .reset      (reset),
        .start      (start),
        .plaintext  (plaintext),
        .key        (key),
        .busy       (busy),
        .done       (done),
        .ciphertext (ciphertext)
    );

endmodule
