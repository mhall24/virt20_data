-- RR Skip One Scheduler
-- Designer: Neil E. Olson
-- Date: 7/7/2018
-- CSE Independent Study, Washington University in St. Louis

-- Description: A round robin scheduler with the ability to skip the next queue in the order if it is empty.
-- This module uses multiplexed shift registers rather than a counter and encoder. 

  LIBRARY IEEE;
  USE IEEE.STD_LOGIC_1164.ALL;
  USE IEEE.STD_LOGIC_ARITH.ALL;
  USE IEEE.STD_LOGIC_UNSIGNED.ALL; 

  
  ENTITY rr_skip_one IS 
  PORT(
	clk : IN STD_LOGIC ; 
	reset_l : IN STD_LOGIC ; 
	n_select : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
	q_flags : IN STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
	fb_flags : IN STD_LOGIC_VECTOR(7 DOWNTO 0)) ;  
  END rr_skip_one ; 
  
  
  ARCHITECTURE structural OF rr_skip_one IS 
  
  COMPONENT fb_ff
  PORT(
	clk : IN STD_LOGIC ; 
	reset_l : IN STD_LOGIC ; 
	d_in : IN STD_LOGIC ; 
	q : OUT STD_LOGIC ; 
	en : IN STD_LOGIC) ; 
  END COMPONENT ; 
  
  COMPONENT d_ff
  PORT(
	clk : IN STD_LOGIC ; 
	reset_l : IN STD_LOGIC ; 
	d_in : IN STD_LOGIC ; 
	q : OUT STD_LOGIC ; 
	en : IN STD_LOGIC) ; 
  END COMPONENT ; 
  
  SIGNAL and_flags : STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
  SIGNAL m_sel : STD_LOGIC_VECTOR(7 DOWNTO 0) ;
  SIGNAL ff_q : STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
  SIGNAL d_in : STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
  
  
  BEGIN 
  

  ff_1 : fb_ff 
  PORT MAP(
	clk => clk, 
	reset_l => reset_l, 
	d_in => d_in(0),
	q => ff_q(0),
	en => '1') ; 
  
  ff_2 : d_ff 
  PORT MAP(
	clk => clk, 
	reset_l => reset_l, 
	d_in => d_in(1),
	q => ff_q(1),
	en => '1') ;   
  
  ff_3 : d_ff 
  PORT MAP(
	clk => clk, 
	reset_l => reset_l, 
	d_in => d_in(2),
	q => ff_q(2),
	en => '1') ;   
  
  ff_4 : d_ff 
  PORT MAP(
	clk => clk, 
	reset_l => reset_l, 
	d_in => d_in(3),
	q => ff_q(3),
	en => '1') ;  
  
  ff_5 : d_ff 
  PORT MAP(
	clk => clk, 
	reset_l => reset_l, 
	d_in => d_in(4),
	q => ff_q(4),
	en => '1') ;    
  
  ff_6 : d_ff 
  PORT MAP(
	clk => clk, 
	reset_l => reset_l, 
	d_in => d_in(5),
	q => ff_q(5),
	en => '1') ;   

  ff_7 : d_ff 
  PORT MAP(
	clk => clk, 
	reset_l => reset_l, 
	d_in => d_in(6),
	q => ff_q(6),
	en => '1') ;  
	
  ff_8 : d_ff 
  PORT MAP(
	clk => clk, 
	reset_l => reset_l, 
	d_in => d_in(7),
	q => ff_q(7),
	en => '1') ;  

 
  and_flags <= q_flags AND fb_flags ; 
  
  m_sel(0) <= (and_flags(0) AND ff_q(7)) OR (and_flags(7) AND ff_q(6)) ; 
  m_sel(1) <= (and_flags(1) AND ff_q(0)) OR (and_flags(0) AND ff_q(7)) ; 
  m_sel(2) <= (and_flags(2) AND ff_q(1)) OR (and_flags(1) AND ff_q(0)) ; 
  m_sel(3) <= (and_flags(3) AND ff_q(2)) OR (and_flags(2) AND ff_q(1)) ; 
  m_sel(4) <= (and_flags(4) AND ff_q(3)) OR (and_flags(3) AND ff_q(2)) ; 
  m_sel(5) <= (and_flags(5) AND ff_q(4)) OR (and_flags(4) AND ff_q(3)) ; 
  m_sel(6) <= (and_flags(6) AND ff_q(5)) OR (and_flags(5) AND ff_q(4)) ; 
  m_sel(7) <= (and_flags(7) AND ff_q(6)) OR (and_flags(6) AND ff_q(5)) ; 
  
  d_in(0) <= ff_q(7) WHEN (m_sel(0) = '1') ELSE ff_q(6) ; 
  d_in(1) <= ff_q(0) WHEN (m_sel(1) = '1') ELSE ff_q(7) ; 
  d_in(2) <= ff_q(1) WHEN (m_sel(2) = '1') ELSE ff_q(0) ; 
  d_in(3) <= ff_q(2) WHEN (m_sel(3) = '1') ELSE ff_q(1) ; 
  d_in(4) <= ff_q(3) WHEN (m_sel(4) = '1') ELSE ff_q(2) ; 
  d_in(5) <= ff_q(4) WHEN (m_sel(5) = '1') ELSE ff_q(3) ; 
  d_in(6) <= ff_q(5) WHEN (m_sel(6) = '1') ELSE ff_q(4) ; 
  d_in(7) <= ff_q(6) WHEN (m_sel(7) = '1') ELSE ff_q(5) ; 
  
  n_select <= d_in ; 
  
 
  END structural ; 
  