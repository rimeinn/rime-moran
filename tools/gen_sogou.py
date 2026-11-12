#!/usr/bin/env python3

import re
from collections import defaultdict

RE_ENTRY = re.compile(r"^([^\t#][^\t]*)\t([a-z]+)(?=\t|$)")


def gen_sogou(input_path, output_path):
    """
    從字詞模式碼表生成搜狗自定義短語 TXT（UTF-16，帶 BOM）.
    格式爲「編碼,候選位置=詞語」，同碼候選保留原始順序.
    """
    entries = defaultdict(list)
    with open(input_path, encoding="utf-8-sig") as input_file:
        for line in input_file:
            line = line.rstrip("\n")
            m = RE_ENTRY.findall(line)
            if not m:
                continue
            text, code = m[0]
            entries[code].append(text)
    with open(output_path, "w", encoding="utf-16", newline="\r\n") as output_file:
        for code, texts in entries.items():
            for position, text in enumerate(texts, start=1):
                output_file.write(f"{code},{position}={text}\n")


if __name__ == "__main__":
    gen_sogou("moran_fixed.dict.yaml", "魔然繁_搜狗.txt")
    gen_sogou("moran_fixed_simp.dict.yaml", "魔然简_搜狗.txt")
