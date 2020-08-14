""" Utility module """

import sys
import textwrap
import time
import traceback


# ######################################################################################################################


# ----------------------------------------------------------------------------------------------------------------------
def get_formatted_time():
    """ Get formatted time string.

    Time format to use: 2016-04-08 19:37:10 CDT 1460144230
    """

    tm = time.time()
    fmt_tm = time.strftime("%Y-%m-%d %I:%M:%S %p %Z", time.localtime(tm))
    return "%s %d" % (fmt_tm, tm)


# ----------------------------------------------------------------------------------------------------------------------
def print_wrapped(text, width=70, **kwargs):
    subsequent_indent = kwargs.pop("subsequent_indent", None)
    textwrap_kwargs = {}
    if subsequent_indent:
        textwrap_kwargs["subsequent_indent"] = " " * subsequent_indent
    for line in textwrap.wrap(text, width=width, **textwrap_kwargs):
        print(line, **kwargs)


# ######################################################################################################################


# ----------------------------------------------------------------------------------------------------------------------
def is_float_eq(first, second, reltol=1e-6):
    if first == 0 and second == 0:
        return True
    return abs(first - second) / max(abs(first), abs(second)) < reltol


# ----------------------------------------------------------------------------------------------------------------------
def assert_float_eq(first, second, reltol=1e-6):
    assert is_float_eq(first, second, reltol=reltol)


# ----------------------------------------------------------------------------------------------------------------------
def guard(func, value):
    try:
        return func(value)
    except Exception:
        return value


# ######################################################################################################################


# ----------------------------------------------------------------------------------------------------------------------
class TimeIt:
    # ------------------------------------------------------------------------------------------------------------------
    def __init__(self, label="", file=sys.stdout, verbose=True):
        self.label_part = (label + " " if label else "") + "Timer: "
        self.file = file
        self.verbose = verbose

    # ------------------------------------------------------------------------------------------------------------------
    def print_formatted_line(self, text=""):
        if self.verbose:
            print("[%s] %s%s" % (get_formatted_time(), self.label_part, text), file=self.file)

    # ------------------------------------------------------------------------------------------------------------------
    def __enter__(self):
        self.print_formatted_line("Started.")
        self.start_time = time.perf_counter()
        return self

    # ------------------------------------------------------------------------------------------------------------------
    def __exit__(self, exc_type, exc_val, exc_tb):
        self.stop_time = time.perf_counter()
        self.elapsed_time = self.stop_time - self.start_time
        self.print_formatted_line("Stopped. Elapsed time is %0.4f seconds." % self.elapsed_time)


# ----------------------------------------------------------------------------------------------------------------------
class CancelFuturesOnException:
    # ------------------------------------------------------------------------------------------------------------------
    def __init__(self, futures):
        self.futures = futures

    # ------------------------------------------------------------------------------------------------------------------
    def __enter__(self):
        return self

    # ------------------------------------------------------------------------------------------------------------------
    def __exit__(self, exc_type, exc_val, exc_tb):
        # Check for exception.
        if exc_val is None:
            return

        # Print exception.
        print("Caught exception below. Canceling futures.", file=sys.stderr)
        traceback.print_exception(exc_type, exc_val, exc_tb, file=sys.stderr)

        # Cancel futures.
        for f in list(self.futures):
            f.cancel()
        print("All futures are canceled.", file=sys.stderr)


# ######################################################################################################################


# ----------------------------------------------------------------------------------------------------------------------
if __name__ == "__main__":
    pass
