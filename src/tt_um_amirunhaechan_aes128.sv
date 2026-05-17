`default_nettype none

module tt_um_aes128_wrapper (
    input  wire [7:0] ui_in,    // Dedicated inputs: Data Byte
    output wire [7:0] uo_out,   // Dedicated outputs: Ciphertext Byte
    input  wire [7:0] uio_in,   // IOs: Control signals
    output wire [7:0] uio_out,  // IOs: Status signals
    output wire [7:0] uio_oe,   // IOs: Output Enable
    input  wire       ena,      // always 1 when the design is powered
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // Internal 128-bit Registers [cite: 10]
    logic [127:0] p_reg;
    logic [127:0] k_reg;
    
    // Control Signal Mapping
    wire [3:0] byte_index = uio_in[3:0]; // Which byte (0-15)
    wire load_p = uio_in[4];             // Load Plaintext command
    wire load_k = uio_in[5];             // Load Key command
    wire start_pulse = uio_in[6];        // Start signal for core
    
    // Core Status and Data
    wire busy_status, done_status;
    wire [127:0] ciphertext_full;
    wire reset_high = ~rst_n; // Convert TT rst_n to active-high for partner's core

    // --- 1. Serial Loading Logic ---
    // Loads 8-bit data from ui_in into the specific byte of the 128-bit registers
    always_ff @(posedge clk) begin
        if (reset_high) begin
            p_reg <= 128'h0;
            k_reg <= 128'h0;
        end else begin
            if (load_p) 
                p_reg[127 - (byte_index * 8) -: 8] <= ui_in;
            if (load_k) 
                k_reg[127 - (byte_index * 8) -: 8] <= ui_in;
        end
    end

    // --- 2. Instantiate Partner's AES Top ---
    aes_top u_aes_top (
        .clk        (clk),
        .reset      (reset_high),
        .start      (start_pulse),
        .plaintext  (p_reg),
        .key        (k_reg),
        .busy       (busy_status),
        .done       (done_status),
        .ciphertext (ciphertext_full)
    );

    // --- 3. Output Multiplexing ---
    // Displays the indexed byte of the full ciphertext on uo_out
    assign uo_out = ciphertext_full[127 - (byte_index * 8) -: 8];
    
    // Status signals on UIO pins
    assign uio_out[7] = busy_status;
    assign uio_out[6] = done_status;
    assign uio_out[5:0] = 6'b0;
    
    // Set UIO pin directions (7 and 6 are outputs, others are inputs)
    assign uio_oe = 8'b11000000; 

endmodule