`timescale 1ns / 1ps
`default_nettype none

/********************************************************************************
Company:      Washington University in St. Louis
Engineer:     Michael Hall
Module Name:  cspc_major_clock_interface_rr_sched
Description:  CSPC Major Clock Interface with Round Robin Scheduling

This module provides a parallel interface for passing data into a virtualized
hardware block.  The data is provided to the interface in parallel and is clocked
at the major clock.  It is then time-multiplexed into a single stream in a round-
robin fashion and supplied into the C-slowed hardware block via the blk_% ports.
The output of the hardware block is then demultiplexed and provided parallel out
on the major clock.

Internal to the interface, the multiplexer, hardware blcok, and demultiplexer all
operate on the minor clock.  The minor clock is defined to be C times faster than
the major clock.
*********************************************************************************/
module cspc_major_clock_interface_rr_sched(data_inarray, avail_inarray, ready_inarray, common_in, data_outarray, avail_outarray,
	ready_outarray, rst, minor_clk, major_clk, blk_in, blk_common_in, blk_out, blk_en, blk_rst, blk_clk);

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

	// Parameters
	parameter NUM_PORTS = 4;
	parameter WIDTH_IN_PORT   = 16;
	parameter WIDTH_IN_COMMON = 16;
	parameter WIDTH_OUT_PORT  = 16;

	localparam WIDTH_IN_COMMON_MOD = (WIDTH_IN_COMMON == 0 ? 1 : WIDTH_IN_COMMON);

	localparam ARRAY_WIDTH_IN  = NUM_PORTS * WIDTH_IN_PORT;
	localparam ARRAY_WIDTH_OUT = NUM_PORTS * WIDTH_OUT_PORT;
	localparam SELECT_WIDTH = countbits(NUM_PORTS-1);

	// Port declaration
	input wire [ARRAY_WIDTH_IN-1:0] data_inarray;
	input wire avail_inarray;
	output wire ready_inarray;
	input wire [WIDTH_IN_COMMON_MOD-1:0] common_in;
	output wire [ARRAY_WIDTH_OUT-1:0] data_outarray;
	output wire avail_outarray;
	input wire ready_outarray;
	input wire rst;
	input wire minor_clk;
	input wire major_clk;
	output wire [WIDTH_IN_PORT-1:0] blk_in;
	output wire [WIDTH_IN_COMMON_MOD-1:0] blk_common_in;
	input wire [WIDTH_OUT_PORT-1:0] blk_out;
	output wire blk_en;
	output wire blk_rst;
	output wire blk_clk;

	// Wires
	wire rst_MC;                                   // Register "rst" on the major clock
	wire [ARRAY_WIDTH_IN-1:0] data_inarray_MC;     // Register "input_array" on the major clock
	wire avail_inarray_MC;                         // Data available signal on the major clock
	wire ready_inarray_MC;                         // Read data signal on the major clock
	wire [WIDTH_IN_COMMON_MOD-1:0] common_in_MC;   // Register "common_in" on the major clock

	wire [SELECT_WIDTH-1:0] input_muxsel;

	wire [SELECT_WIDTH-1:0] blk_out_select;
	wire blk_out_valid;
	wire [WIDTH_IN_PORT-1:0] input_from_mux;
	wire en_MC;

	wire [ARRAY_WIDTH_OUT-1:0] data_outarray_MC;   // Output array output set on the minor clock (before the last register)
	wire avail_outarray_MC;                        // Output array available signal set on the minor clock
	wire ready_outarray_MC;                        // Output array write signal given on the minor clock

	// Register the reset on the major clock.
	pipe_reg u_pipereg_rst_in (
		.in(rst),
		.out(rst_MC),
		.clk(major_clk)
	);

	// Register the array inputs on the major clock with flow control propagation.
	localparam PR_DATA_WIDTH = ARRAY_WIDTH_IN+WIDTH_IN_COMMON;
	wire [PR_DATA_WIDTH-1:0] pr_data_in, pr_data_in_MC;
	
	generate
		if (WIDTH_IN_COMMON > 0) begin
			assign {data_inarray_MC, common_in_MC} = pr_data_in_MC;
			assign pr_data_in = {data_inarray, common_in};
		end
		else begin
			assign {data_inarray_MC} = pr_data_in_MC;
			assign pr_data_in = {data_inarray};
		end
	endgenerate

	pipe_reg_flow #(.WIDTH(PR_DATA_WIDTH)) u_pipereg_in (
		.data_in(pr_data_in),
		.avail_in(avail_inarray),
		.ready_in(ready_inarray),
		.data_out(pr_data_in_MC),
		.avail_out(avail_inarray_MC),
		.ready_out(ready_inarray_MC),
		.rst(rst),
		.clk(major_clk)
	);
	assign ready_inarray_MC = en_MC | ~avail_inarray_MC;

	// Select the input data stream.
	free_running_counter #(.MAX_COUNT(NUM_PORTS-1)) u_frc (
		.out(input_muxsel),
		.en(en_MC),
		.rst(rst_MC),
		.clk(minor_clk)
	);

	// Multiplex the selected input data stream to a single output.
	multiplexer #(.WIDTH(WIDTH_IN_PORT), .NUM_INPUTS(NUM_PORTS)) u_input_mux (
		.out(input_from_mux),
		.inarray(data_inarray_MC),
		.select(input_muxsel)
	);

	// Define reusable hardware block signals
	assign blk_in = input_from_mux;
	assign blk_common_in = common_in_MC;
	assign blk_en = en_MC | rst_MC;
	assign blk_rst = rst_MC;
	assign blk_clk = minor_clk;

	// Shift the selected input ID and input valid to the output.
	localparam SR_WIDTH = SELECT_WIDTH + 1;
	wire input_valid = 1'b1;
	wire [SR_WIDTH-1:0] sr_in = {input_muxsel, input_valid};
	wire [SR_WIDTH-1:0] sr_out;
	shift_reg #(.WIDTH(SR_WIDTH), .DEPTH(NUM_PORTS)) u_sr_i2o (
		.out(sr_out),
		.outarray(),
		.in(sr_in),
		.inarray(),
		.load(1'b1),
		.parload(1'b0),
		.clr(1'b0),
		.en(en_MC),
		.rst(rst_MC),
		.clk(minor_clk)
	);
	assign blk_out_select = sr_out[SELECT_WIDTH:1];
	assign blk_out_valid  = sr_out[0];

	// Demultiplex the output data stream.
	wire [ARRAY_WIDTH_OUT-1:0] demux_out;
	shift_reg #(.WIDTH(WIDTH_OUT_PORT), .DEPTH(NUM_PORTS-1)) u_sr_demux (
		.out(),
		.outarray(demux_out),
		.in(blk_out),
		.inarray(),
		.load(blk_out_valid),
		.parload(1'b0),
		.clr(1'b0),
		.en(en_MC),
		.rst(rst_MC),
		.clk(minor_clk)
	);

	// Register the demultiplexed outputs on the major clock with flow control propagation.
	assign data_outarray_MC = demux_out;
	assign avail_outarray_MC = blk_out_valid & ~(rst | rst_MC);
	assign en_MC = avail_inarray_MC & (ready_outarray_MC | ~avail_outarray_MC);

	buffer #(.WIDTH(ARRAY_WIDTH_OUT), .IMPL_TYPE("pipe_buf")) u_output_buf (
		.data_in(data_outarray_MC),
		.avail_in(avail_outarray_MC & en_MC),
		.ready_in(ready_outarray_MC),
		.data_out(data_outarray),
		.avail_out(avail_outarray),
		.ready_out(ready_outarray),
		.rst(rst | rst_MC),
		.clk(major_clk)
	);
endmodule
