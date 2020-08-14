`timescale 1ns / 1ps
`default_nettype none

module sync_signals(out, in, rst, clk);
	/* 
		Sync signals to different clock domain.
	*/

	// Design parameters.
	parameter WIDTH = 1;
	parameter DEPTH = 2;

	// Port declaration.
	output wire [WIDTH-1:0] out;     // Output signals
	input wire [WIDTH-1:0] in;       // Input signals
	input wire rst;                  // Target reset
	input wire clk;                  // Target clock

	// Synchronizer implementation.
	generate
		if (DEPTH == 0) begin
			// No synchronization registers.
			assign out = in;
		end

		else if (DEPTH == 1) begin
			// One synchronization register.  Only do this if the clocks are synchronous.
			// Otherwise, there is a risk of metastability.
			reg [WIDTH-1:0] q;
			always @(posedge clk or posedge rst) begin
				if (rst) q = 0;
				else q = in;
			end
			assign out = q;
		end

		else if (DEPTH > 1) begin
			// Chain of synchronization registers.
			reg [WIDTH-1:0] q [0:DEPTH-1];
			integer i;
			always @(posedge clk or posedge rst) begin
				if (rst) begin
					for (i=0; i<DEPTH; i=i+1) q[i] = 0;
				end
				else begin
					for (i=1; i<DEPTH; i=i+1) q[i] <= q[i-1];
					q[0] <= in;
				end
			end
			assign out = q[DEPTH-1];
		end
	endgenerate
endmodule

module buffer_2clk(wdata_in, wavail_in, wready_in, wrst, wclk, rdata_out, ravail_out, rready_out, rrst, rclk);
	/*
		Buffer and transfer data between two clock domains.
		If clock domains are synchronous, then set SYNC_CLKS = 1.

		Sample synthesis runs
		---------------------
		SYNC_CLKS = 1

		FAST_CLK = "none"
		6 Slices, 8 S-FFs, 13 LUTs
		662.0 MHz

		FAST_CLK = "wclk"
		9 Slices, 11 S-FFs, 19 LUTs
		562.7 MHz

		FAST_CLK = "rclk"
		9 Slices, 14 S-FFs, 19 LUTs
		562.4 MHz

		FAST_CLK = "both"
		11 Slices, 14 S-FFs, 21 LUTs
		465.0 MHz

		SYNC_CLKS = 0 (asynchronous)
		21 Slices, 30 S-FFs, 29 LUTs
		381.9 MHz
	*/

	// Functions.
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
	function integer max;
		input integer A, B;
		begin
			if (A > B) max = A;
			else max = B;
		end
	endfunction

	// Design parameters.
	parameter WIDTH = 1;
	parameter DEPTH = 2;
	parameter SYNC_CLKS = 0;
	parameter FAST_CLK = "none";

	localparam ASIZE = (DEPTH==2 ? 3 : max(countbits(DEPTH-1),2));

	// Port declaration.
	input wire [WIDTH-1:0] wdata_in;
	input wire wavail_in;
	output wire wready_in;
	input wire wrst;
	input wire wclk;
	output wire [WIDTH-1:0] rdata_out;
	output wire ravail_out;
	input wire rready_out;
	input wire rrst;
	input wire rclk;

	// Wires.
	wire we, re;
	wire wfull, rempty;

	// Assignments.
	assign wready_in = ~wfull;
	assign we = wavail_in & wready_in;
	assign ravail_out = ~rempty;
	assign re = ravail_out & rready_out;

	// Instantiations.
	generate
		if (SYNC_CLKS) begin
			fifo_2clk_sync #(.DEPTH(DEPTH), .WIDTH(WIDTH), .FIFO_FAST_CLK(FAST_CLK)) u_fifo_2clk_sync (
				.wdata(wdata_in),
				.we(we),
				.wfull(wfull),
				.wrst(wrst),
				.wclk(wclk),
				.rdata(rdata_out),
				.re(re),
				.rempty(rempty),
				.rrst(rrst),
				.rclk(rclk)
			);
		end
		else begin
			fifo_2clk_async #(.ASIZE(ASIZE), .WIDTH(WIDTH)) u_fifo_2clk_async (
				.wdata(wdata_in),
				.we(we),
				.wfull(wfull),
				.wrst(wrst),
				.wclk(wclk),
				.rdata(rdata_out),
				.re(re),
				.rempty(rempty),
				.rrst(rrst),
				.rclk(rclk)
			);
		end
	endgenerate
endmodule

