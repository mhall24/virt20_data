-- C-Slow Scheduler Top Module
-- Designer: Neil E. Olson
-- Date: 6/16/2018
-- CSE Independent Study, Washington University in St. Louis

-- Description: This module houses the "black box" pipeline, queues, and the scheduler hardware. Data is 2 bits, N = 8, C = 4. 


  LIBRARY IEEE;
  USE IEEE.STD_LOGIC_1164.ALL;
  USE IEEE.STD_LOGIC_ARITH.ALL;
  USE IEEE.STD_LOGIC_UNSIGNED.ALL; 
  USE IEEE.STD_LOGIC_TEXTIO.ALL; 
  USE STD.TEXTIO.ALL;
  
  ENTITY c_slow_top IS 
  PORT(
	clk : IN STD_LOGIC
	reset_l : IN STD_LOGIC) ;  
  END c_slow_top ; 
  
  
  ARCHITECTURE structural OF c_slow_top IS 
  
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
  
  
  COMPONENT n_eight_q 
  PORT(
	clk : IN STD_LOGIC ; 
	reset_l : IN STD_LOGIC ; 
	q_activator : IN STD_LOGIC_VECTOR(7 DOWNTO 0) ;
	in_num : IN STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
	mux_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
	sch_sigs : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
	n_sel : IN STD_LOGIC_VECTOR(7 DOWNTO 0)) ;  
  END COMPONENT ; 
		
		
  COMPONENT fb_queue
  PORT( 
	clk : IN STD_LOGIC ; 
	pipe_out : IN STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
	sch_sigs : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) ;
	reset_l : IN STD_LOGIC ; 
	reg_enb : IN STD_LOGIC_VECTOR(7 DOWNTO 0) ;
	mux2_sel : IN STD_LOGIC_VECTOR(7 DOWNTO 0) ;
	fb_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)) ; 
  END COMPONENT ; 
  
  
  COMPONENT result_counter 
  PORT(
	clk : IN STD_LOGIC ; 
	reset_l : IN STD_LOGIC ; 
	pipeline_output : IN STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
	test_done : OUT STD_LOGIC) ;  
  END COMPONENT ; 
  
  COMPONENT data_feeder
  PORT(
	clk : IN STD_LOGIC ; 
	reset_l : IN STD_LOGIC ; 
	n_select : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
	data : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)) ;  
  END COMPONENT ; 
  
  
  COMPONENT scheduler
  PORT(
  
  END COMPONENT ; 
  
  
  
  BEGIN 
  
  
  
  
  
  
  
  END structural ; 
  
  
  
  
  
  
  
  