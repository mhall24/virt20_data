`timescale 1ns / 1 ps
`default_nettype none

/********************************************************************************
Company:      Washington University in St. Louis
Engineer:     Michael Hall
Module Name:  cspc_parallel_interface_two_clocks
Description:  CSPC Parallel Interface with Two Clocks (major and minor clocks)

This module provides a parallel interface for multiplexing parallel data streams
into a single data stream and conversely demultiplexing a single data stream into
multiple parallel data streams out.

The data is input into the interface with context-centric flow-control specified
per context data stream.  A multiplexer then selects one of the context data
streams given an address and reads it out.  Flow-control signals are propagated
accordingly.

A single data stream is then read into a demultiplexer.  An address given to the
demultiplexer selects which context port the data is written to.  Flow control
is handled by returning a valid signal to indicate which port already has data
in it and cannot be written to.

There are two clocks used:  major and minor clocks.  The major clock is used at
parallel interface boundary.  The minor clock is used internally at the single
data stream out (from the input interface) and single data stream in (into the
output interface).

Assumption:  Minor clock is faster than the major clock.
*********************************************************************************/
module cspc_parallel_interface_two_clocks(data_inarray, avail_inarray, ready_inarray, common_in,
	mC_mux_addr, mC_data_in, mC_mux_avail_in, mC_avail_inarray, mC_mux_ready_in, mC_common_in, mC_rst,
	mC_demux_addr, mC_data_out, mC_avail_out, mC_demux_ready_out, mC_ready_outarray,
	data_outarray, avail_outarray, ready_outarray, rst, minor_clk, major_clk);

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

	// Parameters.
	parameter NUM_PORTS = 4;
	parameter WIDTH_IN_PORT   = 16;
	parameter WIDTH_IN_COMMON = 16;
	parameter WIDTH_OUT_PORT  = 16;
	parameter SYNC_CLKS = 1;

	localparam ARRAY_WIDTH_IN  = NUM_PORTS * WIDTH_IN_PORT;
	localparam ARRAY_WIDTH_OUT = NUM_PORTS * WIDTH_OUT_PORT;
	localparam SELECT_WIDTH = countbits(NUM_PORTS-1);

	// Port declaration.
	input wire [ARRAY_WIDTH_IN-1:0] data_inarray;
	input wire [0:NUM_PORTS-1] avail_inarray;
	output wire [0:NUM_PORTS-1] ready_inarray;
	input wire [WIDTH_IN_COMMON-1:0] common_in;

	input wire [SELECT_WIDTH-1:0] mC_mux_addr;
	output wire [WIDTH_IN_PORT-1:0] mC_data_in;
	output wire mC_mux_avail_in;
	output wire [0:NUM_PORTS-1] mC_avail_inarray;
	input wire mC_mux_ready_in;
	output wire [WIDTH_IN_COMMON-1:0] mC_common_in;
	output wire mC_rst;

	input wire [SELECT_WIDTH-1:0] mC_demux_addr;
	input wire [WIDTH_OUT_PORT-1:0] mC_data_out;
	input wire mC_avail_out;
	output wire mC_demux_ready_out;
	output wire [0:NUM_PORTS-1] mC_ready_outarray;

	output wire [ARRAY_WIDTH_OUT-1:0] data_outarray;
	output wire [0:NUM_PORTS-1] avail_outarray;
	input wire [0:NUM_PORTS-1] ready_outarray;
	input wire rst;
	input wire minor_clk;
	input wire major_clk;

	// Wires.
	wire [ARRAY_WIDTH_IN-1:0] mC_data_inarray;
	wire [0:NUM_PORTS-1] mC_ready_inarray;
	wire [0:NUM_PORTS-1] mC_mux_addr_decode;
	wire [0:NUM_PORTS-1] mC_demux_addr_decode;
	wire [0:NUM_PORTS-1] mC_demux_avail_outarray;

	// Cross clock domains.
	generate
		if (SYNC_CLKS) begin
			// Synchronize signals on the major clock.
			sync_signals #(.WIDTH(1), .DEPTH(1)) u_sync_signals_1 (
				.in(rst), .out(mC_rst), .rst(1'b0), .clk(major_clk));
			sync_signals #(.WIDTH(WIDTH_IN_COMMON), .DEPTH(1)) u_sync_signals_2 (
				.in(common_in), .out(mC_common_in), .rst(1'b0), .clk(major_clk));
		end
		else begin
			// Synchronize signals into the minor clock domain (asynchronously).
			sync_signals #(.WIDTH(1), .DEPTH(2)) u_sync_signals_1 (
				.in(rst), .out(mC_rst), .rst(1'b0), .clk(minor_clk));
			sync_signals #(.WIDTH(WIDTH_IN_COMMON), .DEPTH(2)) u_sync_signals_2 (
				.in(common_in), .out(mC_common_in), .rst(1'b0), .clk(minor_clk));
			end
	endgenerate

	// Multiplex the input ports to a single data stream.
	multiplexer #(.WIDTH(WIDTH_IN_PORT), .NUM_INPUTS(NUM_PORTS)) u_mux_data_in (
		.out(mC_data_in),
		.inarray(mC_data_inarray),
		.select(mC_mux_addr)
	);
	assign mC_mux_avail_in = mC_avail_inarray[mC_mux_addr];

	decoder #(.NUM_OUTPUTS(NUM_PORTS)) u_dec_mux_in (.out(mC_mux_addr_decode), .select(mC_mux_addr), .enable(~mC_rst));
	assign mC_ready_inarray = mC_mux_addr_decode & {NUM_PORTS{mC_mux_ready_in}};

	// Demultiplex a single data stream to an output port.
	decoder #(.NUM_OUTPUTS(NUM_PORTS)) u_dec_demux_out (.out(mC_demux_addr_decode), .select(mC_demux_addr), .enable(~mC_rst));

	assign mC_demux_avail_outarray = mC_demux_addr_decode & {NUM_PORTS{mC_avail_out}};
	//assign mC_demux_ready_out = |(mC_demux_addr_decode & mC_ready_outarray);
	assign mC_demux_ready_out = mC_ready_outarray[mC_demux_addr];

	genvar indexPort;
	generate
		for (indexPort=0; indexPort<NUM_PORTS; indexPort=indexPort+1) begin: PORT_LOOP
			// Buffer array input data streams.
			buffer_2clk #(.WIDTH(WIDTH_IN_PORT), .SYNC_CLKS(SYNC_CLKS), .FAST_CLK("rclk")) u_buf_dataport_in (
				.wdata_in(data_inarray[WIDTH_IN_PORT*indexPort+:WIDTH_IN_PORT]),
				.wavail_in(avail_inarray[indexPort]),
				.wready_in(ready_inarray[indexPort]),
				.wrst(rst),
				.wclk(major_clk),
				.rdata_out(mC_data_inarray[WIDTH_IN_PORT*indexPort+:WIDTH_IN_PORT]),
				.ravail_out(mC_avail_inarray[indexPort]),
				.rready_out(mC_ready_inarray[indexPort]),
				.rrst(mC_rst),
				.rclk(minor_clk)
			);

			// Buffer array output data streams.
			buffer_2clk #(.WIDTH(WIDTH_OUT_PORT), .SYNC_CLKS(SYNC_CLKS), .FAST_CLK("wclk")) u_buf_dataport_out (
				.wdata_in(mC_data_out),
				.wavail_in(mC_demux_avail_outarray[indexPort]),
				.wready_in(mC_ready_outarray[indexPort]),
				.wrst(mC_rst),
				.wclk(minor_clk),
				.rdata_out(data_outarray[WIDTH_OUT_PORT*indexPort+:WIDTH_OUT_PORT]),
				.ravail_out(avail_outarray[indexPort]),
				.rready_out(ready_outarray[indexPort]),
				.rrst(rst),
				.rclk(major_clk)
			);
		end
	endgenerate

endmodule
