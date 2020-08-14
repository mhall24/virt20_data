-- D flip flop
-- Designer: Neil E. Olson
-- Date: 6/16/2018
-- CSE Independent Study, Washington University in St. Louis

-- Description: A simple flip flop with an enable


  LIBRARY IEEE;
  USE IEEE.STD_LOGIC_1164.ALL;
  USE IEEE.STD_LOGIC_ARITH.ALL;
  USE IEEE.STD_LOGIC_UNSIGNED.ALL; 
  
  ENTITY d_ff IS 
  PORT(
	clk : IN STD_LOGIC ; 
	reset_l : IN STD_LOGIC ; 
	d_in : IN STD_LOGIC ; 
	q : OUT STD_LOGIC ; 
	en : IN STD_LOGIC) ;  
  END d_ff ; 
  
  
  ARCHITECTURE structural OF d_ff IS 
  
  BEGIN 
  
  
	ff1 : PROCESS(clk)
	BEGIN 
		IF(CLK'EVENT AND CLK = '1') THEN 
			IF(reset_l = '0') THEN 
				q <= '0' ; 
			ELSE 
				IF (en = '1') THEN 
				q <= d_in ; 
				END IF ; 
			END IF ; 
		END IF ; 
	END PROCESS ; 
  
  END structural ; 
  