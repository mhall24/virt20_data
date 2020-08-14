// Copyright 2014 by Michael J. Hall.

`timescale 1ns / 1ps
`default_nettype none


module AES_sbox_lookuptable(outdata1, outdata2, addrin1, addrin2, en1, en2, clk);
	// Substitution box lookup table.

	parameter REG_DEPTH = 0;
	parameter IS_INV = 0;

	// Counts the number of bits in the number.
	function integer countbits;
		input integer num;
		integer bitcnt;
		begin
			bitcnt = 0;
			while (num > 0) begin
				num = num >> 1;
				bitcnt = bitcnt + 1;
			end
			if (bitcnt == 0) bitcnt = 1;
			countbits = bitcnt;
		end
	endfunction

	// Get the file name based on the is invert parameter.
	function [159:0] get_file;   // 20 char return field
		input isinv;
		begin
			if (isinv) begin
				get_file = "rsbox.rom";
			end
			else begin
				get_file = "sbox.rom";
			end
		end
	endfunction

	// Local parameters.
	localparam ROM_WIDTH = 8;
	localparam ROM_ADDR_BITS = 8;

	// Port declarations.
	output wire [ROM_WIDTH-1:0] outdata1, outdata2;
	input wire [ROM_ADDR_BITS-1:0] addrin1, addrin2;
	input wire en1, en2;
	input wire clk;

	// ROM signals.
	reg [ROM_WIDTH-1:0] ROM [0:(2**ROM_ADDR_BITS)-1];

	// Populate the ROM lookup table with values from a file.
	initial $readmemh(get_file(IS_INV), ROM, 0, (2**ROM_ADDR_BITS)-1);

	generate
		if (REG_DEPTH == 0) begin
			// No registers -- use distributed RAM.
			assign outdata1 = ROM[addrin1];
			assign outdata2 = ROM[addrin2];
		end
		else begin
			// One or more registers -- use block RAM.
			reg [ROM_WIDTH-1:0] romOutputDataSR[1:2][0:REG_DEPTH-1];
			integer i;
			always @(posedge clk) begin
				if (en1) begin
					romOutputDataSR[1][0] <= ROM[addrin1];
					for (i=1; i<REG_DEPTH; i=i+1) begin
						romOutputDataSR[1][i] <= romOutputDataSR[1][i-1];
					end
				end
				if (en2) begin
					romOutputDataSR[2][0] <= ROM[addrin2];
					for (i=1; i<REG_DEPTH; i=i+1) begin
						romOutputDataSR[2][i] <= romOutputDataSR[2][i-1];
					end
				end
			end
			assign outdata1 = romOutputDataSR[1][REG_DEPTH-1];
			assign outdata2 = romOutputDataSR[2][REG_DEPTH-1];
		end
	endgenerate
endmodule

module AES_galois_multiplication(out, a, b);
	output reg [7:0] out;
	input wire [7:0] a;
	input wire [7:0] b;

	// Behaviorial combinational logic of the Galois Multiplication.
	integer i;
	reg [7:0] xtime;
	reg hi_bit;
	always @(*) begin
		out = 8'd0;
		xtime = a;
		for (i=0; i<8; i=i+1) begin
			if (b[i])
				out = out ^ xtime;
			{hi_bit, xtime} = {xtime, 1'b0};
			if (hi_bit)
				xtime = xtime ^ 8'h1b;
		end
	end
endmodule

module AES_word_multiplication(outwordarray, awordarray, bwordarray);
	// 4-byte word multiplication in a column using finite-field elements.

	// Get the AMatrix values for the word multiplication.
	function integer AMatrix;
		input integer r;
		input integer c;
		integer out;
		begin
			case (r)
				0: begin
					case (c)
						0: out = 0;
						1: out = 3;
						2: out = 2;
						3: out = 1;
					endcase
				end
				1: begin
					case (c)
						0: out = 1;
						1: out = 0;
						2: out = 3;
						3: out = 2;
					endcase
				end
				2: begin
					case (c)
						0: out = 2;
						1: out = 1;
						2: out = 0;
						3: out = 3;
					endcase
				end
				3: begin
					case (c)
						0: out = 3;
						1: out = 2;
						2: out = 1;
						3: out = 0;
					endcase
				end
			endcase
			AMatrix = out;
		end
	endfunction

	// Port declarations.
	output wire [31:0] outwordarray;  // 4 byte word, little endian
	input wire [31:0] awordarray;     // 4 byte word, little endian
	input wire [31:0] bwordarray;     // 4 byte word, little endian

	// Wires.
	wire [7:0] aword[0:3];
	wire [7:0] bword[0:3];
	wire [7:0] outword[0:3];
	wire [7:0] ga_out[0:3][0:3];

	// Unpack aword.
	genvar unpk_aword_idx;
	generate
		for (unpk_aword_idx=0; unpk_aword_idx<4; unpk_aword_idx=unpk_aword_idx+1) begin: UNPACK_AWORD
			assign aword[unpk_aword_idx] = awordarray[8*unpk_aword_idx +: 8];
		end
	endgenerate

	// Unpack bword.
	genvar unpk_bword_idx;
	generate
		for (unpk_bword_idx=0; unpk_bword_idx<4; unpk_bword_idx=unpk_bword_idx+1) begin: UNPACK_BWORD
			assign bword[unpk_bword_idx] = bwordarray[8*unpk_bword_idx +: 8];
		end
	endgenerate

	// Pack outword.
	genvar pk_outword_idx;
	generate
		for (pk_outword_idx=0; pk_outword_idx<4; pk_outword_idx=pk_outword_idx+1) begin: PACK_OUTWORD
			assign outwordarray[8*pk_outword_idx +: 8] = outword[pk_outword_idx];
		end
	endgenerate

	// Galois multiplication of terms.
	genvar gaR_idx, gaC_idx;
	generate
		for (gaR_idx=0; gaR_idx<4; gaR_idx=gaR_idx+1) begin: GA_ROWS
			for (gaC_idx=0; gaC_idx<4; gaC_idx=gaC_idx+1) begin: GA_COLS
				AES_galois_multiplication gmult (
					.out(ga_out[gaR_idx][gaC_idx]),
					.a(aword[AMatrix(gaR_idx, gaC_idx)]),
					.b(bword[gaC_idx])
				);
			end
			assign outword[gaR_idx] = ga_out[gaR_idx][0] ^ ga_out[gaR_idx][1] ^
			                          ga_out[gaR_idx][2] ^ ga_out[gaR_idx][3];
		end
	endgenerate
endmodule

module AES_MixColumns(block_out, block_in);
	// Mix columns in a block.

	parameter IS_INV = 0;
	parameter Nb = 4;

	localparam [31:0] MULT_ENC = {8'd3, 8'd1, 8'd1, 8'd2};
	localparam [31:0] MULT_DEC = {8'd11, 8'd13, 8'd9, 8'd14};
	localparam [31:0] MULT = {IS_INV ? MULT_DEC : MULT_ENC};

	output wire [32*Nb-1:0] block_out;
	input wire [32*Nb-1:0] block_in;

	genvar i;
	generate
		for (i=0; i<Nb; i=i+1) begin: MIX_COLUMNS
			AES_word_multiplication wm (
				.outwordarray(block_out[32*i+:32]),
				.awordarray(block_in[32*i+:32]),
				.bwordarray(MULT)
			);
		end
	endgenerate
endmodule

module AES_SubBytes(block_out, block_in, en, clk);
	// Perform substution of all bytes in the block.

	parameter REG_DEPTH = 0;
	parameter IS_INV = 0;
	parameter Nb = 4;

	output wire [32*Nb-1:0] block_out;
	input wire [32*Nb-1:0] block_in;
	input wire en;
	input wire clk;

	genvar i;
	generate
		for (i=0; i<4*Nb; i=i+2) begin: SBOX_LOOKUP
			AES_sbox_lookuptable #(
				.REG_DEPTH(REG_DEPTH),
				.IS_INV(IS_INV)
			) sbox_lookup (
				.outdata1(block_out[8*i+:8]),
				.outdata2(block_out[8*(i+1)+:8]),
				.addrin1(block_in[8*i+:8]),
				.addrin2(block_in[8*(i+1)+:8]),
				.en1(en),
				.en2(en),
				.clk(clk)
			);
		end
	endgenerate
endmodule

module AES_ShiftRows(block_out, block_in);
	// Shift rows step.
	// BUG:  Rijndael specification has different shifting amounts for larger Nb (such as 256-bit block size with Nb=8).  Ok for AES.

	parameter IS_INV = 0;
	parameter Nb = 4;

	output wire [32*Nb-1:0] block_out;   // Column-major order, 4 bytes per column with Nb columns, little endian
	input wire [32*Nb-1:0] block_in;     // Column-major order, 4 bytes per column with Nb columns, little endian

	genvar r, c;
	generate
		for (r=0; r<4; r=r+1) begin: BY_ROWS         // Iterate through rows.
			for (c=0; c<Nb; c=c+1) begin: BY_COLS    // Iterate through columns.
				if (IS_INV)
					assign block_out[32*c+8*r+:8] = block_in[32*((c-r+Nb)%Nb)+8*r+:8];
				else
					assign block_out[32*c+8*r+:8] = block_in[32*((c+r+Nb)%Nb)+8*r+:8];
			end
		end
	endgenerate
endmodule

module AES_AddRoundKey(block_out, block_in, round_key);
	// Add the round key.

	parameter Nb = 4;

	output wire [32*Nb-1:0] block_out;
	input wire [32*Nb-1:0] block_in;
	input wire [32*Nb-1:0] round_key;

	assign block_out = block_in ^ round_key;
endmodule

module AES_TransposeRM(block_out, block_in);
	// Transpose row-major block input to column-major block output

	parameter REVERSE = 0;
	parameter Nb = 4;

	output wire [32*Nb-1:0] block_out;
	input wire [32*Nb-1:0] block_in;

	genvar r, c;
	generate
		for (r=0; r<4; r=r+1) begin: BY_ROWS         // Iterate through rows.
			for (c=0; c<Nb; c=c+1) begin: BY_COLS    // Iterate through columns.
				if (REVERSE)
					assign block_out[8*Nb*r+8*c+:8] = block_in[32*c+8*r+:8];
				else
					assign block_out[32*c+8*r+:8] = block_in[8*Nb*r+8*c+:8];
			end
		end
	endgenerate
endmodule

module AES_InitRound(block_out, block_in, round_key);
	parameter IS_INV = 0;
	parameter Nb = 4;

	output wire [32*Nb-1:0] block_out;
	input wire [32*Nb-1:0] block_in;
	input wire [32*Nb-1:0] round_key;

	AES_AddRoundKey #(.Nb(Nb)) u_addroundkey (
		.block_out(block_out),
		.block_in(block_in),
		.round_key(round_key)
	);
endmodule

module AES_FinalRound(block_out, block_in, round_key, en, clk);
	parameter SB_REG_DEPTH = 0;
	parameter REG_OUTPUT = 0;
	parameter IS_INV = 0;
	parameter Nb = 4;

	output wire [32*Nb-1:0] block_out;
	input wire [32*Nb-1:0] block_in;
	input wire [32*Nb-1:0] round_key;
	input wire en;
	input wire clk;

	wire [32*Nb-1:0] state[1:3];

	AES_SubBytes #(.REG_DEPTH(SB_REG_DEPTH), .IS_INV(IS_INV), .Nb(Nb)) u_subbytes (
		.block_out(state[1]),
		.block_in(block_in),
		.en(en),
		.clk(clk)
	);
	AES_ShiftRows #(.IS_INV(IS_INV), .Nb(Nb)) u_shiftrows (
		.block_out(state[2]),
		.block_in(state[1])
	);
	AES_AddRoundKey #(.Nb(Nb)) u_addroundkey (
		.block_out(state[3]),
		.block_in(state[2]),
		.round_key(round_key)
	);
	pipe_reg_en #(.WIDTH(32*Nb), .DEPTH((REG_OUTPUT ? 1 : 0))) u_reg_output (.out(block_out), .in(state[3]), .en(en), .clk(clk));
endmodule

module AES_CoreRound(block_out, block_in, round_key, en, clk);
	parameter SB_REG_DEPTH = 0;
	parameter REG_OUTPUT = 0;
	parameter IS_INV = 0;
	parameter Nb = 4;

	output wire [32*Nb-1:0] block_out;
	input wire [32*Nb-1:0] block_in;
	input wire [32*Nb-1:0] round_key;
	input wire en;
	input wire clk;

	wire [32*Nb-1:0] state[1:4];

	generate
		if (IS_INV) begin
			AES_ShiftRows #(.IS_INV(IS_INV), .Nb(Nb)) u_shiftrows (
				.block_out(state[1]),
				.block_in(block_in)
			);
			AES_SubBytes #(.REG_DEPTH(SB_REG_DEPTH), .IS_INV(IS_INV), .Nb(Nb)) u_subbytes (
				.block_out(state[2]),
				.block_in(state[1]),
				.en(en),
				.clk(clk)
			);
			AES_AddRoundKey #(.Nb(Nb)) u_addroundkey (
				.block_out(state[3]),
				.block_in(state[2]),
				.round_key(round_key)
			);
			AES_MixColumns #(.IS_INV(IS_INV), .Nb(Nb)) u_mixcolumns (
				.block_out(state[4]),
				.block_in(state[3])
			);
		end
		else begin
			AES_SubBytes #(.REG_DEPTH(SB_REG_DEPTH), .IS_INV(IS_INV), .Nb(Nb)) u_subbytes (
				.block_out(state[1]),
				.block_in(block_in),
				.en(en),
				.clk(clk)
			);
			AES_ShiftRows #(.IS_INV(IS_INV), .Nb(Nb)) u_shiftrows (
				.block_out(state[2]),
				.block_in(state[1])
			);
			AES_MixColumns #(.IS_INV(IS_INV), .Nb(Nb)) u_mixcolumns (
				.block_out(state[3]),
				.block_in(state[2])
			);
			AES_AddRoundKey #(.Nb(Nb)) u_addroundkey (
				.block_out(state[4]),
				.block_in(state[3]),
				.round_key(round_key)
			);
		end
		pipe_reg_en #(.WIDTH(32*Nb), .DEPTH((REG_OUTPUT ? 1 : 0))) u_reg_output (.out(block_out), .in(state[4]), .en(en), .clk(clk));
	endgenerate
endmodule

module AES_CoreEncrypt(block_out, block_in, expanded_key, en, clk);
	parameter [27:0] ADD_REG_MASK = 28'b0;
	parameter IS_INV = 0;
	parameter Nb = 4;
	parameter Nr = 14;              // Number of rounds

	localparam EK_SIZE = 4*Nb*(Nr+1);

	output wire [32*Nb-1:0] block_out;           // column-major form
	input wire [32*Nb-1:0] block_in;             // column-major form
	input wire [8*EK_SIZE-1:0] expanded_key;     // column-major form
	input wire en;
	input wire clk;

	wire [32*Nb-1:0] state [0:Nr-1];

	// Initial round
	AES_InitRound #(.IS_INV(IS_INV), .Nb(Nb)) u_initround (
		.block_out(state[0]),
		.block_in(block_in),
		.round_key(expanded_key[32*Nb*(IS_INV ? Nr : 0)+:32*Nb])
	);

	// Core rounds
	genvar i;
	generate
		for (i=1; i<Nr; i=i+1) begin: GEN_CORE_ROUND
			AES_CoreRound #(.SB_REG_DEPTH(ADD_REG_MASK[2*(i-1)]), .REG_OUTPUT(ADD_REG_MASK[2*(i-1)+1]), .IS_INV(IS_INV), .Nb(Nb)) u_coreround (
				.block_out(state[i]),
				.block_in(state[i-1]),
				.round_key(expanded_key[32*Nb*(IS_INV ? Nr-i : i)+:32*Nb]),
				.en(en),
				.clk(clk)
			);
		end
	endgenerate

	// Final round
	AES_FinalRound #(.SB_REG_DEPTH(ADD_REG_MASK[2*(Nr-1)]), .REG_OUTPUT(ADD_REG_MASK[2*(Nr-1)+1]), .IS_INV(IS_INV), .Nb(Nb)) u_finalround (
		.block_out(block_out),
		.block_in(state[Nr-1]),
		.round_key(expanded_key[32*Nb*(IS_INV ? 0 : Nr)+:32*Nb]),
		.en(en),
		.clk(clk)
	);
endmodule

module AES_Encrypt(block_out, block_in, expanded_key, en, clk);
	parameter [27:0] ADD_REG_MASK = 28'b0;
	parameter Nb = 4;
	parameter Nr = 14;              // Number of rounds

	localparam EK_SIZE = 4*Nb*(Nr+1);

	output wire [32*Nb-1:0] block_out;
	input wire [32*Nb-1:0] block_in;
	input wire [8*EK_SIZE-1:0] expanded_key;
	input wire en;
	input wire clk;

	wire [32*Nb-1:0] core_block_in, core_block_out;

	// Transpose input block
	AES_TransposeRM #(.REVERSE(0), .Nb(Nb)) u_transpose_rm2cm (
		.block_out(core_block_in),
		.block_in(block_in)
	);

	// AES core encryption
	AES_CoreEncrypt #(.ADD_REG_MASK(ADD_REG_MASK), .IS_INV(0), .Nb(Nb), .Nr(Nr)) u_core_encrypt (
		.block_out(core_block_out),
		.block_in(core_block_in),
		.expanded_key(expanded_key),
		.en(en),
		.clk(clk)
	);

	// Transpose output block
	AES_TransposeRM #(.REVERSE(1), .Nb(Nb)) u_transpose_cm2rm (
		.block_out(block_out),
		.block_in(core_block_out)
	);
endmodule

module AES_Decrypt(block_out, block_in, expanded_key, en, clk);
	parameter [27:0] ADD_REG_MASK = 28'b0;
	parameter Nb = 4;
	parameter Nr = 14;              // Number of rounds

	localparam EK_SIZE = 4*Nb*(Nr+1);

	output wire [32*Nb-1:0] block_out;           // row-major
	input wire [32*Nb-1:0] block_in;             // row-major
	input wire [8*EK_SIZE-1:0] expanded_key;     // column-major
	input wire en;
	input wire clk;

	wire [32*Nb-1:0] core_block_in, core_block_out;

	// Transpose input block
	AES_TransposeRM #(.REVERSE(0), .Nb(Nb)) u_transpose_rm2cm (
		.block_out(core_block_in),
		.block_in(block_in)
	);

	// AES core decryption
	AES_CoreEncrypt #(.ADD_REG_MASK(ADD_REG_MASK), .IS_INV(1), .Nb(Nb), .Nr(Nr)) u_core_decrypt (
		.block_out(core_block_out),
		.block_in(core_block_in),
		.expanded_key(expanded_key),
		.en(en),
		.clk(clk)
	);

	// Transpose output block
	AES_TransposeRM #(.REVERSE(1), .Nb(Nb)) u_transpose_cm2rm (
		.block_out(block_out),
		.block_in(core_block_out)
	);
endmodule

module AES_Encrypt_CBC(ciphertext_out, plaintext_in, expanded_key, iv, muxsel_iv, en, rst, clk, state_fb_d, state_fb_q);
	parameter [27:0] ADD_REG_MASK = 28'b0;
	parameter Nb = 4;
	parameter Nr = 14;              // Number of rounds

	localparam EK_SIZE = 4*Nb*(Nr+1);

	// Port declarations
	output wire [32*Nb-1:0] ciphertext_out;
	input wire [32*Nb-1:0] plaintext_in;
	input wire [8*EK_SIZE-1:0] expanded_key;
	input wire [32*Nb-1:0] iv;
	input wire muxsel_iv;
	input wire en;
	input wire rst;
	input wire clk;

	// Wires
	wire [32*Nb-1:0] aes_block_in;
	wire [32*Nb-1:0] aes_block_out;

	// State signals
	output reg [32*Nb-1:0] state_fb_d;
	input wire [32*Nb-1:0] state_fb_q;

	AES_Encrypt #(.ADD_REG_MASK(ADD_REG_MASK), .Nb(Nb), .Nr(Nr)) u_aes_encrypt (
		.block_out(aes_block_out),
		.block_in(aes_block_in),
		.expanded_key(expanded_key),
		.en(en),
		.clk(clk)
	);
	assign aes_block_in = (muxsel_iv ? iv : state_fb_q) ^ plaintext_in;
	assign ciphertext_out = state_fb_q;

	// Combinational logic for sequential logic.
	always @(*) begin
		state_fb_d <= state_fb_q;
		if (rst) begin
			state_fb_d <= {32*Nb{1'b0}};
		end
		else if (en) begin
			state_fb_d <= aes_block_out;
		end
	end
endmodule

module AES_Decrypt_CBC(plaintext_out, ciphertext_in, expanded_key, iv, muxsel_iv, en, rst, clk,
		state_ct_d, state_ct_q, state_aes_d, state_aes_q, state_fb_d, state_fb_q);

	parameter [27:0] ADD_REG_MASK = 28'b0;
	parameter Nb = 4;
	parameter Nr = 14;              // Number of rounds

	localparam EK_SIZE = 4*Nb*(Nr+1);

	// Port declarations
	output wire [32*Nb-1:0] plaintext_out;
	input wire [32*Nb-1:0] ciphertext_in;
	input wire [8*EK_SIZE-1:0] expanded_key;
	input wire [32*Nb-1:0] iv;
	input wire muxsel_iv;
	input wire en;
	input wire rst;
	input wire clk;

	// Wires
	wire [32*Nb-1:0] aes_block_out;

	// State signals
	output reg [32*Nb-1:0] state_ct_d;
	input wire [32*Nb-1:0] state_ct_q;
	output reg [32*Nb-1:0] state_aes_d;
	input wire [32*Nb-1:0] state_aes_q;
	output reg [32*Nb-1:0] state_fb_d;
	input wire [32*Nb-1:0] state_fb_q;

	AES_Decrypt #(.ADD_REG_MASK(ADD_REG_MASK), .Nb(Nb), .Nr(Nr)) u_aes_decrypt (
		.block_out(aes_block_out),
		.block_in(ciphertext_in),
		.expanded_key(expanded_key),
		.en(en),
		.clk(clk)
	);
	assign plaintext_out = state_fb_q ^ state_aes_q;

	// Combinational logic for sequential logic.
	always @(*) begin
		state_ct_d <= state_ct_q;
		state_aes_d <= state_aes_q;
		state_fb_d <= state_fb_q;
		if (rst) begin
			state_ct_d <= {32*Nb{1'b0}};
			state_aes_d <= {32*Nb{1'b0}};
			state_fb_d <= {32*Nb{1'b0}};
		end
		else if (en) begin
			state_ct_d <= ciphertext_in;
			state_aes_d <= aes_block_out;
			state_fb_d <= (muxsel_iv ? iv : state_ct_q);
		end
	end
endmodule

module CSLOW_AES_CBC(block_out, block_in, expanded_key, iv, muxsel_iv, en, rst, clk);
	// Parameters
	parameter Nb = 4;
	parameter Nr = 14;              // Number of rounds
	parameter C = 4;                // Max performance should be C=2*Nr.
	parameter CSLOW_MODE = 0;       // 0=state-only registers, 1=manually pipelined registers
	parameter ENC_MODE = 0;         // 0=encryption, 1=decryption

	localparam AR_MASK_SIZE = 2*Nr;

    function integer max;
        input integer A, B;
        begin
            if (A > B) max = A;
            else max = B;
        end
    endfunction

	// Counts the number of bits in the number.
	function integer countbits;
		input integer num;
		integer bitcnt;
		begin
			bitcnt = 0;
			while (num > 0) begin
				num = num >> 1;
				bitcnt = bitcnt + 1;
			end
			if (bitcnt == 0) bitcnt = 1;
			countbits = bitcnt;
		end
	endfunction

	localparam EK_SIZE = 4*Nb*(Nr+1);
	localparam C_BITS = countbits(C);

	function [27:0] generate_ar_mask;
		input integer C;
		input integer AR_MASK_SIZE;
		reg [27:0] ar_mask;
		integer Cp;
		integer MaskSizeP;
		integer i;
		reg [31:0] m;
		begin
			Cp = C - 1;
			MaskSizeP = AR_MASK_SIZE - 1;

			// Initally clear all bits in the mask.
			for (i=0; i<28; i=i+1)
				ar_mask[i] = 1'b0;

			// Calculate the slope to evenly distribute registers.
			m = (AR_MASK_SIZE<<26) / C;

			// Turn on registers in the mask.
			for (i=0; i<Cp; i=i+1)
				ar_mask[max(((m*(i+1))>>26)-1,0)] = 1'b1;

			// Return the pipeline register mask.
			generate_ar_mask = ar_mask;
		end
	endfunction

	function integer count_ones;
		input [27:0] in;
		integer ones;
		integer i;
		begin
			ones = 0;
			for (i=0; i<28; i=i+1) begin
				if (in[i]) ones = ones + 1;
			end
			count_ones = ones;
		end
	endfunction

	localparam [27:0] ADD_REG_MASK_GEN = generate_ar_mask(C, AR_MASK_SIZE);
	localparam AR_COUNT = count_ones(ADD_REG_MASK_GEN);
	localparam EXTRA_REGS = (C-1>AR_COUNT ? C-1-AR_COUNT : 0);

	localparam [27:0] ADD_REG_MASK = (CSLOW_MODE == 1 ? ADD_REG_MASK_GEN : 28'b0);
	localparam STATE_AES_C = (CSLOW_MODE == 1 ? 1 + EXTRA_REGS : C);

	// Port declarations
	output wire [32*Nb-1:0] block_out;
	input wire [32*Nb-1:0] block_in;
	input wire [8*EK_SIZE-1:0] expanded_key;
	input wire [32*Nb-1:0] iv;
	input wire muxsel_iv;
	input wire en;
	input wire rst;
	input wire clk;

	generate
		if (ENC_MODE == 0) begin   // Encryption Mode
			// State signals
			wire [32*Nb-1:0] state_fb_d, state_fb_q;

			// Pipeline state registers
			state_en #(.WIDTH(32*Nb), .C(STATE_AES_C)) u_state (.d(state_fb_d), .q(state_fb_q), .en(en), .rst(1'b0), .clk(clk));

			// Instantiation
			AES_Encrypt_CBC #(.ADD_REG_MASK(ADD_REG_MASK), .Nb(Nb), .Nr(Nr)) u_aes_encrypt_cbc (
				.ciphertext_out(block_out),
				.plaintext_in(block_in),
				.expanded_key(expanded_key),
				.iv(iv),
				.muxsel_iv(muxsel_iv),
				.en(en),
				.rst(rst),
				.clk(clk),
				.state_fb_d(state_fb_d),
				.state_fb_q(state_fb_q)
			);
		end
		else if (ENC_MODE == 1) begin   // Decryption Mode
			// State signals
			wire [32*Nb-1:0] state_ct_d, state_ct_q;
			wire [32*Nb-1:0] state_aes_d, state_aes_q;
			wire [32*Nb-1:0] state_fb_d, state_fb_q;

			// Pipeline state registers
			state_en #(.WIDTH(32*Nb), .C(C)) u_state_1 (.d(state_ct_d), .q(state_ct_q), .en(en), .rst(1'b0), .clk(clk));
			state_en #(.WIDTH(32*Nb), .C(STATE_AES_C)) u_state_2 (.d(state_aes_d), .q(state_aes_q), .en(en), .rst(1'b0), .clk(clk));
			state_en #(.WIDTH(32*Nb), .C(C)) u_state_3 (.d(state_fb_d), .q(state_fb_q), .en(en), .rst(1'b0), .clk(clk));

			// Instantiation
			AES_Decrypt_CBC #(.ADD_REG_MASK(ADD_REG_MASK), .Nb(Nb), .Nr(Nr)) u_aes_decrypt_cbc (
				.plaintext_out(block_out),
				.ciphertext_in(block_in),
				.expanded_key(expanded_key),
				.iv(iv),
				.muxsel_iv(muxsel_iv),
				.en(en),
				.rst(rst),
				.clk(clk),
				.state_ct_d(state_ct_d),
				.state_ct_q(state_ct_q),
				.state_aes_d(state_aes_d),
				.state_aes_q(state_aes_q),
				.state_fb_d(state_fb_d),
				.state_fb_q(state_fb_q)
			);
		end
	endgenerate
endmodule


/********************************************************************************
Company:      Washington University in St. Louis
Engineer:     Michael Hall
Module Name:  PARALLEL_AES_CBC
Description:  Parallelized AES block implementation in CBC feedback mode.
*********************************************************************************/
module PARALLEL_AES_CBC(blockinput_data_inarray, iv_data_inarray, muxsel_iv_data_inarray, expandedkey_data_common_in, avail_inarray, ready_inarray,
	blockoutput_data_outarray, avail_outarray, ready_outarray, rst, minor_clk, major_clk);

	/*
		A parallelized block processes N data streams.  Each data stream has its own input and output port.
		Also, all data streams share a common input port.  The ports are provided as arrays called "inarray"
		and "outarray".  The common input port is called "common_in".  A port consists of data and flow
		control signals.  The data is provided as a record of sub-data fields.

		1)  Multiple inputs/outputs or datasets -- Some blocks can have multiple inputs that form a dataset.
			In this case, simply make multiple arrays of the form <name>_data_<in/out>array to form
			the individual signals in the dataset.  All of these signals share the same avail and ready signals.
		2)  Common inputs to all blocks -- Some blocks can have an input that is constant or common to all blocks
			at the same time.  This is for the case where the block either (1) does not support a non-constant
			input signal or (2) where the signal is designed to be constant and therefore hardware resources can
			be saved.

		Prediction equations:
		1)  # of I/O pins = 32*Nb*(3*NUM_COPIES + Nr + 1) + NUM_COPIES + 7
		2)  # of BRAM     = {2*Nb*Nr*NUM_COPIES if PAR_MODE=0}
		                    {2*Nb*Nr            if PAR_MODE=1}
	*/

	// Parameters
	parameter Nb = 4;
	parameter Nr = 1;               // Number of rounds
	parameter NUM_COPIES = 1;       // Max performance should be NUM_COPIES=2*Nr.
	parameter CSLOW_MODE = 1;       // 0=state-only registers, 1=manually pipelined registers
	parameter ENC_MODE = 0;         // 0=encryption, 1=decryption
	parameter PAR_MODE = 1;         // 0=replicated, 1=virtualized (C-slow)

	localparam WIDTH_IN_BLOCKINPUT   = 32*Nb;
	localparam WIDTH_IN_IV           = 32*Nb;
	localparam WIDTH_IN_MUXSEL_IV    = 1;
	localparam WIDTH_IN_TOTAL        = WIDTH_IN_BLOCKINPUT + WIDTH_IN_IV + WIDTH_IN_MUXSEL_IV;

	localparam WIDTH_COMMON_IN_EXPANDED_KEY = 32*Nb*(Nr+1);
	localparam WIDTH_COMMON_IN_TOTAL        = WIDTH_COMMON_IN_EXPANDED_KEY;

	localparam WIDTH_OUT_BLOCKOUTPUT = 32*Nb;
	localparam WIDTH_OUT_TOTAL       = WIDTH_OUT_BLOCKOUTPUT;

	localparam ARRAY_WIDTH_IN_BLOCKINPUT   = NUM_COPIES * WIDTH_IN_BLOCKINPUT;
	localparam ARRAY_WIDTH_IN_IV           = NUM_COPIES * WIDTH_IN_IV;
	localparam ARRAY_WIDTH_IN_MUXSEL_IV    = NUM_COPIES * WIDTH_IN_MUXSEL_IV;
	localparam ARRAY_WIDTH_IN_TOTAL        = NUM_COPIES * WIDTH_IN_TOTAL;

	localparam ARRAY_WIDTH_OUT_BLOCKOUTPUT = NUM_COPIES * WIDTH_OUT_BLOCKOUTPUT;
	localparam ARRAY_WIDTH_OUT_TOTAL       = NUM_COPIES * WIDTH_OUT_TOTAL;

	// Port declaration
	input wire [ARRAY_WIDTH_IN_BLOCKINPUT-1:0] blockinput_data_inarray;
	input wire [ARRAY_WIDTH_IN_IV-1:0] iv_data_inarray;
	input wire [ARRAY_WIDTH_IN_MUXSEL_IV-1:0] muxsel_iv_data_inarray;
	input wire [WIDTH_COMMON_IN_EXPANDED_KEY-1:0] expandedkey_data_common_in;
	input wire avail_inarray;
	output wire ready_inarray;
	output wire [ARRAY_WIDTH_OUT_BLOCKOUTPUT-1:0] blockoutput_data_outarray;
	output wire avail_outarray;
	input wire ready_outarray;
	input wire rst;
	input wire minor_clk;
	input wire major_clk;

	genvar i;
	generate
		if (PAR_MODE == 0) begin     // Replicated
			// Wires
			wire en;

			wire blk_en;
			wire blk_rst;
			wire blk_clk;

			wire [WIDTH_OUT_BLOCKOUTPUT-1:0] blk_out__block_out [0:NUM_COPIES-1];
			wire [WIDTH_IN_BLOCKINPUT-1:0] blk_in__block_in [0:NUM_COPIES-1];
			wire [WIDTH_IN_IV-1:0] blk_in__iv [0:NUM_COPIES-1];
			wire [WIDTH_IN_MUXSEL_IV-1:0] blk_in__muxsel_iv [0:NUM_COPIES-1];
			wire [WIDTH_COMMON_IN_EXPANDED_KEY-1:0] blk_common_in__expanded_key;

			wire [ARRAY_WIDTH_OUT_TOTAL-1:0] buffer_data_in;
			wire buffer_avail_in;
			wire buffer_ready_in;
			wire [ARRAY_WIDTH_OUT_TOTAL-1:0] buffer_data_out;

			assign ready_inarray = en | ~avail_inarray;

			assign blk_common_in__expanded_key = expandedkey_data_common_in;
			assign blk_en = en | rst;
			assign blk_rst = rst;
			assign blk_clk = major_clk;

			// Replicate the hardware block.
			for (i=0; i<NUM_COPIES; i=i+1) begin: REPLICATE_BLOCK
				assign buffer_data_in[WIDTH_OUT_TOTAL*i+:WIDTH_OUT_TOTAL] = {blk_out__block_out[i]};
				assign blockoutput_data_outarray[WIDTH_OUT_BLOCKOUTPUT*i+:WIDTH_OUT_BLOCKOUTPUT] = buffer_data_out[WIDTH_OUT_TOTAL*i+:WIDTH_OUT_TOTAL];
				assign blk_in__block_in[i] = blockinput_data_inarray[WIDTH_IN_BLOCKINPUT*i+:WIDTH_IN_BLOCKINPUT];
				assign blk_in__iv[i] = iv_data_inarray[WIDTH_IN_IV*i+:WIDTH_IN_IV];
				assign blk_in__muxsel_iv[i] = muxsel_iv_data_inarray[WIDTH_IN_MUXSEL_IV*i+:WIDTH_IN_MUXSEL_IV];

				CSLOW_AES_CBC #(.Nb(Nb), .Nr(Nr), .C(1), .CSLOW_MODE(0), .ENC_MODE(ENC_MODE)) u_cslow_aes_cbc (
					.block_out(blk_out__block_out[i]),
					.block_in(blk_in__block_in[i]),
					.expanded_key(blk_common_in__expanded_key),
					.iv(blk_in__iv[i]),
					.muxsel_iv(blk_in__muxsel_iv[i]),
					.en(blk_en),
					.rst(blk_rst),
					.clk(blk_clk)
				);
			end

			// Valid register.
			reg valid;
			always @(posedge major_clk) begin
				if (rst) begin
					valid <= 1'b0;
				end
				else if (en) begin
					valid <= 1'b1;
				end
			end

			wire avail_outarray_I = valid & ~rst;
			assign buffer_avail_in = avail_outarray_I & en;
			assign en = avail_inarray & (buffer_ready_in | ~avail_outarray_I);

			buffer #(.WIDTH(ARRAY_WIDTH_OUT_TOTAL), .IMPL_TYPE("pipe_buf")) u_output_buf (
				.data_in(buffer_data_in),
				.avail_in(buffer_avail_in),
				.ready_in(buffer_ready_in),
				.data_out(buffer_data_out),
				.avail_out(avail_outarray),
				.ready_out(ready_outarray),
				.rst(rst),
				.clk(major_clk)
			);
		end
		else if (PAR_MODE == 1) begin     // Virtualized
			// Wires
			wire [ARRAY_WIDTH_IN_TOTAL-1:0] data_inarray;
			wire [WIDTH_COMMON_IN_TOTAL-1:0] common_in;
			wire [ARRAY_WIDTH_OUT_TOTAL-1:0] data_outarray;

			wire [WIDTH_IN_TOTAL-1:0] blk_in;
			wire [WIDTH_COMMON_IN_TOTAL-1:0] blk_common_in;
			wire [WIDTH_OUT_TOTAL-1:0] blk_out;
			wire blk_en;
			wire blk_rst;
			wire blk_clk;

			wire [WIDTH_OUT_BLOCKOUTPUT-1:0] blk_out__block_out;
			wire [WIDTH_IN_BLOCKINPUT-1:0] blk_in__block_in;
			wire [WIDTH_IN_IV-1:0] blk_in__iv;
			wire [WIDTH_IN_MUXSEL_IV-1:0] blk_in__muxsel_iv;
			wire [WIDTH_COMMON_IN_EXPANDED_KEY-1:0] blk_common_in__expanded_key;

			// Process the input/output arrays.
			for (i=0; i<NUM_COPIES; i=i+1) begin: PROCESS_ARRAYS
				// Pack input array.
				assign data_inarray[WIDTH_IN_TOTAL*i+:WIDTH_IN_TOTAL] = {
					blockinput_data_inarray[WIDTH_IN_BLOCKINPUT*i+:WIDTH_IN_BLOCKINPUT],
					iv_data_inarray[WIDTH_IN_IV*i+:WIDTH_IN_IV],
					muxsel_iv_data_inarray[WIDTH_IN_MUXSEL_IV*i+:WIDTH_IN_MUXSEL_IV]};

				// Unpack output array.
				assign {blockoutput_data_outarray[WIDTH_OUT_BLOCKOUTPUT*i+:WIDTH_OUT_BLOCKOUTPUT]} =
					data_outarray[WIDTH_OUT_TOTAL*i+:WIDTH_OUT_TOTAL];
			end
			assign common_in = expandedkey_data_common_in;

			// Unpack block inputs.
			assign {blk_in__block_in, blk_in__iv, blk_in__muxsel_iv} = blk_in;
			assign {blk_common_in__expanded_key} = blk_common_in;

			// Pack block outputs.
			assign blk_out = {blk_out__block_out};

			// CSPC major clock interface with round robin scheduling.
			cspc_major_clock_interface_rr_sched #(.NUM_PORTS(NUM_COPIES), .WIDTH_IN_PORT(WIDTH_IN_TOTAL),
				.WIDTH_IN_COMMON(WIDTH_COMMON_IN_TOTAL), .WIDTH_OUT_PORT(WIDTH_OUT_TOTAL)) u_interface (

				.data_inarray(data_inarray),
				.avail_inarray(avail_inarray),
				.ready_inarray(ready_inarray),
				.common_in(common_in),
				.data_outarray(data_outarray),
				.avail_outarray(avail_outarray),
				.ready_outarray(ready_outarray),
				.rst(rst),
				.minor_clk(minor_clk),
				.major_clk(major_clk),
				.blk_in(blk_in),
				.blk_common_in(blk_common_in),
				.blk_out(blk_out),
				.blk_en(blk_en),
				.blk_rst(blk_rst),
				.blk_clk(blk_clk)
			);

			// C-slowed AES Encryption / Decryption function hardware block.
			CSLOW_AES_CBC #(.Nb(Nb), .Nr(Nr), .C(NUM_COPIES), .CSLOW_MODE(CSLOW_MODE), .ENC_MODE(ENC_MODE)) u_cslow_aes_cbc (
				.block_out(blk_out__block_out),
				.block_in(blk_in__block_in),
				.expanded_key(blk_common_in__expanded_key),
				.iv(blk_in__iv),
				.muxsel_iv(blk_in__muxsel_iv),
				.en(blk_en),
				.rst(blk_rst),
				.clk(blk_clk)
			);
		end
	endgenerate
endmodule


module PARALLEL_AES_CBC_CI(shiftin_data, shiftin_last, shiftin_avail_in, shiftin_ready_in, shiftout_data, shiftout_avail_out, shiftout_ready_out,
	shiftout_first, shiftout_last, rst, minor_clk, major_clk);

	// Counts the number of bits in the number.
	function integer countbits;
		input integer num;
		integer bitcnt;
		begin
			bitcnt = 0;
			while (num > 0) begin
				num = num >> 1;
				bitcnt = bitcnt + 1;
			end
			if (bitcnt == 0) bitcnt = 1;
			countbits = bitcnt;
		end
	endfunction

	// Align to 32-bit depth value.
	function integer depth32;
		input integer x;
		begin
			if (x & 31)
				depth32 = ((x>>5)+1);
			else
				depth32 = (x>>5);
		end
	endfunction

	// Parameters.
	parameter Nb = 4;
	parameter Nr = 4;               // Number of rounds
	parameter NUM_COPIES = 2;       // Max performance should be NUM_COPIES=2*Nr.
	parameter CSLOW_MODE = 1;       // 0=state-only registers, 1=manually pipelined registers
	parameter ENC_MODE = 0;         // 0=encryption, 1=decryption
	parameter PAR_MODE = 1;         // 0=replicated, 1=virtualized (C-slow)

	localparam WIDTH_IN_BLOCKINPUT   = 32*Nb;
	localparam WIDTH_IN_IV           = 32*Nb;
	localparam WIDTH_IN_MUXSEL_IV    = 1;
	localparam WIDTH_IN_TOTAL        = WIDTH_IN_BLOCKINPUT + WIDTH_IN_IV + WIDTH_IN_MUXSEL_IV;

	localparam WIDTH_COMMON_IN_EXPANDED_KEY = 32*Nb*(Nr+1);
	localparam WIDTH_COMMON_IN_TOTAL        = WIDTH_COMMON_IN_EXPANDED_KEY;

	localparam WIDTH_OUT_BLOCKOUTPUT = 32*Nb;
	localparam WIDTH_OUT_TOTAL       = WIDTH_OUT_BLOCKOUTPUT;

	localparam ARRAY_WIDTH_IN_BLOCKINPUT   = NUM_COPIES * WIDTH_IN_BLOCKINPUT;
	localparam ARRAY_WIDTH_IN_IV           = NUM_COPIES * WIDTH_IN_IV;
	localparam ARRAY_WIDTH_IN_MUXSEL_IV    = NUM_COPIES * WIDTH_IN_MUXSEL_IV;
	localparam ARRAY_WIDTH_IN_TOTAL        = NUM_COPIES * WIDTH_IN_TOTAL;

	localparam ARRAY_WIDTH_OUT_BLOCKOUTPUT = NUM_COPIES * WIDTH_OUT_BLOCKOUTPUT;
	localparam ARRAY_WIDTH_OUT_TOTAL       = NUM_COPIES * WIDTH_OUT_TOTAL;

	localparam TOTAL_INPUT_BITS  = ARRAY_WIDTH_IN_TOTAL + WIDTH_COMMON_IN_TOTAL;
	localparam TOTAL_OUTPUT_BITS = ARRAY_WIDTH_OUT_TOTAL;

	localparam SR_INPUT_DEPTH    = depth32(TOTAL_INPUT_BITS);
	localparam SR_OUTPUT_DEPTH   = depth32(TOTAL_OUTPUT_BITS);

	localparam SR_INPUT_ARRAY_WIDTH  = 32 * SR_INPUT_DEPTH;
	localparam SR_OUTPUT_ARRAY_WIDTH = 32 * SR_OUTPUT_DEPTH;

	localparam EXTRA_INPUT_BITS  = SR_INPUT_ARRAY_WIDTH  - TOTAL_INPUT_BITS;
	localparam EXTRA_OUTPUT_BITS = SR_OUTPUT_ARRAY_WIDTH - TOTAL_OUTPUT_BITS;

	localparam SR_INPUT_CNT_BITS  = countbits(SR_INPUT_DEPTH);
	localparam SR_OUTPUT_CNT_BITS = countbits(SR_OUTPUT_DEPTH);

	// Port declaration.
	input wire [31:0] shiftin_data;
	input wire shiftin_last;
	input wire shiftin_avail_in;
	output wire shiftin_ready_in;
	output wire [31:0] shiftout_data;
	output wire shiftout_avail_out;
	input wire shiftout_ready_out;
	output wire shiftout_first;
	output wire shiftout_last;
	input wire rst;
	input wire minor_clk;
	input wire major_clk;

	// Wires.
	wire [SR_INPUT_ARRAY_WIDTH-1:0] shiftin_outarray;
	wire [SR_OUTPUT_ARRAY_WIDTH-1:0] shiftout_inarray;

	wire [ARRAY_WIDTH_IN_BLOCKINPUT-1:0] blockinput_data_inarray;
	wire [ARRAY_WIDTH_IN_IV-1:0] iv_data_inarray;
	wire [ARRAY_WIDTH_IN_MUXSEL_IV-1:0] muxsel_iv_data_inarray;
	wire [WIDTH_COMMON_IN_EXPANDED_KEY-1:0] expandedkey_data_common_in;
	wire [ARRAY_WIDTH_OUT_BLOCKOUTPUT-1:0] blockoutput_data_outarray;

	wire blk_avail_in;
	wire blk_ready_in;
	wire blk_avail_out;
	wire blk_ready_out;

	// Assignments.
	assign {blockinput_data_inarray, iv_data_inarray, muxsel_iv_data_inarray, expandedkey_data_common_in} =
		shiftin_outarray[SR_INPUT_ARRAY_WIDTH-1:(SR_INPUT_ARRAY_WIDTH-TOTAL_INPUT_BITS)];
	assign shiftout_inarray[SR_OUTPUT_ARRAY_WIDTH-1:SR_OUTPUT_ARRAY_WIDTH-TOTAL_OUTPUT_BITS] =
		{blockoutput_data_outarray};
	generate
		if (EXTRA_OUTPUT_BITS > 0) begin
			assign shiftout_inarray[EXTRA_OUTPUT_BITS-1:0] = {EXTRA_OUTPUT_BITS{1'b0}};
		end
	endgenerate

	// Parallel AES CBC block.
	PARALLEL_AES_CBC #(.Nb(Nb), .Nr(Nr), .NUM_COPIES(NUM_COPIES), .CSLOW_MODE(CSLOW_MODE),
		.ENC_MODE(ENC_MODE), .PAR_MODE(PAR_MODE)) u_par_aes_cbc (

		.blockinput_data_inarray(blockinput_data_inarray),
		.iv_data_inarray(iv_data_inarray),
		.muxsel_iv_data_inarray(muxsel_iv_data_inarray),
		.expandedkey_data_common_in(expandedkey_data_common_in),
		.avail_inarray(blk_avail_in),
		.ready_inarray(blk_ready_in),
		.blockoutput_data_outarray(blockoutput_data_outarray),
		.avail_outarray(blk_avail_out),
		.ready_outarray(blk_ready_out),
		.rst(rst),
		.minor_clk(minor_clk),
		.major_clk(major_clk)
	);

	// Serial-to-parallel converter.
	ser2par #(.SERIN_WIDTH(32), .SERIN_DEPTH(SR_INPUT_DEPTH)) u_ser2par_in (
		.serin_data(shiftin_data),
		.serin_last(shiftin_last),
		.serin_avail_in(shiftin_avail_in),
		.serin_ready_in(shiftin_ready_in),
		.parout_data(shiftin_outarray),
		.parout_avail_out(blk_avail_in),
		.parout_ready_out(blk_ready_in),
		.rst(rst),
		.clk(major_clk)
	);

	// Parallel-to-serial converter.
	par2ser #(.SEROUT_WIDTH(32), .SEROUT_DEPTH(SR_OUTPUT_DEPTH)) u_par2ser_out (
		.parin_data(shiftout_inarray),
		.parin_avail_in(blk_avail_out),
		.parin_ready_in(blk_ready_out),
		.serout_data(shiftout_data),
		.serout_first(shiftout_first),
		.serout_last(shiftout_last),
		.serout_avail_out(shiftout_avail_out),
		.serout_ready_out(shiftout_ready_out),
		.rst(rst),
		.clk(major_clk)
	);
endmodule


module PARALLEL_AES_CBC_CI_2(shiftin_data, shiftin_last, shiftin_avail_in, shiftin_ready_in, shiftout_data, shiftout_avail_out, shiftout_ready_out,
	shiftout_first, shiftout_last, rst, minor_clk, major_clk);

	/* This module (so to speak) is needed by the RTL compiler tool, otherwise it generates an error when calling functions 
	   defined in the module.  Since this module contains no functions nor makes any function calls, then RTL compiler
	   will NOT produce any errors. */

	// Parameters.
	parameter Nb = 4;
	parameter Nr = 4;               // Number of rounds
	parameter NUM_COPIES = 2;       // Max performance should be NUM_COPIES=2*Nr.
	parameter CSLOW_MODE = 1;       // 0=state-only registers, 1=manually pipelined registers
	parameter ENC_MODE = 0;         // 0=encryption, 1=decryption
	parameter PAR_MODE = 1;         // 0=replicated, 1=virtualized (C-slow)

	// Port declaration.
	input wire [31:0] shiftin_data;
	input wire shiftin_last;
	input wire shiftin_avail_in;
	output wire shiftin_ready_in;
	output wire [31:0] shiftout_data;
	output wire shiftout_avail_out;
	input wire shiftout_ready_out;
	output wire shiftout_first;
	output wire shiftout_last;
	input wire rst;
	input wire minor_clk;
	input wire major_clk;

	// Parallel AES CBC_CI block.
	PARALLEL_AES_CBC_CI #(
		.Nb(Nb),
		.Nr(Nr),
		.NUM_COPIES(NUM_COPIES),
		.CSLOW_MODE(CSLOW_MODE),
		.ENC_MODE(ENC_MODE),
		.PAR_MODE(PAR_MODE)) u_par_aes_cbc_ci (

		.shiftin_data(shiftin_data),
		.shiftin_last(shiftin_last),
		.shiftin_avail_in(shiftin_avail_in),
		.shiftin_ready_in(shiftin_ready_in),
		.shiftout_data(shiftout_data),
		.shiftout_avail_out(shiftout_avail_out),
		.shiftout_ready_out(shiftout_ready_out),
		.shiftout_first(shiftout_first),
		.shiftout_last(shiftout_last),
		.rst(rst),
		.minor_clk(minor_clk),
		.major_clk(major_clk)
	);
endmodule

