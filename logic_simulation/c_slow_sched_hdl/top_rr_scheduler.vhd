-- Round Robin Scheduler Top Module
-- Designer: Neil E. Olson
-- Date: 6/26/2018
-- CSE Independent Study, Washington University in St. Louis

-- Description: This module houses the "black box" pipeline, queues, and the round robin scheduler hardware. Data is 2 bits, N = 8, C = 4. 


  LIBRARY IEEE;
  USE IEEE.STD_LOGIC_1164.ALL;
  USE IEEE.STD_LOGIC_ARITH.ALL;
  USE IEEE.STD_LOGIC_UNSIGNED.ALL; 

  
  ENTITY top_rr_scheduler IS 
  PORT(
	clk : IN STD_LOGIC ; 
	reset_l : IN STD_LOGIC) ;  
  END top_rr_scheduler ; 
  
  
  ARCHITECTURE structural OF top_rr_scheduler IS 
  
  COMPONENT bb_pipeline
  PORT(
	clk : IN STD_LOGIC ;
	n_sel_in : IN STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
	n_sel_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
	data : IN STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
	feedback : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
	reset_l : IN STD_LOGIC ; 
	output : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)) ; 
  END COMPONENT ; 
  
  
  COMPONENT n_eight_q_a_f 
  PORT(
	clk : IN STD_LOGIC ; 
	reset_l : IN STD_LOGIC ; 
	q_activator : IN STD_LOGIC_VECTOR(7 DOWNTO 0) ;
	in_num : IN STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
	queue_flags : OUT STD_LOGIC_VECTOR(63 DOWNTO 0) ; 
	mux_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
	sch_sigs : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
	n_sel : IN STD_LOGIC_VECTOR(7 DOWNTO 0) ;
	ovflo : OUT STD_LOGIC) ;  
  END COMPONENT ; 
		
		
  COMPONENT fb_queue
  PORT( 
	clk : IN STD_LOGIC ; 
	pipe_out : IN STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
	sch_sigs : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) ;
	reset_l : IN STD_LOGIC ; 
	reg_enb : IN STD_LOGIC_VECTOR(7 DOWNTO 0) ;
	mux2_sel : IN STD_LOGIC_VECTOR(7 DOWNTO 0) ;
	fb_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
	valid_pipe_in : IN STD_LOGIC) ; 
  END COMPONENT ; 
  
  
  COMPONENT result_counter 
  PORT(
	clk : IN STD_LOGIC ; 
	reset_l : IN STD_LOGIC ; 
	pipeline_output : IN STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
	test_done : OUT STD_LOGIC ; 
	ovflo : IN STD_LOGIC) ;  
  END COMPONENT ; 
  
  COMPONENT data_feeder
  PORT(
	clk : IN STD_LOGIC ; 
	reset_l : IN STD_LOGIC ; 
	n_select : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
	data : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)) ;  
  END COMPONENT ; 
  
  
  COMPONENT rr_scheduler
  PORT(
	clk : IN STD_LOGIC ; 
	reset_l : IN STD_LOGIC ; 
	n_select : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)) ; 
  END COMPONENT ; 
  
  COMPONENT occupancy_count 
  PORT(
	clk : IN STD_LOGIC ; 
	reset_l : IN STD_LOGIC ; 
	q_flags : IN STD_LOGIC_VECTOR(63 DOWNTO 0)) ;  
  END COMPONENT ; 
  
  
  SIGNAL data_from_feeder : STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
  SIGNAL fb_data : STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
  SIGNAL input_q_sel : STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
  SIGNAL feeder_n_sel : STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
  SIGNAL data_from_q : STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
  SIGNAL in_q_flags_to_sch : STD_LOGIC_VECTOR(7 DOWNTO 0) ;
  SIGNAL fb_q_flags_to_sch : STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
  SIGNAL pipe_2_fb_q_sel : STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
  SIGNAL pipe_out : STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
  SIGNAL done : STD_LOGIC ; 
  SIGNAL ovflo : STD_LOGIC ; 
  SIGNAL fb_in_all_valid : STD_LOGIC_VECTOR(7 DOWNTO 0) ;
  SIGNAL sub_q_flags : STD_LOGIC_VECTOR(63 DOWNTO 0) ; 
  
  
  BEGIN 
  
  input_queue : n_eight_q_a_f 
  PORT MAP(
	clk => clk, 
	reset_l => reset_l, 
	q_activator => feeder_n_sel,
	in_num => data_from_feeder, 
	mux_out => data_from_q,
	sch_sigs => in_q_flags_to_sch,
	queue_flags => sub_q_flags,
	n_sel => fb_in_all_valid,
	ovflo => ovflo) ; 
	
	
  testbench : data_feeder
  PORT MAP( 
	clk => clk, 
	reset_l => reset_l, 
	n_select => feeder_n_sel,
	data => data_from_feeder);
	
  round_robin : rr_scheduler
  PORT MAP(
	clk => clk,
	reset_l => reset_l,
	n_select => input_q_sel) ;
  
  pipe : bb_pipeline
  PORT MAP(
	clk => clk,
	n_sel_in => input_q_sel,
	n_sel_out => pipe_2_fb_q_sel,
	data => data_from_q,
	feedback => fb_data,
	reset_l => reset_l, 
	output => pipe_out) ;
	
  fb_q : fb_queue 
  PORT MAP( 
	clk => clk, 
	pipe_out => pipe_out, 
	sch_sigs => fb_q_flags_to_sch,
	reset_l => reset_l,
	reg_enb => pipe_2_fb_q_sel,
	mux2_sel => fb_in_all_valid,
	fb_out => fb_data, 
	valid_pipe_in => data_from_q(0)) ;   
	
  counter : result_counter
  PORT MAP(
	clk => clk, 
	reset_l => reset_l,
	pipeline_output => pipe_out, 
	test_done => done,
	ovflo => ovflo); 
	
  occ_counter : occupancy_count 
  PORT MAP(
	clk => clk, 
	reset_l => reset_l, 
	q_flags => sub_q_flags) ; 
  

  fb_in_all_valid <= fb_q_flags_to_sch(7 DOWNTO 0) AND input_q_sel(7 DOWNTO 0) ; 
  
  
  END structural ; 
  
  
  
  
  
  
  
  