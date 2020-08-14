-- C-Slowed "Black Box" 
-- Designer: Neil E. Olson
-- Date: 6/16/2018
-- CSE Independent Study, Washington University in St. Louis

-- Description: An arbitrary C-slowed pipeline with two levels of combinational logic inbetween registers. This implementation has C = 4, but making C larger would be simple.  


  LIBRARY IEEE;
  USE IEEE.STD_LOGIC_1164.ALL;
  USE IEEE.STD_LOGIC_ARITH.ALL;
  USE IEEE.STD_LOGIC_UNSIGNED.ALL; 
  
  ENTITY bb_pipeline IS 
  PORT(
	clk : IN STD_LOGIC ;
	n_sel_in : IN STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
	n_sel_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
	data : IN STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
	feedback : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
	reset_l : IN STD_LOGIC ; 
	output : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)) ;  
  END bb_pipeline ; 
  
  
  ARCHITECTURE structural OF bb_pipeline IS 
  
  COMPONENT reg 
	PORT(	clk : IN STD_LOGIC ; 
			reset_l : IN STD_LOGIC ; 
			d_in : IN STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
			q : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)) ; 
  END COMPONENT ; 
  
  COMPONENT reg_8 
  PORT(	clk : IN STD_LOGIC ; 
		reset_l : IN STD_LOGIC ; 
		d_in : IN STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
		q : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)) ; 
  END COMPONENT ; 
  
  ------------------ PIPELINE REGISTERS --------------------
  SIGNAL q1 : STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
  SIGNAL q2 : STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
  SIGNAL q3 : STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
  SIGNAL d1 : STD_LOGIC_VECTOR(1 DOWNTO 0) ;  
  SIGNAL d2 : STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
  SIGNAL d3 : STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
  SIGNAL d4 : STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
  ----------------------------------------------------------
  
  ------------------ N_SEL REGISTERS -----------------------
  SIGNAL n_d2 : STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
  SIGNAL n_d3 : STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
  SIGNAL n_d4 : STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
  
  ----------------------------------------------------------
  
  
  BEGIN 
  
  r1 : reg
  PORT MAP(	clk => clk, 
			reset_l => reset_l, 
			d_in => d1, 
			q => q1) ; 

  r2 : reg
  PORT MAP(	clk => clk, 
			reset_l => reset_l, 
			d_in => d2, 
			q => q2) ; 

  r3 : reg
  PORT MAP(	clk => clk, 
			reset_l => reset_l, 
			d_in => d3, 
			q => q3) ; 

  r4 : reg
  PORT MAP(	clk => clk, 
			reset_l => reset_l, 
			d_in => d4, 
			q => output) ; 	

  n_sel_1 : reg_8 
  PORT MAP( clk => clk, 
			reset_l => reset_l, 
			d_in => n_sel_in, 
			q =>  n_d2) ; 
			
  n_sel_2 : reg_8 
  PORT MAP( clk => clk, 
			reset_l => reset_l, 
			d_in => n_d2, 
			q =>  n_d3) ; 			

  n_sel_3 : reg_8 
  PORT MAP( clk => clk, 
			reset_l => reset_l, 
			d_in => n_d3, 
			q =>  n_d4) ; 
			
  n_sel_4 : reg_8 
  PORT MAP( clk => clk, 
			reset_l => reset_l, 
			d_in => n_d4, 
			q =>  n_sel_out) ; 
			
			
  d1 <= '0' & (data(0) AND feedback(0));
  d2 <= q1 ; 
  d3 <= q2 ; 
  d4 <= q3 ; 

  END structural ; 
  
  
  