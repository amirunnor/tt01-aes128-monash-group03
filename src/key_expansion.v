module key_expansion(
    input  wire [7:0] key_in,
    output wire [7:0] rk_delayed_out,
    output wire [7:0] rk_last_out,
    input  wire [3:0] round_cnt,
    input  wire       clk,
    input  wire       input_sel, 
    input  wire       sbox_sel, 
    input  wire       last_out_sel, 
    input  wire       bit_out_sel, 
    input  wire [7:0] rcon_en
);

    reg [7:0] r15, r14, r13, r12, r11, r10, r9, r8, r7, r6, r5, r4, r3, r2, r1, r0, r_redun;
    wire [7:0] rcon_sbox_o, sbox_o, rcon_o, sbox_in, mux_in_o, mux_bit_o, rcon_num;
    
    // Rcon (Round Constant) function for Key Schedule
    function [7:0] rcon;
        input [3:0] x;
        begin
            case (x)
                4'h0: rcon = 8'h01;
                4'h1: rcon = 8'h02;
                4'h2: rcon = 8'h04;
                4'h3: rcon = 8'h08;
                4'h4: rcon = 8'h10;
                4'h5: rcon = 8'h20;
                4'h6: rcon = 8'h40;
                4'h7: rcon = 8'h80;
                4'h8: rcon = 8'h1b;
                4'h9: rcon = 8'h36;
                default: rcon = 8'h01;
            endcase
        end
    endfunction

    assign rcon_num = rcon(round_cnt);
    assign rcon_sbox_o = sbox_o ^ rcon_o;
    assign rcon_o = rcon_en & rcon_num;
    assign rk_delayed_out = r12;

    // Multiplexer instantiations for key scheduling logic
    mux2_1 mux_in (
        .in0(rk_last_out), 
        .in1(key_in), 
        .out(mux_in_o), 
        .sel(input_sel)
    );
    
    mux2_1 mux_sbox (
        .in0(r13), 
        .in1(r_redun), 
        .out(sbox_in), 
        .sel(sbox_sel)
    ); 
    
    mux2_1 mux_bit (
        .in0(r4 ^ rk_last_out), 
        .in1(r4), 
        .out(mux_bit_o), 
        .sel(bit_out_sel)
    ); 
    
    mux2_1 mux_last_out (
        .in0(r0), 
        .in1(r0 ^ rcon_sbox_o), 
        .out(rk_last_out), 
        .sel(last_out_sel)
    );

    // Using positional mapping: (input, output)
    bSbox sbox (sbox_in, sbox_o);

    // Key register shift bank
    always @ (posedge clk) begin
        r15 <= mux_in_o;
        r14 <= r15;
        r13 <= r14;
        r12 <= r13;
        r11 <= r12;
        r10 <= r11;
        r9  <= r10;
        r8  <= r9;
        r7  <= r8;
        r6  <= r7;
        r5  <= r6;
        r4  <= r5;
        r3  <= mux_bit_o;
        r2  <= r3;
        r1  <= r2;
        r0  <= r1;
    end
    
    // Redundant register for RotWord storage
    always @ (posedge clk) begin
        if (rcon_en == 8'hff) begin
            r_redun <= r12;
        end
    end 

endmodule
