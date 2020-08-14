""" Virtualized hardware queueing simulation """

import concurrent.futures
import csv
import json
import math
import os
import random
import sys
import time
import traceback
from collections import defaultdict, deque, namedtuple
from enum import Enum
from itertools import count

import simpy
import simpy.util

import distributions
import queueing_simulation_common as qsc
import utils


# ----------------------------------------------------------------------------------------------------------------------
class QueueingSystem:
    """ Queueing system class.  The class models the queueing system which includes the queue and server.
    When an arrival occurs, the arrival() function is to be called.  The process_server() function is the
    server process that simulates jobs being serviced and completed.  This class handles the queue
    count. """

    # ------------------------------------------------------------------------------------------------------------------
    class ServiceDiscipline(Enum):
        FCFS = 1
        SIRO = 2
        LCFS = 3

    VALID_QUEUE_DISCIPLINES = tuple(ServiceDiscipline.__members__)

    # ------------------------------------------------------------------------------------------------------------------
    def __init__(self, sim, N, C, S, Rs, arrival_distributions, f_clk, SD=ServiceDiscipline.FCFS,
                 sd_random_class=None, stats_warmup_time=0):
        """
        AD is the arrival distribution.
        N is the number of streams.
        C is the pipeline depth.
        S is the cost of a context switch.
        Rs is the schedule period.
        SD is the service discipline and is one of:
            First Come, First Served (FCFS)
            Last Come, First Served (LCFS)
            Service In, Random Order (SIRO)
        """

        # Simulation and environment
        self.sim = sim
        self.env = sim.env

        # System parameters
        if N < C or N % C != 0:
            raise qsc.QueueingSystemError("N must be >= C and a multiple of C.  N is %s and C is %s." % (N, C))

        self.N = N
        self.C = C
        self.S = S
        self.Rs = Rs
        self.f_clk = f_clk
        self.t_clk = 1 / f_clk

        # Queueing parameters
        self.SD = SD        # Service discipline

        # Setup the arrival processes.
        assert len(arrival_distributions) == N
        self.arrival_distributions = arrival_distributions

        # Setup the interarrival time random sample generators.
        self.next_interarrival_time = [dist.random_sample for dist in self.arrival_distributions]

        # Setup arrival queues
        self.queue = [deque() for _ in range(N)]
        self.total_arrivals = [0 for _ in range(N)]
        self.total_departures = [0 for _ in range(N)]

        # Setup the service discipline random number generator.
        if sd_random_class is None:
            self.sd_random_class = distributions.default_random_class
        else:
            self.sd_random_class = sd_random_class

        # Setup the service discipline.
        if SD == self.ServiceDiscipline.FCFS:
            def get_next_job(queue):
                return queue.pop()
        elif SD == self.ServiceDiscipline.LCFS:
            def get_next_job(queue):
                return queue.popleft()
        elif SD == self.ServiceDiscipline.SIRO:
            def get_next_job(queue):
                index = self.sd_random_class.randrange(len(queue))
                job = queue[index]
                del queue[index]
                return job
        else:
            raise qsc.QueueingSystemError("Queue discipline (%s) is not one of %s",
                                      (repr(SD), repr(self.VALID_QUEUE_DISCIPLINES)))
        self.get_next_job = get_next_job

        # Setup server
        self.jobs_receiving_service = [0 for _ in range(self.N)]
        self.total_jobs_receiving_service = 0

        # Setup callbacks
        self.sim.callbacks_before_run.append(lambda sim: self.event_before_run())
        self.sim.callbacks_after_run.append(lambda sim: self.event_after_run())

        # Setup job stats
        self.stats_warmup_time = stats_warmup_time
        self.stats = [qsc.QueueStats() for _ in range(N)]

        # Busy and idle period setup.
        self.busy_period_num_jobs = [0 for _ in range(self.N)]
        self.busy_period_start = [None for _ in range(self.N)]
        self.idle_period_start = [self.env.now for _ in range(self.N)]

        # Create the arrival processes.
        for index in range(N):
            self.env.process(self.process_arrival(index))

        # Create the real server process.
        self.env.process(self.process_real_server())

    # ------------------------------------------------------------------------------------------------------------------
    def process_arrival(self, index):
        """ Job arrival process.  New jobs are generated from this process that are spaced out by
        the interarrival time.  The interarrival time is determined by the selected arrival process
        distribution chosen above. """

        get_next_interarrival_time = self.next_interarrival_time[index]

        while True:
            next_interarrival_time = get_next_interarrival_time()
            yield self.env.timeout(next_interarrival_time)
            now = self.env.now
            self.total_arrivals[index] += 1
            job_no = self.total_arrivals[index]
            if now >= self.stats_warmup_time:
                self.stats[index].total_arrivals += 1
            self.queue[index].appendleft((job_no, now))
            self.event_arrival(index, job_no)

    # ------------------------------------------------------------------------------------------------------------------
    def process_real_server(self):
        """ Real server process. """

        # Helper functions to handle when a job enters and completes service.
        def job_entered_service(virt_index, job_no):
            self.jobs_receiving_service[virt_index] += 1
            self.total_jobs_receiving_service += 1
            self.busy_period_num_jobs[virt_index] += 1
            self.event_enter_service(virt_index, job_no)

        num_groups = self.N // self.C

        self.print_server_info("Starting")

        while True:
            for active_group_index in range(num_groups):
                self.print_server_info("Now processing queues %d-%d.", active_group_index * self.C,
                                       (active_group_index + 1) * self.C - 1)

                for schedule_period_count in range(self.Rs):
                    for active_group_queue_index in range(self.C):
                        yield self.env.timeout(self.t_clk)

                        virt_index = active_group_index * self.C + active_group_queue_index

                        if len(self.queue[virt_index]) > 0:
                            if self.jobs_receiving_service[virt_index] == 0:
                                # Begin a busy period.
                                if self.env.now >= self.stats_warmup_time:
                                    idle_period_duration = self.env.now - self.idle_period_start[virt_index]
                                    self.stats[virt_index].idle_period.append(
                                        self.idle_period_start[virt_index], idle_period_duration)

                                self.busy_period_start[virt_index] = self.env.now
                                self.busy_period_num_jobs[virt_index] = 0

                            job_no, job_arrival_time = self.get_next_job(self.queue[virt_index])
                            job_entered_service(virt_index, job_no)
                            self.env.process(self.process_virt_computation(
                                virt_index,
                                job_no=job_no,
                                job_arrival_time=job_arrival_time,
                                job_entered_service_time=self.env.now))
                    self.print_server_info("Completed a schedule period")

                # Context switch to the next group.
                self.print_server_info("Context-switching")
                yield self.env.timeout(self.S * self.t_clk)

    # ------------------------------------------------------------------------------------------------------------------
    def process_virt_computation(self, virt_index, job_no, job_arrival_time, job_entered_service_time):
        """ Virtual computation process. """

        # Service time.
        yield self.env.timeout(self.C * self.t_clk)

        # Complete service.
        now = self.env.now
        job_completed_service_time = now
        job_wait_time = job_entered_service_time - job_arrival_time
        job_service_time = job_completed_service_time - job_entered_service_time
        job_response_time = job_completed_service_time - job_arrival_time
        self.stats[virt_index].job_wait_time.append(job_wait_time)
        self.stats[virt_index].job_service_time.append(job_service_time)
        self.stats[virt_index].job_response_time.append(job_response_time)
        self.jobs_receiving_service[virt_index] -= 1
        self.total_jobs_receiving_service -= 1
        self.total_departures[virt_index] += 1
        if now >= self.stats_warmup_time:
            self.stats[virt_index].total_departures += 1
        self.event_complete_service(virt_index, job_no)
        self.print_job_stat_info(virt_index, job_no, job_wait_time, job_service_time, job_response_time)

        # End a busy period if applicable.
        if len(self.queue[virt_index]) == 0:
            if now >= self.stats_warmup_time:
                busy_period_duration = now - self.busy_period_start[virt_index]
                self.stats[virt_index].busy_period.append(
                    self.busy_period_start[virt_index], busy_period_duration, self.busy_period_num_jobs[virt_index])

            self.idle_period_start[virt_index] = now

    # ------------------------------------------------------------------------------------------------------------------
    def event_before_run(self):
        now = self.env.now
        if now >= self.stats_warmup_time:
            for virt_index in range(self.N):
                self.stats[virt_index].jobs_waiting.append(now, self.jobs_waiting(virt_index))
                self.stats[virt_index].jobs_receiving_service.append(
                    now, self.jobs_receiving_service[virt_index])
                self.stats[virt_index].jobs_in_system.append(now, self.jobs_in_system(virt_index))

    # ------------------------------------------------------------------------------------------------------------------
    def event_arrival(self, virt_index, job_no):
        self.print_job_event_info(virt_index, "New job %d arrived in input queue %d" % (job_no, virt_index))
        now = self.env.now
        if now >= self.stats_warmup_time:
            self.stats[virt_index].jobs_waiting.append(now, self.jobs_waiting(virt_index))
            self.stats[virt_index].jobs_in_system.append(now, self.jobs_in_system(virt_index))

    # ------------------------------------------------------------------------------------------------------------------
    def event_enter_service(self, virt_index, job_no):
        self.print_job_event_info(virt_index, "Job %d entered service for virtual computation %d" % (job_no, virt_index))
        now = self.env.now
        if now >= self.stats_warmup_time:
            self.stats[virt_index].jobs_waiting.append(now, self.jobs_waiting(virt_index))
            self.stats[virt_index].jobs_receiving_service.append(
                now, self.jobs_receiving_service[virt_index])

    # ------------------------------------------------------------------------------------------------------------------
    def event_complete_service(self, virt_index, job_no):
        self.print_job_event_info(virt_index, "Job %d completed service" % job_no)
        now = self.env.now
        if now >= self.stats_warmup_time:
            self.stats[virt_index].jobs_receiving_service.append(
                now, self.jobs_receiving_service[virt_index])
            self.stats[virt_index].jobs_in_system.append(now, self.jobs_in_system(virt_index))

    # ------------------------------------------------------------------------------------------------------------------
    def event_after_run(self):
        now = self.env.now
        if now >= self.stats_warmup_time:
            for virt_index in range(self.N):
                self.stats[virt_index].jobs_waiting.append(now, self.jobs_waiting(virt_index))
                self.stats[virt_index].jobs_receiving_service.append(
                    now, self.jobs_receiving_service[virt_index])
                self.stats[virt_index].jobs_in_system.append(now, self.jobs_in_system(virt_index))
                self.stats[virt_index].total_time = now - self.stats_warmup_time

    # ------------------------------------------------------------------------------------------------------------------
    def jobs_waiting(self, index):
        return len(self.queue[index])

    # ------------------------------------------------------------------------------------------------------------------
    def jobs_in_system(self, index):
        return len(self.queue[index]) + self.jobs_receiving_service[index]

    # ------------------------------------------------------------------------------------------------------------------
    def print_server_info(self, msg, *args):
        """ Print server information. """
        if self.sim.show_server_info:
            self.sim.print_simulation_message("Server: " + (msg % args))

    # ------------------------------------------------------------------------------------------------------------------
    def print_job_event_info(self, virt_index, msg):
        """ Print job event information. """
        if self.sim.show_job_event_info:
            self.sim.print_simulation_message("virt_index:%d, jobs_waiting:%d, jobs_receiving_service:%d, "
                                              "jobs_in_system:%d:  %s" %
                         (virt_index, self.jobs_waiting(virt_index), self.jobs_receiving_service[virt_index],
                          self.jobs_in_system(virt_index), msg))

    # ------------------------------------------------------------------------------------------------------------------
    def print_job_stat_info(self, virt_index, job_number, job_wait_time, job_service_time, job_response_time):
        """ Print job statistic information. """
        if self.sim.show_job_stat_info:
            self.sim.print_simulation_message("virt_index:%d, job_no:%d, wait_time:%.03f, service_time:%.03f, "
                                              "response_time:%.03f" %
                         (virt_index, job_number, job_wait_time, job_service_time, job_response_time))


# ----------------------------------------------------------------------------------------------------------------------
class QueueingSystemSimulation:
    PROGRESS_PCT_STEPS = 10        # in percent

    # ------------------------------------------------------------------------------------------------------------------
    def __init__(self, N, C, S, Rs, arrival_distributions, f_clk, SD=QueueingSystem.ServiceDiscipline.FCFS,
                 sd_random_class=None, stats_warmup_time=0, show_server_info=False, show_job_event_info=False,
                 show_job_stat_info=False, show_progress_info=False):

        # Show options.
        self.show_server_info = show_server_info
        self.show_job_event_info = show_job_event_info
        self.show_job_stat_info = show_job_stat_info
        self.show_progress_info = show_progress_info

        # Setup callbacks.
        self.callbacks_before_run = []
        self.callbacks_after_run = []

        # Create environment and queueing system.
        self.env = simpy.Environment()
        self.system = QueueingSystem(self, N, C, S, Rs, arrival_distributions, f_clk, SD=SD,
                                     sd_random_class=sd_random_class, stats_warmup_time=stats_warmup_time)

        # Register the monitor progress process.
        self.env.process(self.process_monitor_progress())

    # ------------------------------------------------------------------------------------------------------------------
    def process_monitor_progress(self):
        """ Show progress process.  This process monitors the progress of the simulation and reports
        at what percentage of the simulation is complete. """
        timeout = self.sim_time * (self.PROGRESS_PCT_STEPS / 100)
        if self.show_progress_info:
            Done = False
            while not Done:
                if self.env.now + timeout >= self.sim_time:
                    yield self.env.timeout(self.sim_time - self.env.now - 1e-15)
                    Done = True
                else:
                    yield self.env.timeout(timeout)
                self.print_simulation_message("%3.f %%" % (self.env.now / self.sim_time * 100))

    # ------------------------------------------------------------------------------------------------------------------
    def execute_callbacks_before_run(self):
        for callback in self.callbacks_before_run:
            callback(self)

    # ------------------------------------------------------------------------------------------------------------------
    def execute_callbacks_after_run(self):
        for callback in self.callbacks_after_run:
            callback(self)

    # ------------------------------------------------------------------------------------------------------------------
    def run(self, sim_time):
        # Save the total simulation time for the monitor_progress process.
        self.sim_time = sim_time

        # Run the simulation.
        t1 = time.time()
        self.execute_callbacks_before_run()
        self.env.run(until=sim_time)
        self.execute_callbacks_after_run()
        execution_time = time.time() - t1

        # Return.
        return execution_time

    # ------------------------------------------------------------------------------------------------------------------
    def print_simulation_message(self, msg):
        """ Formatted simulation message print function. """
        print("[%s]  %s" % (("%.2f" % self.env.now).rjust(9), msg))


# ######################################################################################################################


# ----------------------------------------------------------------------------------------------------------------------
class QueueingSystemSimulationBatch:
    JSON_SEPARATERS = (',', ':')

    SimulationParametersTuple = namedtuple("SimulationParametersTuple", [
        "num_replications",
        "N",
        "C",
        "S",
        "Rs",
        "f_clk",
        "A_dist",
        "lambd",
        "sim_clocks",
    ])

    # ------------------------------------------------------------------------------------------------------------------
    def __init__(self, detail_csv_file, summary_csv_file, max_workers=None, skip_csv_headers=False,
                 csv_file_open_mode="w"):
        self.detail_csv_file = detail_csv_file
        self.summary_csv_file = summary_csv_file
        self.skip_csv_headers = skip_csv_headers
        self.csv_file_open_mode = csv_file_open_mode

        if max_workers is None:
            pass
        elif isinstance(max_workers, str):
            if max_workers == "max_cpus":
                max_workers = os.cpu_count()
            else:
                raise ValueError("max_workers = %s" % repr(max_workers))
        elif isinstance(max_workers, int):
            if max_workers <= 0:
                max_workers = max(1, max_workers + os.cpu_count())
        else:
            raise TypeError("max_workers is type %s" % repr(type(max_workers)))
        self.max_workers = max_workers

    # ------------------------------------------------------------------------------------------------------------------
    def run(self, parameters_iterable):
        """ Run the batch of simulations.  The passed in iterable is an iterable of SimulationParametersTuple containing
         the parameters passed into the simulation. """

        import virt_queueing_model as qm
        import mt19937_substreams

        # Get an iterator from the iterable.
        parameters_iter = iter(parameters_iterable)

        # Create the mt19937 substream index generator.
        mt19937_substream_index_generator = mt19937_substreams.generate_substream_indices(
            start=0, shuffle=False)

        # Create the default dictionary factory of random index generators.
        random_indices_collection = defaultdict(lambda: next(mt19937_substream_index_generator))

        # Function to get the random state for a given set of arguments.
        def get_random_state(*args):
            return mt19937_substreams.get_random_state_at_index(random_indices_collection[args])

        sim_summary_index_counter = count()
        sim_detail_index_counter = count()

        # Change this process to a lower priority if psutil is available.
        if sys.platform.startswith("linux"):
            os.setpriority(os.PRIO_PROCESS, 0, 10)
        elif sys.platform.startswith("win32"):
            try:
                import psutil
            except ImportError:
                print("psutil module not installed. Cannot change process to lower priority.", file=sys.stderr)
            else:
                parent = psutil.Process()
                parent.nice(psutil.BELOW_NORMAL_PRIORITY_CLASS)
        else:
            print("Warning: Unknown platform %s. Cannot change process to lower priority." % repr(sys.platform),
                  file=sys.stderr)

        futures = deque()
        with utils.TimeIt("Do Experiments", verbose=True) as do_experiments_timer, \
                concurrent.futures.ProcessPoolExecutor(max_workers=self.max_workers) as executor, \
                utils.CancelFuturesOnException(futures):

            # Do experiments.
            experiments_info = []
            num_experiments_with_replications = 0

            for parameters in parameters_iter:
                # Parameter calculations.
                t_clk = 1 / parameters.f_clk

                # Do analytical calculations using queueing model.
                model = qm.QueueingSystemModel_MG1(
                    parameters.N, parameters.C, parameters.S, parameters.Rs, t_clk=t_clk, lambd=parameters.lambd)

                replications = []
                extra = {}
                sim_summary_index = next(sim_summary_index_counter)
                experiments_info.append((
                    (
                        sim_summary_index,
                        parameters,
                    ),
                    model,
                    replications,
                    extra,
                ))

                dist_class, dist_args = distributions.RandomDistribution.get_distribution_as_class_and_parameters(
                    parameters.A_dist, parameters.lambd)

                extra["dist_class"] = dist_class
                extra["dist_args"] = dist_args

                for repl_index in range(parameters.num_replications):
                    sim_detail_index = next(sim_detail_index_counter)
                    replications.append((sim_detail_index, repl_index))

                    arrivals_dist_virt_array = []
                    for virt_index in range(parameters.N):
                        arrivals_dist_virt_array.append({
                            "dist_class": dist_class,
                            "dist_args": dist_args,
                            "rngstate": get_random_state("arrival", repl_index),
                            # "rngstate": get_random_state("arrival", virt_index, repl_index),
                        })

                    futures.append(executor.submit(
                        self.do_simulation,
                        parameters.N, parameters.C, parameters.S, parameters.Rs, parameters.f_clk, parameters.A_dist,
                        parameters.lambd, parameters.sim_clocks, repl_index, arrivals_dist_virt_array,
                        sim_detail_index))
                    num_experiments_with_replications += 1

            print("%d experiments (total of %d runs) submitted to concurrent executor." %
                  (len(experiments_info), num_experiments_with_replications))

            # Get results and print out as csv.
            with open(self.detail_csv_file, self.csv_file_open_mode) as f_detail, \
                    open(self.summary_csv_file, self.csv_file_open_mode) as f_summary:
                # Write detail row header.
                cw_detail = csv.writer(f_detail, lineterminator="\n")
                if not self.skip_csv_headers:
                    cw_detail.writerow([
                        # Run info.
                        "Summary Index", "Detail Index", "Exp Elapsed Time (s)", "Sim Elapsed Time (s)",

                        # Simulation parameters.
                        "Sim Clocks", "Sim Time (s)", "N", "C", "S", "Rs", "Lambda A", "Dist A", "Mean A", "Stdv A",
                        "Repl Index", "Virt Index",

                        # Simulation outputs.
                        "Num Arrivals",
                        "Num Departures",
                        "Stats Sim Time (s)",
                        "Mean Jobs Waiting",
                        "Stdv Jobs Waiting",
                        "Mean Jobs Receiving Service",
                        "Stdv Jobs Receiving Service",
                        "Mean Jobs in System",
                        "Stdv Jobs in System",
                        "Cov of Jobs Waiting and Jobs Receiving Service (^2)",
                        "Mean Jobs in Busy Period",
                        "Stdv Jobs in Busy Period",
                        "Mean Busy Period",
                        "Stdv Busy Period",
                        "Mean Idle Period",
                        "Stdv Idle Period",
                        "Mean Wait Time (s)",
                        "Stdv Wait Time (s)",
                        "Mean Service Time (s)",
                        "Stdv Service Time (s)",
                        "Mean Response Time (s)",
                        "Stdv Response Time (s)",
                        "Cov of Wait Time and Service Time (s^2)",
                    ])
                    f_detail.flush()

                # Write summary row header.
                cw_summary = csv.writer(f_summary, lineterminator='\n')
                if not self.skip_csv_headers:
                    cw_summary.writerow([
                        # Run info.
                        "Summary Index", "Mean Exp Elapsed Time (s)", "Mean Sim Elapsed Time (s)",

                        # Simulation parameters.
                        "Sim Clocks", "Sim Time (s)", "N", "C", "S", "Rs", "Lambda A", "Dist A", "Mean A", "Stdv A",
                        "Num Repl",
                        "Num Repl*Virt",

                        # Simulation outputs.
                        "Mean of Mean Jobs Waiting",
                        "Sdom of Mean Jobs Waiting",
                        "Mean of Stdv Jobs Waiting",
                        "Mean of Mean Jobs Receiving Service",
                        "Sdom of Mean Jobs Receiving Service",
                        "Mean of Stdv Jobs Receiving Service",
                        "Mean of Mean Jobs in System",
                        "Sdom of Mean Jobs in System",
                        "Mean of Stdv Jobs in System",
                        "Mean of Cov Jobs Waiting and Jobs Receiving Service",
                        "Sdom of Cov Jobs Waiting and Jobs Receiving Service",
                        "Mean of Mean Wait Time (s)",
                        "Sdom of Mean Wait Time (s)",
                        "Mean of Stdv Wait Time (s)",
                        "Mean of Mean Service Time (s)",
                        "Sdom of Mean Service Time (s)",
                        "Mean of Stdv Service Time (s)",
                        "Mean of Mean Response Time (s)",
                        "Sdom of Mean Response Time (s)",
                        "Mean of Stdv Response Time (s)",

                        # Simulation histogram output.
                        "Mean Histogram of Jobs Waiting",

                        # Analytic queueing model outputs.
                        "[Model] Offered Load",
                        "[Model] Rho",
                        "[Model] Total Schedule Time (clks)",
                        "[Model] Service Time (clks)",
                        "[Model] Vacation Time (clks)",
                        "[Model] Vacation Context Switch Time (clks)",
                        "[Model] Mean Service Time (s)",
                        "[Model] Service Time Second Moment (s)",
                        "[Model] Service Time Third Moment (s)",
                        "[Model] Mean Vacation Waiting Time (s)",
                        "[Model] Service Rate (/s)",
                        "[Model] Total Achievable Throughput (/s)",
                        "[Model] Total Achievable Throughput w/ S=0 (/s)",
                        "[Model] Empty Queue Probability",
                        "[Model] Service Time Fraction",
                        "[Model] Vacation Time Fraction",
                        "[Model] Vacation Context Switch Time Fraction",
                        "[Model] Queue Wait Time (s)",
                        "[Model] Head of Queue Wait Time (s)",
                        "[Model] Service Wait Time (s)",
                        "[Model] Total Wait Time (s)",
                        "[Model] Number in Queue",
                        "[Model] Number in Service",
                        "[Model] Number in System",

                        # JSON blob of analytical queueing model outputs.
                        "[Model] JSON Blob",
                    ])
                    f_summary.flush()

                # Process each future.
                for (sim_summary_index, parameters), model, replications, extra in experiments_info:
                    # Setup statistic results.
                    stats_exp_elapsed_times = qsc.DataArray()
                    stats_sim_elapsed_times = qsc.DataArray()
                    stats_mean_jobs_waiting = qsc.DataArray()
                    stats_std_jobs_waiting = qsc.DataArray()
                    stats_histograms_of_jobs_waiting = []
                    stats_mean_jobs_receiving_service = qsc.DataArray()
                    stats_std_jobs_receiving_service = qsc.DataArray()
                    stats_mean_jobs_in_system = qsc.DataArray()
                    stats_std_jobs_in_system = qsc.DataArray()
                    stats_cov_jobs_waiting_and_jobs_receiving_service = qsc.DataArray()
                    stats_mean_job_wait_time = qsc.DataArray()
                    stats_std_job_wait_time = qsc.DataArray()
                    stats_mean_job_service_time = qsc.DataArray()
                    stats_std_job_service_time = qsc.DataArray()
                    stats_mean_job_response_time = qsc.DataArray()
                    stats_std_job_response_time = qsc.DataArray()

                    # Calculations.
                    sim_time = parameters.sim_clocks / parameters.f_clk

                    dist = extra["dist_class"](*extra["dist_args"])

                    for sim_detail_index, repl_index in replications:
                        # Get next future simulation result.
                        f = futures.popleft()
                        result = f.result()

                        # Print processing message.
                        print("[%d] Processing result." % sim_detail_index)

                        if result is None:
                            print("[%d] Result is None.  Skipping." % sim_detail_index)
                            continue

                        # Results and calculations.
                        exp_elapsed_time = result["exp_elapsed_time"]
                        sim_elapsed_time = result["sim_elapsed_time"]
                        sim_results = result["sim_results"]
                        virt_queues = sim_results["virt_queues"]

                        for virt_index in range(parameters.N):
                            # Write detail row.
                            cw_detail.writerow([
                                # Run info.
                                sim_summary_index, sim_detail_index, exp_elapsed_time, sim_elapsed_time,

                                # Simulation parameters.
                                parameters.sim_clocks,
                                sim_time,
                                parameters.N,
                                parameters.C,
                                parameters.S,
                                parameters.Rs,
                                parameters.lambd,
                                parameters.A_dist,
                                dist.mean(),
                                dist.stdev(),
                                repl_index,
                                virt_index,

                                # Simulation outputs.
                                virt_queues[virt_index]["total_arrivals"],
                                virt_queues[virt_index]["total_departures"],
                                virt_queues[virt_index]["total_time"],
                                virt_queues[virt_index]["mean_jobs_waiting"],
                                virt_queues[virt_index]["std_jobs_waiting"],
                                virt_queues[virt_index]["mean_jobs_receiving_service"],
                                virt_queues[virt_index]["std_jobs_receiving_service"],
                                virt_queues[virt_index]["mean_jobs_in_system"],
                                virt_queues[virt_index]["std_jobs_in_system"],
                                virt_queues[virt_index]["cov_jobs_waiting_and_jobs_receiving_service"],
                                virt_queues[virt_index]["mean_jobs_in_busy_period"],
                                virt_queues[virt_index]["std_jobs_in_busy_period"],
                                virt_queues[virt_index]["mean_busy_period"],
                                virt_queues[virt_index]["std_busy_period"],
                                virt_queues[virt_index]["mean_idle_period"],
                                virt_queues[virt_index]["std_idle_period"],
                                virt_queues[virt_index]["mean_job_wait_time"],
                                virt_queues[virt_index]["std_job_wait_time"],
                                virt_queues[virt_index]["mean_job_service_time"],
                                virt_queues[virt_index]["std_job_service_time"],
                                virt_queues[virt_index]["mean_job_response_time"],
                                virt_queues[virt_index]["std_job_response_time"],
                                virt_queues[virt_index]["cov_job_wait_time_and_job_service_time"],
                            ])

                            # Build statistics.
                            stats_mean_jobs_waiting.append(virt_queues[virt_index]["mean_jobs_waiting"])
                            stats_std_jobs_waiting.append(virt_queues[virt_index]["std_jobs_waiting"])
                            stats_histograms_of_jobs_waiting.append(virt_queues[virt_index]["histogram_jobs_waiting"])
                            stats_mean_jobs_receiving_service.append(
                                virt_queues[virt_index]["mean_jobs_receiving_service"])
                            stats_std_jobs_receiving_service.append(
                                virt_queues[virt_index]["std_jobs_receiving_service"])
                            stats_mean_jobs_in_system.append(virt_queues[virt_index]["mean_jobs_in_system"])
                            stats_std_jobs_in_system.append(virt_queues[virt_index]["std_jobs_in_system"])
                            stats_cov_jobs_waiting_and_jobs_receiving_service.append(
                                virt_queues[virt_index]["cov_jobs_waiting_and_jobs_receiving_service"])
                            stats_mean_job_wait_time.append(virt_queues[virt_index]["mean_job_wait_time"])
                            stats_std_job_wait_time.append(virt_queues[virt_index]["std_job_wait_time"])
                            stats_mean_job_service_time.append(virt_queues[virt_index]["mean_job_service_time"])
                            stats_std_job_service_time.append(virt_queues[virt_index]["std_job_service_time"])
                            stats_mean_job_response_time.append(virt_queues[virt_index]["mean_job_response_time"])
                            stats_std_job_response_time.append(virt_queues[virt_index]["std_job_response_time"])

                        f_detail.flush()

                        # Build statistics.
                        stats_exp_elapsed_times.append(exp_elapsed_time)
                        stats_sim_elapsed_times.append(sim_elapsed_time)

                    if len(stats_exp_elapsed_times) != parameters.num_replications:
                        print(
                            "Skipping summary result (index %d).  The number of detailed results is %d and the number of replications is %d." %
                            (sim_summary_index, len(stats_exp_elapsed_times), parameters.num_replications))
                        continue

                    model_dicts = {
                        "parameters": model.parameters,
                        "calculations": model.calculations,
                    }

                    cw_summary.writerow([
                        # Run info.
                        sim_summary_index, stats_exp_elapsed_times.mean(), stats_sim_elapsed_times.mean(),

                        # Simulation parameters.
                        parameters.sim_clocks,
                        sim_time,
                        parameters.N,
                        parameters.C,
                        parameters.S,
                        parameters.Rs,
                        parameters.lambd,
                        parameters.A_dist,
                        dist.mean(),
                        dist.stdev(),
                        parameters.num_replications,
                        parameters.num_replications * parameters.N,

                        # Simulation outputs.
                        stats_mean_jobs_waiting.mean(),
                        stats_mean_jobs_waiting.sdom(),
                        stats_std_jobs_waiting.mean(),
                        stats_mean_jobs_receiving_service.mean(),
                        stats_mean_jobs_receiving_service.sdom(),
                        stats_std_jobs_receiving_service.mean(),
                        stats_mean_jobs_in_system.mean(),
                        stats_mean_jobs_in_system.sdom(),
                        stats_std_jobs_in_system.mean(),
                        stats_cov_jobs_waiting_and_jobs_receiving_service.mean(),
                        stats_cov_jobs_waiting_and_jobs_receiving_service.sdom(),
                        stats_mean_job_wait_time.mean(),
                        stats_mean_job_wait_time.sdom(),
                        stats_std_job_wait_time.mean(),
                        stats_mean_job_service_time.mean(),
                        stats_mean_job_service_time.sdom(),
                        stats_std_job_service_time.mean(),
                        stats_mean_job_response_time.mean(),
                        stats_mean_job_response_time.sdom(),
                        stats_std_job_response_time.mean(),

                        # Simulation histogram output.
                        json.dumps(qsc.norm_histogram(qsc.mean_histogram(*stats_histograms_of_jobs_waiting)),
                                   separators=self.JSON_SEPARATERS),

                        # Analytic queueing model outputs.
                        model.calculations["offered_load"],
                        model.calculations["rho"],
                        model.calculations["TT"],
                        model.calculations["TS"],
                        model.calculations["TV"],
                        model.calculations["TCS"],
                        model.calculations["X"],
                        model.calculations["X2"],
                        model.calculations["X3"],
                        model.calculations["V"],
                        model.calculations["muS"],
                        model.calculations["TTOT"],
                        model.calculations["TTOT0"],
                        model.calculations["p0"],
                        model.calculations["ps"],
                        model.calculations["pv"],
                        model.calculations["pcs"],
                        model.calculations["Wq"],
                        model.calculations["Wh"],
                        model.calculations["Ws"],
                        model.calculations["WTOT"],
                        model.calculations["Nq"],
                        model.calculations["Ns"],
                        model.calculations["NTOT"],

                        # JSON blob of analytical queueing model outputs.
                        json.dumps(model_dicts, separators=self.JSON_SEPARATERS)
                    ])
                    f_summary.flush()

    # ------------------------------------------------------------------------------------------------------------------
    @classmethod
    def do_simulation(cls, N, C, S, Rs, f_clk, A_dist, lambd, sim_clocks, repl_index, arrivals, sim_detail_index):
        """ Do a queueing simulation run.  This method runs in a concurrent executor in a worker process. It therefore
         is independent from the rest of the class. """

        # Print simulation label.
        print("[%d] Simulating N=%r, C=%r, S=%r, Rs=%r, A_dist=%r, lambd=%r, sim_clocks=%r, repl_index=%r" %
              (sim_detail_index, N, C, S, Rs, A_dist, lambd, sim_clocks, repl_index))

        experiment_timer = None
        sim_timer = None
        try:
            with utils.TimeIt("Full Experiment", verbose=False) as experiment_timer:
                # Calculations.
                t_clk = 1 / f_clk

                # Setup experiment.
                dedupper = {}
                arrival_distributions = []
                for virt_index, item in enumerate(arrivals):
                    rngstate = item["rngstate"]
                    if rngstate in dedupper:
                        # If the random state for this arrival distribution is the same as another one, then we define
                        # them to be sharing the same random class.  So, we need to dedup them here.
                        random_class = dedupper[rngstate]
                    else:
                        random_class = random.Random()
                        random_class.setstate(item["rngstate"])
                        dedupper[rngstate] = random_class
                    arrival_distributions.append(item["dist_class"](
                        *item["dist_args"],
                        random_class=random_class
                    ))
                del dedupper

                # Create the virtualized queueing system simulation.
                sim = QueueingSystemSimulation(
                    N=N, C=C, S=S, Rs=Rs, arrival_distributions=arrival_distributions, f_clk=f_clk,
                    SD=QueueingSystem.ServiceDiscipline.FCFS, sd_random_class=None, stats_warmup_time=100 * t_clk,
                    show_server_info=False,
                    show_job_event_info=False,
                    show_job_stat_info=False,
                    show_progress_info=False
                )

                # Do experiment.
                with utils.TimeIt("Simulation Run", verbose=False) as sim_timer:
                    sim.run(sim_clocks * t_clk)

                # Get result.
                result = {
                    "sim_detail_index": sim_detail_index,
                    "sim_elapsed_time": sim_timer.elapsed_time,
                    "sim_results": {
                        "virt_queues": []
                    }
                }

                virt_queues = result["sim_results"]["virt_queues"]
                for virt_index in range(N):
                    queue_stats = sim.system.stats[virt_index]
                    # Filter out unstable queues.
                    if queue_stats.total_arrivals >= 1.1 * queue_stats.total_departures:
                        print("[%d] System is unstable.  Total arrivals is %d and total departures is %d." %
                              (sim_detail_index, queue_stats.total_arrivals, queue_stats.total_departures))
                        return None
                    virt_queues.append({
                        "mean_jobs_waiting": queue_stats.jobs_waiting.mean(),
                        "std_jobs_waiting": queue_stats.jobs_waiting.std(),
                        "histogram_jobs_waiting": queue_stats.jobs_waiting.histogram(),
                        "mean_jobs_receiving_service": queue_stats.jobs_receiving_service.mean(),
                        "std_jobs_receiving_service": queue_stats.jobs_receiving_service.std(),
                        "mean_jobs_in_system": queue_stats.jobs_in_system.mean(),
                        "std_jobs_in_system": queue_stats.jobs_in_system.std(),
                        "cov_jobs_waiting_and_jobs_receiving_service":
                            queue_stats.cov_jobs_waiting_and_jobs_receiving_service(),
                        "cov_job_wait_time_and_job_service_time": queue_stats.cov_job_wait_time_and_job_service_time(),
                        "mean_jobs_in_busy_period": queue_stats.busy_period.num_jobs.mean(),
                        "std_jobs_in_busy_period": queue_stats.busy_period.num_jobs.std(),
                        "mean_busy_period": queue_stats.busy_period.duration.mean(),
                        "std_busy_period": queue_stats.busy_period.duration.std(),
                        "mean_idle_period": queue_stats.idle_period.duration.mean(),
                        "std_idle_period": queue_stats.idle_period.duration.std(),
                        "mean_job_wait_time": queue_stats.job_wait_time.mean(),
                        "std_job_wait_time": queue_stats.job_wait_time.std(),
                        "mean_job_service_time": queue_stats.job_service_time.mean(),
                        "std_job_service_time": queue_stats.job_service_time.std(),
                        "mean_job_response_time": queue_stats.job_response_time.mean(),
                        "std_job_response_time": queue_stats.job_response_time.std(),
                        "total_arrivals": queue_stats.total_arrivals,
                        "total_departures": queue_stats.total_departures,
                        "total_time": queue_stats.total_time,
                    })

            result["exp_elapsed_time"] = experiment_timer.elapsed_time
        except Exception:
            # Print exception message.
            print(("[%d] Got exception:\n" % sim_detail_index) + "".join(traceback.format_exc()))
            raise
        finally:
            # Print finished label.
            if experiment_timer is not None:
                if sim_timer is not None:
                    print("[%d] Finished in total elapsed time %.2f s and sim elapsed time %.2f s." %
                          (sim_detail_index, experiment_timer.elapsed_time, sim_timer.elapsed_time))
                else:
                    print("[%d] Finished in total elapsed time %.2f s." %
                          (sim_detail_index, experiment_timer.elapsed_time))
            else:
                print("[%d] Finished.")

        # Return the result.
        return result


# ######################################################################################################################


# ----------------------------------------------------------------------------------------------------------------------
def example_queueing_sim():
    N = 8
    random_class = random.Random(0)
    arrival_distributions = [
        distributions.ExponentialDistribution(0.5 / N, random_class=random_class)
        for _ in range(N)
    ]

    sim = QueueingSystemSimulation(
        N=N, C=4, S=2, Rs=2, arrival_distributions=arrival_distributions, f_clk=1,
        SD=QueueingSystem.ServiceDiscipline.FCFS, sd_random_class=random_class, stats_warmup_time=0,
        show_server_info=True,
        show_job_event_info=True,
        show_job_stat_info=True,
        show_progress_info=True
    )

    #sim.run(100000)
    sim.run(100)
    print()
    for virt_index in range(N):
        sim.system.stats[virt_index].print("Virtual computation %d" % virt_index, job_unit="elements", time_unit="s")


# ----------------------------------------------------------------------------------------------------------------------
def example_queueing_sim_batch():
    import virt_queueing_model as qm

    sim_batch = QueueingSystemSimulationBatch("eg_sim.detail.csv", "eg_sim.summary.csv")

    parameters = [
        sim_batch.SimulationParametersTuple(
            num_replications,
            N,
            C,
            S,
            Rs,
            f_clk,
            A_dist,
            # Lambd
            qm.QueueingSystemModel_MG1.calc_lambd_from_offered_load(N, 1 / f_clk, offered_load),
            # Sim clocks
            10000
        )
        for num_replications, N, C, S, Rs, f_clk, A_dist, offered_load in [
            (1, 8, 4, 10, 2, 1, "M", 0.3),
            (2, 8, 2, 8, 2, 1, "M", 0.3),
        ]
    ]

    sim_batch.run(parameters)


# ----------------------------------------------------------------------------------------------------------------------
if __name__ == "__main__":
    #example_queueing_sim()
    example_queueing_sim_batch()
