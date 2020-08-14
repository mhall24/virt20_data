-- Feedback Queue 
-- Designer: Neil E. Olson
-- Date: 6/24/2018
-- CSE Independent Study, Washington University in St. Louis

-- Description: The feedback queue for the c-slowed pipeline


  LIBRARY IEEE;
  USE IEEE.STD_LOGIC_1164.ALL;
  USE IEEE.STD_LOGIC_ARITH.ALL;
  USE IEEE.STD_LOGIC_UNSIGNED.ALL; 
  
  ENTITY fb_queue IS 
  PORT( clk : IN STD_LOGIC ; 
		pipe_out : IN STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
		sch_sigs : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) ; -- The signal to the scheduler showing which queue slots have valid data. 
		reset_l : IN STD_LOGIC ; 
		reg_enb : IN STD_LOGIC_VECTOR(7 DOWNTO 0) ; -- The pipeline follower that corresponds to the Nth server. 
		mux2_sel : IN STD_LOGIC_VECTOR(7 DOWNTO 0) ; -- The second mux outputs data from the queue depending on the scheduler's choice. 
		fb_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0) ; -- The feedback going back into the pipeline
		valid_pipe_in : IN STD_LOGIC) ; 
  END fb_queue ; 
  
  
  ARCHITECTURE structural OF fb_queue IS 
  
  COMPONENT fb_reg_en
  PORT(
	clk : IN STD_LOGIC ; 
	reset_l : IN STD_LOGIC ; 
	d_in : IN STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
	q : OUT STD_LOGIC_VECTOR(1 DOWNTO 0) ;
	en : IN STD_LOGIC) ; 
  END COMPONENT ; 
  
  COMPONENT fb_ff 
  PORT(
	clk : IN STD_LOGIC ; 
	reset_l : IN STD_LOGIC ; 
	d_in : IN STD_LOGIC ; 
	q : OUT STD_LOGIC ; 
	en : IN STD_LOGIC) ;
  END COMPONENT ; 
  
 ---------------------- REGISTER SIGNALS ---------------------------- 
  SIGNAL rq_1 : STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
  SIGNAL rq_2 : STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
  SIGNAL rq_3 : STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
  SIGNAL rq_4 : STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
  SIGNAL rq_5 : STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
  SIGNAL rq_6 : STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
  SIGNAL rq_7 : STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
  SIGNAL rq_8 : STD_LOGIC_VECTOR(1 DOWNTO 0) ; 
  ---------------------------------------------------------------------
  
  ------------------------ FLAG SIGNALS -------------------------------
  SIGNAL en_1 : STD_LOGIC ;
  SIGNAL en_2 : STD_LOGIC ;  
  SIGNAL en_3 : STD_LOGIC ;
  SIGNAL en_4 : STD_LOGIC ;
  SIGNAL en_5 : STD_LOGIC ;
  SIGNAL en_6 : STD_LOGIC ;
  SIGNAL en_7 : STD_LOGIC ;  
  SIGNAL en_8 : STD_LOGIC ;  
  ---------------------------------------------------------------------
  
  SIGNAL follower_enb : STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
  SIGNAL pipe_low_bit : STD_LOGIC_VECTOR(7 DOWNTO 0) ; 
 
  BEGIN 
   
   n1 : fb_reg_en 
   PORT MAP( 
		clk => clk,
		reset_l => reset_l, 
		d_in => pipe_out,
		q => rq_1,
		en => follower_enb(0) 
	) ; 
   
   n2 : fb_reg_en 
   PORT MAP( 
		clk => clk,
		reset_l => reset_l, 
		d_in => pipe_out,
		q => rq_2,
		en => follower_enb(1) 
	) ;    
   
   n3 : fb_reg_en 
   PORT MAP( 
		clk => clk,
		reset_l => reset_l, 
		d_in => pipe_out,
		q => rq_3,
		en => follower_enb(2) 
	) ;   
   
   n4 : fb_reg_en 
   PORT MAP( 
		clk => clk,
		reset_l => reset_l, 
		d_in => pipe_out,
		q => rq_4,
		en => follower_enb(3) 
	) ;    
   
   n5 : fb_reg_en 
   PORT MAP( 
		clk => clk,
		reset_l => reset_l, 
		d_in => pipe_out,
		q => rq_5,
		en => follower_enb(4) 
	) ;    
   
   n6 : fb_reg_en 
   PORT MAP( 
		clk => clk,
		reset_l => reset_l, 
		d_in => pipe_out,
		q => rq_6,
		en => follower_enb(5) 
	) ;   
	
   n7 : fb_reg_en 
   PORT MAP( 
		clk => clk,
		reset_l => reset_l, 
		d_in => pipe_out,
		q => rq_7,
		en => follower_enb(6) 
	) ;   	
   
   n8 : fb_reg_en 
   PORT MAP( 
		clk => clk,
		reset_l => reset_l, 
		d_in => pipe_out,
		q => rq_8,
		en => follower_enb(7) 
	) ;      
	
   f1 : fb_ff  
   PORT MAP( 
		clk => clk,
		reset_l => reset_l, 
		d_in => reg_enb(0),
		q => sch_sigs(0), 
		en => en_1
	) ; 
   
   f2 : fb_ff  
   PORT MAP( 
		clk => clk,
		reset_l => reset_l, 
		d_in => reg_enb(1),
		q => sch_sigs(1), 
		en => en_2
	) ;   
   
   f3 : fb_ff  
   PORT MAP( 
		clk => clk,
		reset_l => reset_l, 
		d_in => reg_enb(2),
		q => sch_sigs(2), 
		en => en_3
	) ;   
   
   f4 : fb_ff  
   PORT MAP( 
		clk => clk,
		reset_l => reset_l, 
		d_in => reg_enb(3),
		q => sch_sigs(3), 
		en => en_4
	) ;   
   
   f5 : fb_ff  
   PORT MAP( 
		clk => clk,
		reset_l => reset_l, 
		d_in => reg_enb(4),
		q => sch_sigs(4), 
		en => en_5
	) ;      
   
   f6 : fb_ff  
   PORT MAP( 
		clk => clk,
		reset_l => reset_l, 
		d_in => reg_enb(5),
		q => sch_sigs(5), 
		en => en_6
	) ;      
   
   f7 : fb_ff  
   PORT MAP( 
		clk => clk,
		reset_l => reset_l, 
		d_in => reg_enb(6),
		q => sch_sigs(6), 
		en => en_7
	) ;      
   
   f8 : fb_ff  
   PORT MAP( 
		clk => clk,
		reset_l => reset_l, 
		d_in => reg_enb(7),
		q => sch_sigs(7), 
		en => en_8
	) ;      
   
   
   WITH mux2_sel SELECT
	fb_out <= rq_1 WHEN "00000001", 
			  rq_2 WHEN "00000010", 
			  rq_3 WHEN "00000100", 
			  rq_4 WHEN "00001000", 
			  rq_5 WHEN "00010000", 
			  rq_6 WHEN "00100000", 
			  rq_7 WHEN "01000000", 
			  rq_8 WHEN "10000000",
			  "00" WHEN OTHERS ; 
   
   
   en_1 <= follower_enb(0) OR (mux2_sel(0) AND valid_pipe_in) ; 
   en_2 <= follower_enb(1) OR (mux2_sel(1) AND valid_pipe_in) ; 
   en_3 <= follower_enb(2) OR (mux2_sel(2) AND valid_pipe_in) ;    
   en_4 <= follower_enb(3) OR (mux2_sel(3) AND valid_pipe_in) ;    
   en_5 <= follower_enb(4) OR (mux2_sel(4) AND valid_pipe_in) ;    
   en_6 <= follower_enb(5) OR (mux2_sel(5) AND valid_pipe_in) ;    
   en_7 <= follower_enb(6) OR (mux2_sel(6) AND valid_pipe_in) ;   
   en_8 <= follower_enb(7) OR (mux2_sel(7) AND valid_pipe_in) ;   
   
   pipe_low_bit <= pipe_out(0) & pipe_out(0) & pipe_out(0) & pipe_out(0) & pipe_out(0) & pipe_out(0) & pipe_out(0) & pipe_out(0) ; 
   follower_enb <= reg_enb AND pipe_low_bit ; 
   
   
  END structural ; 
  
  