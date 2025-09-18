from utils import *
import argparse
from tools.zrmify import zrmify

parser = argparse.ArgumentParser()
parser.add_argument('--simplified', action='store_true')
args = parser.parse_args()

if args.simplified:
    freq_table = freq_simp_table
else:
    freq_table = freq_trad_table

print(open('header.dict.yaml').read())
for ((char, py), w) in freq_table.items():
    sp = zrmify(py)
    for aux in aux_table[char]:
        print(f'{char}\t{sp};{aux}\t{w}')

