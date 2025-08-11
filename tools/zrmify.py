#/usr/bin/env python3

# zrmify.py -- 把拼音（字符串）轉換成自然碼雙拼（字符串）
#
# Copyright (c) 2023  ksqsf
# License: MIT License

'''
把拼音（字符串）轉換成自然碼雙拼（字符串）。
'''

def zrmify(pinyin: str) -> str:
    '''將空白分隔的拼音序列轉換爲等價的自然碼雙拼，結果以空格分隔。'''
    pinyins = pinyin.split()
    try:
        return ' '.join(map(zrmify1, pinyins))
    except:
        raise ValueError('Cannot zrmify pinyin %s' % pinyin)

def zrmify1(pinyin: str) -> str:
    '''將一個有效的拼音序列轉換爲等價的自然碼雙拼。'''
    assert len(pinyin) > 0
    if pinyin[0] in 'aeiou':
        return 零聲母轉換(pinyin)
    elif pinyin == 'n':
        return 'en'
    elif len(pinyin) > 2 and pinyin[:2] in ['zh', 'ch', 'sh']:
        聲 = 聲母轉換(pinyin[:2])
        韻 = 韻母轉換(pinyin[2:])
        return 聲 + 韻
    else:
        聲 = 聲母轉換(pinyin[:1])
        韻 = 韻母轉換(pinyin[1:])
        return 聲 + 韻

def 零聲母轉換(pinyin: str) -> str:
    if len(pinyin) == 2:
        return pinyin
    elif len(pinyin) == 1:
        return pinyin * 2
    else:
        match pinyin:
            case 'ang': return 'ah'
            case 'eng': return 'eg'
            case _: raise ValueError('無效零聲母拼音序列: ' + pinyin)

def 聲母轉換(pinyin: str) -> str:
    match pinyin:
        case 'zh': return 'v'
        case 'ch': return 'i'
        case 'sh': return 'u'
        case _:
            if pinyin in 'bpmfdtnlgkhjqxrzcsyw':
                return pinyin
            else:
                raise ValueError('無效拼音聲母序列: ' + pinyin)

映射表 = {
    'a': 'a', 'o': 'o', 'e': 'e', 'i': 'i', 'u': 'u', 'v': 'v',
    'ai': 'l', 'ei': 'z', 'ui': 'v', 'ao': 'k', 'ou': 'b', 'iu': 'q',
    'ie': 'x', 've': 't', 'ue': 't', 'an': 'j', 'en': 'f', 'in': 'n',
    'un': 'p',
    'ang': 'h', 'eng': 'g', 'ing': 'y', 'ong': 's',
    'ia': 'w', 'iao': 'c', 'ian': 'm', 'iang': 'd', 'iong': 's',
    'ua': 'w', 'uo': 'o', 'uai': 'y', 'uan': 'r', 'van': 'r', 'uang': 'd'
}

def 韻母轉換(pinyin: str) -> str:
    global 映射表
    if pinyin in 映射表:
        return 映射表[pinyin]
    else:
        raise ValueError('無效拼音韻母序列: ' + pinyin)


################################################################################
from collections import defaultdict
可接i介音聲母 = {'b','p','m','f','d','t','n','l','j','q','x','y'}
反向映射表 = defaultdict(list)

for (k, v) in 映射表.items():
    反向映射表[v].append(k)
反向映射表['o'] = ['uo'] # only lo, bo, po, mo, fo

def unzrmify1(sp: str):
    '''將一個自然碼雙拼轉換回拼音'''
    if sp == 'ah': return 'ang'
    if sp == 'eg': return 'eng'
    if sp == 'ls': return 'long'
    if sp == 'nv': return 'nv'
    if sp == 'lv': return 'lv'
    if sp in ['aa', 'ee', 'oo']: return sp[0]
    if sp[0] in 'aoe': return sp
    if sp[1] == 's' and sp[0] in 'dltyn': return sp[0] + 'ong'
    if sp[1] == 'o' and sp[0] in 'bpmfwy': return sp[0] + 'o'
    if sp[1] == 'v' and sp[0] in 'dt': return sp[0] + 'ui'
    if sp[1] == 't' and sp[0] in 'nl': return sp[0] + 've'

    聲 = {'v':'zh', 'u':'sh', 'i': 'ch'}.get(sp[0], sp[0])
    可能的韻 = 反向映射表[sp[1]]

    if len(可能的韻) == 1:
        res = 聲 + 可能的韻[0]
    else:
        if 可能的韻[0][0] in 'iv':
            i韻 = 可能的韻[0]
            非i韻 = 可能的韻[1]
        else:
            i韻 = 可能的韻[1]
            非i韻 = 可能的韻[0]
        if 聲 in 可接i介音聲母:
            res = 聲 + i韻
        else:
            res = 聲 + 非i韻

    if len(res) > 2:
        if res[1] == 'v' and res[0] in 'dtnljqxy':
            return res[0] + 'u' + res[2:]
    return res


def unzrmify(sps: str):
    return ' '.join(unzrmify1(sp) for sp in sps.split())


################################################################################

ALL_PINYIN = ["a", "ai", "an", "ang", "ao", "ba", "bai", "ban", "bang", "bao", "bei", "ben", "beng", "bi", "bian", "biao", "bie", "bin", "bing", "bo", "bu", "ca", "cai", "can", "cang", "cao", "ce", "cen", "ceng", "cha", "chai", "chan", "chang", "chao", "che", "chen", "cheng", "chi", "chong", "chou", "chu", "chuai", "chuan", "chuang", "chui", "chun", "chuo", "ci", "cong", "cou", "cu", "cuan", "cui", "cun", "cuo", "da", "dai", "dan", "dang", "dao", "de", "deng", "di", "dian", "diao", "die", "ding", "diu", "dong", "dou", "du", "duan", "dui", "dun", "duo", "e", "ei", "en", "er", "fa", "fan", "fang", "fei", "fen", "feng", "fo", "fou", "fu", "ga", "gai", "gan", "gang", "gao", "ge", "gei", "gen", "geng", "gong", "gou", "gu", "gua", "guai", "guan", "guang", "gui", "gun", "guo", "ha", "hai", "han", "hang", "hao", "he", "hei", "hen", "heng", "hong", "hou", "hu", "hua", "huai", "huan", "huang", "hui", "hun", "huo", "ji", "jia", "jian", "jiang", "jiao", "jie", "jin", "jing", "jiong", "jiu", "ju", "juan", "jue", "jun", "ka", "kai", "kan", "kang", "kao", "ke", "ken", "keng", "kong", "kou", "ku", "kua", "kuai", "kuan", "kuang", "kui", "kun", "kuo", "la", "lai", "lan", "lang", "lao", "le", "lei", "leng", "li", "lia", "lian", "liang", "liao", "lie", "lin", "ling", "liu", "long", "lou", "lu", "luan", "lun", "luo", "lv", "lve", "ma", "mai", "man", "mang", "mao", "me", "mei", "men", "meng", "mi", "mian", "miao", "mie", "min", "ming", "miu", "mo", "mou", "mu", "na", "nai", "nan", "nang", "nao", "ne", "nei", "nen", "neng", "ni", "nian", "niang", "niao", "nie", "nin", "ning", "niu", "nong", "nou", "nu", "nuan", "nuo", "nv", "nve", "o", "ou", "pa", "pai", "pan", "pang", "pao", "pei", "pen", "peng", "pi", "pian", "piao", "pie", "pin", "ping", "po", "pou", "pu", "qi", "qia", "qian", "qiang", "qiao", "qie", "qin", "qing", "qiong", "qiu", "qu", "quan", "que", "qun", "ran", "ran", "rang", "rao", "re", "ren", "reng", "ri", "rong", "rou", "ru", "ruan", "rui", "run", "ruo", "sa", "sai", "san", "sang", "sao", "se", "sen", "seng", "sha", "shai", "shan", "shang", "shao", "she", "shen", "sheng", "shi", "shou", "shu", "shua", "shuai", "shuan", "shuang", "shui", "shun", "shuo", "si", "song", "sou", "su", "suan", "sui", "sun", "suo", "ta", "tai", "tan", "tang", "tao", "te", "teng", "ti", "tian", "tiao", "tie", "ting", "tong", "tou", "tu", "tuan", "tui", "tun", "tuo", "wa", "wai", "wan", "wang", "wei", "wen", "weng", "wo", "wu", "xi", "xia", "xian", "xiang", "xiao", "xie", "xin", "xing", "xiong", "xiu", "xu", "xuan", "xue", "xun", "ya", "yan", "yang", "yao", "ye", "yi", "yin", "ying", "yo", "yong", "you", "yu", "yuan", "yue", "yun", "za", "zai", "zan", "zang", "zao", "ze", "zei", "zen", "zeng", "zha", "zhai", "zhan", "zhang", "zhao", "zhe", "zhen", "zheng", "zhi", "zhong", "zhou", "zhu", "zhua", "zhuai", "zhuan", "zhuang", "zhui", "zhun", "zhuo", "zi", "zong", "zou", "zu", "zuan", "zui", "zun", "zuo"]

ALL_ZRMSP = [zrmify1(py) for py in ALL_PINYIN]

def _test_roundtrip():
    for py in ALL_PINYIN:
        sp = zrmify1(py)
        pyr = unzrmify1(sp)
        if pyr != py:
            print(f'Error: {py=}, {sp=}, {pyr=}')

################################################################################

def main():
    import sys
    for line in sys.stdin:
        parts = line.strip().split('\t')
        if len(parts) >= 2:
            parts[1] = zrmify(parts[1])
        print('\t'.join(parts))

if __name__ == '__main__':
    main()
