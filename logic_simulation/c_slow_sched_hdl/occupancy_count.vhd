-- Occupancy Counter
-- Designer: Neil E. Olson
-- Date: 7/15/2018
-- CSE Independent Study, Washington University in St. Louis

-- Description: A module to record mean queue occupancy. 

  LIBRARY IEEE;
  USE IEEE.STD_LOGIC_1164.ALL;
  USE IEEE.STD_LOGIC_ARITH.ALL;
  USE IEEE.STD_LOGIC_UNSIGNED.ALL; 
  USE IEEE.STD_LOGIC_TEXTIO.ALL; 
  USE STD.TEXTIO.ALL;

  
  ENTITY occupancy_count IS 
  PORT(
	clk : IN STD_LOGIC ; 
	reset_l : IN STD_LOGIC ; 
	q_flags : IN STD_LOGIC_VECTOR(63 DOWNTO 0)) ;  
  END occupancy_count ; 
  
  
  ARCHITECTURE structural OF occupancy_count IS 
  
  
  BEGIN 
  
  
  occ_count : PROCESS(clk)
  FILE data : TEXT open WRITE_MODE is "queue_occ.txt";
  VARIABLE outline : LINE ;
  VARIABLE total_occ_count_1 : INTEGER := 0 ; 
  BEGIN	
  IF (clk'EVENT AND clk = '1') THEN 
  total_occ_count_1 := 0 ; 
  
  IF reset_l = '1' THEN 
	IF q_flags(0) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(1) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 	
	
	IF q_flags(2) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 

	IF q_flags(3) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ;
	
	IF q_flags(4) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(5) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(6) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(7) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(8) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(9) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(10) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(11) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(12) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(13) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(14) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(15) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(16) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(17) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(18) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(19) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(20) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(21) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(22) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 

	IF q_flags(23) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(24) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(25) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(26) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(27) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(28) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(29) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(30) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(31) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(32) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(33) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(34) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(35) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(36) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(37) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(38) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(39) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(40) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(41) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(42) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(43) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(44) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(45) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(46) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(47) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(48) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(49) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(50) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(51) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(52) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(53) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(54) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(55) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(56) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(57) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(58) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(59) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(60) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(61) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(62) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 
	
	IF q_flags(63) = '1' THEN 
		total_occ_count_1 := total_occ_count_1 + 1 ; 
	END IF ; 

	WRITE(outline, total_occ_count_1) ; 
	WRITE(outline,STRING'(",")) ;
	WRITELINE(data,outline) ;
	
	END IF ; 
	END IF ; 

	END PROCESS ; 
					
  END structural ; 
  