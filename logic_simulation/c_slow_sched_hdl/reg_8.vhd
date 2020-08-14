-- 8-bit Register Model
-- Designer: Neil E. Olson
-- Date: 6/16/2018
-- CSE Independent Study, Washington University in St. Louis

-- Description: A simple 8-bit register


  LIBRARY IEEE;
  USE IEEE.STD_LOGIC_1164.ALL;
  USE IEEE.STD_LOGIC_ARITH.ALL;
  USE IEEE.STD_LOGIC_UNSIGNED.ALL; 
  
  ENTITY reg_8 IS 
  PORT(
	clk : IN STD_LOGIC ; 
	reset_l : IN STD_LOGIC ; 
	d_in : IN STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
	q : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)) ;  
  END reg_8 ; 
  
  
  ARCHITECTURE structural OF reg_8 IS 
  
  BEGIN 
  
  
	reg1 : PROCESS(clk)
	BEGIN 
		IF(CLK'EVENT AND CLK = '1') THEN 
			IF(reset_l = '0') THEN 
				q <= "00000000" ; 
			ELSE 
				q <= d_in ; 
			END IF ; 
		END IF ; 
	END PROCESS ; 
  
  END structural ; 
  