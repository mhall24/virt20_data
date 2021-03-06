-- Input Queue With N=8
-- Designer: Neil E. Olson
-- Date: 7/10/2018
-- CSE Independent Study, Washington University in St. Louis

-- Description: A variation of an N=8 queue that also provides all of the status flags for each sub-queue. This is for the most_full_sch module. 


  LIBRARY IEEE;
  USE IEEE.STD_LOGIC_1164.ALL;
  USE IEEE.STD_LOGIC_ARITH.ALL;
  USE IEEE.STD_LOGIC_UNSIGNED.ALL; 
  
  ENTITY n_eight_q_a_f IS 
  PORT(
	clk : IN STD_LOGIC ; 
	reset_l : IN STD_LOGIC ; 
	q_activator : IN STD_LOGIC_VECTOR(7 DOWNTO 0) ; -- The LSB corresponds to queue N1. The MSB is queue N8. 
	in_num : IN STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
	queue_flags : OUT STD_LOGIC_VECTOR(63 DOWNTO 0) ; -- Bit zero is the first flag of the first queue. Bit 63 is the 8th flag of the 8th queue. 
	mux_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
	sch_sigs : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
	n_sel : IN STD_LOGIC_VECTOR(7 DOWNTO 0) ; -- The LSB triggers the output (and activation) of N1. MSB triggers N8 to output. 
	ovflo : OUT STD_LOGIC) ;  -- Signals one of the queues is full.  
  END n_eight_q_a_f ; 
  
  
  ARCHITECTURE structural OF n_eight_q_a_f IS 
  
  COMPONENT in_queue_a_f
  PORT( clk : IN STD_LOGIC ; 
		in_num : IN STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
		sched_sig : OUT STD_LOGIC ; 
		reset_l : IN STD_LOGIC ; 
		q_flags : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) ;
		out_num : OUT STD_LOGIC_VECTOR(1 DOWNTO 0) ;
		sch_act : IN STD_LOGIC ;
		in_act : IN STD_LOGIC ; 
		ovflo : OUT STD_LOGIC) ;
  END COMPONENT ; 
  
  SIGNAL n1_out : STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
  SIGNAL n2_out : STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
  SIGNAL n3_out : STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
  SIGNAL n4_out : STD_LOGIC_VECTOR(1 DOWNTO 0) ;  
  SIGNAL n5_out : STD_LOGIC_VECTOR(1 DOWNTO 0) ;  
  SIGNAL n6_out : STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
  SIGNAL n7_out : STD_LOGIC_VECTOR(1 DOWNTO 0) ;  
  SIGNAL n8_out : STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
  SIGNAL ovflo_sig : STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
  
  BEGIN 
  
  n1 : in_queue_a_f 
  PORT MAP( clk => clk, 
		in_num => in_num,
		sched_sig => sch_sigs(0),
		reset_l => reset_l, 
		out_num =>  n1_out,
		sch_act => n_sel(0),
		q_flags => queue_flags(7 DOWNTO 0),
		in_act => q_activator(0),
		ovflo => ovflo_sig(0)) ; 
  
  n2 : in_queue_a_f 
  PORT MAP( clk => clk, 
		in_num => in_num,
		sched_sig => sch_sigs(1),
		reset_l => reset_l, 
		out_num =>  n2_out,
		sch_act =>  n_sel(1),
		q_flags => queue_flags(15 DOWNTO 8), 
		in_act => q_activator(1),
		ovflo => ovflo_sig(1)) ;  
  
  n3 : in_queue_a_f 
  PORT MAP( clk => clk, 
		in_num => in_num,
		sched_sig => sch_sigs(2),
		reset_l => reset_l, 
		out_num =>  n3_out,
		sch_act => n_sel(2),
		q_flags => queue_flags(23 DOWNTO 16),
		in_act => q_activator(2),
		ovflo => ovflo_sig(2)) ;  
  
  n4 : in_queue_a_f 
  PORT MAP( clk => clk, 
		in_num => in_num,
		sched_sig => sch_sigs(3),
		reset_l => reset_l, 
		out_num =>  n4_out,
		sch_act => n_sel(3),
		q_flags => queue_flags(31 DOWNTO 24), 
		in_act => q_activator(3),
		ovflo => ovflo_sig(3)) ;  
  
  n5 : in_queue_a_f 
  PORT MAP( clk => clk, 
		in_num => in_num,
		sched_sig => sch_sigs(4),
		reset_l => reset_l, 
		out_num =>  n5_out,
		sch_act => n_sel(4),
		q_flags => queue_flags(39 DOWNTO 32),
		in_act => q_activator(4),
		ovflo => ovflo_sig(4)) ;  
  
  n6 : in_queue_a_f 
  PORT MAP( clk => clk, 
		in_num => in_num,
		sched_sig => sch_sigs(5),
		reset_l => reset_l, 
		out_num =>  n6_out,
		sch_act => n_sel(5),
		q_flags => queue_flags(47 DOWNTO 40),
		in_act => q_activator(5),
		ovflo => ovflo_sig(5)) ;  
  
  n7 : in_queue_a_f 
  PORT MAP( clk => clk, 
		in_num => in_num,
		sched_sig => sch_sigs(6),
		reset_l => reset_l, 
		out_num =>  n7_out,
		sch_act => n_sel(6),
		q_flags => queue_flags(55 DOWNTO 48), 
		in_act => q_activator(6),
		ovflo => ovflo_sig(6)) ; 
  
  n8 : in_queue_a_f 
  PORT MAP( clk => clk, 
		in_num => in_num,
		sched_sig => sch_sigs(7),
		reset_l => reset_l, 
		out_num =>  n8_out,
		sch_act => n_sel(7), 
		q_flags => queue_flags(63 DOWNTO 56), 		
		in_act => q_activator(7),
		ovflo => ovflo_sig(7)) ; 
  
  
  WITH n_sel SELECT 
	mux_out <= n1_out WHEN "00000001", 
			   n2_out WHEN "00000010", 
			   n3_out WHEN "00000100", 
			   n4_out WHEN "00001000", 
			   n5_out WHEN "00010000", 
			   n6_out WHEN "00100000", 
			   n7_out WHEN "01000000", 
			   n8_out WHEN "10000000", 
			   "00" WHEN OTHERS ; 
  
  
  ovflo <= ovflo_sig(0) OR ovflo_sig(1) OR ovflo_sig(2) OR ovflo_sig(3) OR ovflo_sig(4) OR ovflo_sig(5) OR ovflo_sig(6) OR ovflo_sig(7);
  
 
  END structural ; 
  
  
  
  
  
  
  
  