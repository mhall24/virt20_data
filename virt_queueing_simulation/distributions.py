""" Distributions module """

import math
import operator as op
import random
import re
from functools import reduce
from itertools import permutations

import utils

default_random_class = random._inst


# ######################################################################################################################


# ----------------------------------------------------------------------------------------------------------------------
def nCr(n, r):
    r = min(r, n-r)
    if r == 0: return 1
    numer = reduce(op.mul, range(n, n-r, -1))
    denom = reduce(op.mul, range(1, r+1))
    return numer//denom


# ######################################################################################################################


# ----------------------------------------------------------------------------------------------------------------------
class WeightedChoice:
    # ------------------------------------------------------------------------------------------------------------------
    def __init__(self, weights, random_class=None):
        # Setup the random class.
        if random_class is None:
            self.random_class = default_random_class
        else:
            self.random_class = random_class

        # Normalize the weights (exclude the last value as this will be the default case when a random sample is
        # tested).
        assert len(weights) >= 1
        divisor = sum(weights)
        self.norm_weights = tuple(wi/divisor for wi in weights[:-1])

    # ------------------------------------------------------------------------------------------------------------------
    def __call__(self):
        return self.choice()

    # ------------------------------------------------------------------------------------------------------------------
    def choice(self):
        # Get random sample between 0 and 1.
        sample = self.random_class.random()

        # Test sample against the normalized weights.
        for i, wi_prime in enumerate(self.norm_weights):
            if sample < wi_prime:
                return i
            sample -= wi_prime

        # Default case is the last choice.
        return len(self.norm_weights)


# ######################################################################################################################


# ----------------------------------------------------------------------------------------------------------------------
class RandomDistribution:
    # ------------------------------------------------------------------------------------------------------------------
    def __init__(self, lambd, random_class=None):
        self.lambd = lambd
        if random_class is None:
            self.random_class = default_random_class
        else:
            self.random_class = random_class

    # ------------------------------------------------------------------------------------------------------------------
    @staticmethod
    def get_distribution_as_class_and_parameters(type, lambd):
        if type == "D":
            # Deterministic
            return DiscreteDistribution, (lambd,)
        elif type == "M":
            # Exponential
            return ExponentialDistribution, (lambd,)
        elif type[:1] == "E":
            # Erlang with parameter k
            try:
                k = int(type[1:])
                if k < 1: raise ValueError
            except Exception:
                raise ValueError("type == %s" % repr(type))
            return ErlangDistribution, (lambd, k)
        elif type[:4] == "Hypo":
            # Hypoexponential with weights
            #     Expect a type string of the form:  "Hypo(w1, w2, ..., wk)"
            #     where wi is the weighted lambda for a given exponential distribution.
            try:
                if type[4] != "(" or type[-1] != ")":
                    raise ValueError
                weights = tuple(float(w_str) for w_str in type[5:-1].split(","))
            except Exception:
                raise ValueError("type == %s" % repr(type))
            return HypoexponentialDistribution, (lambd, weights)
        elif type[:5] == "Hyper":
            # Hyperexponential with lambda weights and parallel exponential distribution probabilities
            #     Expect a type string of the form:  "Hyper(WL=[], WP=[])"
            #     where WL are the weighted lambdas for each parallel exponential distribution
            #     and WP are the weighted probabilities for each parallel exponential distribution
            try:
                match = re.match(r"\(\s*WL\s*=\s*\[(.*)\]\s*,\s*WP\s*=\s*\[(.*)\]\s*\)", type[5:])
                wl_str, wp_str = match.groups()
                lambd_weights = tuple(float(s) for s in wl_str.split(","))
                prob_weights = tuple(float(s) for s in wp_str.split(","))
            except Exception:
                raise ValueError("type == %s" % repr(type))
            return HyperexponentialDistribution, (lambd, lambd_weights, prob_weights)
        else:
            raise ValueError("type == %s" % repr(type))

    # ------------------------------------------------------------------------------------------------------------------
    @classmethod
    def get_distribution(cls, type, lambd, random_class=None):
        dist_class, dist_args = cls.get_distribution_as_class_and_parameters(type, lambd)
        return dist_class(*dist_args, random_class=random_class)

    # ------------------------------------------------------------------------------------------------------------------
    def mean(self):
        raise NotImplementedError

    # ------------------------------------------------------------------------------------------------------------------
    def variance(self):
        raise NotImplementedError

    # ------------------------------------------------------------------------------------------------------------------
    def stdev(self):
        return math.sqrt(self.variance())

    # ------------------------------------------------------------------------------------------------------------------
    def cs(self):
        """ Coefficient of variation. """
        return self.stdev() / self.mean()

    # ------------------------------------------------------------------------------------------------------------------
    def moment(self, n):
        raise NotImplementedError

    # ------------------------------------------------------------------------------------------------------------------
    def random_sample(self):
        raise NotImplementedError


# ----------------------------------------------------------------------------------------------------------------------
class DiscreteDistribution(RandomDistribution):
    # ------------------------------------------------------------------------------------------------------------------
    def __init__(self, lambd, random_class=None):
        super().__init__(lambd, random_class)
        utils.assert_float_eq(self.mean(), self.moment(1))

    # ------------------------------------------------------------------------------------------------------------------
    def mean(self):
        return 1/self.lambd

    # ------------------------------------------------------------------------------------------------------------------
    def variance(self):
        return 0

    # ------------------------------------------------------------------------------------------------------------------
    def moment(self, n):
        return 1/(self.lambd**n)

    # ------------------------------------------------------------------------------------------------------------------
    def random_sample(self):
        return 1/self.lambd


# ----------------------------------------------------------------------------------------------------------------------
class ExponentialDistribution(RandomDistribution):
    # ------------------------------------------------------------------------------------------------------------------
    def __init__(self, lambd, random_class=None):
        super().__init__(lambd, random_class)
        utils.assert_float_eq(self.mean(), self.moment(1))

    # ------------------------------------------------------------------------------------------------------------------
    def mean(self):
        return 1/self.lambd

    # ------------------------------------------------------------------------------------------------------------------
    def variance(self):
        return 1/(self.lambd**2)

    # ------------------------------------------------------------------------------------------------------------------
    def moment(self, n):
        return math.factorial(n)/(self.lambd**n)

    # ------------------------------------------------------------------------------------------------------------------
    def random_sample(self):
        return self.random_class.expovariate(self.lambd)


# ----------------------------------------------------------------------------------------------------------------------
class ErlangDistribution(RandomDistribution):
    """ The Erlang distribution consists of a sum of k identical exponential distributions. """
    # ------------------------------------------------------------------------------------------------------------------
    def __init__(self, lambd, k, random_class=None):
        super().__init__(lambd, random_class)
        self.k = k

    # ------------------------------------------------------------------------------------------------------------------
    def mean(self):
        return 1/self.lambd

    # ------------------------------------------------------------------------------------------------------------------
    def variance(self):
        return 1/(self.k*self.lambd**2)

    # ------------------------------------------------------------------------------------------------------------------
    def moment(self, n):
        k = self.k
        lambd = self.lambd
        if n == 1:
            return 1/lambd
        elif n == 2:
            return (1+k)/(k*lambd**2)
        elif n == 3:
            return ((1+k)*(2+k))/(k**2*lambd**3)
        else:
            raise NotImplementedError("n == %s" % repr(n))

    # ------------------------------------------------------------------------------------------------------------------
    def random_sample(self):
        return sum(self.random_class.expovariate(self.lambd*self.k) for _ in range(self.k))


# ----------------------------------------------------------------------------------------------------------------------
class HypoexponentialDistribution(RandomDistribution):
    """ The Hypoexponential distribution is a generalization of the Erlang distribution.  It consists of a sum of k
    independent exponential distributions with separate lambdas. """

    # ------------------------------------------------------------------------------------------------------------------
    def __init__(self, lambd, weights, random_class=None):
        super().__init__(lambd, random_class)
        multiplier = sum(1 / w for w in weights)
        self.lambdas = tuple(wi * multiplier * lambd for wi in weights)

    # ------------------------------------------------------------------------------------------------------------------
    def mean(self):
        return 1/self.lambd

    # ------------------------------------------------------------------------------------------------------------------
    def variance(self):
        return sum(1/lambd_i**2 for lambd_i in self.lambdas)

    # ------------------------------------------------------------------------------------------------------------------
    def moment(self, n):
        if n == 1:
            return self.mean()
        elif n == 2:
            return self.variance() + self.mean()**2
        elif n == 3:
            # todo: verify derived formula
            L = self.lambdas
            k = len(L)
            return sum(6/L[i]**3 for i in range(k)) + \
                nCr(3, 2)*sum(2/(L[i]**2 * L[j]) for i, j in permutations(range(k), 2)) + \
                sum(1/(L[i] * L[j] * L[h]) for i, j, h in permutations(range(k), 3))
        else:
            raise NotImplementedError("n == %s" % repr(n))

    # ------------------------------------------------------------------------------------------------------------------
    def random_sample(self):
        return sum(self.random_class.expovariate(lambd_i) for lambd_i in self.lambdas)


# ----------------------------------------------------------------------------------------------------------------------
class HyperexponentialDistribution(RandomDistribution):
    """ The Hyperexponential distribution consists of k parallel independent exponential distributions. """

    # ------------------------------------------------------------------------------------------------------------------
    def __init__(self, lambd, lambd_weights, prob_weights, random_class=None):
        """
        lambd_weights are weighted lambdas for each parallel exponential distribution.
        prob_weights are weighted probabilities that a given parallel exponential distribution will be picked.
        """
        super().__init__(lambd, random_class)
        self._expo_choice = WeightedChoice(prob_weights, random_class=random_class)
        assert len(lambd_weights) == len(prob_weights)
        divisor = sum(pi for pi in prob_weights)
        self.probabilities = tuple(pi / divisor for pi in prob_weights)
        multiplier = sum(pi/wi for pi, wi in zip(self.probabilities, lambd_weights))
        self.lambdas = tuple(wi * multiplier * lambd for wi in lambd_weights)
        utils.assert_float_eq(self.mean(), self.moment(1))

    # ------------------------------------------------------------------------------------------------------------------
    def mean(self):
        return 1/self.lambd

    # ------------------------------------------------------------------------------------------------------------------
    def variance(self):
        return self.moment(2) - self.mean()**2

    # ------------------------------------------------------------------------------------------------------------------
    def moment(self, n):
        return sum(math.factorial(n)/lambd_i**n * pi for pi, lambd_i in zip(self.probabilities, self.lambdas))

    # ------------------------------------------------------------------------------------------------------------------
    def random_sample(self):
        choice = self._expo_choice()
        return self.random_class.expovariate(self.lambdas[choice])


# ######################################################################################################################


# ----------------------------------------------------------------------------------------------------------------------
if __name__ == "__main__":
    #choose = WeightedChoice([1, 5, 9, 0.1])
    #print(Counter(choose() for _ in range(10000)))

    import numpy as np

    for type in ("M", "E4", "Hyper(WL=[1, 10], WP=[1, 3.26])"):
        lambd = 1
        dist = RandomDistribution.get_distribution(type, lambd)
        print("%s with lambd = %.4f" % (type, lambd))
        print("-" * 40)
        print_blank = False
        if hasattr(dist, "probabilities"):
            print("Prob.:      %s" % ", ".join("%.4f" % p for p in dist.probabilities))
            print_blank = True
        if hasattr(dist, "lambdas"):
            print("Lambdas:    %s" % ", ".join("%.4f" % L for L in dist.lambdas))
            print_blank = True
        if print_blank:
            print()
        print("Mean:       %.4f" % dist.mean())
        print("Variance:   %.4f" % dist.variance())
        print("Stdev:      %.4f" % dist.stdev())
        print("Cs:         %.4f" % dist.cs())
        print("Moment(1):  %.4f" % dist.moment(1))
        print("Moment(2):  %.4f" % dist.moment(2))
        print("Moment(3):  %.4f" % dist.moment(3))
        print()

        X = np.array([dist.random_sample() for _ in range(10000)])
        print("E[X]:       %.4f" % np.mean(X))
        print("E[X^2]:     %.4f" % np.mean(X**2))
        print("E[X^3]:     %.4f" % np.mean(X**3))
        print("Var[X]:     %.4f" % np.var(X))
        print("Std[X]:     %.4f" % np.std(X))
        print()
        print()

