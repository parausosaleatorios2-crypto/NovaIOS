"""Marca como `static` as funcoes auxiliares de nivel superior de cada fx_*.metal.

Os efeitos traduzidos repetem nomes de funcoes auxiliares (fbm, hash, noise...)
e, linkados numa metallib so, isso da 'duplicated symbols'. Com `static` cada
uma fica local ao seu arquivo. Funcoes fragment/kernel/vertex ficam como estao.
Uso: python3 -I Tools/static_helpers.py Shaders
"""
import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from reparar_shader import split_top, code_of  # noqa: E402

SKIP = re.compile(r'(fragment|kernel|vertex|static|inline|struct|constant|using|typedef|'
                  r'template|namespace|enum|class|union|#)\b')


def fix(text):
    out, n = [], 0
    for it in split_top(text):
        code = code_of(it)
        if code.endswith('}') and '(' in code and code.index('(') < code.index('{') \
           and not SKIP.match(code) and '=' not in code[:code.index('(')]:
            k = it.index(code[:12])
            it = it[:k] + 'static ' + it[k:]
            n += 1
        out.append(it)
    return ''.join(out), n


if __name__ == '__main__':
    total = 0
    for p in sorted(pathlib.Path(sys.argv[1]).glob('fx_*.metal')):
        s = p.read_text(encoding='utf-8')
        t, n = fix(s)
        if n:
            p.write_text(t, encoding='utf-8', newline='\n')
            total += n
    print('funcoes marcadas static:', total)
