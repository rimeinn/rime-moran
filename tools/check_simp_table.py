import opencc
import re
import os

cc = opencc.OpenCC('t2s.json')
RE_ENTRY = re.compile(r'^([^\t]+)\t')

admitted_patterns = [
    '乾', '雨濛濛', '矇眬'
]

def special(word):
    return any(pat in word for pat in admitted_patterns)

maybe_wrong = []
warning = []

with open('../moran_fixed_simp.dict.yaml') as f:
    for l in f:
        m = RE_ENTRY.match(l)
        if not m: continue
        word = m[1]
        if len(word) == 1: continue
        s_word = cc.convert(word)
        if word != s_word:
            if special(word):
                warning.append((word, s_word))
            else:
                maybe_wrong.append((word, s_word))


for (w, sw) in maybe_wrong:
    print('[ERROR] Possibly wrong word "%s", maybe you meant "%s"?' % (w, sw))

for (w, sw) in warning:
    print('[WARNING] Possibly wrong word "%s", maybe you meant "%s"?' % (w, sw))

if maybe_wrong:
    exit(1)
