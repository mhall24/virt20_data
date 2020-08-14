'''
Created on Jan 30, 2016

@author: Michael Hall
'''

import random
import sys
from collections import OrderedDict

import distributions
import utils
import virt_queueing_model as qm
import virt_queueing_simulation as qs

ServiceDiscipline = qs.QueueingSystem.ServiceDiscipline

SHOW_PLOTS = False

JSON_SEPARATERS = (',', ':')


# ######################################################################################################################


# ----------------------------------------------------------------------------------------------------------------------
def main_single():
    # Parameters.
    C = 10
    N = 100
    S = 100
    Rs = 20

    f_clk = 1
    offered_loads = [0.08 for _ in range(N)]

    #arrival_rates = [0.5 / N for _ in range(N)]

    # Calculations.
    t_clk = 1 / f_clk
    arrival_rates = [offered_loads[i] / (N * t_clk) for i in range(N)]

    # Random class.
    random_class = random.Random(0)

    # Generate arrival process distributions.
    arrival_process_distributions = [

        # distributions.ExponentialDistribution(
        #     lambd=arrival_rates[i],
        #     random_class=random_class)

        distributions.ErlangDistribution(
            lambd=arrival_rates[i],
            k=10,
            random_class=random_class)

        # distributions.HyperexponentialDistribution(
        #     lambd=arrival_rates[i],
        #     lambd_weights=(1, 10),
        #     prob_weights=(1, 10),
        #     random_class=random_class)

        for i in range(N)
    ]

    # Create the virtualized queueing system simulation.
    sim = qs.QueueingSystemSimulation(
        N=N, C=C, S=S, Rs=Rs, arrival_distributions=arrival_process_distributions, f_clk=f_clk,
        SD=ServiceDiscipline.FCFS, sd_random_class=random_class, stats_warmup_time=100 * t_clk,
        show_server_info=False,
        show_job_event_info=False,
        show_job_stat_info=False,
        show_progress_info=True
    )

    # Run the simulation.
    with utils.TimeIt("Simulation Run"):
        sim.run(1000000 * t_clk)
    print()

    # Print formatting parameters.
    width = 37

    # Helper print function.
    def print_value(name, value, indent=0, width=width, file=sys.stdout):
        left_part = " " * indent + name + ": "
        print("{left_part:{width}}{value}".format(left_part=left_part, value=value, width=width), file=file)

    print("Parameters")
    print("----------")
    print_value("N", "%d total data streams" % sim.system.N)
    print_value("C", "%d fine-grain contexts" % sim.system.C)
    print_value("S", "%d clks" % sim.system.S)
    print_value("Rs", "%d schedule period rounds" % sim.system.Rs)
    print()
    print_value("f_clk", "{:,.1f} Hz".format(sim.system.f_clk))
    print_value("t_clk", "{:,.3f} us".format(sim.system.t_clk * 1e6))
    print()
    print("Arrival rates")
    for i in range(N):
        lambda_index = i + 1
        print_value("lambda_%d" % lambda_index, "%.4f elements/s" % arrival_rates[i], indent=3)
    print()
    print_value("service_discipline", sim.system.SD)
    print()

    print("Simulation results")
    print("------------------")
    for virt_index in range(N):
        sim.system.stats[virt_index].print("Virtual computation %d" % virt_index, job_unit="elements", time_unit="s")


# ----------------------------------------------------------------------------------------------------------------------
def main_experiment(skip_csv_headers=False):
    # Max workers.
    max_workers = None

    # Result file parameters.
    result_file_prefix = "MG1_sim"
    result_file_open_mode = "a"

    # Calculations.
    detail_csv_file = result_file_prefix + ".detail.csv"
    summary_csv_file = result_file_prefix + ".summary.csv"

    # Define generator to generate parameters.
    def generate_parameters():
        sim_clocks = 1000000
        f_clk = 1
        t_clk = 1 / f_clk

        # Define the distributions of interest.
        distributions = OrderedDict([
            ("M at Sigma", "M"),
            ("Half Sigma", "E4"),
            ("Twice Sigma", "Hyper(WL=[1, 10], WP=[1, 3.26])"),
            ("D at Zero", "D")
        ])

        for _, A_dist in distributions.items():
            for C, N, S, offered_load_list, Rs_max, num_replications in [
                (10, 100, 100, [0.08, 0.5], 40, 1),
                (4, 8, 4, [0.16, 0.48], 20, 10),
            ]:
                for offered_load in offered_load_list:
                    lambd = qm.QueueingSystemModel_MG1.calc_lambd_from_offered_load(N, t_clk, offered_load)
                    for Rs in range(1, Rs_max + 1):
                        # Do analytical calculations using queueing model.
                        model = qm.QueueingSystemModel_MG1(N, C, S, Rs, t_clk=t_clk, lambd=lambd)

                        # Skip this experiment if the system is not stable as indicated by the model.
                        if not model.is_stable:
                            continue

                        yield qs.QueueingSystemSimulationBatch.SimulationParametersTuple(
                            num_replications,
                            N,
                            C,
                            S,
                            Rs,
                            f_clk,
                            A_dist,
                            lambd,
                            sim_clocks,
                        )

    # Create batch simulator class instance.
    batch_sim = qs.QueueingSystemSimulationBatch(detail_csv_file, summary_csv_file, max_workers=max_workers,
                                                 skip_csv_headers=skip_csv_headers,
                                                 csv_file_open_mode=result_file_open_mode)

    # Run the batch simulations.
    batch_sim.run(generate_parameters())


# ----------------------------------------------------------------------------------------------------------------------
if __name__ == "__main__":
    #main_single()
    main_experiment(skip_csv_headers=False)
