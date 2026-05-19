/*
 * Cleaned UTF-8 Verilog for Parallel-to-Serial Converter
 */

module ps_conv (
    input  wire [7:0]  din,
    output wire [7:0]  dout, 
    input  wire [31:0] pdin, // highest byte goes out first
    input  wire        pld,  // 1: parallel load, 0: serial unload
    input  wire        clk
);

    reg [7:0] reg3, reg2, reg1, reg0;
    wire [7:0] mux1_o, mux2_o, mux3_o;

    // Multiplexers to switch between loading parallel data and shifting serial data
    // Matches the mux2_1(in0, in1, out, sel) signature
    mux2_1 mux0 (
        .in0(pdin[31:24]), 
        .in1(reg0), 
        .out(dout), 
        .sel(pld)
    );
    
    mux2_1 mux1 (
        .in0(pdin[23:16]), 
        .in1(reg1), 
        .out(mux1_o), 
        .sel(pld)
    );
    
    mux2_1 mux2 (
        .in0(pdin[15:8]), 
        .in1(reg2), 
        .out(mux2_o), 
        .sel(pld)
    );
    
    mux2_1 mux3 (
        .in0(pdin[7:0]), 
        .in1(reg3), 
        .out(mux3_o), 
        .sel(pld)
    );

    // Shift register bank
    always @ (posedge clk) begin
        reg3 <= din;
        reg2 <= mux3_o;
        reg1 <= mux2_o;
        reg0 <= mux1_o;
    end

endmodule
