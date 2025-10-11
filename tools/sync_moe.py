"""
sync_moe.py -- 同步上游萌百詞條

工作流程：
1. 從上游倉庫找出上一次更新版本和本次更新版本之間的新增詞條，並刪除所有長度大於 7 的詞條
2. 合併 suiginko/moetype 中校對過的讀音
3. 調用 LLM 將文字轉換成繁體
4. 調用 gen-dict 將其轉換成
"""

import requests
from collections import defaultdict
import opencc
import re
from utils import *

t2s = opencc.OpenCC('t2s.json')
s2t = opencc.OpenCC('s2t.json')

# 對應於上游 https://github.com/outloudvi/mw2fcitx/releases 的 tag 名
# 每次更新，需在此處新增一行
MOEDICT_RELEASE_DATES = [
    '20240709',
    '20250909',
    '20251009',
]

class MDict:
    def __init__(self):
        self.words = set()
        self.word2pinyin = defaultdict(list)
        super().__init__()

    def add(self, word, pinyin):
        assert isinstance(pinyin, str)
        self.words.add(word)
        self.word2pinyin[word].append(pinyin)

    def sub(self, other):
        """Remove all words from @self that appear also in @other."""
        result = MDict()
        result.words = self.words - other.words
        for w in result.words:
            result.word2pinyin[w] = self.word2pinyin[w]
        return result

    def fix_pinyin(self, standard):
        """
        Create a new MDict. All pinyins are replaced by standard.
        """
        result = MDict()
        result.words = self.words
        for w in result.words:
            result.word2pinyin[w] = standard.word2pinyin.get(w, self.word2pinyin[w])
        return result

    def save(self, path: str, mode='w'):
        with open(path, mode) as f:
            for (w, pys) in self.word2pinyin.items():
                for py in pys:
                    assert isinstance(py, str)
                    f.write(f'{w}\t{py}\n')


def parse_rime_dict(content: str) -> MDict:
    RE = re.compile(r'^([^\t]+)\t([a-z; ]+)$')
    result = MDict()
    for line in content.split('\n'):
        m = RE.findall(line)
        if not m:
            continue
        word = m[0][0]
        code = m[0][1]
        result.add(word, code)
    return result


def fetch_dict(url: str) -> MDict:
    resp = requests.get(url)
    return parse_rime_dict(resp.text)


def fetch_upstream_dict(tag: str) -> MDict:
    return fetch_dict(f'https://github.com/outloudvi/mw2fcitx/releases/download/{tag}/moegirl.dict.yaml')


def fetch_suiginko_dict() -> MDict:
    return fetch_dict('https://raw.githubusercontent.com/suiginko/moetype/refs/heads/main/no-tone_moegirl.dict.yaml')


LATEST = fetch_upstream_dict(MOEDICT_RELEASE_DATES[-1])
LAST   = fetch_upstream_dict(MOEDICT_RELEASE_DATES[-2])
DELTA  = LATEST.sub(LAST)
SUIGINKO = fetch_suiginko_dict()

DELTA = DELTA.fix_pinyin(SUIGINKO)


# for (w, pys) in DELTA.word2pinyin.items():
#     if len(w) > 7:
#         continue
#     for py in pys:
#         print(f'{w}\t{py}')

def traditionalize(d: MDict):
    ambiguous_words = []
    result = MDict()
    for w in d.words:
        pys = d.word2pinyin[w]
        has_ambiguous = False
        ambiguous_positions = []
        for i, char in enumerate(w):
            if char in ambiguous_chars:
                has_ambiguous = True
                ambiguous_positions.append({
                    'pos': i,
                    'char': char,
                    'options': ambiguous_chars[char]
                })
        if has_ambiguous:
            ambiguous_words.append({
                'original': w,
                'pinyin': pys,
                'ambiguous_positions': ambiguous_positions,
            })
        else:
            converted = s2t.convert(w)
            result.word2pinyin[converted] = pys
                
    return result, ambiguous_words


def str_ambi(ambi):
    prompt = ''
    for item in ambi:
        for py in item['pinyin']:
            prompt += f"{item['original']}\t{py}\n"
    return prompt

simple, ambi = traditionalize(DELTA)
simple.save('out_simple.txt')
print('無歧義轉換結果已寫入 out_simple.txt')

def count_tokens(text: str) -> int:
    import tiktoken
    encoder = tiktoken.get_encoding("cl100k_base")
    tokens = encoder.encode(text)
    token_count = len(tokens)
    return token_count


with open('out_ambi.txt', 'w') as f:
    f.write(str_ambi(ambi))
print(f'歧義詞語已寫入 out_ambi.txt')
