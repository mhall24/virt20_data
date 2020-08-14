# README for Research Data

Data Structure:
* HDL Code (hdl)
  - Contains the COS and AES example application Verilog designs.
    - COS
      - Top-level module (for test results): PARALLEL_COS_feedback_app_CI_2
        - Parameters: NUM_TERMS, NUM_COPIES, CSLOW_MODE, PAR_MODE
    - AES
      - Top-level module (for test results): PARALLEL_AES_CBC_CI_2
        - Parameters: Nr, NUM_COPIES, CSLOW_MODE, ENC_MODE, PAR_MODE
  - Note, the SHA-2 application code is proprietary.

* Mersenne Twister 19937 (mt19937)
  - This code generates 10,000 random substreams using the MT19937 random number generator algorithm.
  - Run "make" to compile and run the program.
  - These data files will be used by the queueing simulation in virt_queueing_simulation.

* Virtualized Hardware Queueing Simulation (virt_queueing_simulation)
  - Contains the queueing model (derived analytically in the paper and coded in Python), and the queueing simulation
    (also coded in Python) for simulating the virtualized, C-slow hardware design.
  - The virtualized hardware queueing model is in virt_queueing_model.py.
  - The virtualized hardware queueing simulation is in virt_queueing_simulation.py.
  - Run the simulation with run_experiments.py.

* Logic Simulation (logic_simulation)
  - Three scheduling algorithms were implemented:
    - Round-robin scheduler
    - Round-robin skip scheduler - This improves on round-robin by optionally skipping an input queue if empty.
    - Capacity prioritization scheduler - This always gets the next element from the most
      full queue.  This is work-conserving.
  - VHDL files implementing the scheduling algorithms are in the hdl folder.
  - A write-up of the logic simulation is in Final Write-Up.pdf.
  - The data set results are described below under alternate_scheduling_algorithms.

* Data set results (datasets)
  - fpga_synthesis
    - Contains FPGA synthesis, place, and route results for the COS, AES, and SHA-2 applications.  This data is used
      to calibrate the clock model in Appendix A.
  - virt_queueing_simulation
    - Contains virtualized hardware simulation results.  This data is used to:
      (1) validate the analytical model,
      (2) measure a histogram of the input queues for sizing the hardware FIFOs, and
      (3) explore alternate arrival distribution processes to assess the assumption of Poisson arrivals in the
          analytical model.
  - alternate_scheduling_algorithms
    - Results for the three scheduling algorithms:
      - Round-robin scheduler (rr_sched.csv) - This is here for comparison to other results in the paper.
      - Round-robin skip scheduler (rr_skip_one_sched.csv)
      - Capacity prioritization scheduler (most_full_sched.csv)
    - Each circuit was simulated in a logic simulation with parameters C=4, N=8, S=0, and OL=0.5.
    - The simulation was run for 1000 clock cycles with 10 runs.  The measurement taken was the sum of the queue
      occupancy across all input queues (N=8).
    - Mean queue occupancy (MQO) is calculated as the mean across columns (test runs) divided by the number of input
      queues (N=8).
    - This data is used show performance improvement of virtualized hardware in terms of the mean queue occupancy by
      using more work-conserving schedulers.
