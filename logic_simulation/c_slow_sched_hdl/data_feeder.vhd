-- Data Feeder
-- Designer: Neil E. Olson
-- Date: 6/25/2018
-- CSE Independent Study, Washington University in St. Louis

-- Description: Provides test data for the pipeline


  LIBRARY IEEE;
  USE IEEE.STD_LOGIC_1164.ALL;
  USE IEEE.STD_LOGIC_ARITH.ALL;
  USE IEEE.STD_LOGIC_UNSIGNED.ALL; 

  
  ENTITY data_feeder IS 
  PORT(
	clk : IN STD_LOGIC ; 
	reset_l : IN STD_LOGIC ; 
	n_select : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
	data : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)) ;  
  END data_feeder ; 
  
  
  ARCHITECTURE structural OF data_feeder IS 
  
  COMPONENT test_rom
  PORT(
    clka : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(3 DOWNTO 0));	
  END COMPONENT ; 
  
  
  SIGNAL memory_addr : STD_LOGIC_VECTOR(10 DOWNTO 0) ; 
  SIGNAL n_sel : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0000" ; 
  
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
				memory_addr <= "00000000000" ;  
			ELSE  
				memory_addr <= memory_addr + 1 ;
			END IF ; 
		END IF ; 
	END PROCESS ; 
  
	
	WITH n_sel SELECT
		n_select <= "00000001" WHEN "0001", 
					"00000010" WHEN "0010", 
					"00000100" WHEN "0011", 
					"00001000" WHEN "0100", 
					"00010000" WHEN "0101", 
					"00100000" WHEN "0110", 
					"01000000" WHEN "0111", 
					"10000000" WHEN "1000", 
					"00000000" WHEN OTHERS ; 
					
	data <= "01" ; 
					
  END structural ; 
  