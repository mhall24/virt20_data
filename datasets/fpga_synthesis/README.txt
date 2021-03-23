Column descriptions of data result files for COS, AES, and SHA.  Note, columns
specific to certain applications are indicated in parenthesis after the names.
The columns are described as follows:

run_index
 - The run index of all runs done in order.
sort_order
 - A designated sort order for human viewing that groups all replications
   together for the runs.
timestamp
 - The time at which the run was done.
elapsed_time[s]
 - The total execution time of the run.
peak_mem_MB
 - The peak memory used in the run in megabytes.
CSLOW_MODE (cos, aes)
 - C-slow mode for COS or AES.  MANPIPE is manually pipelined.  Pipeline stages
   are explicitly added and balanced in the design for a given C.
Allow_BRAM (cos, aes)
 - Whether or not Block RAM is allowed in FPGA synthesis.
UseDSP48s (cos)
 - Whether or not DSP48s are allowed in FPGA synthesis.
NUM_TERMS (cos)
 - The number of Taylor-series terms used in approximating the Cosine function.
ENC_MODE (aes)
 - The encryption mode of AES.  This is to encrypt or decrypt.
Nr (aes)
 - Number of rounds of AES.  For AES 256-bit standard, this is 14 rounds.
NUM_COPIES (cos, aes)
 - For a virtualized design, this is the "C" parameter, or the number of
   pipeline stages in the design allowing for C independent streams of
   computation.
 - For a replicated design, this is the number of copies of a non-pipelined
   design, also allowing for C independent streams of computation, but with much
   higher resource usage.
PAR_MODE (cos, aes)
 - Parallel mode.  This may be virtual (VIRT) or replicated (REPL).  Virtual
   uses a pipelined design.  Replicated uses multiple copies of a non-pipelined
   design.
HASH_TYPE (sha)
 - SHA-2 hash type.  This is either SHA-256 or SHA-512.
HASH_ROUNDS (sha)
 - SHA-2 hash rounds.  This is either 64 rounds for SHA-256 or 80 rounds for
   SHA-512.
NUM_PIPE_STAGES (sha)
 - This is the "C" parameter in SHA-2, or the number of pipeline stages allowing
   for C independent streams of computation.
HASH_IMPL (sha)
 - SHA-2 hash implementation.  This is either virtualized or sequential.
VIRT_IN_DEPTH (sha)
 - This is the input content-addressable queue length for a virtualized
   implementation.
VIRT_OUT_DEPTH (sha)
 - This is the output reorder buffer depth for a virtualized implementation.
Clk_Period_Constraint (sha)
 - Clock period constraint in seconds.  This is the maximum time in seconds
   that the clock period is allowed.  It is set to 1 second to indicate
   unconstrained.
repl_index
 - The replication index.
Slices (cos, aes, sha)
 - The number of slices used in a synthesized FPGA circuit.
Slice-FF (cos, aes), Slice Registers (sha)
 - The number of slice flip-flops used in a synthesized FPGA circuit.
4-LUT (cos, aes), Slice LUTs (sha)
 - The number of 4-input lookup tables used in a synthesized FPGA circuit.
LUT as Logic (sha)
 - The number of 4-input lookup tables used as logic in a synthesized FPGA
   circuit.
LUT as Memory (sha)
 - The number of 4-input lookup tables used as memory in a synthesized FPGA
   circuit.
Bonded I/O (cos, aes), Bonded IOBs (sha)
 - The number of I/O pins used in a synthesized FPGA circuit.
DSP48 (cos, aes), DSPs (sha)
 - The number of DSP48 hardware blocks used in a synthesized FPGA circuit.
BRAMs (cos, aes, sha)
 - The number of block RAMs used in a synthesized FPGA circuit.
Syn_minorClk_T (cos, aes)
 - Synthesized, minor clock period.  Internal to the (parallel) interface, the
   multiplexer, C-slowed hardware block, and demultiplexer all operate on the
   minor clock.
Syn_majorClk_T (cos, aes)
 - Synthesized, major clock period.  The data provided to the (parallel)
   interface operates on the major clock.
Par_minorClk_T (cos, aes)
 - Place & route, minor clock period
Par_majorClk_T (cos, aes)
 - Place & route, major clock period
Syn_minorClk_Freq (cos, aes)
 - Synthesized, minor clock frequency
Syn_majorClk_Freq (cos, aes)
 - Synthesized, major clock frequency
Par_minorClk_Freq (cos, aes)
 - Place & route, minor clock frequency
Par_majorClk_Freq (cos, aes)
 - Place & route, major clock frequency
Syn_selClk_T (cos, aes)
 - Synthesized, selected clock period
Par_selClk_T (cos, aes)
 - Place & route, selected clock period
Syn_selClk_Freq (cos, aes)
 - Synthesized, selected clock frequency
Par_selClk_Freq (cos, aes)
 - Place & route, selected clock frequency
pr_Clk_T (sha)
 - Place & route, clock period
pr_Clk_Freq (sha)
 - Place & route, clock frequency
Stream_Freq
 - The throughput of an individual stream of the synthesized FPGA circuit.
Total_Throughput
 - The total throughput of the synthesized FPGA circuit.
