import cPickle
import numpy
import pandas
import sys
import numpy

CITIES_NEIGHBORS_FILE = '/home/chefele/kaggle/Santa/data/santa_cities_nndists.pkl'

def get_neighbors():
    print "Loading nearest neighbor distances from:", CITIES_NEIGHBORS_FILE,"...",
    sys.stdout.flush()
    fin = open(CITIES_NEIGHBORS_FILE, 'rb')
    neighbors = cPickle.load(fin)
    fin.close()
    print "Done."
    sys.stdout.flush()
    return neighbors # list of dataframes, one per city

nbrs = get_neighbors()

all_dists = 0
for nbr in nbrs:
    dists = numpy.array(nbr['dist'])
    all_dists += dists/dists[0]

all_dists /= all_dists[0]

print all_dists

for n, dist in enumerate(all_dists):
    print n+1, dist

