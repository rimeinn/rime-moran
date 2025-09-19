# gen_zrmdb.py -- 生成 zrmdb.txt

from utils import *

for (char, auxes) in aux_table.items():
    for aux in auxes:
        print(f'{char} {aux}')
