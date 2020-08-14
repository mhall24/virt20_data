""" mt19937 sub-streams module """

import os
import random
from itertools import chain

import numpy as np

# ######################################################################################################################

MT19937_STATES_FILE = os.path.join(os.path.dirname(__file__), "..", "mt19937", "mt19937_states.dat")

# ######################################################################################################################

# Load the state data file, which contains an nstreams x 624 array of unsigned ints (type np.uint32).
state_array = np.fromfile(MT19937_STATES_FILE, dtype=np.uint32)
state_array = state_array.reshape(10000, 624)
nstreams = state_array.shape[0]


# ######################################################################################################################

# ----------------------------------------------------------------------------------------------------------------------
def get_random_state_at_index(index):
    # Convert the array of np.uint32s to a list of Python ints.
    state_list = [int(x) for x in state_array[index]]

    # Append the required value of 624 to the list.
    state_list.append(624)

    # Define the required internal state tuple and use it to set the state for a new RNG instance.
    rng_state = (3, tuple(state_list), None)
    return rng_state


# ----------------------------------------------------------------------------------------------------------------------
def get_random_class_at_index(index):
    rng_state = get_random_state_at_index(index)
    rng = random.Random()
    rng.setstate(rng_state)
    return rng


# ----------------------------------------------------------------------------------------------------------------------
def generate_substream_indices(start=0, shuffle=False):
    # Determine the iteration of the indices.
    if shuffle:
        indices = list(range(nstreams))
        random.shuffle(indices)
    else:
        indices = chain(range(start, nstreams), range(start))

    # Generate sub-streams.
    for index in indices:
        yield index

# Create mt19937 substream index generator.
index_generator = generate_substream_indices()


# ######################################################################################################################
