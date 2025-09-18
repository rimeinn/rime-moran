#!/bin/bash

for f in data/opencc/*.txt; do
    bn="$(basename $f)"
    bn=${bn%.txt}.ocd2
    opencc_dict -i "$f" -o "../opencc/$bn" -f text -t ocd2
done
