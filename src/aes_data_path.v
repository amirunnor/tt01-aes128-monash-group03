module aes_data_path(
    input  wire [7:0] d_in,
    output wire [7:0] d_out,
    input  wire       pld,
    input  wire [1:0] c3,
    input  wire       clk,
    input  wire [7:0] mc_en,
    input  wire [7:0] rk_delayed_out,
    input  wire [7:0] rk_last_out
);

    wire [7:0] sr_in, sr_out, s_out, mc_out0, mc_out1, mc_out2, mc_out3, sbox_o;
    wire [31:0] pdin;

    assign pdin  = {mc_out0, mc_out1, mc_out2, mc_out3};
    assign sr_in = rk_delayed_out ^ s_out;
    assign d_out = sbox_o ^ rk_last_out;

    // SR: byte_permutation (din, dout, c3, clk)
    byte_permutation SR (sr_in, sr_out, c3, clk);

    // PS: ps_conv (din, dout, pdin, pld, clk)
    ps_conv PS (d_in, s_out, pdin, pld, clk);

    // MC: mixcolumn_8 (din, en, dout0, dout1, dout2, dout3, clk)
    mixcolumn_8 MC (sbox_o, mc_en, mc_out0, mc_out1, mc_out2, mc_out3, clk);

    // SB: bSbox (A, Q)
    bSbox SB (sr_out, sbox_o);

endmodule
