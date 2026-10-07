# gen_chars.py -- 生成單字表

import argparse

from utils import *
from zrmify import zrmify

parser = argparse.ArgumentParser()
parser.add_argument('--simplified', action='store_true')
args = parser.parse_args()

if args.simplified:
    freq_table = freq_simp_table
else:
    freq_table = freq_trad_table

print('# 自動生成，請勿編輯。')
print("# AUTO-GENERATED. DO NOT EDIT.")
header = open('tools/data/chars.dict.yaml').read()
header = header.replace('YYYYmmdd', get_chars_version())
print(header)

for ((char, py), w) in freq_table.items():
    sp = zrmify(py)
    for i, aux in enumerate(aux_table[char]):
        if i == 0:
            weight = int(w)
        else:
            weight = int(w) // 4 * 3
        print(f'{char}\t{sp};{aux}\t{weight}')
