/*
 * Top-level Module: 8-bit Serial AES-128 Core
 * Architecture: Ultra-compact shift-register based datapath
 */

module tt_um_amirun_8_aes (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // Internal Signal Mapping
    wire rst = !rst_n || !ena;
    wire [7:0] key_in = uio_in;
    wire [7:0] d_in   = ui_in;
    wire [7:0] d_out_w;
    reg  [7:0] d_out_reg;
    reg        d_vld;

    assign uio_out[0] = d_vld;
    assign uio_oe[0]  = 1'b1; // Set uio[0] as an output
    assign uio_out = 8'b0;      // uio pins used as inputs for key
    assign uio_oe  = 8'b0;      // all uio pins are inputs

    // Controller signals
    wire [3:0] round_cnt_w;
    reg  input_sel, sbox_sel, last_out_sel, bit_out_sel;
    reg  [7:0] rcon_en;
    reg  [3:0] cnt;
    reg  [7:0] round_cnt;
    reg  [2:0] state;
    wire [7:0] rk_delayed_out, rk_last_out;
    reg  [1:0] c3;
    wire pld;
    reg  [7:0] mc_en_reg;
    reg  pld_reg;
    wire [7:0] mc_en;

    // Output Registering
    always @(posedge clk) begin
        if (rst) d_out_reg <= 8'h0;
        else     d_out_reg <= d_out_w;
    end

    assign pld = pld_reg;
    assign mc_en = mc_en_reg;
    assign round_cnt_w = round_cnt[7:4];

    // Sub-module Instantiations
    key_expansion key_unit (
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

    aes_data_path data_path_unit (
        .d_in(d_in), 
        .d_out(d_out_w), 
        .pld(pld), 
        .c3(c3), 
        .clk(clk), 
        .mc_en(mc_en), 
        .rk_delayed_out(rk_delayed_out), 
        .rk_last_out(rk_last_out)
    );

    // State Parameters
    parameter load = 3'h0; 
    parameter b1st = 3'h1; 
    parameter b2nd = 3'h2; 
    parameter b3rd = 3'h3; 
    parameter norm = 3'h4; 
    parameter shif = 3'h5; 

    // State Machine for Key Schedule & Rounds
    always @(posedge clk) begin
        if (rst) begin
            state <= load;
            cnt <= 4'h0;
        end else begin
            case (state)
                load: begin
                    cnt <= cnt + 4'h1;
                    if (cnt == 4'hf) begin
                        state <= b1st;
                        cnt <= 4'h0;
                    end
                end
                b1st: begin
                    state <= b2nd;
                    cnt <= 4'h0;
                end
                b2nd: begin
                    cnt <= cnt + 4'h1;
                    if (cnt == 4'h1) begin
                        state <= b3rd;
                        cnt <= 4'h0;
                    end
                end
                b3rd: begin
                    state <= norm;
                    cnt <= 4'h0;
                end
                norm: begin
                    cnt <= cnt + 4'h1;
                    if (cnt == 4'h7) begin
                        state <= shif;
                        cnt <= 4'h0;
                    end
                end
                shif: begin
                    cnt <= cnt + 4'h1;
                    if (cnt == 4'h3) begin
                        state <= b1st;
                        cnt <= 4'h0;
                    end
                end
                default: state <= load;
            endcase
        end
    end

    // Control Logic Mux Selects
    always @(*) begin
        case(state)
            load: begin
                input_sel = 1'b0; sbox_sel = 1'b1; last_out_sel = 1'b0; bit_out_sel = 1'b0; rcon_en = 8'h00;
            end
            b1st: begin
                input_sel = 1'b1; sbox_sel = 1'b1; last_out_sel = 1'b0; bit_out_sel = 1'b1; rcon_en = 8'hFF;
            end
            b2nd: begin
                input_sel = 1'b1; sbox_sel = 1'b1; last_out_sel = 1'b0; bit_out_sel = 1'b1; rcon_en = 8'h00;
            end
            b3rd: begin
                input_sel = 1'b1; sbox_sel = 1'b0; last_out_sel = 1'b0; bit_out_sel = 1'b1; rcon_en = 8'h00;
            end
            norm: begin
                input_sel = 1'b1; sbox_sel = 1'b0; last_out_sel = 1'b1; bit_out_sel = 1'b1; rcon_en = 8'h00;
            end
            shif: begin
                input_sel = 1'b1; sbox_sel = 1'b0; last_out_sel = 1'b1; bit_out_sel = 1'b0; rcon_en = 8'h00;
            end
            default: begin
                input_sel = 1'b0; sbox_sel = 1'b1; last_out_sel = 1'b0; bit_out_sel = 1'b0; rcon_en = 8'h00;
            end
        endcase
    end

    // Round Counter logic
    always @(posedge clk) begin
        if (rst || cnt == 4'hf || round_cnt_w == 4'ha) begin
            round_cnt <= 8'h00;
        end else begin
            round_cnt <= round_cnt + 8'h01;
        end
    end

    // ShiftRows control
    always @(posedge clk) begin
        if (state == load) c3 <= 2'h3;
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

    // MixColumn & Parallel Load control
    always @(posedge clk) begin
        if (round_cnt[1:0] == 2'b11) begin
            mc_en_reg <= 8'h00;
            pld_reg   <= 1'b1;
        end else begin
            mc_en_reg <= 8'hFF;
            pld_reg   <= (state == load) ? 1'b0 : 1'b0;
        end
    end

    // Valid signal logic
    always @(posedge clk) begin
        if (rst) d_vld <= 1'b0;
        else if (round_cnt == 8'h90) d_vld <= 1'b1;
    end

endmodule
