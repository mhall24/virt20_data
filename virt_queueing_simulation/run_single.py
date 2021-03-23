'''
Created on Jan 30, 2016

@author: Michael Hall
'''

import random
import sys

import distributions
import utils
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
if __name__ == "__main__":
    main_single()
