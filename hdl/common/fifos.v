`timescale 1ns / 1ps
`default_nettype none

module fifo_2clk_sync(
	wdata, we, wfull, wrst, wclk,
	rdata, re, rempty, rrst, rclk);

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

	/*
		Design based on the following paper with modifications
		------------------------------------------------------
		Title:       "Simulation and Synthesis Techniques for Asynchronous FIFO Design"
		Author:      Clifford E. Cummings, Sunburst Design, Inc.
		Email:       cliffc@sunburst-design.com
		Conference:  SNUG San Jose 2002
	*/

	// Design parameters.
	parameter DEPTH = 2;                               // Minimum DEPTH is 1.
	parameter WIDTH = 8;
	parameter FIFO_FAST_CLK = "none";                  // Four options:  "wclk", "rclk", "both", "none".
	                                                   // - Necessary for "accurate" FIFO status implementation.

	localparam FAST_WCLK = (FIFO_FAST_CLK == "wclk" || FIFO_FAST_CLK == "both");
	localparam FAST_RCLK = (FIFO_FAST_CLK == "rclk" || FIFO_FAST_CLK == "both");

	/*
		Guide:
			1)  "pessimistic" fifo status is used when FIFO_FAST_CLK == "none".  Specifying which
			    clock is the faster clock will turn on the "accurate" fifo status mode.
			2)  rclk = wclk, "pessimistic" fifo status implementation, desired full throughput
				Set DEPTH >= 4   (Fast clock frequency of design, but more registers used)
			3)  rclk = wclk, "accurate" fifo status implementation, desired full throughput
				Set DEPTH >= 2   (Slower clock frequency of design, but less registers used)

		Rates:
			FIFO_STATUS_IMPL     DEPTH      WPERIOD     RPERIOD      RATE
			  pessismistic         1           1           1         1/4 (both)
			  pessismistic         1           1           2         1/3 (R)
			  pessismistic         1           1           3+        1/2 (R)
			  pessismistic         1           2           1         1/3 (W)
			  pessismistic         1           3+          1         1/2 (W)
			  pessismistic         2           1           1         1/2 (both)
			  pessismistic         2           1           2         2/3 (R)
			  pessismistic         2           1           3+        Full (R)
			  pessismistic         2           2           1         2/3 (W)
			  pessismistic         2           3+          1         Full (W)
			  pessismistic         3           1           1         3/4 (both)
			  pessismistic         3           1           2+        Full (R)
			  pessismistic         3           2+          1         Full (W)
			  pessismistic         4           1+          1+        Full
			  accurate             1           1           1         1/2 (both)
			  accurate             1           1           2+        1/2 (R)
			  accurate             1           2+          1         1/2 (W)
			  accurate             2           1+          1+        Full

		Tradeoffs:
			1) The depth determines the number of registers used.  Increasing registers will
			   increase area and performance.
			2) Pessismistic fifo implementation uses less logic, but suffers more in
			   performance.
	*/

	// Port declaration.
	input wire [WIDTH-1:0] wdata;
	input wire we;
	output wire wfull;
	input wire wrst;
	input wire wclk;
	output wire [WIDTH-1:0] rdata;
	input wire re;
	output wire rempty;
	input wire rrst;
	input wire rclk;

	// Calculated parameters.
	localparam ADDRSIZE = countbits(DEPTH-1);

	// Wires.
	wire [ADDRSIZE-1:0] waddr, raddr;
	reg [ADDRSIZE:0] wbin, rbin;
	wire [ADDRSIZE:0] wbinnext, rbinnext;
	wire [ADDRSIZE:0] wptr, rptr;
	wire [ADDRSIZE:0] wptrnext, rptrnext;
	wire [ADDRSIZE:0] ws_rptr, rs_wptr;
	wire winc, rinc;
	reg wfull_reg, rempty_reg;
	reg wsinc, rsinc;
	reg wtoggle, rtoggle;
	reg w_rtoggle, r_wtoggle;
	wire w_rsincgate, r_wsincgate;

	// Cross clock domains.
	assign rs_wptr = wptr;     // Synchronous by definition.
	assign ws_rptr = rptr;
	always @(posedge wclk) w_rtoggle <= rtoggle;
	always @(posedge rclk) r_wtoggle <= wtoggle;

	// FIFO memory (distributed RAM).
	reg [WIDTH-1:0] mem [0:DEPTH-1];
	assign rdata = mem[raddr];
	always @(posedge wclk)
		if (we && !wfull) mem[waddr] <= wdata;

	// Read pointer.
	wire rempty_val;
	always @(posedge rclk or posedge rrst) begin
		if (rrst) begin
			rempty_reg <= 1'b1;
			rbin <= 0;
			rtoggle <= 0;
			rsinc <= 0;
		end
		else begin
			rempty_reg <= rempty_val;
			rbin <= rbinnext;
			rtoggle <= ~rtoggle;
			rsinc <= rinc;
		end
	end
	assign rinc = re & ~rempty;
	assign rptr = rbin;
	assign raddr = rbin[ADDRSIZE-1:0];
	assign rbinnext = (rinc ? (raddr == DEPTH-1 ? {~rbin[ADDRSIZE],{ADDRSIZE{1'b0}}} : rbin + 1) : rbin);
	assign rptrnext = rbinnext;
	assign rempty_val = (rptrnext == rs_wptr) & ~(FAST_WCLK & winc);
	assign r_wsincgate = (FAST_RCLK ? wtoggle ^ r_wtoggle : 1'b0);
	assign rempty = rempty_reg & ~(wsinc & r_wsincgate);

	// Write pointer.
	wire wfull_val;
	always @(posedge wclk or posedge wrst) begin
		if (wrst) begin
			wfull_reg <= 0;
			wbin <= 0;
			wtoggle <= 0;
			wsinc <= 0;
		end
		else begin
			wfull_reg <= wfull_val;
			wbin <= wbinnext;
			wtoggle <= ~wtoggle;
			wsinc <= winc;
		end
	end
	assign winc = we & ~wfull;
	assign wptr = wbin;
	assign waddr = wbin[ADDRSIZE-1:0];
	assign wbinnext = (winc ? (waddr == DEPTH-1 ? {~wbin[ADDRSIZE],{ADDRSIZE{1'b0}}} : wbin + 1) : wbin);
	assign wptrnext = wbinnext;
	assign wfull_val = (wptrnext[ADDRSIZE-1:0] == ws_rptr[ADDRSIZE-1:0]) & 
	                   (wptrnext[ADDRSIZE] != ws_rptr[ADDRSIZE]) & ~(FAST_RCLK & rinc);
	assign w_rsincgate = (FAST_WCLK ? rtoggle ^ w_rtoggle : 1'b0);
	assign wfull = wfull_reg & ~(rsinc & w_rsincgate);
endmodule


module fifo_2clk_async(
	wdata, we, wfull, wrst, wclk,
	rdata, re, rempty, rrst, rclk);

	/*
		Design given in the following paper
		-----------------------------------
		Title:       "Simulation and Synthesis Techniques for Asynchronous FIFO Design"
		Author:      Clifford E. Cummings, Sunburst Design, Inc.
		Email:       cliffc@sunburst-design.com
		Conference:  SNUG San Jose 2002
	*/

	// Design parameters.
	parameter ASIZE = 3;
	parameter WIDTH = 8;

	/*
		Guide:
			1)  rclk=wclk, desired full throughput
			    Set ASIZE=3.

		Rates:
			ASIZE      WPERIOD     RPERIOD     RATE
			  2           1           1        1/2 (both)
			  2           1           2        2/3 (R)
			  2           1           3        4/5 (R)
			  2           1           >4       Full (R)
			  2           2           1        2/3 (W)
			  2           3           1        4/5 (W)
			  2           >4          1        Full (W)
			  3           1+          1+       Full (both)

		Notes:
			1)  DEPTH of FIFO = 2^ASIZE.  ASIZE=2 uses 4 registers, ASIZE=3 uses 8 registers.
	*/

	// Port declaration.
	input wire [WIDTH-1:0] wdata;
	input wire we;
	output reg wfull;
	input wire wrst;
	input wire wclk;
	output wire [WIDTH-1:0] rdata;
	input wire re;
	output reg rempty;
	input wire rrst;
	input wire rclk;

	// Calculated parameters.
	localparam DEPTH = 1<<ASIZE;

	// Wires.
	wire [ASIZE-1:0] waddr, raddr;
	reg [ASIZE:0] wbin, rbin;
	reg [ASIZE:0] wptr, rptr;
	wire [ASIZE:0] wbinnext, rbinnext;
	wire [ASIZE:0] wgraynext, rgraynext;
	reg [ASIZE:0] wq2_rptr, rq2_wptr;

	// Cross clock domains.
	reg [ASIZE:0] wq1_rptr, rq1_wptr;
	always @(posedge wclk or posedge wrst)
		if (wrst) {wq2_rptr,wq1_rptr} <= {2*(ASIZE+1){1'b0}};
		else {wq2_rptr,wq1_rptr} <= {wq1_rptr,rptr};
	always @(posedge rclk or posedge rrst)
		if (rrst) {rq2_wptr,rq1_wptr} <= {2*(ASIZE+1){1'b0}};
		else {rq2_wptr,rq1_wptr} <= {rq1_wptr,wptr};
	
	// FIFO memory (distributed RAM).
	reg [WIDTH-1:0] mem [0:DEPTH-1];
	assign rdata = mem[raddr];
	always @(posedge wclk)
		if (we && !wfull) mem[waddr] <= wdata;

	// Read pointer.
	wire rempty_val;
	always @(posedge rclk or posedge rrst) begin
		if (rrst) begin
			{rbin,rptr} <= 0;
			rempty <= 1'b1;
		end
		else begin
			{rbin,rptr} <= {rbinnext,rgraynext};
			rempty <= rempty_val;
		end
	end
	assign raddr = rbin[ASIZE-1:0];
	assign rbinnext = rbin + (re & ~rempty);
	assign rgraynext = (rbinnext>>1) ^ rbinnext;
	assign rempty_val = (rgraynext == rq2_wptr);

	// Write pointer.
	wire wfull_val;
	always @(posedge wclk or posedge wrst) begin
		if (wrst) begin
			{wbin,wptr} <= 0;
			wfull <= 0;
		end
		else begin
			{wbin,wptr} <= {wbinnext,wgraynext};
			wfull <= wfull_val;
		end
	end
	assign waddr = wbin[ASIZE-1:0];
	assign wbinnext = wbin + (we & ~wfull);
	assign wgraynext = (wbinnext>>1) ^ wbinnext;

	//------------------------------------------------------------------
	// Simplified version of the three necessary full-tests:
	// assign wfull_val=((wgnext[ADDRSIZE] !=wq2_rptr[ADDRSIZE] ) &&
	// (wgnext[ADDRSIZE-1] !=wq2_rptr[ADDRSIZE-1]) &&
	// (wgnext[ADDRSIZE-2:0]==wq2_rptr[ADDRSIZE-2:0]));
	//------------------------------------------------------------------
	assign wfull_val = (wgraynext=={~wq2_rptr[ASIZE:ASIZE-1],
									wq2_rptr[ASIZE-2:0]});

endmodule
