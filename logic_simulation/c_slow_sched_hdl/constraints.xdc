set_property PACKAGE_PIN G30 [get_ports {clk}]


create_clock -period 1000.00 -name clk -waveform {0.000 5.000} [get_ports clk]

set_false_path -from [get_ports {reset_l}]
set_false_path -to [get_ports {n_select[0]}]
set_false_path -to [get_ports {n_select[1]}]
set_false_path -to [get_ports {n_select[2]}]
set_false_path -to [get_ports {n_select[3]}]
set_false_path -to [get_ports {n_select[4]}]
set_false_path -to [get_ports {n_select[5]}]
set_false_path -to [get_ports {n_select[6]}]
set_false_path -to [get_ports {n_select[7]}]
