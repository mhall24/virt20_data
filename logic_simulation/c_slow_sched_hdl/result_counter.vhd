-- Results Counter
-- Designer: Neil E. Olson
-- Date: 6/24/2018
-- CSE Independent Study, Washington University in St. Louis

-- Description: A counter to compare throughput of different scheduling schemes


  LIBRARY IEEE;
  USE IEEE.STD_LOGIC_1164.ALL;
  USE IEEE.STD_LOGIC_ARITH.ALL;
  USE IEEE.STD_LOGIC_UNSIGNED.ALL; 
  USE IEEE.STD_LOGIC_TEXTIO.ALL; 
  USE STD.TEXTIO.ALL;  
  
  ENTITY result_counter IS 
  PORT(
	clk : IN STD_LOGIC ; 
	reset_l : IN STD_LOGIC ; 
	pipeline_output : IN STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
	test_done : OUT STD_LOGIC ;
	ovflo : IN STD_LOGIC) ;  
  END result_counter ; 
  
  
  ARCHITECTURE structural OF result_counter IS 
  
  SIGNAL valid_count : STD_LOGIC_VECTOR(9 DOWNTO 0) ; 
  SIGNAL final_clocks : STD_LOGIC_VECTOR(12 DOWNTO 0) ;
  SIGNAL done : STD_LOGIC := '0' ; 
  SIGNAL clocks_reg : STD_LOGIC_VECTOR(12 DOWNTO 0) ; 
  SIGNAL ovflo_counts : STD_LOGIC_VECTOR(9 DOWNTO 0) ; 
  
  BEGIN 
  
	count : PROCESS(clk)
	FILE data : TEXT open WRITE_MODE is "operating_results.txt";
	VARIABLE outline : LINE ;
	BEGIN 
		IF(CLK'EVENT AND CLK = '1') THEN 
			IF(reset_l = '0') THEN 
				valid_count <= "0000000000" ; 
				final_clocks <= "0000000000000" ; 
				clocks_reg <= "0000000000000" ; 
				ovflo_counts <= "0000000000" ; 
			ELSE 
				final_clocks <= final_clocks + 1 ;
				IF ovflo = '1' THEN 
					ovflo_counts <= ovflo_counts + 1 ; 
				END IF ; 
				IF pipeline_output(0) = '1' THEN 
					valid_count <= valid_count + 1 ; 
					IF final_clocks = 1000 THEN 
						WRITE(outline,conv_integer(final_clocks)); 
						WRITE(outline,STRING'(" final,")) ;
						WRITE(outline,conv_integer(valid_count)) ; 
						WRITE(outline,STRING'(" valid,")) ;
						WRITE(outline,conv_integer(ovflo_counts)) ; 
						WRITE(outline,STRING'(" overflow")) ;
						done <= '1' ; 
						clocks_reg <= final_clocks ; 
						WRITELINE(data,outline) ;
					END IF ; 
				END IF ; 
				
			END IF ; 
		END IF ; 
	END PROCESS ; 
  
  test_done <= done ; 
  
  END structural ; 
  