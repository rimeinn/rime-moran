#!/usr/bin/env python3

# 本項目詞庫自提交至 rime/rime-essay 後，承衆高手校對糾錯。本腳本自動
# 從 rime-essay 拉取修改到項目詞庫中。

import pandas as pd
from rime_dict import base_dict, latest_essay

import opencc

CC = opencc.OpenCC('t2s.json')
def normalize(s):
    return CC.convert(s)

print('Reading dicts...')
BASE = base_dict()
ESSAY = latest_essay()
ESSAY_WORDS = set(ESSAY['text'])

print('Normalizing...')
BASE['text_norm'] = BASE['text'].apply(normalize)
ESSAY['text_norm'] = ESSAY['text'].apply(normalize)

def should_change(row):
    return row['text_x'] != row['text_y'] and row['text_x'] not in ESSAY_WORDS and '纔' not in row['text_y']

print('Computing differences...')
X = pd.merge(BASE, ESSAY, on='text_norm', how='left').dropna()

changes = X[X.apply(should_change, axis=1)]
change_map = dict(zip(changes['text_x'], changes['text_y']))

new_base = BASE.copy()
new_base.loc[new_base['text'].isin(change_map.keys()), 'text'] = \
    new_base.loc[new_base['text'].isin(change_map.keys()), 'text'].map(change_map)

print('Writing...')
with open('../moran.base.dict.yaml', 'w') as f:
    for _, row in new_base.iterrows():
        if not row['is_entry']:
            f.write(f"{row['line']}\n")
        else:
            f.write(f"{row['text']}\t{row['code']}\t{row['weight']}\n")
