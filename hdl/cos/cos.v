// Developed by Michael J. Hall.  This is being placed in the public domain.

`timescale 1ns / 1ps
`default_nettype none

/********************************************************************************
Company:      Washington University in St. Louis
Engineer:     Michael Hall
Module Name:  COS_taylor
Description:  Cosine transcendental function calculated by Taylor series.
*********************************************************************************/
module COS_taylor(x, result);

	// Parameters
	parameter NUM_TERMS = 20;

	// Port declaration
	input wire signed [15:0] x;             // Q3.12
	output wire signed [15:0] result;       // Q1.14

	localparam coeffs_xa_rs = -2;
	wire signed [17:0] coeffs [0:24];
	wire signed [8:0] coeffs_mr_rightshift [0:24];

	// Define all of the coefficient constants.
	assign coeffs[ 0] = 18'h1_0000;    // Q1.16 signed       (x^0 term)
	assign coeffs[ 1] = 18'h3_0000;    // Q0.17 signed       (x^2 term)
	assign coeffs[ 2] = 18'h1_5555;    // Q-4.21 signed      (x^4 term)
	assign coeffs[ 3] = 18'h2_93e9;    // Q-9.26 signed      (x^6 term)
	assign coeffs[ 4] = 18'h1_a01a;    // Q-15.32 signed     (x^8 term)
	assign coeffs[ 5] = 18'h2_d81b;    // Q-21.38 signed     (x^10 term)
	assign coeffs[ 6] = 18'h1_1eee;    // Q-28.45 signed     (x^12 term)
	assign coeffs[ 7] = 18'h2_6c69;    // Q-36.53 signed     (x^14 term)
	assign coeffs[ 8] = 18'h1_ae7f;    // Q-44.61 signed     (x^16 term)
	assign coeffs[ 9] = 18'h2_97d8;    // Q-52.69 signed     (x^18 term)
	assign coeffs[10] = 18'h1_e543;    // Q-61.78 signed     (x^20 term)
	assign coeffs[11] = 18'h2_f31c;    // Q-69.86 signed     (x^22 term)
	assign coeffs[12] = 18'h1_f2cf;    // Q-79.96 signed     (x^24 term)
	assign coeffs[13] = 18'h2_7718;    // Q-88.105 signed    (x^26 term)
	assign coeffs[14] = 18'h1_0a19;    // Q-97.114 signed    (x^28 term)
	assign coeffs[15] = 18'h2_c6cd;    // Q-107.124 signed   (x^30 term)
	assign coeffs[16] = 18'h1_434d;    // Q-117.134 signed   (x^32 term)
	assign coeffs[17] = 18'h2_d8f0;    // Q-127.144 signed   (x^34 term)
	assign coeffs[18] = 18'h1_df98;    // Q-138.155 signed   (x^36 term)
	assign coeffs[19] = 18'h2_a2b5;    // Q-148.165 signed   (x^38 term)
	assign coeffs[20] = 18'h1_ca8f;    // Q-159.176 signed   (x^40 term)
	assign coeffs[21] = 18'h2_ef51;    // Q-169.186 signed   (x^42 term)
	assign coeffs[22] = 18'h1_272b;    // Q-180.197 signed   (x^44 term)
	assign coeffs[23] = 18'h2_dbf8;    // Q-191.208 signed   (x^46 term)
	assign coeffs[24] = 18'h0_4247;    // Q-200.217 signed   (x^48 term)

	// Define the right shift amounts after the constant multiplication with each x term.
	assign coeffs_mr_rightshift[ 0] = 2;
	assign coeffs_mr_rightshift[ 1] = 14;
	assign coeffs_mr_rightshift[ 2] = 12;
	assign coeffs_mr_rightshift[ 3] = 11;
	assign coeffs_mr_rightshift[ 4] = 11;
	assign coeffs_mr_rightshift[ 5] = 11;
	assign coeffs_mr_rightshift[ 6] = 12;
	assign coeffs_mr_rightshift[ 7] = 14;
	assign coeffs_mr_rightshift[ 8] = 16;
	assign coeffs_mr_rightshift[ 9] = 18;
	assign coeffs_mr_rightshift[10] = 21;
	assign coeffs_mr_rightshift[11] = 23;
	assign coeffs_mr_rightshift[12] = 27;
	assign coeffs_mr_rightshift[13] = 30;
	assign coeffs_mr_rightshift[14] = 33;
	assign coeffs_mr_rightshift[15] = 37;
	assign coeffs_mr_rightshift[16] = 41;
	assign coeffs_mr_rightshift[17] = 45;
	assign coeffs_mr_rightshift[18] = 50;
	assign coeffs_mr_rightshift[19] = 54;
	assign coeffs_mr_rightshift[20] = 59;
	assign coeffs_mr_rightshift[21] = 63;
	assign coeffs_mr_rightshift[22] = 68;
	assign coeffs_mr_rightshift[23] = 73;
	assign coeffs_mr_rightshift[24] = 76;

	// Define all intermediate results.
	wire signed [35:0] xi [2:(NUM_TERMS-1)*2];   // Raw result of "x" term multiplications (36-bit).
	wire signed [17:0] xp [1:(NUM_TERMS-1)*2];   // Shifted result of "x" term multiplication (18-bit).
	wire signed [35:0] mi [0:NUM_TERMS-1];       // Raw result of constant coefficient multiplication with "x" term (36-bit).
	wire signed [15:0] mr [0:NUM_TERMS-1];       // Shifted result of constant coefficient multiplication with "x" term (18-bit).
	wire signed [15:0] csum [0:NUM_TERMS-1];     // Cumulative sum result of results for all terms.

	// Multiply "x" term to get a chain of "x^p" terms:  "x", "x^2", "x^4", "x^6", etc.
	genvar i;
	generate
		assign xp[1] = (coeffs_xa_rs > 0 ? x >>> coeffs_xa_rs : x <<< (-coeffs_xa_rs));
		for (i=2; i<=(NUM_TERMS-1)*2; i=i+1) begin: BLK1
			assign xi[i] = xp[i-1]*xp[1];             // 20 multipliers
			assign xp[i] = xi[i] >>> 17;
		end
	endgenerate

	// Multiply each the even "x^p" terms by its corresponding coefficient.
	genvar j;
	generate
		assign mi[0] = coeffs[0];
		for (j=1; j<NUM_TERMS; j=j+1) begin: BLK2
			assign mi[j] = coeffs[j] * xp[j*2];       // 11 multipliers
		end
	endgenerate

	// Right shift all multiplied terms to get it into the final result form (Q1.14).
	genvar k;
	generate
		for (k=0; k<NUM_TERMS; k=k+1) begin: BLK3
			assign mr[k] = (coeffs_mr_rightshift[k] >= 0 ? mi[k] >>> coeffs_mr_rightshift[k] : 
								 mi[k] <<< (-coeffs_mr_rightshift[k]));
		end
	endgenerate

	// Cumulatively add all results.
	genvar m;
	generate
		assign csum[0] = mr[0];
		for (m=1; m<NUM_TERMS; m=m+1) begin: BLK4
			assign csum[m] = csum[m-1] + mr[m];
		end
	endgenerate

	// Return the final result.
	assign result = csum[NUM_TERMS-1];
endmodule


/********************************************************************************
Company:      Washington University in St. Louis
Engineer:     Michael Hall
Module Name:  COS_taylor_pipelined
Description:  Cosine transcendental function calculated by Taylor series.
*********************************************************************************/
module COS_taylor_pipelined(x, result, en, clk);

	// Parameters
	parameter NUM_TERMS = 12;
	parameter C = 5;
	parameter FB = 2'b11;

	localparam PR_MASK_SIZE = (NUM_TERMS-1)*4;     // <-- This is the maximum number of registers that can be instantiated.

	// Note, registers are doubled up in here.  Realistically, the performance limit is seen when we consider
	// only one register instantiated in each of the double register pairs.  This can be calculated as:
	//    MaxC = (NUM_TERMS-1)*2 + 1;

	function real i2r;
		input integer i;
		begin
			i2r = i * 1.0;
		end
	endfunction

	function integer r2i;
		input real r;
		begin
			r2i = r;
		end
	endfunction

	function [95:0] generate_pr_mask;
		input integer C;
		input [1:0] FB;
		input integer PR_MASK_SIZE;
		reg [95:0] pr_mask;
		integer Cp;
		reg frontR, backR;
		integer i;
		real m;
		begin
			// Determine the front, back, and mid pipeline registers to set.
			frontR = FB[1];
			backR  = FB[0];
			if (C == 0) begin
				frontR = 1'b0;
				backR = 1'b0;
				Cp = 0;
			end
			else if (C == 1) begin
				if (backR) begin
					frontR = 1'b0;
					Cp = 1;
				end
				else if (frontR)
					Cp = 0;
				else
					Cp = 2;
			end
			else begin
				if (!frontR && !backR) Cp = C + 1;
				else if (frontR && backR) Cp = C - 1;
				else Cp = C;
			end

			// Set the pipeline registers mask for the mid registers first.
			for (i=0; i<PR_MASK_SIZE; i=i+1)
				pr_mask[i] = 1'b0;
			m = i2r(PR_MASK_SIZE) / i2r(Cp);
			for (i=0; i<(Cp-1); i=i+1)
				pr_mask[r2i(m*(i2r(i)+1.0)-1.0)] = 1'b1;

			// Set the front and back registers next.
			if (frontR) pr_mask[0] = 1'b1;
			if (backR) pr_mask[PR_MASK_SIZE-1] = 1'b1;

			// Return the pipeline register mask.
			generate_pr_mask = pr_mask;
		end
	endfunction

	function integer count_ones;
		input [95:0] in;
		input integer PR_MASK_SIZE;
		integer ones;
		integer i;
		begin
			ones = 0;
			for (i=0; i<PR_MASK_SIZE; i=i+1) begin
				if (in[i]) ones = ones + 1;
			end
			count_ones = ones;
		end
	endfunction

	localparam [95:0] pr_mask_tmp = generate_pr_mask(C, FB, PR_MASK_SIZE);
	localparam [PR_MASK_SIZE-1:0] PR_MASK = pr_mask_tmp[PR_MASK_SIZE-1:0];
	localparam PR_MASK_REG_COUNT = count_ones(pr_mask_tmp, PR_MASK_SIZE);
	localparam EXTRA_REGS = (C > PR_MASK_REG_COUNT ? C-PR_MASK_REG_COUNT : 0);

	// Port declaration
	input wire signed [15:0] x;             // Q3.12
	output wire signed [15:0] result;       // Q1.14
	input wire en;
	input wire clk;

	localparam coeffs_xa_rs = -2;
	wire signed [17:0] coeffs [0:24];
	wire signed [8:0] coeffs_mr_rightshift [0:24];

	// Define all of the coefficient constants.
	assign coeffs[ 0] = 18'h1_0000;    // Q1.16 signed       (x^0 term)
	assign coeffs[ 1] = 18'h3_0000;    // Q0.17 signed       (x^2 term)
	assign coeffs[ 2] = 18'h1_5555;    // Q-4.21 signed      (x^4 term)
	assign coeffs[ 3] = 18'h2_93e9;    // Q-9.26 signed      (x^6 term)
	assign coeffs[ 4] = 18'h1_a01a;    // Q-15.32 signed     (x^8 term)
	assign coeffs[ 5] = 18'h2_d81b;    // Q-21.38 signed     (x^10 term)
	assign coeffs[ 6] = 18'h1_1eee;    // Q-28.45 signed     (x^12 term)
	assign coeffs[ 7] = 18'h2_6c69;    // Q-36.53 signed     (x^14 term)
	assign coeffs[ 8] = 18'h1_ae7f;    // Q-44.61 signed     (x^16 term)
	assign coeffs[ 9] = 18'h2_97d8;    // Q-52.69 signed     (x^18 term)
	assign coeffs[10] = 18'h1_e543;    // Q-61.78 signed     (x^20 term)
	assign coeffs[11] = 18'h2_f31c;    // Q-69.86 signed     (x^22 term)
	assign coeffs[12] = 18'h1_f2cf;    // Q-79.96 signed     (x^24 term)
	assign coeffs[13] = 18'h2_7718;    // Q-88.105 signed    (x^26 term)
	assign coeffs[14] = 18'h1_0a19;    // Q-97.114 signed    (x^28 term)
	assign coeffs[15] = 18'h2_c6cd;    // Q-107.124 signed   (x^30 term)
	assign coeffs[16] = 18'h1_434d;    // Q-117.134 signed   (x^32 term)
	assign coeffs[17] = 18'h2_d8f0;    // Q-127.144 signed   (x^34 term)
	assign coeffs[18] = 18'h1_df98;    // Q-138.155 signed   (x^36 term)
	assign coeffs[19] = 18'h2_a2b5;    // Q-148.165 signed   (x^38 term)
	assign coeffs[20] = 18'h1_ca8f;    // Q-159.176 signed   (x^40 term)
	assign coeffs[21] = 18'h2_ef51;    // Q-169.186 signed   (x^42 term)
	assign coeffs[22] = 18'h1_272b;    // Q-180.197 signed   (x^44 term)
	assign coeffs[23] = 18'h2_dbf8;    // Q-191.208 signed   (x^46 term)
	assign coeffs[24] = 18'h0_4247;    // Q-200.217 signed   (x^48 term)

	// Define the right shift amounts after the constant multiplication with each x term.
	assign coeffs_mr_rightshift[ 0] = 2;
	assign coeffs_mr_rightshift[ 1] = 14;
	assign coeffs_mr_rightshift[ 2] = 12;
	assign coeffs_mr_rightshift[ 3] = 11;
	assign coeffs_mr_rightshift[ 4] = 11;
	assign coeffs_mr_rightshift[ 5] = 11;
	assign coeffs_mr_rightshift[ 6] = 12;
	assign coeffs_mr_rightshift[ 7] = 14;
	assign coeffs_mr_rightshift[ 8] = 16;
	assign coeffs_mr_rightshift[ 9] = 18;
	assign coeffs_mr_rightshift[10] = 21;
	assign coeffs_mr_rightshift[11] = 23;
	assign coeffs_mr_rightshift[12] = 27;
	assign coeffs_mr_rightshift[13] = 30;
	assign coeffs_mr_rightshift[14] = 33;
	assign coeffs_mr_rightshift[15] = 37;
	assign coeffs_mr_rightshift[16] = 41;
	assign coeffs_mr_rightshift[17] = 45;
	assign coeffs_mr_rightshift[18] = 50;
	assign coeffs_mr_rightshift[19] = 54;
	assign coeffs_mr_rightshift[20] = 59;
	assign coeffs_mr_rightshift[21] = 63;
	assign coeffs_mr_rightshift[22] = 68;
	assign coeffs_mr_rightshift[23] = 73;
	assign coeffs_mr_rightshift[24] = 76;

	// Define all intermediate results.
	wire signed [15:0] x_after_extra_regs;
	wire signed [17:0] x_pipelined[0:NUM_TERMS*4-7];
	wire signed [35:0] x_multraw [2:(NUM_TERMS-1)*2];     // Raw result of "x" term multiplications (36-bit).
	wire signed [17:0] x_multshift_1 [2:(NUM_TERMS-1)*2]; // Shifted result of "x" term multiplication (18-bit).
	wire signed [17:0] x_multshift_2 [2:(NUM_TERMS-1)*2];
	wire signed [17:0] x_power [1:(NUM_TERMS-1)*2];       // Shifted result of "x" term multiplication (18-bit).
	wire signed [35:0] mi [0:NUM_TERMS-1];        // Raw result of constant coefficient multiplication with "x" term (36-bit).
	wire signed [15:0] mr [0:NUM_TERMS-1];        // Shifted result of constant coefficient multiplication with "x" term (18-bit).
	wire signed [15:0] csum [0:NUM_TERMS-1];      // Cumulative sum result of results for all terms.
	wire signed [15:0] csum_i1 [1:NUM_TERMS-1];   // Intermediate sum result 1.
	wire signed [15:0] csum_i2 [1:NUM_TERMS-1];   // Intermediate sum result 2.
	wire signed [15:0] csum_i3 [1:NUM_TERMS-1];   // Intermediate sum result 3.
	wire signed [15:0] csum_i4 [1:NUM_TERMS-1];   // Intermediate sum result 4.

	// Add extra pipeline registers on the "x" input for C > PR_MASK_SIZE.
	pipe_reg_en #(.WIDTH(16), .DEPTH(EXTRA_REGS)) u_pipe_reg_x_extraregs (
		.in(x), .out(x_after_extra_regs), .en(en), .clk(clk));

	// Pipeline the "x" input at each point of the "x^p" multiplier chain.
	genvar h;
	generate
		assign x_pipelined[0] = (coeffs_xa_rs > 0 ? x_after_extra_regs >>> coeffs_xa_rs :
			                                         x_after_extra_regs <<< (-coeffs_xa_rs));
		pipe_reg_en #(.WIDTH(18), .DEPTH(PR_MASK[0])) u_pipereg_x_1 (
			.in(x_pipelined[0]), .out(x_pipelined[1]), .en(en), .clk(clk));
		for (h=1; h<=NUM_TERMS*4-8; h=h+2) begin: PIPE1
			pipe_reg_en #(.WIDTH(18), .DEPTH(PR_MASK[h])) u_pipereg_x_1 (
				.in(x_pipelined[h]), .out(x_pipelined[h+1]), .en(en), .clk(clk));
			pipe_reg_en #(.WIDTH(18), .DEPTH(PR_MASK[h+1])) u_pipereg_x_2 (
				.in(x_pipelined[h+1]), .out(x_pipelined[h+2]), .en(en), .clk(clk));
		end
	endgenerate

	// Multiply "x" term to get a chain of "x^p" terms:  "x", "x^2", "x^4", "x^6", etc.
	genvar i;
	generate
		assign x_power[1] = x_pipelined[1];
		for (i=2; i<=(NUM_TERMS-1)*2; i=i+1) begin: BLK1
			assign x_multraw[i]   = x_power[i-1]*x_pipelined[2*i-3];
			assign x_multshift_1[i] = x_multraw[i] >>> 17;
			pipe_reg_en #(.WIDTH(18), .DEPTH(PR_MASK[2*i-3])) u_pipereg_x_power_1 (
				.in(x_multshift_1[i]), .out(x_multshift_2[i]), .en(en), .clk(clk));
			pipe_reg_en #(.WIDTH(18), .DEPTH(PR_MASK[2*i-2])) u_pipereg_x_power_2 (
				.in(x_multshift_2[i]), .out(x_power[i]), .en(en), .clk(clk));
		end
	endgenerate

	// Multiply each even "x^p" term by its corresponding coefficient.
	genvar j;
	generate
		assign mi[0] = coeffs[0];
		for (j=1; j<NUM_TERMS; j=j+1) begin: BLK2
			assign mi[j] = coeffs[j] * x_power[j*2];
		end
	endgenerate

	// Right shift all multiplied terms to get it into the final result form (Q1.14).
	genvar k;
	generate
		for (k=0; k<NUM_TERMS; k=k+1) begin: BLK3
			assign mr[k] = (coeffs_mr_rightshift[k] >= 0 ? mi[k] >>> coeffs_mr_rightshift[k] : 
								 mi[k] <<< (-coeffs_mr_rightshift[k]));
		end
	endgenerate

	// Cumulatively add all results.
	genvar m, n;
	generate
		assign csum[0] = mr[0];
		for (m=1; m<NUM_TERMS; m=m+1) begin: BLK4
			assign csum_i1[m] = csum[m-1] + mr[m];
			pipe_reg_en #(.WIDTH(16), .DEPTH(PR_MASK[4*m-1])) u_pipereg_csum_1 (
				.in(csum_i1[m]), .out(csum_i2[m]), .en(en), .clk(clk));
			pipe_reg_en #(.WIDTH(16), .DEPTH((m<NUM_TERMS-1) ? PR_MASK[4*m] : 0)) u_pipereg_csum_2 (
				.in(csum_i2[m]), .out(csum_i3[m]), .en(en), .clk(clk));
			pipe_reg_en #(.WIDTH(16), .DEPTH((m<NUM_TERMS-1) ? PR_MASK[4*m+1] : 0)) u_pipereg_csum_3 (
				.in(csum_i3[m]), .out(csum_i4[m]), .en(en), .clk(clk));
			pipe_reg_en #(.WIDTH(16), .DEPTH((m<NUM_TERMS-1) ? PR_MASK[4*m+2] : 0)) u_pipereg_csum_4 (
				.in(csum_i4[m]), .out(csum[m]), .en(en), .clk(clk));
		end
	endgenerate

	// Return the final result.
	assign result = csum[NUM_TERMS-1];
endmodule


/********************************************************************************
Company:      Washington University in St. Louis
Engineer:     Michael Hall
Module Name:  COS_feedback_app
Description:  Cosine with feedback reusable hardware block.
*********************************************************************************/
module COS_feedback_app(in, out, rst, en, clk, state_sum_d, state_sum_q);

	// Parameters
	parameter NUM_TERMS = 12;
	parameter C = 4;
	parameter FB = 2'b11;

	localparam WIDTH_IN  = 16;
	localparam WIDTH_OUT = 16;

	// Port declaration
	input wire signed [WIDTH_IN-1:0] in;            // Q3.12
	output wire signed [WIDTH_OUT-1:0] out;         // Q1.14
	input wire rst;
	input wire en;
	input wire clk;

	// Wires
	wire [WIDTH_IN-1:0]  cos_in;
	wire [WIDTH_OUT-1:0] cos_result;

	// State signals
	output reg [WIDTH_OUT-1:0] state_sum_d;     // Q1.14
	input wire [WIDTH_OUT-1:0] state_sum_q;     // Q1.14

	COS_taylor_pipelined #(
		.NUM_TERMS(NUM_TERMS),
		.C(C),
		.FB(FB)
	) u_cos (
		.x(cos_in),
		.result(cos_result),
		.en(en),
		.clk(clk)
	);

	// Combinational logic
	always @(*) begin
		if (rst) begin
			state_sum_d <= {WIDTH_OUT{1'b0}};
		end
		else begin
			state_sum_d <= cos_result;          // Q1.14
		end
	end
	assign cos_in = in + ($signed(state_sum_q) >>> 2);   // Q3.12
	assign out = state_sum_q;                   // Q1.14
endmodule


/********************************************************************************
Company:      Washington University in St. Louis
Engineer:     Michael Hall
Module Name:  CSLOW_COS_feedback_app
Description:  Cosine-feedback reusable hardware block.
*********************************************************************************/
module CSLOW_COS_feedback_app(in, out, en, rst, clk);
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

	function GetFB;
		input integer NUM_TERMS;
		input integer C;
		begin
			if (C > ((NUM_TERMS-1)*2))
				GetFB = 2'b10;
			else
				GetFB = 2'b00;
		end
	endfunction

	parameter NUM_TERMS = 12;
	parameter C = 4;

	localparam WIDTH_IN  = 16;
	localparam WIDTH_OUT = 16;
	localparam WIDTH_STATE = WIDTH_OUT;

	localparam PR_MASK_SIZE = (NUM_TERMS-1)*4;
	localparam FB = GetFB(NUM_TERMS, C);
	localparam PE_COUNTER_WIDTH = countbits(C);

	// Port declaration
	input wire signed [WIDTH_IN-1:0] in;
	output wire signed [WIDTH_OUT-1:0] out;
	input wire en;
	input wire rst;
	input wire clk;

	// Wires
	wire rst_extended;

	// State signals
	wire [WIDTH_OUT-1:0] state_sum_d, state_sum_q;

	// Extend reset
	pulse_extender #(
		.COUNTER_WIDTH(PE_COUNTER_WIDTH)
	) uut (
		.out(rst_extended),
		.in(rst),
		.pulse_extended_count(C),
		.en(en),
		.clk(clk)
	);

	// Pipeline state registers
	state_en #(
		.WIDTH(WIDTH_STATE),
		.C(1)
	) p_sum (
		.d(state_sum_d),
		.q(state_sum_q),
		.en(en),
		.rst(1'b0),
		.clk(clk)
	);

	// Instantiation
	COS_feedback_app #(
		.NUM_TERMS(NUM_TERMS),
		.C(C-1),
		.FB(FB)
	) u_acc (
		.in(in),
		.out(out),
		.rst(rst_extended),
		.en(en),
		.clk(clk),
		.state_sum_d(state_sum_d),
		.state_sum_q(state_sum_q)
	);
endmodule


/********************************************************************************
Company:      Washington University in St. Louis
Engineer:     Michael Hall
Module Name:  PARALLEL_COS_feedback_app
Description:  Parallelized Cosine-feedback block implementation.
*********************************************************************************/
module PARALLEL_COS_feedback_app(input_inarray, avail_inarray, ready_inarray,
	output_outarray, avail_outarray, ready_outarray, rst, minor_clk, major_clk);

	/*
		A parallelized block processes N data streams.  Each data stream has its own input and output port.
		Also, all data streams share a common input port.  The ports are provided as arrays called "inarray"
		and "outarray".
	*/

	// Parameters
	parameter NUM_TERMS  = 12;
	parameter NUM_COPIES = 1;
	parameter CSLOW_MODE = 1;       // 0=state-only registers, 1=manually pipelined registers
	parameter PAR_MODE = 1;         // 0=replicated, 1=virtualized (C-slow)

	localparam WIDTH_IN  = 16;
	localparam WIDTH_OUT = 16;
	localparam ARRAY_WIDTH_IN = WIDTH_IN * NUM_COPIES;
	localparam ARRAY_WIDTH_OUT = WIDTH_OUT * NUM_COPIES;

	// Port declaration
	input wire [ARRAY_WIDTH_IN-1:0] input_inarray;
	input wire avail_inarray;
	output wire ready_inarray;
	output wire [ARRAY_WIDTH_OUT-1:0] output_outarray;
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

			wire [WIDTH_OUT-1:0] blk_out [0:NUM_COPIES-1];
			wire [WIDTH_IN-1:0] blk_in [0:NUM_COPIES-1];

			wire [ARRAY_WIDTH_OUT-1:0] buffer_data_in;
			wire buffer_avail_in;
			wire buffer_ready_in;
			wire [ARRAY_WIDTH_OUT-1:0] buffer_data_out;

			assign ready_inarray = en | ~avail_inarray;

			assign blk_en = en | rst;
			assign blk_rst = rst;
			assign blk_clk = major_clk;

			// Replicate the hardware block.
			for (i=0; i<NUM_COPIES; i=i+1) begin: REPLICATE_BLOCK
				assign buffer_data_in[WIDTH_OUT*i+:WIDTH_OUT] = {blk_out[i]};
				assign output_outarray[WIDTH_OUT*i+:WIDTH_OUT] = buffer_data_out[WIDTH_OUT*i+:WIDTH_OUT];
				assign blk_in[i] = input_inarray[WIDTH_IN*i+:WIDTH_IN];

				CSLOW_COS_feedback_app #(
					.NUM_TERMS(NUM_TERMS),
					.C(1)
				) u_cslow_cos (
					.in(blk_in[i]),
					.out(blk_out[i]),
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

			buffer #(
				.WIDTH(ARRAY_WIDTH_OUT),
				.IMPL_TYPE("pipe_buf")
			) u_output_buf (
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
			wire [ARRAY_WIDTH_IN-1:0] data_inarray;
			wire [ARRAY_WIDTH_OUT-1:0] data_outarray;

			wire [WIDTH_IN-1:0] blk_in;
			wire [WIDTH_OUT-1:0] blk_out;
			wire blk_en;
			wire blk_rst;
			wire blk_clk;

			// Process the input/output arrays.
			for (i=0; i<NUM_COPIES; i=i+1) begin: PROCESS_ARRAYS
				// Pack input array.
				assign data_inarray[WIDTH_IN*i+:WIDTH_IN] = {input_inarray[WIDTH_IN*i+:WIDTH_IN]};

				// Unpack output array.
				assign {output_outarray[WIDTH_OUT*i+:WIDTH_OUT]} = data_outarray[WIDTH_OUT*i+:WIDTH_OUT];
			end

			// CSPC major clock interface with round robin scheduling.
			cspc_major_clock_interface_rr_sched #(
				.NUM_PORTS(NUM_COPIES),
				.WIDTH_IN_PORT(WIDTH_IN),
				.WIDTH_IN_COMMON(0),
				.WIDTH_OUT_PORT(WIDTH_OUT)
			) u_interface (
				.data_inarray(data_inarray),
				.avail_inarray(avail_inarray),
				.ready_inarray(ready_inarray),
				.common_in(),
				.data_outarray(data_outarray),
				.avail_outarray(avail_outarray),
				.ready_outarray(ready_outarray),
				.rst(rst),
				.minor_clk(minor_clk),
				.major_clk(major_clk),
				.blk_in(blk_in),
				.blk_common_in(),
				.blk_out(blk_out),
				.blk_en(blk_en),
				.blk_rst(blk_rst),
				.blk_clk(blk_clk)
			);

			// C-slowed transcendental feedback function hardware block.
			CSLOW_COS_feedback_app #(
				.NUM_TERMS(NUM_TERMS),
				.C(NUM_COPIES)
			) u_cslow_cos (
				.in(blk_in),
				.out(blk_out),
				.en(blk_en),
				.rst(blk_rst),
				.clk(blk_clk)
			);
		end
	endgenerate
endmodule


module PARALLEL_COS_feedback_app_CI(shiftin_data, shiftin_last, shiftin_avail_in, shiftin_ready_in, shiftout_data, shiftout_avail_out,
	shiftout_ready_out, shiftout_first, shiftout_last, rst, minor_clk, major_clk);

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
	parameter NUM_TERMS = 12;
	parameter NUM_COPIES = 2;
	parameter CSLOW_MODE = 1;       // 0=state-only registers, 1=manually pipelined registers
	parameter PAR_MODE = 1;         // 0=replicated, 1=virtualized (C-slow)

	localparam WIDTH_IN  = 16;
	localparam WIDTH_OUT = 16;
	localparam ARRAY_WIDTH_IN = WIDTH_IN * NUM_COPIES;
	localparam ARRAY_WIDTH_OUT = WIDTH_OUT * NUM_COPIES;

	localparam TOTAL_INPUT_BITS  = ARRAY_WIDTH_IN;
	localparam TOTAL_OUTPUT_BITS = ARRAY_WIDTH_OUT;

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

	wire [ARRAY_WIDTH_IN-1:0] input_data_inarray;
	wire [ARRAY_WIDTH_OUT-1:0] output_data_outarray;

	wire blk_avail_in;
	wire blk_ready_in;
	wire blk_avail_out;
	wire blk_ready_out;

	// Assignments.
	assign {input_data_inarray} =
		shiftin_outarray[SR_INPUT_ARRAY_WIDTH-1:(SR_INPUT_ARRAY_WIDTH-TOTAL_INPUT_BITS)];
	assign shiftout_inarray[SR_OUTPUT_ARRAY_WIDTH-1:SR_OUTPUT_ARRAY_WIDTH-TOTAL_OUTPUT_BITS] =
		{output_data_outarray};
	generate
		if (EXTRA_OUTPUT_BITS > 0) begin
			assign shiftout_inarray[EXTRA_OUTPUT_BITS-1:0] = {EXTRA_OUTPUT_BITS{1'b0}};
		end
	endgenerate

	// Parallel Cosine Feedback application block.
	PARALLEL_COS_feedback_app #(.NUM_TERMS(NUM_TERMS), .NUM_COPIES(NUM_COPIES), .CSLOW_MODE(CSLOW_MODE),
		.PAR_MODE(PAR_MODE)) u_par_cos_taylor (

		.input_inarray(input_data_inarray),
		.avail_inarray(blk_avail_in),
		.ready_inarray(blk_ready_in),
		.output_outarray(output_data_outarray),
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


module PARALLEL_COS_feedback_app_CI_2(shiftin_data, shiftin_last, shiftin_avail_in, shiftin_ready_in, shiftout_data, shiftout_avail_out, 
	shiftout_ready_out,	shiftout_first, shiftout_last, rst, minor_clk, major_clk);

	/* This module (so to speak) is needed by the RTL compiler tool, otherwise it generates an error when calling functions 
	   defined in the module.  Since this module contains no functions nor makes any function calls, then RTL compiler
	   will NOT produce any errors. */

	// Parameters.
	parameter NUM_TERMS = 12;
	parameter NUM_COPIES = 2;
	parameter CSLOW_MODE = 1;       // 0=state-only registers, 1=manually pipelined registers
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
	PARALLEL_COS_feedback_app_CI #(
		.NUM_TERMS(NUM_TERMS),
		.NUM_COPIES(NUM_COPIES),
		.CSLOW_MODE(CSLOW_MODE),
		.PAR_MODE(PAR_MODE)) u_par_cos_ci (

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
