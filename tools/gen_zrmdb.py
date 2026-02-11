# gen_zrmdb.py -- 生成 zrmdb.txt

# zrmdb.txt 格式:
# 字 tab 碼1 space 碼2 space 碼3 ...

from utils import *

for (char, auxes) in aux_table.items():
    print(f'{char}\t{" ".join(auxes)}')
