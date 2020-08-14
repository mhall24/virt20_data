""" Virtualized hardware queueing model """

import math
import sys
from collections import OrderedDict

import numpy as np

import queueing_model_common as qmc

QueueingSystemModelError = qmc.QueueingSystemModelError


# ######################################################################################################################


# ----------------------------------------------------------------------------------------------------------------------
class QueueingSystemModel_MG1:
    # ------------------------------------------------------------------------------------------------------------------
    def __init__(self, N, C, S, Rs, f_clk=None, t_clk=None, lambd=None, offered_load=None, rho=None):
        """
        N is the number of streams.
        C is the pipeline depth.
        S is the cost of a context switch.
        Rs is the schedule period.
        """

        # System parameters
        if N < C or N % C != 0:
            raise QueueingSystemModelError("N must be >= C and a multiple of C.  N is %s and C is %s." % (N, C))

        self.N = N
        self.C = C
        self.S = S
        self.Rs = Rs

        if f_clk is None:
            if t_clk is None:
                self.f_clk = f_clk = 1
                self.t_clk = t_clk = 1
            else:
                self.t_clk = t_clk
                self.f_clk = f_clk = 1 / t_clk
        else:
            assert t_clk is None
            self.f_clk = f_clk
            self.t_clk = t_clk = 1 / f_clk

        # Calculate lambda arrivals.
        if lambd is None:
            if offered_load is None:
                assert rho is not None
                self.lambd = lambd = self.calc_lambd_from_rho(N, C, S, Rs, t_clk, rho)
            else:
                self.lambd = lambd = self.calc_lambd_from_offered_load(N, t_clk, offered_load)
        else:
            assert offered_load is None
            assert rho is None
            self.lambd = lambd

        # Save model parameters in dictionary.
        self.parameters = OrderedDict([
            ("N", self.N),
            ("C", self.C),
            ("S", self.S),
            ("Rs", self.Rs),
            ("f_clk", self.f_clk),
            ("t_clk", self.t_clk),
            ("lambd", self.lambd),
        ])

        # Do model calculations that do not require arrivals.
        TCS = S * N / C
        TT = Rs * N + TCS
        TS = Rs * C
        TV = TT - TS
        X = C * t_clk
        X2 = X ** 2
        X3 = X ** 3
        muS = Rs / (TT * t_clk)

        ps = TS / TT
        pv = 1 - ps
        pcs = TCS / TT

        Ws = X

        # Do model calculations that do require arrivals.
        offered_load = self.calc_offered_load_from_lambd(N, t_clk, lambd)
        Rs_gt_f = (S * N * lambd * t_clk) / (C * (1 - N * lambd * t_clk))
        Rs_min = 1 + math.floor(Rs_gt_f)
        rho = lambd / muS
        TTOT = N * muS
        TTOT0 = 1 / t_clk

        p0 = 1 - rho if not np.isnan(rho) and rho < 1 else np.nan

        # Options.
        service_period_queueing_delay = 1  # Delay due to C.
        service_period_vacation_delay_for_empty_queue = 1  # Fixed vacation delay due to empty queue.
        vacation_period_queueing_delay = 1  # Delay due to S.  Amortized with increasing Rs.
        vacation_period_schedule_delay = 1  # Delay increases with Rs.

        # Wait time expressions.
        V = 0 if not np.isnan(rho) and rho < 1 else np.nan
        if vacation_period_schedule_delay:
            V += 1 / 2 * p0 * (1 - ps) * TV * t_clk
        if service_period_vacation_delay_for_empty_queue:
            V += 1 / 2 * p0 * ps * C * t_clk
        if vacation_period_queueing_delay:
            V += (1 - p0) * (TV * t_clk) / Rs

        Wh = V / (1 - rho) if not np.isnan(rho) and rho < 1 else np.nan
        Wq = Wh if not np.isnan(rho) and rho < 1 else np.nan
        if service_period_queueing_delay:
            Wq += lambd * X2 / (2 * (1 - rho)) if not np.isnan(rho) and rho < 1 else np.nan
        WTOT = Wq + Ws

        # Queue occupancy expressions.
        Nq = lambd * Wq
        Ns = lambd * Ws
        NTOT = lambd * WTOT

        # Save model calculations in dictionary.
        self.calculations = {
            "offered_load": offered_load,
            "TCS": TCS,
            "TT": TT,
            "TS": TS,
            "TV": TV,
            "X": X,
            "X2": X2,
            "X3": X3,
            "V": V,
            "muS": muS,
            "Rs_gt_f": Rs_gt_f,
            "Rs_min": Rs_min,
            "rho": rho,
            "TTOT": TTOT,
            "TTOT0": TTOT0,
            "p0": p0,
            "ps": ps,
            "pv": pv,
            "pcs": pcs,
            "Wq": Wq,
            "Wh": Wh,
            "Ws": Ws,
            "WTOT": WTOT,
            "Nq": Nq,
            "Ns": Ns,
            "NTOT": NTOT,
        }

    # ------------------------------------------------------------------------------------------------------------------
    @staticmethod
    def calc_offered_load_from_lambd(N, t_clk, lambd):
        return lambd * N * t_clk

    # ------------------------------------------------------------------------------------------------------------------
    @classmethod
    def calc_offered_load_from_rho(cls, N, C, S, Rs, t_clk, rho):
        lambd = cls.calc_lambd_from_rho(N, C, S, Rs, t_clk, rho)
        return cls.calc_offered_load_from_lambd(N, t_clk, lambd)

    # ------------------------------------------------------------------------------------------------------------------
    @staticmethod
    def calc_lambd_from_offered_load(N, t_clk, offered_load):
        return offered_load / (N * t_clk)

    # ------------------------------------------------------------------------------------------------------------------
    @staticmethod
    def calc_lambd_from_rho(N, C, S, Rs, t_clk, rho):
        muS = Rs / ((Rs * N + S * N / C) * t_clk)
        return rho * muS

    # ------------------------------------------------------------------------------------------------------------------
    @property
    def is_stable(self):
        return self.calculations["rho"] < 1

    # ------------------------------------------------------------------------------------------------------------------
    def print(self, file=sys.stdout):
        print("Queueing Model Parameters", file=file)
        print("-------------------------", file=file)
        print("   N:            %d streams" % self.parameters["N"], file=file)
        print("   C:            %d pipeline stages" % self.parameters["C"], file=file)
        print("   S:            %d clks" % self.parameters["S"], file=file)
        print("   Rs:           %d rnds" % self.parameters["Rs"], file=file)
        print("   t_clk:        %.4g s" % self.parameters["t_clk"], file=file)
        print("   f_clk:        %.3f Hz" % self.parameters["f_clk"], file=file)
        print("   lambd:        %.4f e/s" % self.parameters["lambd"], file=file)
        print(file=file)
        print("Queueing Model Calculations", file=file)
        print("-------------------------", file=file)
        print("   offered_load: %.4f" % self.calculations["offered_load"], file=file)
        print("   TT:           %d clks" % self.calculations["TT"], file=file)
        print("   TS:           %d clks" % self.calculations["TS"], file=file)
        print("   TV:           %d clks" % self.calculations["TV"], file=file)
        print("   TCS:          %d clks (lost due to context switch)" % self.calculations["TCS"], file=file)
        print("   X:            %.2f s" % self.calculations["X"], file=file)
        print("   X2:           %.2f s" % self.calculations["X2"], file=file)
        print("   X3:           %.2f s" % self.calculations["X3"], file=file)
        print("   V:            %.2f s" % self.calculations["V"], file=file)
        print("   muS:          %.4f e/s" % self.calculations["muS"], file=file)
        print("   Rs_gt_f:      %.3f" % self.calculations["Rs_gt_f"], file=file)
        print("   Rs_min:       %d" % self.calculations["Rs_min"], file=file)
        print("   rho:          %.4f" % self.calculations["rho"], file=file)
        print("   TTOT:         %.3f e/s" % self.calculations["TTOT"], file=file)
        print("   TTOT0:        %.3f e/s" % self.calculations["TTOT0"], file=file)
        print("   p0:           %.4f" % self.calculations["p0"], file=file)
        print("   ps:           %.4f" % self.calculations["ps"], file=file)
        print("   pv:           %.4f" % self.calculations["pv"], file=file)
        print("   pcs:          %.4f (lost due to context switch)" % self.calculations["pcs"], file=file)
        print("   Wq:           %.2f s" % self.calculations["Wq"], file=file)
        print("   Wh:           %.2f s" % self.calculations["Wh"], file=file)
        print("   Ws:           %.2f s" % self.calculations["Ws"], file=file)
        print("   WTOT:         %.2f s" % self.calculations["WTOT"], file=file)
        print("   Nq:           %.2f s" % self.calculations["Nq"], file=file)
        print("   Ns:           %.2f s" % self.calculations["Ns"], file=file)
        print("   NTOT:         %.2f s" % self.calculations["NTOT"], file=file)
        print(file=file)


# ######################################################################################################################


# ----------------------------------------------------------------------------------------------------------------------
if __name__ == "__main__":
    model = QueueingSystemModel_MG1(100, 10, 100, 11, offered_load=0.5, f_clk=1)
    model.print()
