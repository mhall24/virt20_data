'''
Created on Jan 30, 2016

@author: Michael Hall
'''

from collections import OrderedDict

import virt_queueing_model as qm
import virt_queueing_simulation as qs

ServiceDiscipline = qs.QueueingSystem.ServiceDiscipline

SHOW_PLOTS = False

JSON_SEPARATERS = (',', ':')


# ######################################################################################################################


# ----------------------------------------------------------------------------------------------------------------------
def main_experiments(skip_csv_headers=False):
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
    main_experiments(skip_csv_headers=False)
