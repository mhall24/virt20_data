-- Priority Scheduler
-- Designer: Neil E. Olson
-- Date: 6/25/2018
-- CSE Independent Study, Washington University in St. Louis

-- Description: The first attempt at a scheduler for the c-slowed pipeline. This scheduler takes in signals from the flags in the input and feedback 
-- queues in order to feed a valid job into the pipeline. It gives priority to the N=1 queue before others, but if any queue is almost full, then that queue is serviced first. 
-- The logic is somewhat simpler if the scheduling has priority. 

  LIBRARY IEEE;
  USE IEEE.STD_LOGIC_1164.ALL;
  USE IEEE.STD_LOGIC_ARITH.ALL;
  USE IEEE.STD_LOGIC_UNSIGNED.ALL; 

  
  ENTITY priority_scheduler IS 
  PORT(
	clk : IN STD_LOGIC ; 
	reset_l : IN STD_LOGIC ; 
	n_select : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
	input_flag : IN STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
	fb_flag : IN STD_LOGIC_VECTOR(7 DOWNTO 0)) ;  
  END priority_scheduler ; 
  
  
  ARCHITECTURE structural OF priority_scheduler IS 
  

  
  
  SIGNAL memory_addr : STD_LOGIC_VECTOR(9 DOWNTO 0) ; 
  SIGNAL n_sel : STD_LOGIC_VECTOR(2 DOWNTO 0) := "000" ; 
  
  BEGIN 
  
  
  my_rom : test_rom
  PORT MAP( 
	clka => clk, 
	addra => memory_addr, 
	douta => n_sel) ; 
	
	
	addr : PROCESS(clk)

	BEGIN 
		IF(CLK'EVENT AND CLK = '1') THEN 
			IF(reset_l = '0') THEN 
				memory_addr <= "0000000000" ;  
			ELSE  
				memory_addr <= memory_addr + 1 ;
			END IF ; 
		END IF ; 
	END PROCESS ; 
  
	
	WITH n_sel SELECT
		n_select <= "00000001" WHEN "000", 
					"00000010" WHEN "001", 
					"00000100" WHEN "010", 
					"00001000" WHEN "011", 
					"00010000" WHEN "100", 
					"00100000" WHEN "101", 
					"01000000" WHEN "110", 
					"10000000" WHEN "111", 
					"00000000" WHEN OTHERS ; 
					
	data <= "01" ; 
					
  END structural ; 
  