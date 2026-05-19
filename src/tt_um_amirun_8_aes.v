/*
 * Cleaned UTF-8 Verilog for 8-bit Serial AES-128
 * Top Module: tt_um_amirun_8_aes
 */

module tt_um_amirun_8_aes (
    input  wire [7:0] ui_in,    // Dedicated inputs - mapped to d_in
    output wire [7:0] uo_out,   // Dedicated outputs - mapped to d_out
    input  wire [7:0] uio_in,   // IOs: Input path - mapped to key_in
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // Internal Reset Logic (Tiny Tapeout uses active-low reset)
    wire rst = !rst_n;

    // Mapping TT pins to internal signals
    wire [7:0] d_in   = ui_in;
    wire [7:0] key_in = uio_in;
    wire [7:0] d_out_w;
    reg  [7:0] d_out_reg;
    reg        d_vld;

    // Control and Status
    assign uo_out = d_out_reg;
    assign uio_oe = 8'h00;    // Configure all uio as inputs for key_in
    assign uio_out = 8'h00;

    // Internal State/Control Signals
    wire [3:0] round_cnt_w;
    reg input_sel, sbox_sel, last_out_sel, bit_out_sel;
    reg [7:0] rcon_en;
    reg [3:0] cnt;
    reg [7:0] round_cnt;
    reg [2:0] state;
    wire [7:0] rk_delayed_out, rk_last_out;
    reg [1:0] c3;
    wire pld;
    reg [7:0] mc_en_reg;
    reg pld_reg;
    wire [7:0] mc_en;

    always @(posedge clk) begin
        d_out_reg <= d_out_w;
    end

    assign pld = pld_reg;
    assign mc_en = mc_en_reg;
    assign round_cnt_w = round_cnt[7:4];

    // Sub-module Instantiations
    key_expansion key (
        .key_in(key_in), 
        .rk_delayed_out(rk_delayed_out), 
        .round_cnt(round_cnt_w), 
        .rk_last_out(rk_last_out), 
        .clk(clk), 
        .input_sel(input_sel), 
        .sbox_sel(sbox_sel), 
        .last_out_sel(last_out_sel), 
        .bit_out_sel(bit_out_sel), 
        .rcon_en(rcon_en)
    );

    aes_data_path data_path (
        .d_in(d_in), 
        .d_out(d_out_w), 
        .pld(pld), 
        .c3(c3), 
        .clk(clk), 
        .mc_en(mc_en), 
        .rk_delayed_out(rk_delayed_out), 
        .rk_last_out(rk_last_out)
    );

    // FSM Parameters
    localparam LOAD_S = 3'h0;
    localparam B1ST_S = 3'h1;
    localparam B2ND_S = 3'h2;
    localparam B3RD_S = 3'h3;
    localparam NORM_S = 3'h4;
    localparam SHIF_S = 3'h5;

    // FSM Logic
    always @(posedge clk) begin
        if (rst) begin
            state <= LOAD_S;
            cnt <= 4'h0;
        end else begin
            case (state)
                LOAD_S: begin
                    cnt <= cnt + 4'h1;
                    if (cnt == 4'hf) begin
                        state <= B1ST_S;
                        cnt <= 4'h0;
                    end
                end
                B1ST_S: begin
                    state <= B2ND_S;
                    cnt <= 4'h0;
                end
                B2ND_S: begin
                    cnt <= cnt + 4'h1;
                    if (cnt == 4'h1) begin
                        state <= B3RD_S;
                        cnt <= 4'h0;
                    end
                end
                B3RD_S: begin
                    state <= NORM_S;
                    cnt <= 4'h0;
                end
                NORM_S: begin
                    cnt <= cnt + 4'h1;
                    if (cnt == 4'h7) begin
                        state <= SHIF_S;
                        cnt <= 4'h0;
                    end
                end
                SHIF_S: begin
                    cnt <= cnt + 4'h1;
                    if (cnt == 4'h3) begin
                        state <= B1ST_S;
                        cnt <= 4'h0;
                    end
                end
                default: state <= LOAD_S;
            endcase
        end
    end

    // Combinational Logic for Control
    always @(*) begin
        input_sel    = 1'b1;
        sbox_sel     = 1'b0;
        last_out_sel = 1'b0;
        bit_out_sel  = 1'b0;
        rcon_en      = 8'h00;
        case (state)
            LOAD_S: begin
                input_sel = 1'b0; sbox_sel = 1'b1; last_out_sel = 1'b0; bit_out_sel = 1'b0; rcon_en = 8'h00;
            end
            B1ST_S: begin
                input_sel = 1'b1; sbox_sel = 1'b1; last_out_sel = 1'b0; bit_out_sel = 1'b1; rcon_en = 8'hFF;
            end
            B2ND_S: begin
                input_sel = 1'b1; sbox_sel = 1'b1; last_out_sel = 1'b0; bit_out_sel = 1'b1; rcon_en = 8'h00;
            end
            B3RD_S: begin
                input_sel = 1'b1; sbox_sel = 1'b0; last_out_sel = 1'b0; bit_out_sel = 1'b1; rcon_en = 8'h00;
            end
            NORM_S: begin
                input_sel = 1'b1; sbox_sel = 1'b0; last_out_sel = 1'b1; bit_out_sel = 1'b1; rcon_en = 8'h00;
            end
            SHIF_S: begin
                input_sel = 1'b1; sbox_sel = 1'b0; last_out_sel = 1'b1; bit_out_sel = 1'b0; rcon_en = 8'h00;
            end
        endcase
    end

    // Counter and Control Registers
    always @(posedge clk) begin
        if (rst || cnt == 4'hf || round_cnt_w == 4'ha)
            round_cnt <= 8'h00;
        else
            round_cnt <= round_cnt + 8'h01;
    end

    always @(posedge clk) begin
        if (state == LOAD_S) 
            c3 <= 2'h3;
        else begin
            case (round_cnt[3:0])
                4'h0: c3 <= 2'h2;
                4'h1: c3 <= 2'h1;
                4'h2: c3 <= 2'h0;
                4'h3: c3 <= 2'h3;
                4'h4: c3 <= 2'h2;
                4'h5: c3 <= 2'h1;
                4'h6: c3 <= 2'h1;
                4'h7: c3 <= 2'h3;
                4'h8: c3 <= 2'h2;
                4'h9: c3 <= 2'h3;
                4'hA: c3 <= 2'h2;
                4'hB: c3 <= 2'h3;
                4'hC: c3 <= 2'h3;
                4'hD: c3 <= 2'h3;
                4'hE: c3 <= 2'h3;
                4'hF: c3 <= 2'h3;
            endcase
        end
    end

    always @(posedge clk) begin
        mc_en_reg <= (round_cnt[1:0] == 2'b11) ? 8'h00 : 8'hFF;
        if (state == LOAD_S)
            pld_reg <= 1'b0;
        else
            pld_reg <= (round_cnt[1:0] == 2'b11);
    end

    always @(posedge clk) begin
        if (rst) d_vld <= 1'b0;
        else if (round_cnt == 8'h90) d_vld <= 1'b1;
    end

endmodule
