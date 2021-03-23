There are 3 data files:

1. Round-robin scheduler (rr_sched.csv)
2. Round-robin skip scheduler (rr_skip_one_sced.csv)
3. Capacity prioritization scheduler (most_full_sched.csv)

Columns:
 - The columns represent 10 independent test runs.
Rows:
 - The rows represent 1000 clock cycles of simulated time.
Measurement:
 - The measurement is the sum of the queue occupancy across all input queues
   (N=8).
Mean queue occupancy:
 - The mean queue occupancy (MQO) is calculated as the mean across columns
   (test runs) divided by the number of input queues (N=8).
