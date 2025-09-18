from collections import defaultdict, OrderedDict


def tsv_reader(path):
    with open(path, 'r') as f:
        for line in f:
            line = line.rstrip('\n')
            if not line or line.startswith('#'):
                continue
            parts = line.split('\t')
            yield parts


def get_keys(parts, key_indices):
    if isinstance(key_indices, int):
        return parts[key_indices]

    keys = list()
    for ki in key_indices:
        keys.append(parts[ki])
    keys = tuple(keys)
    return keys


def read_tsv(path, key_indices, value_index):
    """Read a TSV file into a dict."""
    res = OrderedDict()
    for parts in tsv_reader(path):
        keys = get_keys(parts, key_indices)
        value = parts[value_index]
        res[keys] = value

    return res


def read_tsv_many(path, key_indices, value_index):
    res = defaultdict(list)
    for parts in tsv_reader(path):
        keys = get_keys(parts, key_indices)
        value = parts[value_index]
        res[keys].append(value)
    return res


pinyin_table = read_tsv_many('pinyin.txt', 0, 1)
freq_trad_table = read_tsv('pinyin.txt', (0, 1), 2)
freq_simp_table = read_tsv('pinyin.txt', (0, 1), 3)
chai_table = read_tsv('moran_chai.txt', (0, 1), 2)
aux_table = read_tsv_many('moran_chai.txt', 0, 1)


# 僅考慮有讀音的字
all_chars = sorted(list(set(pinyin_table.keys())))
