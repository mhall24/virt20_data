/* Generate 10,000 random substreams from the Mersenne Twister 19937.
 * These are 2^50, or ~ 1 quadrillion (10^15) apart.
 *
 * This code came from http://www.howardklein.net/?p=157.
 */

#include <iostream>
#include <sstream>
#include <fstream>
#include <boost/random/mersenne_twister.hpp>
#include <math.h>
#include <vector>

using namespace std;

int main(int argc, char** argv)
{
    unsigned long long substream_sz = pow(2, 50);
    int nstreams = 10000;
    const char * outfilename = "mt19937_states.dat";

    boost::random::mt19937 rng;
    ofstream fout(outfilename, ios::out | ios::binary);

    for (int i = 0; i < nstreams; ++i)
    {
        cout << "Stream " << i << endl;
        rng.discard(substream_sz);
        std::stringstream input;
        input << rng;

        std::vector<unsigned> state;
        unsigned p;
        while (input >> p)
        {
            state.push_back(p);
        }
        fout.write(reinterpret_cast<const char *>(&state[0]),
            state.size() * sizeof(unsigned));
    }
}
