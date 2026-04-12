#!/bin/bash

echo "＊ 請確保已經更新了 sync_moe.py 中的版本歷史 ＊"

if [ "$OPENROUTER_API_KEY" = "" ]; then
    echo "＊ 請設置 OPENROUTER_API_KEY ＊"
    exit 1
fi

uv run tools/sync_moe.py
uv run tools/llm_tradify.py out_ambi.txt

cat out_ambi_batch*.out >> out_simple.txt

opencc -c tw2t.json -i out_simple.txt -o result.txt
make quick
uv run tools/schemagen.py gen-dict --compact --no-freq --input-dict result.txt  >> moran.moe.dict.yaml 

echo "＊ 請更新了 moran.moe.dict.yaml 中的版本歷史和上游版本 ＊"
