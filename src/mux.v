/*
 * Cleaned UTF-8 Verilog for AES Multiplexer Units
 */

module mux2_1 (
    input  wire [7:0] in0,
    input  wire [7:0] in1,
    output wire [7:0] out,
    input  wire       sel
);

    assign out = sel ? in0 : in1;

endmodule

module mux4_1 (
    input  wire [7:0] in0,
    input  wire [7:0] in1,
    input  wire [7:0] in2,
    input  wire [7:0] in3,
    output wire [7:0] out,
    input  wire [1:0] sel
);

    reg [7:0] out_reg;
    assign out = out_reg;

    always @(*) begin
        case(sel)
            2'b00:   out_reg = in0;
            2'b01:   out_reg = in1;
            2'b10:   out_reg = in2;
            2'b11:   out_reg = in3;
            default: out_reg = in0;
        endcase
    end

endmodule
