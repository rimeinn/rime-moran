from collections import defaultdict
import re
import requests
import pandas as pd
from opencc import OpenCC

def read_compact_dict(filename):
    RE_COMPACT_DICT_LINE = re.compile(r"^(.+)\t([ ;a-z]+)\t(\d*)$")
    table = []
    with open(filename, 'r') as f:
        for l in f:
            l = l.rstrip()
            matches = RE_COMPACT_DICT_LINE.findall(l)
            if not matches:
                table.append(['', '', '', l, False])
            else:
                text, code, weight = matches[0]
                table.append([text, code, weight, '', True])
    df = pd.DataFrame(table,
                      columns=['text', 'code', 'weight', 'line', 'is_entry'])
    return df


def base_dict():
    return read_compact_dict('moran.base.dict.yaml')


def base_dict_freq() -> dict[str, int]:
    RE_COMPACT_DICT_LINE = re.compile(r"^(.+)\t([ ;a-z]+)\t(\d*)$")
    ret: dict[str, int] = defaultdict(int)
    with open('moran.base.dict.yaml', 'r') as f:
        for l in f:
            l = l.rstrip()
            matches = RE_COMPACT_DICT_LINE.findall(l)
            if matches:
                text, code, weight = matches[0]
                weight = int(weight)
                ret[text] += weight
    return ret


def base_dict_freq_normalized() -> dict[str, int]:
    cc = OpenCC('t2s.json')
    RE_COMPACT_DICT_LINE = re.compile(r"^(.+)\t([ ;a-z]+)\t(\d*)$")
    ret: dict[str, int] = defaultdict(int)
    with open('moran.base.dict.yaml', 'r') as f:
        for l in f:
            l = l.rstrip()
            matches = RE_COMPACT_DICT_LINE.findall(l)
            if matches:
                text, code, weight = matches[0]
                text = cc.convert(text)
                weight = int(weight)
                ret[text] += weight
    return ret


def moe_dict():
    return read_compact_dict('moran.moe.dict.yaml')


def tencent_dict():
    return read_compact_dict('moran.tencent.dict.yaml')


def read_fixed(path: str) -> pd.DataFrame:
    RE_FIXED_DICT_LINE = re.compile(r"^([^\t]+)\t([a-z]+)(.*)$")
    table = []
    with open(path, 'r') as f:
        for l in f:
            l = l.rstrip()
            matches = RE_FIXED_DICT_LINE.findall(l)
            if matches:
                text, code, *_ = matches[0]
                table.append([text, code])
    df = pd.DataFrame(table, columns=['text', 'code'])
    return df


def fixed_trad_dict() -> pd.DataFrame:
    return read_fixed('moran_fixed.dict.yaml')


def fixed_simp_dict() -> pd.DataFrame:
    return read_fixed('moran_fixed_simp.dict.yaml')


def latest_essay() -> pd.DataFrame:
    r = requests.get('https://github.com/rime/rime-essay/raw/refs/heads/master/essay.txt')
    ret = []
    for l in r.text.split('\n'):
        try:
            [text, weight] = l.split('\t')
            ret.append([text, weight])
        except:
            pass
    df = pd.DataFrame(ret, columns=['text', 'weight'])
    df = df.astype({'weight': int})
    return df


def charset():
    RE_LINE = re.compile(r"^(.*)\tt$")
    ret = set()
    with open('moran_charset.dict.yaml', 'r') as f:
        for l in f:
            l = l.rstrip()
            matches = RE_LINE.findall(l)
            if not matches:
                continue
            char = matches[0]
            ret.add(char)
    return ret
