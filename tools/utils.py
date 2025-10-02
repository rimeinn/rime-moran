from collections import defaultdict, OrderedDict
import os
from datetime import datetime


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
        try:
            assert keys not in res
        except:
            print(f'Duplicate keys: {keys=}, {value=}')
            raise
        res[keys] = value

    return res


def read_tsv_many(path, key_indices, value_index):
    res = defaultdict(list)
    for parts in tsv_reader(path):
        keys = get_keys(parts, key_indices)
        value = parts[value_index]
        res[keys].append(value)
    return res


pinyin_table = read_tsv_many('tools/data/chars.txt', 0, 1)
freq_trad_table = read_tsv('tools/data/chars.txt', (0, 1), 2)
freq_simp_table = read_tsv('tools/data/chars.txt', (0, 1), 3)
chai_table = read_tsv('tools/data/moran_chai.txt', (0, 1), 2)
aux_table = read_tsv_many('tools/data/moran_chai.txt', 0, 1)


# 僅考慮有讀音的字
all_chars = sorted(list(set(pinyin_table.keys())))


def get_modified_date(file_path):
    """Returns the modified date of a file as a datetime object."""
    timestamp = os.path.getmtime(file_path)
    return datetime.fromtimestamp(timestamp)


def get_chars_version():
    chaidate = get_modified_date('tools/data/moran_chai.txt')
    charsdate = get_modified_date('tools/data/chars.txt')
    return max(chaidate, charsdate).strftime('%Y%m%d')


ambiguous_chars = {
    '发': ['發', '髮'],  # 發展/頭髮
    '干': ['乾', '幹', '干'],  # 乾燥/幹活/干涉
    '后': ['後', '后'],  # 後面/皇后
    '历': ['歷', '曆'],  # 歷史/日曆
    '里': ['裡', '里'],  # 裡面/公里
    '面': ['面', '麵'],  # 面對/麵條
    '复': ['復', '複'],  # 恢復/複雜
    '台': ['臺', '台', '檯'],  # 臺灣/台階/檯面
    '征': ['徵', '征'],  # 徵收/征服
    '余': ['餘', '余'],  # 剩餘/余先生
    '云': ['雲', '云'],  # 雲彩/云曰
    '准': ['準', '准'],  # 準備/准許
    '制': ['製', '制'],  # 製作/制度
    '板': ['板', '闆'],  # 木板/老闆
    '表': ['表', '錶'],  # 表格/手錶
    '丑': ['醜', '丑'],  # 醜陋/丑時
    '斗': ['鬥', '斗'],  # 戰鬥/斗量
    '谷': ['谷', '穀'],  # 山谷/穀物
    '划': ['劃', '划'],  # 計劃/划船
    '几': ['幾', '几'],  # 幾個/茶几
    '卷': ['卷', '捲'],  # 書卷/捲起
    '了': ['了', '瞭'],  # 了解/瞭望
    '么': ['麼', '么'],  # 什麼/么麼
    '朴': ['樸', '朴'],  # 樸素/朴姓
    '舍': ['舍', '捨'],  # 宿舍/捨棄
    '术': ['術', '朮'],  # 技術/白朮
    '松': ['松', '鬆'],  # 松樹/鬆弛
    '系': ['系', '係', '繫'],  # 系統/關係/繫帶
    '咸': ['咸', '鹹'],  # 咸陽/鹹味
    '向': ['向', '嚮'],  # 方向/嚮往
    '御': ['御', '禦'],  # 御用/防禦
    '愿': ['願', '愿'],  # 願望/愿愿
    '岳': ['岳', '嶽'],  # 岳父/山嶽
    '致': ['致', '緻'],  # 導致/精緻
    '钟': ['鐘', '鍾'],  # 時鐘/鍾姓
    '种': ['種', '种'],  # 種類/种地
    '周': ['周', '週'],  # 周圍/星期週
    '注': ['注', '註'],  # 注意/註解
    '签': ['簽', '籤'],  # 簽名/抽籤
    '借': ['借', '藉'],  # 借錢/憑藉
}
