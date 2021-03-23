""" Queueing simulation common module """

import math
import statistics
import sys
from collections import defaultdict, deque
from itertools import zip_longest

import numpy as np

inf = float('inf')
nan = float('nan')


# ######################################################################################################################


# ----------------------------------------------------------------------------------------------------------------------
def ensure_pos(x):
    if x < 0: return nan
    return x


# ----------------------------------------------------------------------------------------------------------------------
def cov(X, Y):
    return np.cov(X, Y)[0, 1]


# ----------------------------------------------------------------------------------------------------------------------
def var(X):
    if len(X) <= 1:
        return np.nan
    else:
        return np.var(X, ddof=1)


# ----------------------------------------------------------------------------------------------------------------------
def mean_histogram(*histograms):
    return [statistics.mean(counts) for counts in zip_longest(*histograms, fillvalue=0)]


# ----------------------------------------------------------------------------------------------------------------------
def norm_histogram(histogram):
    total = sum(histogram)
    return [value / total for value in histogram]


# ######################################################################################################################


# ----------------------------------------------------------------------------------------------------------------------
class TimeCountSeries:
    _DATA_SERIES_CLASS = deque

    # ------------------------------------------------------------------------------------------------------------------
    def __init__(self, data_series=None, _make_copy=True):
        if _make_copy:
            self.data_series = self._get_data_series(data_series)
        else:
            self.data_series = data_series

    # ------------------------------------------------------------------------------------------------------------------
    @classmethod
    def _get_data_series(cls, data_series, _make_iter=False):
        if data_series is None:
            if _make_iter:
                return iter(())
            else:
                return cls._DATA_SERIES_CLASS()
        elif isinstance(data_series, cls):
            if _make_iter:
                return iter(data_series.data_series)
            else:
                return data_series.data_series
        else:
            if _make_iter:
                return ((a, b) for a,b in data_series)
            else:
                return cls._DATA_SERIES_CLASS((a, b) for a, b in data_series)

    # ------------------------------------------------------------------------------------------------------------------
    def append(self, t, c):
        if len(self.data_series) <= 1:
            if len(self.data_series) == 1:
                pt, pc = self.data_series[-1]
                if pt == t:
                    del self.data_series[-1]
        else:
            ppt, ppc = self.data_series[-2]
            pt, pc = self.data_series[-1]
            if pt == t or pc == ppc:
                del self.data_series[-1]
        self.data_series.append((t, c))

    # ------------------------------------------------------------------------------------------------------------------
    @staticmethod
    def _moment(iterable, moment=1, apply_func=None):
        # Check apply function.
        if apply_func is None:
            apply_func = lambda c: c

        # Get iterator over the data.
        it = iter(iterable)

        # Initialize the calculated moment result.
        result = 0.0

        # Get the first value.
        try:
            t, c = next(it)
            tfront = t
        except StopIteration:
            return result

        # Iterate over the remaining values to calculate the result.
        nt = tfront
        for nt, nc in it:
            # The result is calculated as the sum of the integrated area of each segment.
            result += apply_func(c)**moment * (nt - t)

            # Save the next t and next c into the current t and current c.
            t, c = nt, nc

        # Calculate the expected value by dividing the integrated result by the total time.
        if nt == tfront:
            return np.nan
        else:
            return result / (nt - tfront)

    # ------------------------------------------------------------------------------------------------------------------
    @staticmethod
    def _multiply(left_iterable, right_iterable):
        def get_segments(iterable):
            # Generator for getting each segment from an iterable.
            try:
                t, c = next(iterable)
            except StopIteration:
                return
            for nt, nc in iterable:
                yield t, nt, c
                t, c = nt, nc
            yield t, inf, c

        def do_multiply():
            # Do multiplication of left and right time count series.
            try:
                seg_gen_L = get_segments(iter(left_iterable))
                seg_gen_R = get_segments(iter(right_iterable))

                seg_L, seg_R = next(seg_gen_L), next(seg_gen_R)

                while True:
                    # Get segments info.
                    t1L, t2L, cL = seg_L
                    t1R, t2R, cR = seg_R

                    if t2L <= t1R:
                        # No overlap, L is earlier than R.
                        seg_L = next(seg_gen_L)
                    elif t2R <= t1L:
                        # No overlap, R is earlier than L.
                        seg_R = next(seg_gen_R)
                    else:
                        if t1L < t1R:
                            # Overlap, L is earlier than R.
                            yield t1R, cL * cR
                        elif t1R < t1L:
                            # Overlap, R is earlier than L.
                            yield t1L, cL * cR
                        else:
                            # Overlap, L and R start at the same time.
                            yield t1L, cL * cR

                        if t2L < t2R:
                            # L ends before R.
                            seg_L = next(seg_gen_L)
                        elif t2R < t2L:
                            # R ends before L.
                            seg_R = next(seg_gen_R)
                        else:
                            # L and R end at the same time.
                            seg_L = next(seg_gen_L)
                            seg_R = next(seg_gen_R)
            except StopIteration:
                return

        def do_remove_redundant(iterable):
            # Do removal of redundant segments.
            out_t, out_c = None, None
            for t, c in iterable:
                if out_c != c:
                    yield t, c
                    out_t, out_c = t, c
            if out_t is not None and out_t != t:
                yield t, c

        # Do multiplication, remove redundant segments, and return as a generator.
        return do_remove_redundant(do_multiply())

    # ------------------------------------------------------------------------------------------------------------------
    def __mul__(self, other):
        return self.__class__(self._DATA_SERIES_CLASS(self._multiply(self.data_series, self._get_data_series(other))),
                              _make_copy=False)

    # ------------------------------------------------------------------------------------------------------------------
    def moment(self, moment=1, statefunc=None):
        return self._moment(self.data_series, moment=moment, apply_func=statefunc)

    # ------------------------------------------------------------------------------------------------------------------
    def mean(self, statefunc=None):
        return self.moment(moment=1, statefunc=statefunc)

    # ------------------------------------------------------------------------------------------------------------------
    def var(self, statefunc=None):
        E1 = self.moment(moment=1, statefunc=statefunc)
        E2 = self.moment(moment=2, statefunc=statefunc)
        return E2 - E1**2

    # ------------------------------------------------------------------------------------------------------------------
    def std(self, statefunc=None):
        return math.sqrt(self.var(statefunc=statefunc))

    # ------------------------------------------------------------------------------------------------------------------
    def cov(self, other):
        other_data_iters = [self._get_data_series(other, _make_iter=True) for _ in range(2)]

        EX = self._moment(self.data_series, moment=1)
        EY = self._moment(other_data_iters[0], moment=1)
        EXY = self._moment(self._multiply(self.data_series, other_data_iters[1]), moment=1)

        # cov[X,Y] = E[(X-ux)(Y-uy)] = E[XY] - ux*uy
        return EXY - EX*EY

    # ------------------------------------------------------------------------------------------------------------------
    def histogram(self, normalize=False):
        """ Calculate the histogram of the counts.
        Returns a list where the index into the list is the count and the
        list elements are the cumulative time for each count.
        """

        # Get iterator over the data.
        it = iter(self.data_series)

        # Initialize histogram dictionary.
        histogram_dict = defaultdict(lambda: 0)

        # Get the first value.
        t, t1, c = None, None, None
        try:
            t, c = next(it)
            t1 = t
        except StopIteration:
            pass

        # Iterate over the remaining values to calculate the result.
        max_c = 0
        for nt, nc in it:
            histogram_dict[c] += nt - t
            if c > max_c:
                max_c = c

            # Save the next t and next c into the current t and current c.
            t, c = nt, nc

        # Calculate histogram as list.
        histogram = [histogram_dict[n] for n in range(max_c + 1)]

        # Normalize the histogram if necessary.
        if normalize:
            # Check for errors caused by empty data or zero time.
            if t is None:
                total = 0
            else:
                total = t - t1
            if total == 0:
                raise ValueError("Data series is empty or has zero time. Cannot normalize histogram data.")

            # Do normalization.
            histogram = [value / total for value in histogram]

        # Return the histogram result.
        return histogram


# ----------------------------------------------------------------------------------------------------------------------
class DataArray(list):
    # ------------------------------------------------------------------------------------------------------------------
    def mean(self):
        if len(self) >= 1:
            return statistics.mean(self)
        else:
            return nan

    # ------------------------------------------------------------------------------------------------------------------
    def var(self):
        if len(self) >= 2:
            return statistics.variance(self)
        else:
            return nan

    # ------------------------------------------------------------------------------------------------------------------
    def std(self):
        if len(self) >= 2:
            return statistics.stdev(self)
        else:
            return nan

    # ------------------------------------------------------------------------------------------------------------------
    def sdom(self):
        if len(self) >= 2:
            return statistics.stdev(self) / math.sqrt(len(self))
        else:
            return nan

    # ------------------------------------------------------------------------------------------------------------------
    def cdf(self):
        data_array = np.array(self)
        data_array.sort()
        probability = np.linspace(0, 1, data_array.size)
        return data_array, probability


# ----------------------------------------------------------------------------------------------------------------------
class BusyPeriodData:
    # ------------------------------------------------------------------------------------------------------------------
    def __init__(self):
        # Create stats objects.
        self.start = DataArray()
        self.duration = DataArray()
        self.num_jobs = DataArray()

    # ------------------------------------------------------------------------------------------------------------------
    def append(self, start, duration, num_jobs):
        # Create stats objects.
        self.start.append(start)
        self.duration.append(duration)
        self.num_jobs.append(num_jobs)


# ----------------------------------------------------------------------------------------------------------------------
class IdlePeriodData:
    # ------------------------------------------------------------------------------------------------------------------
    def __init__(self):
        # Create stats objects.
        self.start = DataArray()
        self.duration = DataArray()

    # ------------------------------------------------------------------------------------------------------------------
    def append(self, start, duration):
        # Create stats objects.
        self.start.append(start)
        self.duration.append(duration)


# ----------------------------------------------------------------------------------------------------------------------
class QueueStats:
    # ------------------------------------------------------------------------------------------------------------------
    def __init__(self):
        # Create stats objects.
        self.jobs_waiting = TimeCountSeries()
        self.jobs_receiving_service = TimeCountSeries()
        self.jobs_in_system = TimeCountSeries()
        self.busy_period = BusyPeriodData()
        self.idle_period = IdlePeriodData()
        self.job_wait_time = DataArray()
        self.job_service_time = DataArray()
        self.job_response_time = DataArray()
        self.total_arrivals = 0
        self.total_departures = 0
        self.total_time = 0

    # ------------------------------------------------------------------------------------------------------------------
    def P_jobs_waiting(self, cond):
        """ Calculate mean P[cond(jobs_waiting)].
        cond(jobs_waiting) should return a boolean. """
        return self.jobs_waiting.mean(statefunc=cond)

    # ------------------------------------------------------------------------------------------------------------------
    def histogram_jobs_waiting(self):
        """ Calculate histogram of the number of jobs waiting.
        Returns an array where the index into the array is the number of jobs and the
        values in the array are the cumulative time of the number of jobs waiting.
        """
        return np.array(self.jobs_waiting.histogram())

    # ------------------------------------------------------------------------------------------------------------------
    def prob_histogram_jobs_waiting(self):
        """ Calculate probability histogram of the number of jobs waiting.
        Returns an array where the index into the array is the number of jobs and the
        values in the array are the probability of the number of jobs waiting.
        """
        histogram_array = self.histogram_jobs_waiting()
        prob_histogram_array = histogram_array / np.sum(histogram_array)
        return prob_histogram_array

    # ------------------------------------------------------------------------------------------------------------------
    def P_jobs_in_system(self, cond):
        """ Calculate mean P[cond(jobs_in_system)].
        cond(jobs_in_system) should return a boolean. """
        return self.jobs_in_system.mean(statefunc=cond)

    # ------------------------------------------------------------------------------------------------------------------
    def histogram_jobs_in_system(self):
        """ Calculate histogram of the number of jobs in the system.
        Returns an array where the index into the array is the number of jobs and the
        values in the array are the cumulative time of the number of jobs in the system.
        """
        return np.array(self.jobs_in_system.histogram())

    # ------------------------------------------------------------------------------------------------------------------
    def prob_histogram_jobs_in_system(self):
        """ Calculate probability histogram of the number of jobs in the system.
        Returns an array where the index into the array is the number of jobs and the
        values in the array are the probability of the number of jobs in the system.
        """
        histogram_array = self.histogram_jobs_in_system()
        prob_histogram_array = histogram_array / np.sum(histogram_array)
        return prob_histogram_array

    # ------------------------------------------------------------------------------------------------------------------
    def mean_p0(self):
        return self.P_jobs_in_system(cond=lambda X: X == 0)

    # ------------------------------------------------------------------------------------------------------------------
    def cov_jobs_waiting_and_jobs_receiving_service(self):
        jobs_waiting_stats = self.jobs_waiting
        jobs_receiving_service_stats = self.jobs_receiving_service
        return jobs_waiting_stats.cov(jobs_receiving_service_stats)

    # ------------------------------------------------------------------------------------------------------------------
    def histogram_jobs_in_busy_period(self):
        """ Calculate histogram of the number of jobs in a busy period.
        Returns an array where the index into the array is 1-based indexed of the
        number of jobs and the values in the array are the count of the number of
        jobs in the busy period.
        """

        # Initialize histogram dictionary.
        histogram = defaultdict(lambda: 0)

        # Iterate over the values to calculate the result.
        max_n = 0
        for n in self.busy_period.num_jobs:
            histogram[n] += 1
            if n > max_n:
                max_n = n

        return [histogram[n] for n in range(1, max_n + 1)]

    # ------------------------------------------------------------------------------------------------------------------
    def prob_histogram_jobs_in_busy_period(self):
        """ Calculate probability histogram of the number of jobs in the busy period.
        Returns an array where the index into the array is 1-based indexed of the number
        of jobs and the values in the array are the probability of the number of jobs in
        the busy period.
        """
        histogram_array = self.histogram_jobs_in_busy_period()
        prob_histogram_array = histogram_array / np.sum(histogram_array)
        return prob_histogram_array

    # ------------------------------------------------------------------------------------------------------------------
    def cov_job_wait_time_and_job_service_time(self):
        job_wait_time = np.array(self.job_wait_time)
        job_service_time = np.array(self.job_service_time)
        return cov(job_wait_time, job_service_time)

    # ------------------------------------------------------------------------------------------------------------------
    def print(self, title=None, job_unit="jobs", time_unit="time unit", indent=3, step_indent=3, width=37, file=sys.stdout):
        # Helper print function.
        def print_value(name, value, extra_indent=0):
            left_part = " " * (indent + extra_indent) + name + ": "
            print("{left_part:{width}}{value}".format(left_part=left_part, value=value, width=width), file=file)

        def print_data(obj, name, unit):
            print_value("mean(%s)" % name, "%.4f %s" % (obj.mean(), unit))
            print_value("std(%s)" % name, "%.4f %s" % (obj.std(), unit))
            #print_value("var(%s)" % name, "%.4f %s**2" % (obj.var(), unit))

        # Print stats.
        if title:
            print(title, file=file)
        print_value("mean(p0)", "%.4f" % self.mean_p0())
        print_data(self.jobs_waiting, "jobs_waiting", job_unit)
        print_data(self.jobs_receiving_service, "jobs_receiving_service", job_unit)
        print_data(self.jobs_in_system, "jobs_in_system", job_unit)
        print_value("cov(jbs_waiting, jbs_recv_ser)", "%.4f %s**2" %
                    (self.cov_jobs_waiting_and_jobs_receiving_service(), job_unit))
        print_data(self.busy_period.num_jobs, "jobs_in_busy_period", job_unit)
        print_data(self.busy_period.duration, "busy_period_duration", time_unit)
        print_data(self.idle_period.duration, "idle_time", time_unit)
        print_data(self.job_wait_time, "job_wait_time", time_unit)
        print_data(self.job_service_time, "job_service_time", time_unit)
        print_data(self.job_response_time, "job_response_time", time_unit)
        print_value("cov(jb_wait_tm, jb_service_tm)", "%.4f %s**2" %
                    (self.cov_job_wait_time_and_job_service_time(), time_unit))
        print(file=file)
        print("   Probability histogram of data elements waiting in the queue:", file=file)
        for n, pn in enumerate(self.prob_histogram_jobs_waiting()):
            print_value("%3d" % n, "%.6f" % pn, extra_indent=step_indent)
        print(file=file)
        print("   Probability histogram of data elements in the system:", file=file)
        for n, pn in enumerate(self.prob_histogram_jobs_in_system()):
            print_value("%3d" % n, "%.6f" % pn, extra_indent=step_indent)
        print(file=file)


# ######################################################################################################################


# ----------------------------------------------------------------------------------------------------------------------
class QueueingSystemError(Exception): pass

