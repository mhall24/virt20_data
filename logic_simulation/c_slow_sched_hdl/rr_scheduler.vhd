-- Round Robin Scheduler
-- Designer: Neil E. Olson
-- Date: 6/25/2018
-- CSE Independent Study, Washington University in St. Louis

-- Description: A simple round robin scheduler. 

  LIBRARY IEEE;
  USE IEEE.STD_LOGIC_1164.ALL;
  USE IEEE.STD_LOGIC_ARITH.ALL;
  USE IEEE.STD_LOGIC_UNSIGNED.ALL; 

  
  ENTITY rr_scheduler IS 
  PORT(
	clk : IN STD_LOGIC ; 
	reset_l : IN STD_LOGIC ; 
	n_select : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)) ;  
  END rr_scheduler ; 
  
  
  ARCHITECTURE structural OF rr_scheduler IS 
  
  COMPONENT d_ff
  PORT(
	clk : IN STD_LOGIC ; 
	reset_l : IN STD_LOGIC ; 
	d_in : IN STD_LOGIC ; 
	q : OUT STD_LOGIC ; 
	en : IN STD_LOGIC) ; 
  END COMPONENT ;   
  
  COMPONENT fb_ff
  PORT(
	clk : IN STD_LOGIC ; 
	reset_l : IN STD_LOGIC ; 
	d_in : IN STD_LOGIC ; 
	q : OUT STD_LOGIC ; 
	en : IN STD_LOGIC) ; 
  END COMPONENT ;
  
  

  SIGNAL d_in : STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
  SIGNAL q : STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
  
  
  BEGIN 
  
  ff_1 : fb_ff 
  PORT MAP(
	clk => clk, 
	reset_l => reset_l, 
	d_in => d_in(0),
	q => q(0),
	en => '1') ; 
  
  ff_2 : d_ff 
  PORT MAP(
	clk => clk, 
	reset_l => reset_l, 
	d_in => d_in(1),
	q => q(1),
	en => '1') ;   
  
  ff_3 : d_ff 
  PORT MAP(
	clk => clk, 
	reset_l => reset_l, 
	d_in => d_in(2),
	q => q(2),
	en => '1') ;   
  
  ff_4 : d_ff 
  PORT MAP(
	clk => clk, 
	reset_l => reset_l, 
	d_in => d_in(3),
	q => q(3),
	en => '1') ;  
  
  ff_5 : d_ff 
  PORT MAP(
	clk => clk, 
	reset_l => reset_l, 
	d_in => d_in(4),
	q => q(4),
	en => '1') ;    
  
  ff_6 : d_ff 
  PORT MAP(
	clk => clk, 
	reset_l => reset_l, 
	d_in => d_in(5),
	q => q(5),
	en => '1') ;   

  ff_7 : d_ff 
  PORT MAP(
	clk => clk, 
	reset_l => reset_l, 
	d_in => d_in(6),
	q => q(6),
	en => '1') ;  
	
  ff_8 : d_ff 
  PORT MAP(
	clk => clk, 
	reset_l => reset_l, 
	d_in => d_in(7),
	q => q(7),
	en => '1') ;  

	
	d_in(0) <= q(7) ; 
	d_in(1) <= q(0) ; 
	d_in(2) <= q(1) ; 
	d_in(3) <= q(2) ; 
	d_in(4) <= q(3) ; 
	d_in(5) <= q(4) ; 
	d_in(6) <= q(5) ; 
	d_in(7) <= q(6) ; 
	

	n_select <= d_in ; 
	
	
					
  END structural ; 
  