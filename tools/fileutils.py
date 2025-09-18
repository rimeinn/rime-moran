import re

def lines(path: str):
    '''
    Yields (lineNumber, line)
    '''
    with open(path, 'r') as f:
        for i, l in enumerate(f):
            l = l.rstrip('\n')
            yield i, l

def lines_split_header(path: str):
    with open(path, 'r') as f:
        for l in f:
            l = l.rstrip('\n')
            if l == '...':
                yield False, l
                break
            else:
                yield False, l
        for i, l in enumerate(f):
            l = l.rstrip('\n')
            yield True, l

RE_CHARS_DICT = r"^([^\t])+\t([a-z; ]+)\t([0-9]+)(\t.*)?$"
RE_CHARS_DICT = re.compile(RE_CHARS_DICT)

def decode_chars_line(line: str):
    m = RE_CHARS_DICT.findall(line)
    if not m: return None
    text, code, wstr, remaining = m[0]
    w = int(wstr)
    sp, aux = code.split(';')
    return (text, sp, aux, w, remaining)
