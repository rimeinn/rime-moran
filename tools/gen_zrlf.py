# gen_zrlf.py -- 生成兩分詞庫

from utils import *
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('--simplified', action='store_true')
args = parser.parse_args()

if args.simplified:
    freq_table = freq_simp_table
else:
    freq_table = freq_trad_table

char_freq_table: dict[str, int] = {}
for (char, _py), freq in freq_table.items():
    char_freq_table[char] = max(char_freq_table.get(char, 0), int(freq))

print('# 自動生成，請勿編輯。')
print('# AUTO-GENERATED. DO NOT EDIT.')
print('''# Rime dictionary
# encoding: utf-8

# 本詞庫將原詞庫拼音轉換爲自然碼雙拼。
# 轉換過程中殘留了有歧義的碼（以 !!! 標記）

---
name: "zrlf"
version: "{}+5.0"
sort: by_weight
use_preset_vocabulary: false
columns:
  - text
  - code
  - weight
  - comment
...'''.format(get_modified_date('tools/data/zrlf.txt').strftime('%y%m%d')))

for parts in tsv_reader('tools/data/zrlf.txt'):
    word = parts[0]
    code = parts[1]
    freq = char_freq_table.get(word, 0)
    if len(parts) > 2:
        comment = parts[2]
        print(f'{word}\t{code}\t{freq}\t{comment}')
    else:
        print(f'{word}\t{code}\t{freq}')
