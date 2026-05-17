<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This project implements a hardware-accelerated AES-128 encryption core using an iterative architecture to minimize area on the silicon.  

Because Tiny Tapeout has a limited I/O count, the 128-bit plaintext and 128-bit key are loaded into internal registers using a byte-serial interface. The user provides 8 bits of data via ui_in and a 4-bit index via uio_in[3:0] to specify which byte is being updated. Once the data is fully staged in the registers, a start pulse triggers the FSM.  
The encryption process follows the standard FIPS-197 algorithm, executing 10 iterative rounds:  - Initial Round: XOR with the original key.
- Main Rounds (1-9): SubBytes, ShiftRows, MixColumns, and AddRoundKey.
- Final Round (10): SubBytes, ShiftRows, and AddRoundKey (MixColumns is bypassed).

The result is stored in an output register, which can be read back byte-by-byte using the same 4-bit index bus.

## How to test

To verify the encryption core, follow these steps:
1. Reset: Assert rst_n (pull low) to initialize the FSM and clear registers.
2. Load the Key:
   - Set uio_in[5] (load_key) to high
   - For each of the 16 bytes (index 0 to 15), provide the byte on ui_in[7:0] and set the index      on uio_in[3:0].
3. Load the Plaintext:
   -  Set uio_in[5] (load_key) to low and uio_in[4] (load_plaintext) to high.
   -  Repeat the indexing process to load all 16 bytes of data on ui_in[7:0].
4. Encrypt:
   - Set both load signals to low.
   - Pulse uio_in[6] (start) high for one clock cycle.
5. Read Result:
   - Wait for uio_out[6] (done) to go high.
   - Change the index on uio_in[3:0] from 0 to 15 to read the 128-bit ciphertext byte-by-byte        on uo_out[7:0].

## External hardware

No mandatory external hardware is required for basic operation.
