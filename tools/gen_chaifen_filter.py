# gen_chai_filter.py -- 生成拆分濾鏡數據

from utils import *

for char in all_chars:
    tip = ''
    for aux in aux_table[char]:
        chai = chai_table.get((char, aux), '.')
        tip += f'〔{chai}{aux}〕'
    print(f'{char}\t{tip}')
