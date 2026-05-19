module byte_permutation (
    input  wire [7:0] din,
    output wire [7:0] dout,
    input  wire [1:0] c3,
    input  wire       clk
);

    wire c0, c1, c2;
    wire [7:0] mux0_o, mux1_o, mux2_o;
    reg  [7:0] reg12, reg11, reg10, reg9, reg8, reg7, reg6, reg5, reg4, reg3, reg2, reg1;

    // Control logic for ShiftRows byte selection
    assign c0 = ~(c3[1] | c3[0]);
    assign c1 = ~(c3[1] | (~c3[0])); 
    assign c2 = ~((~c3[1]) | c3[0]);

    // Multiplexer instantiations
    mux2_1 mux0 (
        .in0(reg1), 
        .in1(din), 
        .out(mux0_o), 
        .sel(c0)
    );
    
    mux2_1 mux1 (
        .in0(reg1), 
        .in1(reg9), 
        .out(mux1_o), 
        .sel(c1)
    );
    
    mux2_1 mux2 (
        .in0(reg1), 
        .in1(reg5), 
        .out(mux2_o), 
        .sel(c2)
    );
    
    mux4_1 mux3 (
        .in0(din), 
        .in1(reg9), 
        .in2(reg5), 
        .in3(reg1), 
        .out(dout), 
        .sel(c3)
    );

    // Shift Register bank for byte storage
    always @(posedge clk) begin
        reg12 <= mux0_o;
        reg11 <= reg12;
        reg10 <= reg11;
        reg9  <= reg10;
        reg8  <= mux1_o;
        reg7  <= reg8;
        reg6  <= reg7;
        reg5  <= reg6;
        reg4  <= mux2_o;
        reg3  <= reg4;
        reg2  <= reg3;
        reg1  <= reg2;
    end

endmodule
