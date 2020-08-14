-- Most Full Scheduler
-- Designer: Neil E. Olson
-- Date: 7/10/2018
-- CSE Independent Study, Washington University in St. Louis

-- Description: A scheduler designed to pick the queue which is most full (most jobs waiting)

  LIBRARY IEEE;
  USE IEEE.STD_LOGIC_1164.ALL;
  USE IEEE.STD_LOGIC_ARITH.ALL;
  USE IEEE.STD_LOGIC_UNSIGNED.ALL; 

  
  ENTITY most_full_sch_imp IS 
  PORT(
	clk : IN STD_LOGIC ; 
	reset_l : IN STD_LOGIC ; 
	n_select : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
	q1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
	q2 : IN STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
	q3 : IN STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
	q4 : IN STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
	q5 : IN STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
	q6 : IN STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
	q7 : IN STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
	q8 : IN STD_LOGIC_VECTOR(7 DOWNTO 0)) ; 	
	--fb_flags : IN STD_LOGIC_VECTOR(7 DOWNTO 0)) ;  
  END most_full_sch_imp ; 
  
  
  ARCHITECTURE structural OF most_full_sch_imp IS 
  

  SIGNAL buf_sel : STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
  SIGNAL buf_out : STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
  SIGNAL fb_and_col_1 : STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
  SIGNAL fb_and_col_2 : STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
  SIGNAL fb_and_col_3 : STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
  SIGNAL fb_and_col_4 : STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
  SIGNAL fb_and_col_5 : STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
  SIGNAL fb_and_col_6 : STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
  SIGNAL fb_and_col_7 : STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
  SIGNAL fb_and_col_8 : STD_LOGIC_VECTOR(7 DOWNTO 0) ;  
  SIGNAL q : STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
  
  BEGIN 
  
  test_ff : PROCESS(clk) 
  BEGIN
	IF (clk'EVENT AND clk = '1') THEN
		IF reset_l = '0' THEN 
			q <= "00000000" ; 
		ELSE 
			q <= n_select ; 
		END IF ; 
	END IF ; 
  END PROCESS ; 
  
  fb_flags <= q ; 
  
  col_sel : PROCESS(fb_and_col_1, fb_and_col_2, fb_and_col_3, fb_and_col_4, fb_and_col_5, fb_and_col_6, fb_and_col_7, fb_and_col_8)
  BEGIN
	IF (fb_and_col_8 /= 0) THEN 
		buf_sel <= "10000000" ; 
	ELSIF (fb_and_col_7 /= 0) THEN 
		buf_sel <= "01000000" ; 
	ELSIF (fb_and_col_6 /= 0) THEN 
		buf_sel <= "00100000" ; 
	ELSIF (fb_and_col_5 /= 0) THEN 
		buf_sel <= "00010000" ; 
	ELSIF (fb_and_col_4 /= 0) THEN 
		buf_sel <= "00001000" ; 
	ELSIF (fb_and_col_3 /= 0) THEN 
		buf_sel <= "00000100" ; 
	ELSIF (fb_and_col_2 /= 0) THEN 
		buf_sel <= "00000010" ; 
	ELSIF (fb_and_col_1 /= 0) THEN 
		buf_sel <= "00000001" ; 
	ELSE 
		buf_sel <= "00000000" ; 
	END IF ; 
  END PROCESS ; 
  
  WITH buf_sel SELECT
  buf_out <= fb_and_col_8 WHEN "10000000", 
			 fb_and_col_7 WHEN "01000000", 
			 fb_and_col_6 WHEN "00100000", 
			 fb_and_col_5 WHEN "00010000", 
			 fb_and_col_4 WHEN "00001000", 
			 fb_and_col_3 WHEN "00000100", 
			 fb_and_col_2 WHEN "00000010", 
			 fb_and_col_1 WHEN "00000001", 
			 "00000000" WHEN OTHERS ; 
			 
  n_sel : PROCESS(buf_out)
  BEGIN
	IF buf_out(7) = '1' THEN 
		n_select <= "10000000" ; 
	ELSIF buf_out(6) = '1' THEN
		n_select <= "01000000" ; 
	ELSIF buf_out(5) = '1' THEN 
		n_select <= "00100000" ;
	ELSIF buf_out(4) = '1' THEN
		n_select <= "00010000" ; 
	ELSIF buf_out(3) = '1' THEN 
		n_select <= "00001000" ; 			 
	ELSIF buf_out(2) = '1' THEN
		n_select <= "00000100" ; 
	ELSIF buf_out(1) = '1' THEN 
		n_select <= "00000010" ; 			 
	ELSIF buf_out(0) = '1' THEN 
		n_select <= "00000001" ; 				 
	ELSE 
		n_select <= "00000000" ; 
	END IF ; 
  END PROCESS ; 
			 		 
	
  fb_and_col_8 <= fb_flags AND (q8(7) & q7(7) & q6(7) & q5(7) & q4(7) & q3(7) & q2(7) & q1(7)) ; 
  fb_and_col_7 <= fb_flags AND (q8(6) & q7(6) & q6(6) & q5(6) & q4(6) & q3(6) & q2(6) & q1(6)) ;   
  fb_and_col_6 <= fb_flags AND (q8(5) & q7(5) & q6(5) & q5(5) & q4(5) & q3(5) & q2(5) & q1(5)) ; 
  fb_and_col_5 <= fb_flags AND (q8(4) & q7(4) & q6(4) & q5(4) & q4(4) & q3(4) & q2(4) & q1(4)) ; 
  fb_and_col_4 <= fb_flags AND (q8(3) & q7(3) & q6(3) & q5(3) & q4(3) & q3(3) & q2(3) & q1(3)) ; 
  fb_and_col_3 <= fb_flags AND (q8(2) & q7(2) & q6(2) & q5(2) & q4(2) & q3(2) & q2(2) & q1(2)) ; 
  fb_and_col_2 <= fb_flags AND (q8(1) & q7(1) & q6(1) & q5(1) & q4(1) & q3(1) & q2(1) & q1(1)) ; 
  fb_and_col_1 <= fb_flags AND (q8(0) & q7(0) & q6(0) & q5(0) & q4(0) & q3(0) & q2(0) & q1(0)) ; 
	
END structural ; 			 
			 