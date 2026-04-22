#!/usr/bin/env python3

from mdict_utils.base.writemdict import MDictWriter
from utils import *
from zrmify import zrmify
import sys
import os


if len(sys.argv) != 2:
    print('Usage: gen_mdx.py <output path>')
    sys.exit(1)


def gen_page(char: str, sps: list[str], chais: list[tuple[str, str]]) -> str:
    html = f'''
    <link href="main.css" rel="stylesheet" type="text/css" />
    <div class="char-card">
      <span class="character">{char}</span>
      <div class="">{gen_fullcode(sps, chais)}</div>
      <div class="chai">{gen_aux(chais)}</div>
    </div>
    '''
    return html.replace('\n', '')

def gen_fullcode(sps: list[str], chais: list[tuple[str, str]]) -> str:
    result = '<span class="section-label">全碼</span>'
    for sp in sps:
        for (auxcode, _) in chais:
            result += f'<span class="fullcode-item">{sp};{auxcode}</span>'
    return result

def gen_aux(chais: list[tuple[str, str]]):
    result = ''
    for (auxcode, chai) in chais:
        result += f'<span class="chai-item"><ruby>{auxcode}<rt>{chai}</rt></ruby></span>'
    return result

mdict = {}

for char in all_chars:
    pys: list[str] = pinyin_table.get(char, [])
    sps = list(map(zrmify, pys))
    chais: list[tuple[str, str]] = [(code, chai_table.get((char, code), '.')) for code in aux_table[char]]
    mdict[char] = gen_page(char, sps, chais)

writer = MDictWriter(
    mdict,
    title = '魔然',
    description = '魔然拆字',
)
with open(sys.argv[1], 'wb') as f:
    writer.write(f)
