`timescale 1ns / 1ps
`default_nettype none

/* SYN_ALLOW_RETIMING compiler define (FOR SYMPLIFY ONLY)
	The SYN_ALLOW_RETIMING compiler define is used to set the "syn_allow_retiming"
	constraint on the pipeline registers to be retimed by the Synplify Premier
	tool.  Note, this only works with Synplify Premier.  For Xilinx, one must
	turn on Register Balancing in the synthesis options to achieve the same
	effect. */
`define SYN_ALLOW_RETIMING



/********************************************************************************
Company:      Washington University in St. Louis
Engineer:     Michael Hall
Module Name:  pipe_reg
Description:  Pipeline register(s) for context-switched pipelined circuits.

In a context-switched pipelined circuit, "pipe_reg" provides a flexible pipeline
register module for implementing the intermediate pipeline registers in a 
C-slowed hardware block.  The "pipe_reg" module does not include a RESET, but
rather is set by the input "in".  This is because a C-slowed hardware block
will be reset by propagating the signal values through the pipeline registers.

The "pipe_reg" module is NOT enabled, meaning that the registers are always
shifting data through the pipeline.  The width of the pipeline registers is
set via the WIDTH parameter and the depth, or number of pipeline registers, is
set via the DEPTH parameter.

Depth = 0:          NO PIPELINE REGISTERS
Depth = 1:          ONE PIPELINE REGISTER
Depth = 2 or more:  CHAIN OF PIPELINE REGISTERS
*********************************************************************************/
module pipe_reg(out, in, clk);
	parameter WIDTH = 1;
	parameter DEPTH = 1;

	output wire [WIDTH-1:0] out;     // Output data
	input wire [WIDTH-1:0] in;       // Input data

	input wire clk;                  // Clock

	generate
		if (DEPTH == 0) begin
			// No pipeline register.
			assign out = in;
		end

		else if (DEPTH == 1) begin
			// One pipeline register.
			`ifdef SYN_ALLOW_RETIMING
				(* register_balancing = "yes" *)
				reg [WIDTH-1:0] pipeline_register /* synthesis syn_allow_retiming = 1 */ ;
			`else
				reg [WIDTH-1:0] pipeline_register;
			`endif
			always @(posedge clk) begin
				pipeline_register = in;
			end
			assign out = pipeline_register;
		end

		else if (DEPTH > 1) begin
			// Chain of pipeline registers.
			`ifdef SYN_ALLOW_RETIMING
				(* register_balancing = "yes" *)
				reg [WIDTH-1:0] pipeline_registers[0:DEPTH-1] /* synthesis syn_allow_retiming = 1 */ ;
			`else
				reg [WIDTH-1:0] pipeline_registers[0:DEPTH-1];
			`endif
			integer i;
			always @(posedge clk) begin
				// Shift and load pipeline registers
				for (i=1; i<DEPTH; i=i+1)
					pipeline_registers[i] <= pipeline_registers[i-1];
				pipeline_registers[0] <= in;
			end
			assign out = pipeline_registers[DEPTH-1];
		end
	endgenerate
endmodule


/********************************************************************************
Company:      Washington University in St. Louis
Engineer:     Michael Hall
Module Name:  pipe_reg_en
Description:  Pipeline register(s) for context-switched pipelined circuits with 
              enabled registers.

In a context-switched pipelined circuit, "pipe_reg_en" provides a flexible
pipeline register module for implementing the intermediate pipeline registers 
in a C-slowed hardware block.  The "pipe_reg" module does not include a RESET,
but rather is set by the input "in".  This is because a C-slowed hardware block
will be reset by propagating the signal values through the pipeline registers.

The "pipe_reg" module is ENABLED by the "en" port, allowing all pipeline registers
to be paused during a context-switch.  The width of the pipeline registers is
set via the WIDTH parameter and the depth, or number of pipeline registers, is
set via the DEPTH parameter.

Depth = 0:          NO PIPELINE REGISTERS
Depth = 1:          ONE PIPELINE REGISTER
Depth = 2 or more:  CHAIN OF PIPELINE REGISTERS
*********************************************************************************/
module pipe_reg_en(out, in, en, clk);
	parameter WIDTH = 1;
	parameter DEPTH = 1;

	output wire [WIDTH-1:0] out;     // Output data
	input wire [WIDTH-1:0] in;       // Input data

	input wire en;                   // Enable
	input wire clk;                  // Clock

	generate
		if (DEPTH == 0) begin
			// No pipeline register.
			assign out = in;
		end

		else if (DEPTH == 1) begin
			// One pipeline register.
			`ifdef SYN_ALLOW_RETIMING
				(* register_balancing = "yes" *)
				reg [WIDTH-1:0] pipeline_register /* synthesis syn_allow_retiming = 1 */ ;
			`else
				reg [WIDTH-1:0] pipeline_register;
			`endif
			always @(posedge clk) begin
				if (en)
					pipeline_register = in;
				else
					pipeline_register = pipeline_register;
			end
			assign out = pipeline_register;
		end

		else if (DEPTH > 1) begin
			// Chain of pipeline registers.
			`ifdef SYN_ALLOW_RETIMING
				(* register_balancing = "yes" *)
				reg [WIDTH-1:0] pipeline_registers[0:DEPTH-1] /* synthesis syn_allow_retiming = 1 */ ;
			`else
				reg [WIDTH-1:0] pipeline_registers[0:DEPTH-1];
			`endif
			integer i;
			always @(posedge clk) begin
				if (en) begin
					// Shift and load pipeline registers
					for (i=1; i<DEPTH; i=i+1)
						pipeline_registers[i] <= pipeline_registers[i-1];
					pipeline_registers[0] <= in;
				end
			end
			assign out = pipeline_registers[DEPTH-1];
		end
	endgenerate
endmodule


/********************************************************************************
Company:      Washington University in St. Louis
Engineer:     Michael Hall
Module Name:  pipe_reg_flow
Description:  Pipeline register(s) with flow control propagation.
*********************************************************************************/
module pipe_reg_flow(data_in, avail_in, ready_in, data_out, avail_out, ready_out, rst, clk);
	parameter WIDTH = 1;
	parameter DEPTH = 1;

	input wire [WIDTH-1:0] data_in;         // Input data
	input wire avail_in;                    // Input data available
	output wire ready_in;                   // Input data ready

	output wire [WIDTH-1:0] data_out;       // Output data
	output wire avail_out;                  // Output data available
	input wire ready_out;                   // Output data ready

	input wire rst;                         // Reset
	input wire clk;                         // Clock

	wire en;                                // Enable
	reg [0:DEPTH-1] valid;                  // Pipeline register valid

	// Build data pipeline register.
	pipe_reg_en #(.WIDTH(WIDTH), .DEPTH(DEPTH)) u_pipe_reg (.out(data_out), .in(data_in), .en(en), .clk(clk));

	// Build valid pipeline register.
	always @(posedge clk) begin
		if (rst) valid = {DEPTH{1'b0}};
		else if (en) valid = (DEPTH == 1 ? avail_in : {avail_in, valid[0:DEPTH-2]});
	end

	assign ready_in = en;
	assign avail_out = valid[DEPTH-1];
	assign en = ready_out;
endmodule


/********************************************************************************
Company:      Washington University in St. Louis
Engineer:     Michael Hall
Module Name:  buffer_output
Description:  Buffer output with flow control propagation.

This module provides an output buffer that will buffer the output if the
ready_out signal is not asserted, or pass the input directly to the output if it
is asserted and the buffer is empty.  The main use of this module is to buffer
the ready_out signal to isolate it from the ready_in signal, thus breaking the
chaining of the backpressure signal.
*********************************************************************************/
module buffer_output(data_in, avail_in, ready_in, data_out, avail_out, ready_out, rst, clk);
	parameter WIDTH = 1;

	// Port declaration
	input wire [WIDTH-1:0] data_in;         // Input data
	input wire avail_in;                    // Input data available
	output wire ready_in;                   // Input data ready

	output wire [WIDTH-1:0] data_out;       // Output data
	output wire avail_out;                  // Output data available
	input wire ready_out;                   // Output data ready

	input wire rst;                         // Reset
	input wire clk;                         // Clock

	// Declarations
	wire write_to_buffer;
	wire read_from_buffer;
	`ifdef SYN_ALLOW_RETIMING
		(* register_balancing = "yes" *)
		reg [WIDTH-1:0] buf_reg /* synthesis syn_allow_retiming = 1 */ ;
	`else
		reg [WIDTH-1:0] buf_reg;
	`endif
	reg valid;

	always @(posedge clk) begin
		if (rst) begin
			valid <= 1'b0;
		end
		else if (write_to_buffer) begin
			buf_reg <= data_in;
			valid <= 1'b1;
		end
		else if (read_from_buffer) begin
			valid <= 1'b0;
		end
	end
	assign write_to_buffer = ready_in & avail_in & ~ready_out;
	assign read_from_buffer = valid & ready_out;
	assign data_out = (valid ? buf_reg : data_in);
	assign avail_out = valid | avail_in;
	assign ready_in = ~valid;
endmodule


/********************************************************************************
Company:      Washington University in St. Louis
Engineer:     Michael Hall
Module Name:  buffer
Description:  Buffer with flow control propagation.

This module will buffer the data and flow control signals.  The avail and ready
signals are both broken up with registers.
*********************************************************************************/
module buffer(data_in, avail_in, ready_in, data_out, avail_out, ready_out, rst, clk);
	parameter WIDTH = 1;
	parameter IMPL_TYPE = "fifo";
	parameter BYPASS = 0;

	// Port declaration
	input wire [WIDTH-1:0] data_in;         // Input data
	input wire avail_in;                    // Input data available
	output wire ready_in;                   // Input data ready

	output wire [WIDTH-1:0] data_out;       // Output data
	output wire avail_out;                  // Output data available
	input wire ready_out;                   // Output data ready

	input wire rst;                         // Reset
	input wire clk;                         // Clock

	// Implementations
	generate
		if (BYPASS) begin
			assign data_out = data_in;
			assign avail_out = avail_in;
			assign ready_in = ready_out;
		end
		else if (IMPL_TYPE == "pipe_buf") begin
			wire [WIDTH-1:0] data_out_I;
			wire avail_out_I;
			wire ready_out_I;

			pipe_reg_flow #(.WIDTH(WIDTH), .DEPTH(1)) u_pipe_reg (
				.data_in(data_in),
				.avail_in(avail_in),
				.ready_in(ready_in),
				.data_out(data_out_I),
				.avail_out(avail_out_I),
				.ready_out(ready_out_I),
				.rst(rst),
				.clk(clk));
			buffer_output #(.WIDTH(WIDTH)) u_buffer_out (
				.data_in(data_out_I),
				.avail_in(avail_out_I),
				.ready_in(ready_out_I),
				.data_out(data_out),
				.avail_out(avail_out),
				.ready_out(ready_out),
				.rst(rst),
				.clk(clk));
		end
		else if (IMPL_TYPE == "fifo") begin
			wire FULL;
			wire EMPTY;

			fifo #(.Depth(2), .Width(WIDTH), .UseBlockRAM(0)) u_fifo (
				.DIN(data_in),
				.DOUT(data_out),
				.RE(ready_out),
				.WE(avail_in & ~FULL),
				.EMPTY(EMPTY),
				.ONE(),
				.FULL(FULL),
				.AFULL(),
				.DFULL(),
				.RST(rst),
				.CLK(clk));

			assign ready_in = ~FULL;
			assign avail_out = ~EMPTY;
		end
	endgenerate
endmodule


/********************************************************************************
Company:      Washington University in St. Louis
Engineer:     Michael Hall
Module Name:  replicate2
Description:  Replicate 1 input port to 2 output ports with flow control.

This module will replicate data from 1 input port to 2 output ports while handling
flow control signals by asserting backpressure when necessary.
*********************************************************************************/
module replicate2(data_in, avail_in, ready_in, data_out0, avail_out0, ready_out0, data_out1, avail_out1, ready_out1, rst, clk);
	// Parameters
	parameter WIDTH = 16;

	localparam NUM_REPLICATION = 2;

	// Port declaration.
	input wire [WIDTH-1:0] data_in;
	input wire avail_in;
	output wire ready_in;

	output wire [WIDTH-1:0] data_out0;
	output wire avail_out0;
	input wire ready_out0;

	output wire [WIDTH-1:0] data_out1;
	output wire avail_out1;
	input wire ready_out1;

	input wire rst;
	input wire clk;

	// Wires.
	wire [0:NUM_REPLICATION-1] buf_avail_in ;
	wire [0:NUM_REPLICATION-1] buf_ready_in;
	wire [0:NUM_REPLICATION-1] buf_write_to_buffer;

	wire [WIDTH-1:0] buf_data_out [0:NUM_REPLICATION-1];
	wire [0:NUM_REPLICATION-1] buf_avail_out;
	wire [0:NUM_REPLICATION-1] buf_ready_out;

	// Registers.
	reg [0:NUM_REPLICATION-1] consumed;
	reg [0:NUM_REPLICATION-1] nconsumed;
	reg all_consumed;

	// Assignments.
	assign data_out0 = buf_data_out[0];
	assign avail_out0 = buf_avail_out[0];
	assign buf_ready_out[0] = ready_out0;
	assign data_out1 = buf_data_out[1];
	assign avail_out1 = buf_avail_out[1];
	assign buf_ready_out[1] = ready_out1;

	// Generate output buffers.
	genvar i;
	generate
		for (i=0; i<NUM_REPLICATION; i=i+1) begin: GEN_BUFFERS
			assign buf_write_to_buffer[i] = buf_avail_in[i] & buf_ready_in[i];
			assign buf_avail_in[i] = avail_in & ~consumed[i];

			buffer #(.WIDTH(WIDTH), .IMPL_TYPE("fifo")) u_buf (
				.data_in(data_in),
				.avail_in(buf_avail_in[i]),
				.ready_in(buf_ready_in[i]),
				.data_out(buf_data_out[i]),
				.avail_out(buf_avail_out[i]),
				.ready_out(buf_ready_out[i]),
				.rst(rst),
				.clk(clk)
			);
		end
	endgenerate

	// Sequential logic.
	integer k;
	always @(posedge clk) begin
		consumed <= nconsumed;
	end

	// Combinational logic.
	integer j;
	always @(*) begin
		all_consumed = 1'b0;
		nconsumed = consumed;
		if (rst) begin
			// Reset the consumed registers.
			nconsumed = {NUM_REPLICATION{1'b0}};
		end
		else begin
			// Mark when a buffer consumes a data value.  Keep track of whether all 
			// buffers have consumed data.
			for (j=0; j<NUM_REPLICATION; j=j+1)
				if (buf_write_to_buffer[j]) nconsumed[j] = 1'b1;
			all_consumed = &nconsumed;

			// If all buffers have consumed data, then clear the consumed register.  We
			// retain the all_consumed signal however for setting the ready_in signal.
			if (all_consumed) begin
				nconsumed = {NUM_REPLICATION{1'b0}};
			end
		end
	end
	assign ready_in = all_consumed;
endmodule


/********************************************************************************
Company:      Washington University in St. Louis
Engineer:     Michael Hall
Module Name:  sync_streams
Description:  Synchronize the data output of multiple streams.
*********************************************************************************/
module sync_streams(avail_in_array, ready_in_array, avail_out, ready_out);
	parameter NUM_STREAMS = 1;

	// Port declaration.
	input wire [0:NUM_STREAMS-1] avail_in_array;
	output wire [0:NUM_STREAMS-1] ready_in_array;
	output wire avail_out;
	input wire ready_out;

	// Assignments.
	assign avail_out = &avail_in_array;
	assign ready_in_array = {NUM_STREAMS{avail_out & ready_out}};
endmodule


/********************************************************************************
Company:      Washington University in St. Louis
Engineer:     Michael Hall
Module Name:  state_comb
Description:  Combinational logic of the state register for context-switched
              pipelined circuits.

In a context-switched pipelined circuit, "state_comb" implements the
combinational logic of a state register.  This logic is combined with other
combinational logic in a circuit and provides the next output value to a
register.

"d" is the input data.  "nq" is the next output data.  "en" is the enable signal.
"rst" is the reset signal.  "WIDTH" is the width of the input and output data.
"resetval" is the value used to reset the register to when "rst" is asserted
true.
*********************************************************************************/
module state_comb(d, q, nq, en, rst);
	parameter WIDTH                = 1;
	parameter [WIDTH-1:0] resetval = 0;

	input wire [WIDTH-1:0] d;
	input wire [WIDTH-1:0] q;
	output reg [WIDTH-1:0] nq;
	input wire en;
	input wire rst;

	always @(*) begin
		if (rst)
			nq <= resetval;
		else if (en)
			nq <= d;
		else
			nq <= q;
	end
endmodule


/********************************************************************************
Company:      Washington University in St. Louis
Engineer:     Michael Hall
Module Name:  state
Description:  State register for context-switched pipelined circuits.

In a context-switched pipelined circuit, "state" is a register that can be
enabled, reset, and clocked.  There is one global, synchronous clock in the
entire design.

"d" is the input data.  "q" is the output data.  "rst" is the reset which is 
always synchronous.  "clk" is the global, synchronous clock.  "WIDTH" sets the 
width of the register.  "C" controls the number of registers that are chained in 
sequence in a C-slowed design.  And, "resetval" is used to set the value of the 
register when "rst" is asserted true.

This module provides a convenient way to represent state in both regular and 
C-slowed systems.  In the future, this state may be replaced or supplemented with
a context-switch manager with secondary memory storage.
*********************************************************************************/
module state(d, q, rst, clk);
	parameter WIDTH                = 1;
	parameter C                    = 1;
	parameter [WIDTH-1:0] resetval = 0;

	input wire [WIDTH-1:0] d;                // D input
	output wire [WIDTH-1:0] q;               // Q output
	input wire rst;                          // Reset
	input wire clk;                          // Clock

	wire [WIDTH-1:0] nq;                     // Next Q

	state_comb #(.WIDTH(WIDTH), .resetval(resetval)) state_comb (
		.d(d),
		.q(q),
		.nq(nq),
		.en(1'b1),
		.rst(rst));
	pipe_reg #(.WIDTH(WIDTH), .DEPTH(C)) state_regs (
		.out(q),
		.in(nq),
		.clk(clk));
endmodule


/********************************************************************************
Company:      Washington University in St. Louis
Engineer:     Michael Hall
Module Name:  state_en
Description:  State register for context-switched pipelined circuits with enabled
              registers.

In a context-switched pipelined circuit, "state" is a register that can be
enabled, reset, and clocked.  There is one global, synchronous clock in the
entire design.

"d" is the input data.  "q" is the output data.  "en" is the enable signal.
"rst" is the reset which is always synchronous.  "clk" is the global, synchronous
clock.  "WIDTH" sets the width of the register.  "C" controls the number of 
registers that are chained in sequence in a C-slowed design.  And, "resetval" is
used to set the value of the register when "rst" is asserted true.

This module provides a convenient way to represent state in both regular and 
C-slowed systems.  In the future, this state may be replaced or supplemented with
a context-switch manager with secondary memory storage.
*********************************************************************************/
module state_en(d, q, en, rst, clk);
	parameter WIDTH                = 1;
	parameter C                    = 1;
	parameter [WIDTH-1:0] resetval = 0;

	input wire [WIDTH-1:0] d;                // D input
	output wire [WIDTH-1:0] q;               // Q output
	input wire en;                           // Enable
	input wire rst;                          // Reset
	input wire clk;                          // Clock

	wire [WIDTH-1:0] nq;                     // Next Q

	state_comb #(.WIDTH(WIDTH), .resetval(resetval)) state_comb (
		.d(d),
		.q(q),
		.nq(nq),
		.en(en),
		.rst(rst));
	pipe_reg_en #(.WIDTH(WIDTH), .DEPTH(C)) state_regs (
		.out(q),
		.in(nq),
		.en(en),
		.clk(clk));
endmodule


/********************************************************************************
Company:      Washington University in St. Louis
Engineer:     Michael Hall
Module Name:  fifo
Description:  General-purpose FIFO.

This module implements a FIFO of a given width and depth using either block RAM
or distributed RAM.
*********************************************************************************/
module fifo(DIN, DOUT, RE, WE, EMPTY, ONE, FULL, AFULL, DFULL, RST, CLK);
	// Calculate the address width - For example, an 8 element array requires 3 address bits.
	function integer CalcAddrWidth;
		input integer Size;
		integer Bits;
		begin
			Bits = 0;
			Size = Size - 1;
			while (Size > 0) begin
				Size = Size >> 1;
				Bits = Bits + 1;
			end
			CalcAddrWidth = Bits;
		end
	endfunction

	// Return the minimum of two numbers
	function integer Max;
		input integer A, B;
		begin
			if (A > B) Max = A;
			else Max = B;
		end
	endfunction

	parameter Depth = 4;            // Number of data elements in fifo
	parameter Width = 51;           // Width of data in fifo
	parameter UseBlockRAM = 1;      // Use Block RAM for the fifo implementation

	localparam RamAddrBits = Max(CalcAddrWidth(Depth), 1);
	localparam CntBits = CalcAddrWidth(Depth + 1);

	input wire [Width-1:0] DIN;     // Data written into the fifo
	output wire [Width-1:0] DOUT;   // Data read from the fifo
	input wire RE;                  // Read enable
	input wire WE;                  // Write enable
	output wire EMPTY;              // Empty
	output wire ONE;                // One element
	output wire FULL;               // Full
	output wire AFULL;              // Almost full (At most 1 space available)
	output wire DFULL;              // Dynamic full (adaptively select between Full and AFull)
	                                // -- Useful for using all the capacity of the FIFO without
	                                //    overrunning it in a Moore FSM

	input wire RST;                 // Reset
	input wire CLK;                 // Clock (40 MHz)

	generate
		if (Depth == 0) begin
			reg fifoCnt;

			// FIFO logic
			always @(posedge CLK) begin
				if (RST) begin
					fifoCnt = 0;
				end
				else begin
					if (RE && !EMPTY) begin
						fifoCnt = 0;
					end
					if (WE && !FULL) begin
						fifoCnt = 1;
					end
				end
			end
			assign EMPTY = (fifoCnt == 0);
			assign ONE   = (fifoCnt == 1);
			assign FULL  = (fifoCnt == 1);
			assign AFULL = FULL;
			assign DFULL = FULL;
			assign DOUT  = DIN;
		end
		else if (UseBlockRAM) begin
			// Block RAM instantiation
			reg [Width-1:0] fifoRAM [Depth-1:0];     // Block RAM for the fifo
			reg [RamAddrBits-1:0] fifoWriteAddr;     // Block RAM write address
			reg [RamAddrBits-1:0] fifoReadAddr;      // Block RAM read address
			wire fifoEn;                             // Block RAM ram-enable
			wire fifoWe;                             // Block RAM write-enable
			wire [Width-1:0] fifoInputData;          // Block RAM input data
			reg [Width-1:0] fifoOutputData;          // Block RAM output data
			reg [CntBits-1:0] fifoCnt;
			reg fifoOutputValid;

			always @(posedge CLK) begin
				if (fifoEn) begin
					if (fifoWe)
						fifoRAM[fifoWriteAddr] <= fifoInputData;
					fifoOutputData <= fifoRAM[fifoReadAddr];
				end
			end
			assign fifoEn = 1;
			assign fifoWe = WE && !FULL;

			// Output Buffer
			reg [Width-1:0] OutputBuffer;
			reg OutputBufferValid;
			reg RE_dly;
			reg WE_dly;

			// FIFO logic
			always @(posedge CLK) begin
				if (RST) begin
					fifoWriteAddr <= 0;
					fifoReadAddr <= 0;
					fifoCnt = 0;
					fifoOutputValid <= 0;

					OutputBufferValid <= 0;
					RE_dly <= 0;
				end
				else begin
					RE_dly <= RE;
					WE_dly <= WE;
					if (fifoCnt != 0)
						fifoOutputValid <= 1;

					if (!EMPTY) begin
						if (RE) begin
							OutputBufferValid <= 0;
							fifoCnt = fifoCnt - 1;
							if (fifoCnt != 0) begin
								if (fifoReadAddr == (Depth-1))
									fifoReadAddr <= 0;
								else
									fifoReadAddr <= fifoReadAddr + 1;
							end
						end
						else if (!OutputBufferValid) begin
							OutputBuffer <= fifoOutputData;
							OutputBufferValid <= 1;
							if (!RE_dly) begin
								if (fifoReadAddr == (Depth-1))
									fifoReadAddr <= 0;
								else
									fifoReadAddr <= fifoReadAddr + 1;
							end
						end
					end
					else if (WE_dly) begin
						RE_dly <= 1;
						if (fifoReadAddr == (Depth-1))
							fifoReadAddr <= 0;
						else
							fifoReadAddr <= fifoReadAddr + 1;
					end

					if (WE && !FULL) begin
						if (fifoCnt == 0)
							fifoOutputValid <= 0;
						if (fifoWriteAddr == (Depth-1))
							fifoWriteAddr <= 0;
						else
							fifoWriteAddr <= fifoWriteAddr + 1;
						fifoCnt = fifoCnt + 1;
					end
				end
			end
			assign EMPTY = (fifoCnt == 0) || !(fifoOutputValid || OutputBufferValid);
			assign ONE   = (fifoCnt == 1) && (fifoOutputValid || OutputBufferValid);
			assign FULL  = (fifoCnt == Depth);
			assign AFULL = (fifoCnt == Depth-1) || FULL;
			assign DFULL = (WE ? AFULL : FULL);

			assign fifoInputData = DIN;
			assign DOUT  = (OutputBufferValid ? OutputBuffer : fifoOutputData);
		end
		else begin
			// Distributed RAM instantiation
			reg [Width-1:0] fifoRAM [Depth-1:0];     // Distributed RAM for the fifo
			reg [RamAddrBits-1:0] fifoWriteAddr;     // Distributed RAM write address
			reg [RamAddrBits-1:0] fifoReadAddr;      // Distributed RAM read address
			wire fifoEn;                             // Distributed RAM ram-enable
			wire fifoWe;                             // Distributed RAM write-enable
			wire [Width-1:0] fifoInputData;          // Distributed RAM input data
			wire [Width-1:0] fifoOutputData;         // Distributed RAM output data
			reg [CntBits-1:0] fifoCnt;

			always @(posedge CLK) begin
				if (fifoEn) begin
					if (fifoWe)
						fifoRAM[fifoWriteAddr] <= fifoInputData;
				end
			end
			assign fifoOutputData = fifoRAM[fifoReadAddr];
			assign fifoEn = 1;
			assign fifoWe = WE && !FULL;

			// FIFO logic
			always @(posedge CLK) begin
				if (RST) begin
					fifoWriteAddr <= 0;
					fifoReadAddr <= 0;
					fifoCnt = 0;
				end
				else begin
					if (RE && !EMPTY) begin
						if (fifoReadAddr == (Depth-1))
							fifoReadAddr <= 0;
						else
							fifoReadAddr <= fifoReadAddr + 1;
						fifoCnt = fifoCnt - 1;
					end
					if (WE && !FULL) begin
						if (fifoWriteAddr == (Depth-1))
							fifoWriteAddr <= 0;
						else
							fifoWriteAddr <= fifoWriteAddr + 1;
						fifoCnt = fifoCnt + 1;
					end
				end
			end
			assign EMPTY = (fifoCnt == 0);
			assign ONE   = (fifoCnt == 1);
			assign FULL  = (fifoCnt == Depth);
			assign AFULL = (fifoCnt == Depth-1) || FULL;
			assign DFULL = (WE ? AFULL : FULL);

			assign fifoInputData = DIN;
			assign DOUT  = fifoOutputData;
		end
	endgenerate
endmodule


/********************************************************************************
Company:      Washington University in St. Louis
Engineer:     Michael Hall
Module Name:  shift_reg
Description:  General-purpose shift register.

This module implements a shift register that can take any arbitrary width input
and shift it for any arbitrary number of times through a chain of registers.
*********************************************************************************/
module shift_reg(out, outarray, in, inarray, load, parload, clr, en, rst, clk);
	parameter WIDTH      = 16;
	parameter DEPTH      = 4;
	parameter OA_MODE    = 0;           // 0=[outarray={in,sreg}] (default), 1=[outarray=sreg]
	parameter SR_MODE    = 0;           // 0=shift into MSB, 1=shift into LSB;

	localparam SR_ARRAY_WIDTH = WIDTH * DEPTH;
	localparam IN_ARRAY_WIDTH = (DEPTH==0 ? 1 : SR_ARRAY_WIDTH);
	localparam OUT_ARRAY_WIDTH = (OA_MODE==0 ? SR_ARRAY_WIDTH + WIDTH : (DEPTH==0 ? 1 : SR_ARRAY_WIDTH));

	output wire [WIDTH-1:0] out;                  // Output data
	output wire [OUT_ARRAY_WIDTH-1:0] outarray;   // Output data array
	input wire [WIDTH-1:0] in;                    // Input data
	input wire [IN_ARRAY_WIDTH-1:0] inarray;      // Input data array
	input wire load;                              // Load
	input wire parload;                           // Parallel load
	input wire clr;                               // Clear
	input wire en;                                // Enable

	input wire rst;                               // Reset
	input wire clk;                               // Clock

	generate
		if (DEPTH == 0) begin
			// Output the input.
			assign out = in;

			// Make the output array.
			if (OA_MODE == 0)
				assign outarray = in;
			else
				assign outarray = 1'bz;
		end
		else begin 
			reg [SR_ARRAY_WIDTH-1:0] sreg;        // Shift register
			integer i;
			always @(posedge clk) begin
				if (rst) begin
					// Zero the shift register upon reset.
					sreg <= {SR_ARRAY_WIDTH{1'b0}};
				end
				else if (en) begin
					if (clr) begin
						// Clear the shift register.
						sreg <= {SR_ARRAY_WIDTH{1'b0}};
					end
					else if (parload) begin
						// Parallel load the shift register.
						sreg <= inarray;
					end
					else if (load) begin
						if (SR_MODE == 0) begin
							// Shift into MSB.
							for (i=0; i<SR_ARRAY_WIDTH-WIDTH; i=i+1)
								sreg[i] <= sreg[i+WIDTH];
							sreg[SR_ARRAY_WIDTH-1:SR_ARRAY_WIDTH-WIDTH] <= in;
						end
						else begin
							// Shift into LSB.
							for (i=SR_ARRAY_WIDTH-1; i>=WIDTH; i=i-1)
								sreg[i] <= sreg[i-WIDTH];
							sreg[WIDTH-1:0] <= in;
						end
					end
				end
			end

			// Assign the output.
			if (SR_MODE == 0)
				// Output from the right.
				assign out = sreg[WIDTH-1:0];
			else
				// Output from the left.
				assign out = sreg[SR_ARRAY_WIDTH-1:SR_ARRAY_WIDTH-WIDTH];

			// Make the output array.
			if (OA_MODE == 0)
				assign outarray = {in, sreg};
			else
				assign outarray = sreg;
		end
	endgenerate
endmodule


/********************************************************************************
Company:      Washington University in St. Louis
Engineer:     Michael Hall
Module Name:  multiplexer
Description:  General-purpose multiplexer.

This multiplexer module takes any number of inputs and returns the selected
one to the output.  The inputs are packed into an input array "inarray".
*********************************************************************************/
module multiplexer(out, inarray, select);
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
	parameter WIDTH = 1;
	parameter NUM_INPUTS = 1;

	localparam ARRAY_WIDTH = WIDTH * NUM_INPUTS;
	localparam SELECT_WIDTH = countbits(NUM_INPUTS-1);

	// Port declaration
	output wire [WIDTH-1:0] out;
	input wire [ARRAY_WIDTH-1:0] inarray;
	input wire [SELECT_WIDTH-1:0] select;

	wire [WIDTH-1:0] in[0:NUM_INPUTS-1];

	// Unpack input array
	genvar unpk_idx;
	generate
		for (unpk_idx=0; unpk_idx<(NUM_INPUTS); unpk_idx=unpk_idx+1) begin: UNPACK
			assign in[unpk_idx] = inarray[WIDTH*unpk_idx +: WIDTH];
		end
	endgenerate

	// Implement the multiplexer
	assign out = in[select];
endmodule


/********************************************************************************
Company:      Washington University in St. Louis
Engineer:     Michael Hall
Module Name:  decoder
Description:  General-purpose decoder.

This decoder/demultiplexer module takes select and enable inputs and produces
decoder outputs with only one output selected if enable is true.  If enable is
false, then no outputs are selected.
*********************************************************************************/
module decoder(out, select, enable);
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
	parameter NUM_OUTPUTS = 16;
	localparam SELECT_WIDTH = countbits(NUM_OUTPUTS-1);

	// Port declaration
	output reg [0:NUM_OUTPUTS-1] out;
	input wire [SELECT_WIDTH-1:0] select;
	input wire enable;

	// Implement the decoder.
	always @(*) begin
		out <= {NUM_OUTPUTS{1'b0}};
		if (enable) begin
			if (select < NUM_OUTPUTS)
				out[select] <= 1'b1;
		end
	end
endmodule


/********************************************************************************
Company:      Washington University in St. Louis
Engineer:     Michael Hall
Module Name:  priority encoder
Description:  General-purpose priority encoder.

This priority encoder module takes in a set of inputs and encodes them to the
output according to the priority of the inputs.  This ensures that there is always
a valid value assigned to the output.  The priority is set by parameter PRIORITY
which is one of "high" or "low".  A "high" priority means that the higher bits
in the input have priority and will be encoded first.  Conversely, a "low"
priority means that the lower bits in the input have priority and will be
encoded first.  A valid flag is asserted out when any of the bits in the input
are set.  It is false if "in" is all zeros.  Note, the output "out" is still set
to whichever is considered the highest priority output value determined by the
PRIORITY parameter.
*********************************************************************************/
module priority_encoder(vld, out, in);
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
	parameter NUM_INPUTS = 4;
	parameter PRIORITY = "high";
	localparam OUT_WIDTH = countbits(NUM_INPUTS-1);

	// Port declaration
	output reg vld;
	output reg [OUT_WIDTH-1:0] out;
	input wire [NUM_INPUTS-1:0] in;

	// Implement the priority encoder.
	integer i;
	always @(*) begin
		vld <= 1'b0;
		if (PRIORITY == "low") begin
			out <= 0;
			for (i=NUM_INPUTS-1; i>=0; i=i-1) begin
				if (in[i]) begin
					out <= i;
					vld <= 1'b1;
				end
			end
		end
		else if (PRIORITY == "high") begin
			out <= NUM_INPUTS-1;
			for (i=0; i<NUM_INPUTS; i=i+1) begin
				if (in[i]) begin
					out <= i;
					vld <= 1'b1;
				end
			end
		end
		else begin
			out <= {OUT_WIDTH{1'b0}};
		end
	end
endmodule


/********************************************************************************
Company:      Washington University in St. Louis
Engineer:     Michael Hall
Module Name:  token_ring
Description:  General-purpose token ring.

This token ring module is implemented as a shift register.  Upon reset, the shift
register is initialized with all zeros except for the first register which is set
to 1.  At every clock, the token is passed around the token ring.  This continues
indefinitely.  The token will be passed only when enable is set true.
*********************************************************************************/
module token_ring(out, en, rst, clk);
	parameter SIZE = 16;

	output wire [SIZE-1:0] out;       // Output data
	input wire en;                    // Enable

	input wire rst;                   // Reset
	input wire clk;                   // Clock

	reg [SIZE-1:0] tk_ring;           // Token ring shift register

	integer i;
	always @(posedge clk) begin
		if (rst) begin
			tk_ring <= {SIZE{1'b0}};
			tk_ring[0] <= 1'b1;
		end
		else if (en) begin
			tk_ring <= {tk_ring[SIZE-2:0], tk_ring[SIZE-1]};
		end
	end
	assign out = tk_ring;
endmodule


/********************************************************************************
Company:      Washington University in St. Louis
Engineer:     Michael Hall
Module Name:  free_running_counter
Description:  Free running counter

This module implements a free running counter that automatically increments and
loops about some maximum number.  The free running counter can be enabled and
reset.  There are multiple implementations of the free running counter:

impl_type
---------
"counter":  Increment a counter directly to produce the free running count.
"encoder":  Pass a token around in a shift register.  Then pass it to an encoder.
*********************************************************************************/
module free_running_counter(out, en, rst, clk);
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
	parameter IMPL_TYPE = "counter";
	parameter MIN_COUNT = 0;
	parameter MAX_COUNT = 15;

	localparam WIDTH = countbits(MAX_COUNT);

	// Port declaration
	output wire [WIDTH-1:0] out;
	input wire en;
	input wire rst;
	input wire clk;

	// Encoder implementation parameters
	localparam TK_SIZE = MAX_COUNT - MIN_COUNT + 1;
	localparam PE_OUT_WIDTH = countbits(TK_SIZE-1);

	// Generate the specified implementation.
	generate
		if (IMPL_TYPE == "counter") begin
			reg [WIDTH-1:0] outcnt;
			always @(posedge clk) begin
				if (rst) begin
					outcnt <= MIN_COUNT;
				end
				else if (en) begin
					if (outcnt == MAX_COUNT)
						outcnt <= MIN_COUNT;
					else
						outcnt <= outcnt + 1;
				end
			end
			assign out = outcnt;
		end
		else if (IMPL_TYPE == "encoder") begin
			wire [TK_SIZE-1:0] tk_out;
			wire pe_vld;
			wire [PE_OUT_WIDTH-1:0] pe_out;
			wire [WIDTH-1:0] pe_out_expand;

			token_ring #(.SIZE(TK_SIZE)) tk (.out(tk_out), .en(en), .rst(rst), .clk(clk));
			priority_encoder #(.NUM_INPUTS(TK_SIZE), .PRIORITY("low")) pe (.vld(pe_vld), .out(pe_out), .in(tk_out));
			assign pe_out_expand = {{(WIDTH-PE_OUT_WIDTH){1'b0}}, pe_out};
			assign out = pe_out_expand + MIN_COUNT;
		end
	endgenerate
endmodule


/********************************************************************************
Company:      Washington University in St. Louis
Engineer:     Michael Hall
Module Name:  pulse_extender
Description:  Pulse extender
*********************************************************************************/
module pulse_extender(out, in, pulse_extended_count, en, clk);
	parameter COUNTER_WIDTH = 8;

	output wire out;
	input wire in;
	input wire [COUNTER_WIDTH-1:0] pulse_extended_count;
	input wire en;
	input wire clk;

	reg [COUNTER_WIDTH-1:0] cntr;
	reg out_reg = 1'b0;

	always @(posedge clk) begin
		if (en) begin
			if (in) begin
				cntr <= 2;
				if (pulse_extended_count > 1)
					out_reg <= 1'b1;
			end
			else begin
				if (cntr == pulse_extended_count)
					out_reg <= 1'b0;
				else
					cntr <= cntr + 1;
			end
		end
	end
	assign out = (in & (pulse_extended_count != 0)) | out_reg;
endmodule


/********************************************************************************
Company:      Washington University in St. Louis
Engineer:     Michael Hall
Module Name:  ser2par
Description:  Serial-to-parallel converter.
*********************************************************************************/
module ser2par(serin_data, serin_last, serin_avail_in, serin_ready_in, parout_data, parout_avail_out, parout_ready_out, rst, clk);

	// Parameters.
	parameter SERIN_WIDTH = 16;
	parameter SERIN_DEPTH = 4;

	localparam PAROUT_WIDTH = SERIN_WIDTH * SERIN_DEPTH;

	// Port declaration.
	input wire [SERIN_WIDTH-1:0] serin_data;
	input wire serin_last;
	input wire serin_avail_in;
	output wire serin_ready_in;
	output wire [PAROUT_WIDTH-1:0] parout_data;
	output reg parout_avail_out;
	input wire parout_ready_out;
	input wire rst;
	input wire clk;

	// Wires.
	wire sr_shift;

	// Input shift register.
	shift_reg #(.WIDTH(32), .DEPTH(SERIN_DEPTH), .OA_MODE(1), .SR_MODE(1)) u_sr_in (
		.out(),
		.outarray(parout_data),
		.in(serin_data),
		.inarray(),
		.load(sr_shift),
		.parload(1'b0),
		.clr(1'b0),
		.en(1'b1),
		.rst(rst),
		.clk(clk)
	);

	// Sequential logic.
	always @(posedge clk) begin
		if (rst)
			parout_avail_out <= 1'b0;
		else
			parout_avail_out <= parout_avail_out & ~parout_ready_out | serin_last;
	end

	// Assignments.
	assign sr_shift = serin_avail_in & serin_ready_in;
	assign serin_ready_in = parout_ready_out | ~parout_avail_out;
endmodule


/********************************************************************************
Company:      Washington University in St. Louis
Engineer:     Michael Hall
Module Name:  par2ser
Description:  Parallel-to-serial converter.
*********************************************************************************/
module par2ser(parin_data, parin_avail_in, parin_ready_in, serout_data, serout_first, serout_last, serout_avail_out, serout_ready_out, rst, clk);

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
	parameter SEROUT_WIDTH = 16;
	parameter SEROUT_DEPTH = 4;

	localparam PARIN_WIDTH = SEROUT_WIDTH * SEROUT_DEPTH;
	localparam SEROUT_DEPTH_BITS = countbits(SEROUT_DEPTH);

	// Port declaration.
	input wire [PARIN_WIDTH-1:0] parin_data;
	input wire parin_avail_in;
	output wire parin_ready_in;
	output wire [SEROUT_WIDTH-1:0] serout_data;
	output wire serout_first;
	output wire serout_last;
	output wire serout_avail_out;
	input wire serout_ready_out;
	input wire rst;
	input wire clk;

	// Wires.
	wire sr_shift;
	wire sr_parload;

	reg serout_state, nserout_state;
	reg [SEROUT_DEPTH_BITS-1:0] serout_cnt, nserout_cnt;

	// Output shift register.
	shift_reg #(.WIDTH(32), .DEPTH(SEROUT_DEPTH), .OA_MODE(1), .SR_MODE(1)) u_sr_out (
		.out(serout_data),
		.outarray(),
		.in(32'h0),
		.inarray(parin_data),
		.load(sr_shift),
		.parload(sr_parload),
		.clr(1'b0),
		.en(1'b1),
		.rst(rst),
		.clk(clk)
	);

	// Sequential process
	always @(posedge clk) begin
		serout_state <= nserout_state;
		serout_cnt <= nserout_cnt;
	end

	// Combinational process
	always @(*) begin
		nserout_state <= serout_state;
		nserout_cnt   <= serout_cnt;

		if (rst) begin
			nserout_state <= 0;
			nserout_cnt <= 0;
		end
		else begin
			case (serout_state)
				0: begin
					if (parin_avail_in) begin
						nserout_state <= 1;
						nserout_cnt <= 0;
					end
				end
				1: begin
					if (sr_shift) begin
						if (serout_last) begin
							if (sr_parload)
								nserout_state <= 1;
							else
								nserout_state <= 0;
							nserout_cnt <= 0;
						end
						else
							nserout_cnt <= serout_cnt + 1;
					end
				end
				default: begin
					nserout_state <= 0;
				end
			endcase
		end
	end

	// Assignments.
	assign sr_parload = parin_avail_in & parin_ready_in;
	assign serout_first = (serout_cnt == 0);
	assign serout_last  = (serout_cnt == SEROUT_DEPTH-1);
	assign serout_avail_out = (serout_state == 1);
	assign sr_shift = serout_avail_out & serout_ready_out;
	assign parin_ready_in = (serout_state == 0) | sr_shift & serout_last;
endmodule
