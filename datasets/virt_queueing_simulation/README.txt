Summary file (column descriptions):

Summary Index
 - The summary index.  This is one per line and represents an aggregation of
   replications and virtual queues from the simulations.
Mean Exp Elapsed Time (s)
 - The mean experiment elapsed time.  This is the time to run the entire
   experiment which includes simulation setup time, the simulation time itself,
   and statistics calculation time.
Mean Sim Elapsed Time (s)
 - The mean simulation elapsed time.  This is the time only to run only the
   simulation part.
Sim Clocks
 - The number of simulated clock cycles.
Sim Time (s)
 - The total simulation time in seconds.  Note, the clock period is assumed to
   be 1 in these simulations.
N
 - The number of data streams.  This corresponds to the number of virtual queues
   in the simulation.
C
 - The pipeline depth.  This corresponds to the service time to serve 1 job in a
   virtual queue when the server is not on vacation.
S
 - The context switch cost.
Rs
 - The schedule period.
Lambda A
 - Mean rate of the arrival distribution.
Dist A
 - The arrival distribution.
   - D is discrete.
   - M is exponential (1 sigma).
   - E4 is Erlang as the sum of 4 exponential distributions (0.5 sigma).
   - Hyper(...) is a hyperexponential distribution consisting of parallel
     exponential distributions (2 sigma).
Mean A
 - The mean interarrival time of the arrival distribution.
Stdv A
 - The standard deviation of the interarrival time of the arrival distribution.
Num Repl
 - The number of replications.
Num Repl*Virt
 - The total number of replications and virtual queues together.
Mean of Mean Jobs Waiting
 - The mean of the mean jobs waiting in the virtual queue.
Sdom of Mean Jobs Waiting
 - The standard deviation of the mean of the mean jobs waiting in the virtual
   queue.
Mean of Stdv Jobs Waiting
 - The mean of the standard deviation of jobs waiting in the virtual queue.
Mean of Mean Jobs Receiving Service
 - The mean of the mean jobs receiving service.
Sdom of Mean Jobs Receiving Service
 - The standard deviation of the mean of the mean jobs receiving service.
Mean of Stdv Jobs Receiving Service
 - The mean of the standard deviation of jobs receiving service.
Mean of Mean Jobs in System
 - The mean of the mean jobs in the system.
Sdom of Mean Jobs in System
 - The standard deviation of the mean of the mean jobs in the system.
Mean of Stdv Jobs in System
 - The mean of the standard deviation of jobs in the system.
Mean of Cov Jobs Waiting and Jobs Receiving Service
 - The mean of the covariance of jobs waiting in the virtual queue with jobs
   receiving service.
Sdom of Cov Jobs Waiting and Jobs Receiving Service
 - The standard deviation of the mean of the covariance of jobs waiting in the
   virtual queue with jobs receiving service.
Mean of Mean Wait Time (s)
 - The mean of the mean wait time for a job in the system.
Sdom of Mean Wait Time (s)
 - The standard deviation of the mean of the mean wait time for a job in the
   system.
Mean of Stdv Wait Time (s)
 - The mean of the standard deviation of the wait time for a job in the system.
Mean of Mean Service Time (s)
 - The mean of the mean service time for a job.
Sdom of Mean Service Time (s)
 - The standard deviation of the mean of the mean service time for a job.
Mean of Stdv Service Time (s)
 - The mean of the standard deviation of service time for a job.
Mean of Mean Response Time (s)
 - The mean of the mean response time for a job.
Sdom of Mean Response Time (s)
 - The standard deviation of the mean of the mean response time for a job.
Mean of Stdv Response Time (s)
 - The mean of the standard deviation of response time for a job.
Mean Histogram of Jobs Waiting
 - The mean histogram of jobs waiting in the virtual queue.  This is expressed
   as a JSON array where the elements represent the probabilities of
   [0, 1, 2, ...] jobs waiting in the queue.
[Model] Offered Load
 - The offered load calculated in the queueing model.
[Model] Rho
 - The utilization calculated in the queueing model.
[Model] Total Schedule Time (clks)
 - The total schedule time in clock cycles calculated in the queueing model.
[Model] Service Time (clks)
 - The service time in clock cycles calculated in the queueing model.
[Model] Vacation Time (clks)
 - The vacation time in clock cycles calculated in the queueing model.
[Model] Vacation Context Switch Time (clks)
 - The vacation context switch time in clock cycles calculated in the queueing
   model.
[Model] Mean Service Time (s)
 - The mean service time calculated in the queueing model.
[Model] Service Time Second Moment (s)
 - The second moment of the service time calculated in the queueing model.
[Model] Service Time Third Moment (s)
 - The third moment of the service time calculated in the queueing model.
[Model] Mean Vacation Waiting Time (s)
 - The mean vacation waiting time calculated in the queueing model.
[Model] Service Rate (/s)
 - The service rate calculated in the queueing model.
[Model] Total Achievable Throughput (/s)
 - The total achievable throughput calculated in the queueing model.
[Model] Total Achievable Throughput w/ S=0 (/s)
 - The maximum total achievable throughput with no context switch overhead
   calculated in the queueing model.
[Model] Empty Queue Probability
 - The probability of an empty queue calculated in the queue model.
[Model] Service Time Fraction
 - The fraction of time the server is actively servicing jobs calculated in the
   queueing model.
[Model] Vacation Time Fraction
 - The fraction of time the server is on vacation calculated in the queueing
   model.
[Model] Vacation Context Switch Time Fraction
 - The fraction of time the server is context switching between virtual servers
   in the queueing model.
[Model] Queue Wait Time (s)
 - The queue wait time calculated in the queueing model.
[Model] Head of Queue Wait Time (s)
 - The wait time of a job at the head of the queue calculated in the queueing
   model.
[Model] Service Wait Time (s)
 - The service wait time calculated in the queueing model.
[Model] Total Wait Time (s)
 - The total wait time calculated in the queueing model.
[Model] Number in Queue
 - The mean number of jobs in the queue calculated in the queueing model.
[Model] Number in Service
 - The mean number of jobs being serviced calculated in the queueing model.
[Model] Number in System
 - The mean number of jobs in the system calculated in the queueing model.
[Model] JSON Blob
 - A JSON object containing all parameters of the queueing model.


Detail file (column descriptions):

Summary Index
 - The summary index that this detail row is associated with.  The summary index
   represents an aggregation of replications and virtual queues from the
   simulation.
Detail Index
 - The detail index.  This represents a single simulation run which consists of
   results from multiple virtual queues.
Exp Elapsed Time (s)
 - The elapsed time to run the entire experiment.  This includes the simulation
   elapsed time plus the time for setup and calculating statistics.
Sim Elapsed Time (s)
 - The elapsed time to run only the simulation part.
Sim Clocks
 - The number of simulated clock cycles.
Sim Time (s)
 - The total simulation time in seconds.  Note, the clock period is assumed to
   be 1 in these simulations.
N
 - The number of data streams.  This corresponds to the number of virtual queues
   in the simulation.
C
 - The pipeline depth.  This corresponds to the service time to serve 1 job in a
   virtual queue when the server is not on vacation.
S
 - The context switch cost.
Rs
 - The schedule period.
Lambda A
 - Mean rate of the arrival distribution.
Dist A
 - The arrival distribution.  (The values are described above for the summary
   file.)
Mean A
 - The mean interarrival time of the arrival distribution.
Stdv A
 - The standard deviation of the interarrival time of the arrival distribution.
Repl Index
 - The replication index.
Virt Index
 - The virtual queue index.
Num Arrivals
 - The total number of arrivals.
Num Departures
 - The total number of departures.
Stats Sim Time (s)
 - The total simulation time minus the warm-up time.
Mean Jobs Waiting
 - The mean jobs waiting in the virtual queue.
Stdv Jobs Waiting
 - The standard deviation of jobs waiting in the virtual queue.
Mean Jobs Receiving Service
 - The mean jobs receiving service.
Stdv Jobs Receiving Service
 - The standard deviation of jobs receiving service.
Mean Jobs in System
 - The mean jobs in the system.
Stdv Jobs in System
 - The standard deviation of jobs in the system.
Cov of Jobs Waiting and Jobs Receiving Service (^2)
 - The covariance of jobs waiting in the virtual queue with jobs receiving
   service.
Mean Jobs in Busy Period
 - The mean jobs in a busy period.
Stdv Jobs in Busy Period
 - The standard deviation of jobs in a busy period.
Mean Busy Period
 - The mean length of a busy period.
Stdv Busy Period
 - The standard deviation of the length of a busy period.
Mean Idle Period
 - The mean length of an idle period.
Stdv Idle Period
 - The standard deviation of the length of an idle period.
Mean Wait Time (s)
 - The mean wait time for a job in the system.
Stdv Wait Time (s)
 - The standard deviation of wait time for a job in the system.
Mean Service Time (s)
 - The mean service time for a job.
Stdv Service Time (s)
 - The standand deviation of service time for a job.
Mean Response Time (s)
 - The mean response time for a job.
Stdv Response Time (s)
 - The standard deviation of response time for a job.
Cov of Wait Time and Service Time (s^2)
 - The covariance of wait time for a job in the system with service time for a
   job.
