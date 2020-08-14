-- Register Model
-- Designer: Neil E. Olson
-- Date: 6/16/2018
-- CSE Independent Study, Washington University in St. Louis

-- Description: A simple 2-bit register to act as a stage in the "black box" pipeline


  LIBRARY IEEE;
  USE IEEE.STD_LOGIC_1164.ALL;
  USE IEEE.STD_LOGIC_ARITH.ALL;
  USE IEEE.STD_LOGIC_UNSIGNED.ALL; 
  
  ENTITY reg_en IS 
  PORT(
	clk : IN STD_LOGIC ; 
	reset_l : IN STD_LOGIC ; 
	d_in : IN STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
	q : OUT STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
	en : IN STD_LOGIC) ;  
  END reg_en ; 
  
  
  ARCHITECTURE structural OF reg_en IS 
  
  BEGIN 
  
  
	reg1 : PROCESS(clk)
	BEGIN 
		IF(CLK'EVENT AND CLK = '1') THEN 
			IF(reset_l = '0') THEN 
				q <= "00" ; 
			ELSE 
				IF (en = '1') THEN 
				q <= d_in ; 
				END IF ; 
			END IF ; 
		END IF ; 
	END PROCESS ; 
  
  END structural ; 
  