-- Input Queue 
-- Designer: Neil E. Olson
-- Date: 6/16/2018
-- CSE Independent Study, Washington University in St. Louis

-- Description: Input data queue for a single server. The queue is 6 deep. N=8 is the number of queues to be implemented. 


  LIBRARY IEEE;
  USE IEEE.STD_LOGIC_1164.ALL;
  USE IEEE.STD_LOGIC_ARITH.ALL;
  USE IEEE.STD_LOGIC_UNSIGNED.ALL; 
  
  ENTITY in_queue IS 
  PORT( clk : IN STD_LOGIC ; 
		in_num : IN STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
		sched_sig : OUT STD_LOGIC ; -- The signal to the scheduler showing that there is valid data in the queue
		reset_l : IN STD_LOGIC ; 
		out_num : OUT STD_LOGIC_VECTOR(1 DOWNTO 0) ; -- The output into the pipeline from the queue
		sch_act : IN STD_LOGIC ;   -- An activation signal from the scheduler attributed to a read
		in_act : IN STD_LOGIC ;   -- An activation signal from the data source signaling a write to the queue
		ovflo : OUT STD_LOGIC) ;
  END in_queue ; 
  
  
  ARCHITECTURE structural OF in_queue IS 
  
  COMPONENT reg_en 
  PORT(
	clk : IN STD_LOGIC ; 
	reset_l : IN STD_LOGIC ; 
	d_in : IN STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
	q : OUT STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
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
  
 ---------------------- REGISTER SIGNALS ----------------------------
  SIGNAL lz_1 : STD_LOGIC ; 
  SIGNAL lf_1 : STD_LOGIC ; 
  SIGNAL mux_1 : STD_LOGIC ; 
  SIGNAL deq_1 : STD_LOGIC_VECTOR(4 DOWNTO 0) ; -- Signals for d, en, and q for the register. The top two bits are d, the middle bit is en, and q is the bottom two. 
  
  SIGNAL lz_2 : STD_LOGIC ; 
  SIGNAL lf_2 : STD_LOGIC ; 
  SIGNAL mux_2 : STD_LOGIC ; 
  SIGNAL deq_2 : STD_LOGIC_VECTOR(4 DOWNTO 0) ;  
  
  SIGNAL lz_3 : STD_LOGIC ; 
  SIGNAL lf_3 : STD_LOGIC ; 
  SIGNAL mux_3 : STD_LOGIC ; 
  SIGNAL deq_3 : STD_LOGIC_VECTOR(4 DOWNTO 0) ;  
  
  SIGNAL lz_4 : STD_LOGIC ; 
  SIGNAL lf_4 : STD_LOGIC ; 
  SIGNAL mux_4 : STD_LOGIC ; 
  SIGNAL deq_4 : STD_LOGIC_VECTOR(4 DOWNTO 0) ;
  
  SIGNAL lz_5 : STD_LOGIC ; 
  SIGNAL lf_5 : STD_LOGIC ; 
  SIGNAL mux_5 : STD_LOGIC ; 
  SIGNAL deq_5 : STD_LOGIC_VECTOR(4 DOWNTO 0) ; 
  
  SIGNAL lz_6 : STD_LOGIC ; 
  SIGNAL lf_6 : STD_LOGIC ; 
  SIGNAL mux_6 : STD_LOGIC ; 
  SIGNAL deq_6 : STD_LOGIC_VECTOR(4 DOWNTO 0) ; 
  
  SIGNAL lz_7 : STD_LOGIC ; 
  SIGNAL lf_7 : STD_LOGIC ; 
  SIGNAL mux_7 : STD_LOGIC ; 
  SIGNAL deq_7 : STD_LOGIC_VECTOR(4 DOWNTO 0) ; 
  
  SIGNAL lz_8 : STD_LOGIC ; 
  SIGNAL lf_8 : STD_LOGIC ; 
  SIGNAL mux_8 : STD_LOGIC ; 
  SIGNAL deq_8 : STD_LOGIC_VECTOR(4 DOWNTO 0) ;  

  ---------------------------------------------------------------------
  
  ------------------------ FLAG SIGNALS -------------------------------
  SIGNAL deq_ff_1 : STD_LOGIC_VECTOR(2 DOWNTO 0) ;
  SIGNAL deq_ff_2 : STD_LOGIC_VECTOR(2 DOWNTO 0) ;  
  SIGNAL deq_ff_3 : STD_LOGIC_VECTOR(2 DOWNTO 0) ;
  SIGNAL deq_ff_4 : STD_LOGIC_VECTOR(2 DOWNTO 0) ;
  SIGNAL deq_ff_5 : STD_LOGIC_VECTOR(2 DOWNTO 0) ;
  SIGNAL deq_ff_6 : STD_LOGIC_VECTOR(2 DOWNTO 0) ;
  SIGNAL deq_ff_7 : STD_LOGIC_VECTOR(2 DOWNTO 0) ;
  SIGNAL deq_ff_8 : STD_LOGIC_VECTOR(2 DOWNTO 0) ;  
  ---------------------------------------------------------------------

  
 
  BEGIN 
   
   reg1 : reg_en 
   PORT MAP( 
		clk => clk,
		reset_l => reset_l, 
		d_in => deq_1(4 DOWNTO 3),
		q => deq_1(1 DOWNTO 0), 
		en => deq_1(2)
	) ; 
   
   reg2 : reg_en 
   PORT MAP( 
		clk => clk,
		reset_l => reset_l, 
		d_in => deq_2(4 DOWNTO 3),
		q => deq_2(1 DOWNTO 0), 
		en => deq_2(2)
	) ; 
	
   reg3 : reg_en 
   PORT MAP( 
		clk => clk,
		reset_l => reset_l, 
		d_in => deq_3(4 DOWNTO 3),
		q => deq_3(1 DOWNTO 0), 
		en => deq_3(2)
	) ; 
	
   reg4 : reg_en 
   PORT MAP( 
		clk => clk,
		reset_l => reset_l, 
		d_in => deq_4(4 DOWNTO 3),
		q => deq_4(1 DOWNTO 0), 
		en => deq_4(2)
	) ; 
	
   reg5 : reg_en 
   PORT MAP( 
		clk => clk,
		reset_l => reset_l, 
		d_in => deq_5(4 DOWNTO 3),
		q => deq_5(1 DOWNTO 0), 
		en => deq_5(2)
	) ; 
	
   reg6 : reg_en 
   PORT MAP( 
		clk => clk,
		reset_l => reset_l, 
		d_in => deq_6(4 DOWNTO 3),
		q => deq_6(1 DOWNTO 0), 
		en => deq_6(2)
	) ; 
	
   reg7 : reg_en 
   PORT MAP( 
		clk => clk,
		reset_l => reset_l, 
		d_in => deq_7(4 DOWNTO 3),
		q => deq_7(1 DOWNTO 0), 
		en => deq_7(2)
	) ; 
	
   reg8 : reg_en 
   PORT MAP( 
		clk => clk,
		reset_l => reset_l, 
		d_in => deq_8(4 DOWNTO 3),
		q => deq_8(1 DOWNTO 0), 
		en => deq_8(2)
	) ; 
   
   
   ff1 : d_ff  
   PORT MAP( 
		clk => clk,
		reset_l => reset_l, 
		d_in => deq_ff_1(2),
		q => deq_ff_1(0), 
		en => deq_ff_1(1)
	) ; 
   
   ff2 : d_ff  
   PORT MAP( 
		clk => clk,
		reset_l => reset_l, 
		d_in => deq_ff_2(2),
		q => deq_ff_2(0), 
		en => deq_ff_2(1)
	) ; 
	
   ff3 : d_ff  
   PORT MAP( 
		clk => clk,
		reset_l => reset_l, 
		d_in => deq_ff_3(2),
		q => deq_ff_3(0), 
		en => deq_ff_3(1)
	) ; 
	
   ff4 : d_ff  
   PORT MAP( 
		clk => clk,
		reset_l => reset_l, 
		d_in => deq_ff_4(2),
		q => deq_ff_4(0), 
		en => deq_ff_4(1)
	) ; 
	
   ff5 : d_ff  
   PORT MAP( 
		clk => clk,
		reset_l => reset_l, 
		d_in => deq_ff_5(2),
		q => deq_ff_5(0), 
		en => deq_ff_5(1)
	) ; 
	
   ff6 : d_ff  
   PORT MAP( 
		clk => clk,
		reset_l => reset_l, 
		d_in => deq_ff_6(2),
		q => deq_ff_6(0), 
		en => deq_ff_6(1)
	) ; 
   
   ff7 : d_ff  
   PORT MAP( 
		clk => clk,
		reset_l => reset_l, 
		d_in => deq_ff_7(2),
		q => deq_ff_7(0), 
		en => deq_ff_7(1)
	) ; 

   ff8 : d_ff  
   PORT MAP( 
		clk => clk,
		reset_l => reset_l, 
		d_in => deq_ff_8(2),
		q => deq_ff_8(0), 
		en => deq_ff_8(1)
	) ; 	
   
   ------------------------- MUXES ---------------------------------
   deq_1(4 DOWNTO 3) <= deq_2(1 DOWNTO 0) WHEN (mux_1 = '0') ELSE in_num ;
   deq_2(4 DOWNTO 3) <= deq_3(1 DOWNTO 0) WHEN (mux_2 = '0') ELSE in_num ;
   deq_3(4 DOWNTO 3) <= deq_4(1 DOWNTO 0) WHEN (mux_3 = '0') ELSE in_num ;
   deq_4(4 DOWNTO 3) <= deq_5(1 DOWNTO 0) WHEN (mux_4 = '0') ELSE in_num ;
   deq_5(4 DOWNTO 3) <= deq_6(1 DOWNTO 0) WHEN (mux_5 = '0') ELSE in_num ;
   deq_6(4 DOWNTO 3) <= deq_7(1 DOWNTO 0) WHEN (mux_6 = '0') ELSE in_num ;   
   deq_7(4 DOWNTO 3) <= deq_8(1 DOWNTO 0) WHEN (mux_7 = '0') ELSE in_num ;   
   deq_8(4 DOWNTO 3) <= "00" WHEN (mux_8 = '0') ELSE in_num ; 
   
   deq_ff_1(2) <= deq_ff_2(0) WHEN (mux_1 = '0') ELSE '1' ; 
   deq_ff_2(2) <= deq_ff_3(0) WHEN (mux_2 = '0') ELSE '1' ; 
   deq_ff_3(2) <= deq_ff_4(0) WHEN (mux_3 = '0') ELSE '1' ; 
   deq_ff_4(2) <= deq_ff_5(0) WHEN (mux_4 = '0') ELSE '1' ; 
   deq_ff_5(2) <= deq_ff_6(0) WHEN (mux_5 = '0') ELSE '1' ; 
   deq_ff_6(2) <= deq_ff_7(0) WHEN (mux_6 = '0') ELSE '1' ;    
   deq_ff_7(2) <= deq_ff_8(0) WHEN (mux_7 = '0') ELSE '1' ;    
   deq_ff_8(2) <= '0' WHEN (mux_8 = '0') ELSE '1' ; 
   ------------------------------------------------------------------
   
   
   ------------------ LAST ZERO, LAST FLAG ------------------
   lz_1 <= NOT(deq_ff_1(0)) ; 
   lf_1 <= deq_ff_1(0) AND (NOT(deq_ff_2(0))) ; 
   
   lz_2 <= deq_ff_1(0) AND (NOT(deq_ff_2(0))) ; 
   lf_2 <= deq_ff_2(0) AND (NOT(deq_ff_3(0))) ; 
   
   lz_3 <= deq_ff_2(0) AND (NOT(deq_ff_3(0))) ; 
   lf_3 <= deq_ff_3(0) AND (NOT(deq_ff_4(0))) ; 
   
   lz_4 <= deq_ff_3(0) AND (NOT(deq_ff_4(0))) ; 
   lf_4 <= deq_ff_4(0) AND (NOT(deq_ff_5(0))) ; 
   
   lz_5 <= deq_ff_4(0) AND (NOT(deq_ff_5(0))) ; 
   lf_5 <= deq_ff_5(0) AND (NOT(deq_ff_6(0))) ; 
   
   lz_6 <= deq_ff_5(0) AND (NOT(deq_ff_6(0))) ; 
   lf_6 <= deq_ff_6(0) AND (NOT(deq_ff_7(0))) ;   
   
   lz_7 <= deq_ff_6(0) AND (NOT(deq_ff_7(0))) ; 
   lf_7 <= deq_ff_7(0) AND (NOT(deq_ff_8(0))) ;   
   
   lz_8 <= deq_ff_7(0) AND (NOT(deq_ff_8(0))) ; 
   lf_8 <= deq_ff_8(0) ; 
   ----------------------------------------------------------
   
   
   ------------------------ MUX INPUTS ----------------------------
   mux_1 <= (lz_1 AND in_act AND (NOT(sch_act))) OR (in_act AND lf_1) ; 
   mux_2 <= (lz_2 AND in_act AND (NOT(sch_act))) OR (in_act AND lf_2) ;    
   mux_3 <= (lz_3 AND in_act AND (NOT(sch_act))) OR (in_act AND lf_3) ;   
   mux_4 <= (lz_4 AND in_act AND (NOT(sch_act))) OR (in_act AND lf_4) ;    
   mux_5 <= (lz_5 AND in_act AND (NOT(sch_act))) OR (in_act AND lf_5) ;    
   mux_6 <= (lz_6 AND in_act AND (NOT(sch_act))) OR (in_act AND lf_6) ;   
   mux_7 <= (lz_7 AND in_act AND (NOT(sch_act))) OR (in_act AND lf_7) ;  
   mux_8 <= (lz_8 AND in_act AND (NOT(sch_act))) OR (in_act AND lf_8) ;     
   ----------------------------------------------------------------
   
   
   ----------------- REG ENABLES --------------------
   deq_1(2) <= (sch_act AND in_act) OR sch_act OR (lz_1 AND in_act) ; 
   deq_2(2) <= (sch_act AND in_act) OR sch_act OR (lz_2 AND in_act) ;
   deq_3(2) <= (sch_act AND in_act) OR sch_act OR (lz_3 AND in_act) ;
   deq_4(2) <= (sch_act AND in_act) OR sch_act OR (lz_4 AND in_act) ;
   deq_5(2) <= (sch_act AND in_act) OR sch_act OR (lz_5 AND in_act) ;
   deq_6(2) <= (sch_act AND in_act) OR sch_act OR (lz_6 AND in_act) ;
   deq_7(2) <= (sch_act AND in_act) OR sch_act OR (lz_7 AND in_act) ;   
   deq_8(2) <= (sch_act AND in_act) OR sch_act OR (lz_8 AND in_act) ;   
   --------------------------------------------------
   
   
   ----------------- FF ENABLES ------------------
   deq_ff_1(1) <= sch_act OR in_act ; 
   deq_ff_2(1) <= sch_act OR in_act ;   
   deq_ff_3(1) <= sch_act OR in_act ; 
   deq_ff_4(1) <= sch_act OR in_act ;    
   deq_ff_5(1) <= sch_act OR in_act ;    
   deq_ff_6(1) <= sch_act OR in_act ; 
   deq_ff_7(1) <= sch_act OR in_act ;    
   deq_ff_8(1) <= sch_act OR in_act ;    
   -----------------------------------------------
   
   sched_sig <= deq_ff_1(0) ; 
   out_num <= deq_1(1 DOWNTO 0) ; 
   ovflo <= deq_ff_8(0) ; 
   
  END structural ; 
  
  