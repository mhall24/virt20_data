set_property PACKAGE_PIN D13 [get_ports {clk}]


create_clock -period 1000.00 -name clk -waveform {0.000 5.000} [get_ports clk]

set_property PACKAGE_PIN K16 [get_ports {reset_l}]
set_property PACKAGE_PIN L17 [get_ports {n_select[0]}]
set_property PACKAGE_PIN J15 [get_ports {n_select[1]}]
set_property PACKAGE_PIN J16 [get_ports {n_select[2]}]
set_property PACKAGE_PIN J18 [get_ports {n_select[3]}]
set_property PACKAGE_PIN K18 [get_ports {n_select[4]}]
set_property PACKAGE_PIN K17 [get_ports {n_select[5]}]
set_property PACKAGE_PIN L18 [get_ports {n_select[6]}]
set_property PACKAGE_PIN J14 [get_ports {n_select[7]}]

set_property PACKAGE_PIN K15 [get_ports {q1[1]}]
set_property PACKAGE_PIN L15 [get_ports {q1[2]}]
set_property PACKAGE_PIN M15 [get_ports {q1[3]}]
set_property PACKAGE_PIN M16 [get_ports {q1[4]}]
set_property PACKAGE_PIN M17 [get_ports {q1[5]}]
set_property PACKAGE_PIN M14 [get_ports {q1[6]}]
set_property PACKAGE_PIN N14 [get_ports {q1[7]}]
set_property PACKAGE_PIN N16 [get_ports {q1[0]}]

set_property PACKAGE_PIN N17 [get_ports {q2[1]}]
set_property PACKAGE_PIN N18 [get_ports {q2[2]}]
set_property PACKAGE_PIN P18 [get_ports {q2[3]}]
set_property PACKAGE_PIN P15 [get_ports {q2[4]}]
set_property PACKAGE_PIN P16 [get_ports {q2[5]}]
set_property PACKAGE_PIN P14 [get_ports {q2[6]}]
set_property PACKAGE_PIN R15 [get_ports {q2[7]}]
set_property PACKAGE_PIN T14 [get_ports {q2[0]}]

set_property PACKAGE_PIN T15 [get_ports {q3[1]}]
set_property PACKAGE_PIN R16 [get_ports {q3[2]}]
set_property PACKAGE_PIN R17 [get_ports {q3[3]}]
set_property PACKAGE_PIN R18 [get_ports {q3[4]}]
set_property PACKAGE_PIN T18 [get_ports {q3[5]}]
set_property PACKAGE_PIN T17 [get_ports {q3[6]}]
set_property PACKAGE_PIN U17 [get_ports {q3[7]}]
set_property PACKAGE_PIN U15 [get_ports {q3[0]}]

set_property PACKAGE_PIN U16 [get_ports {q4[1]}]
set_property PACKAGE_PIN V16 [get_ports {q4[2]}]
set_property PACKAGE_PIN V17 [get_ports {q4[3]}]
set_property PACKAGE_PIN R13 [get_ports {q4[4]}]
set_property PACKAGE_PIN T13 [get_ports {q4[5]}]
set_property PACKAGE_PIN U14 [get_ports {q4[6]}]
set_property PACKAGE_PIN V14 [get_ports {q4[7]}]
set_property PACKAGE_PIN V12 [get_ports {q4[0]}]

set_property PACKAGE_PIN V13 [get_ports {q5[1]}]
set_property PACKAGE_PIN T12 [get_ports {q5[2]}]
set_property PACKAGE_PIN U12 [get_ports {q5[3]}]
set_property PACKAGE_PIN U11 [get_ports {q5[4]}]
set_property PACKAGE_PIN U9 [get_ports {q5[5]}]
set_property PACKAGE_PIN V9 [get_ports {q5[6]}]
set_property PACKAGE_PIN U10 [get_ports {q5[7]}]
set_property PACKAGE_PIN D10 [get_ports {q5[0]}]

set_property PACKAGE_PIN D8 [get_ports {q6[1]}]
set_property PACKAGE_PIN C8 [get_ports {q6[2]}]
set_property PACKAGE_PIN D9 [get_ports {q6[3]}]
set_property PACKAGE_PIN C9 [get_ports {q6[4]}]
set_property PACKAGE_PIN B9 [get_ports {q6[5]}]
set_property PACKAGE_PIN A9 [get_ports {q6[6]}]
set_property PACKAGE_PIN C11 [get_ports {q6[7]}]
set_property PACKAGE_PIN B11 [get_ports {q6[0]}]

set_property PACKAGE_PIN B10 [get_ports {q7[1]}]
set_property PACKAGE_PIN A10 [get_ports {q7[2]}]
set_property PACKAGE_PIN D11 [get_ports {q7[3]}]
set_property PACKAGE_PIN C12 [get_ports {q7[4]}]
set_property PACKAGE_PIN B12 [get_ports {q7[5]}]
set_property PACKAGE_PIN A12 [get_ports {q7[6]}]
set_property PACKAGE_PIN A13 [get_ports {q7[7]}]
set_property PACKAGE_PIN A14 [get_ports {q7[0]}]

set_property PACKAGE_PIN C14 [get_ports {q8[1]}]
set_property PACKAGE_PIN B15 [get_ports {q8[2]}]
set_property PACKAGE_PIN B14 [get_ports {q8[3]}]
set_property PACKAGE_PIN A15 [get_ports {q8[4]}]
set_property PACKAGE_PIN G17 [get_ports {q8[5]}]
set_property PACKAGE_PIN C13 [get_ports {q8[6]}]
set_property PACKAGE_PIN E13 [get_ports {q8[7]}]
set_property PACKAGE_PIN D14 [get_ports {q8[0]}]

set_property PACKAGE_PIN E15 [get_ports {fb_flags[0]}]
set_property PACKAGE_PIN D15 [get_ports {fb_flags[1]}]
set_property PACKAGE_PIN E16 [get_ports {fb_flags[2]}]
set_property PACKAGE_PIN D16 [get_ports {fb_flags[3]}]
set_property PACKAGE_PIN B16 [get_ports {fb_flags[4]}]
set_property PACKAGE_PIN A17 [get_ports {fb_flags[5]}]
set_property PACKAGE_PIN C16 [get_ports {fb_flags[6]}]
set_property PACKAGE_PIN B17 [get_ports {fb_flags[7]}]

set_property IOSTANDARD LVCMOS33 [get_ports {clk}]

set_property IOSTANDARD LVCMOS33 [get_ports {reset_l}]
set_property IOSTANDARD LVCMOS33 [get_ports {n_select[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {n_select[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {n_select[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {n_select[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {n_select[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {n_select[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {n_select[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {n_select[7]}]

set_property IOSTANDARD LVCMOS33 [get_ports {q1[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q1[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q1[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q1[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q1[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q1[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q1[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q1[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports {q2[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q2[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q2[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q2[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q2[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q2[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q2[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q2[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports {q3[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q3[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q3[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q3[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q3[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q3[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q3[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q3[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports {q4[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q4[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q4[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q4[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q4[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q4[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q4[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q4[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports {q5[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q5[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q5[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q5[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q5[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q5[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q5[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q5[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports {q6[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q6[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q6[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q6[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q6[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q6[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q6[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q6[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports {q7[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q7[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q7[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q7[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q7[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q7[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q7[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q7[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports {q8[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q8[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q8[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q8[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q8[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q8[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q8[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {q8[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports {fb_flags[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fb_flags[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fb_flags[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fb_flags[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fb_flags[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fb_flags[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fb_flags[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fb_flags[7]}]