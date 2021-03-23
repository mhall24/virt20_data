# README for Research Data

README - generated 20210313 by Michael J. Hall and Roger D. Chamberlain

This document describes the data set associated with the journal paper:

Michael J. Hall, Neil E. Olson, and Roger D. Chamberlain, "Utilizing
Virtualized Hardware Logic Computations to Benefit Multi-User Performance,"
Electronics, 10(6):665, 2021. DOI: 10.3390/electronics10060665

The manuscript extends the conference paper:

Michael J. Hall and Roger D. Chamberlain, "Using M/G/1 Queueing Models with
Vacations to Analyze Virtualized Logic Computations," in Proc. of 33rd
IEEE International Conference on Computer Design (ICCD), October 2015,
pp. 86-93. DOI: 10.1109/ICCD.2015.7357087

-------------------
General Information
-------------------

1. Title - Data from Virtualized Hardware Logic Computations

2. Author Information

   Principal Investigator:
      Roger D. Chamberlain
      Dept. of Computer Science and Engineering
      McKelvey School of Engineering
      Washington University in St. Louis
      roger@wustl.edu

   Lead Author:
      Michael J. Hall
      Velocidata, Inc.
      mhall24@wustl.edu

   Co-Author:
      Neil E. Olson
      Dept. of Electrical and Systems Engineering
      McKelvey School of Engineering
      Washington University in St. Louis
      nolson@wustl.edu

3. Date - The data set was developed between 2015 and 2018

4. Geographic Location - The data set was developed in St. Louis, MO, USA

5. Funding Sources - This work was supported by NSF grant CNS-0931693
   and Exegy, Inc.

--------------------------
Sharing/Access Information
--------------------------

1. License - The data set is in the public domain.

2. Publication - the journal article is as follows:

Michael J. Hall, Neil E. Olson, and Roger D. Chamberlain, "Utilizing
Virtualized Hardware Logic Computations to Benefit Multi-User Performance,"
Electronics, 2021.

3. Links to other locations - none.

4. Links to ancillary data sets - none.

5. Original sources for input data - none.

--------------------
Data & File Overview
--------------------

The data files are organized in 5 sub-directories, each described below.

* HDL Code (hdl)
  - Contains the COS and AES example application Verilog designs.
    - COS
      - Top-level module (for test results): PARALLEL_COS_feedback_app_CI_2
        - Parameters: NUM_TERMS, NUM_COPIES, CSLOW_MODE, PAR_MODE
    - AES
      - Top-level module (for test results): PARALLEL_AES_CBC_CI_2
        - Parameters: Nr, NUM_COPIES, CSLOW_MODE, ENC_MODE, PAR_MODE
  - Note: the SHA-2 application code is proprietary and is not included.

* Mersenne Twister 19937 (mt19937)
  - This code generates 10,000 random substreams using the MT19937 random
    number generator algorithm.
  - Run "make" to compile and run the program.
    - This compiles using GCC on Linux.
    - It depends on the Boost C++ library.
      - Update the CPPFLAGS in the Makefile to the correct location of Boost.
  - These data files will be used by the queueing simulation in
    virt_queueing_simulation.

* Virtualized Hardware Queueing Simulation (virt_queueing_simulation)
  - Contains the queueing model (derived analytically in the paper and
    coded in Python), and the queueing simulation (also coded in Python)
    for simulating the virtualized, C-slow hardware design.
  - The virtualized hardware queueing model is in virt_queueing_model.py.
  - The virtualized hardware queueing simulation is in
    virt_queueing_simulation.py.
  - A batch of simulations is run in parallel with run_experiments.py.
    - The following experimental parameters are varied:
      - Arrival distribution
      - Pipeline depth, C
      - Number of data streams, N
      - Context switch cost, S
      - Offered load
      - Schedule period, Rs
      - Number of replications
    - This runs in Python 3.9 and depends on the following packages:
      numpy, scipy, simpy, psutil.
    - To run the simulations, execute:  python run_experiments.py.
    - It produces two CSV files:  MG1_sim.detail.csv and MG1_sim.summary.csv.
      - The detail file contains data results for all replications and virtual
        queues of the simulations.
      - The summary file aggregates the replication and virtual queue data
        across experimental runs to provide statistical information.
  - A single simulation can be run with run_single.py.
    - The experimental parameters can be varied in the code.

* Logic Simulation (logic_simulation)
  - Three scheduling algorithms were implemented:
    - Round-robin scheduler
    - Round-robin skip scheduler - This improves on round-robin by optionally
      skipping an input queue if empty.
    - Capacity prioritization scheduler - This always gets the next element
      from the most full queue.  This is work-conserving.
  - VHDL files implementing the scheduling algorithms are in the
    c_slow_sched_hdl folder.
  - COE files used in Vivado for initializing input data values in a ROM for
    testing are in the data_set_coe_files folder.
  - A write-up of the logic simulation is in Final Write-Up.pdf.
  - The data set results are described below under
    alternate_scheduling_algorithms.

* Data set results (datasets)
  - fpga_synthesis
    - Contains FPGA synthesis, place, and route results for the COS, AES,
      and SHA-2 applications.  This data is used to calibrate the clock model
      in the Appendix.
    - See the README.txt in the sub-folder for detailed descriptions of the
      dataset.
  - virt_queueing_simulation
    - Contains virtualized hardware simulation results.  This data is used to:
      (1) validate the analytical model,
      (2) measure a histogram of the input queues for sizing the hardware
          FIFOs, and
      (3) explore alternate arrival distribution processes to assess the
          assumption of Poisson arrivals in the analytical model.
    - See the README.txt in the sub-folder for detailed descriptions of the
      dataset.
  - alternate_scheduling_algorithms
    - Results for the three scheduling algorithms:
      - Round-robin scheduler (rr_sched.csv) - This is here for comparison to
        other results in the paper.
      - Round-robin skip scheduler (rr_skip_one_sched.csv)
      - Capacity prioritization scheduler (most_full_sched.csv)
    - Each circuit was simulated in a logic simulation with parameters
      C=4, N=8, S=0, and OL=0.5.
    - The simulation was run for 1000 clock cycles with 10 runs.  The
      measurement taken was the sum of the queue occupancy across all
      input queues (N=8).
    - Mean queue occupancy (MQO) is calculated as the mean across columns
      (test runs) divided by the number of input queues (N=8).
    - This data is used show performance improvement of virtualized hardware
      in terms of the mean queue occupancy by using more work-conserving
      schedulers.
    - See the README.txt in the sub-folder for detailed descriptions of the
      dataset.
