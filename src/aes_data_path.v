/*
 * Cleaned UTF-8 Verilog for AES Data Path
 * Ensure this file is saved as aes_data_path.v
 */

module aes_data_path (
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

    // Instantiations
    // Ensure these module names (byte_permutation, ps_conv, etc.) 
    // match the filenames in your src folder exactly.
    byte_permutation SR (
        .in(sr_in), 
        .out(sr_out), 
        .c3(c3), 
        .clk(clk)
    );

    ps_conv PS (
        .d_in(d_in), 
        .s_out(s_out), 
        .pdin(pdin), 
        .pld(pld), 
        .clk(clk)
    );

    mixcolumn_8 MC (
        .sbox_o(sbox_o), 
        .mc_en(mc_en), 
        .mc_out0(mc_out0), 
        .mc_out1(mc_out1), 
        .mc_out2(mc_out2), 
        .mc_out3(mc_out3), 
        .clk(clk)
    );

    bSbox SB (
        .in(sr_out), 
        .out(sbox_o)
    );

endmodule
