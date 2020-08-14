-- Register Model Initialized High 
-- Designer: Neil E. Olson
-- Date: 6/26/2018
-- CSE Independent Study, Washington University in St. Louis

-- Description: A simple 2-bit register that is initialized to "01" for the pipeline feedback


  LIBRARY IEEE;
  USE IEEE.STD_LOGIC_1164.ALL;
  USE IEEE.STD_LOGIC_ARITH.ALL;
  USE IEEE.STD_LOGIC_UNSIGNED.ALL; 
  
  ENTITY fb_reg_en IS 
  PORT(
	clk : IN STD_LOGIC ; 
	reset_l : IN STD_LOGIC ; 
	d_in : IN STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
	q : OUT STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
	en : IN STD_LOGIC) ;  
  END fb_reg_en ; 
  
  
  ARCHITECTURE structural OF fb_reg_en IS 
  
  BEGIN 
  
  
	reg1 : PROCESS(clk)
	BEGIN 
		IF(CLK'EVENT AND CLK = '1') THEN 
			IF(reset_l = '0') THEN 
				q <= "01" ; 
			ELSE 
				IF (en = '1') THEN 
				q <= d_in ; 
				END IF ; 
			END IF ; 
		END IF ; 
	END PROCESS ; 
  
  END structural ; 
  