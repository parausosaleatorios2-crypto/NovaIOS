"""Marca como `static` as funcoes auxiliares de cada fx_*.metal.

Os efeitos traduzidos repetem nomes de funcoes auxiliares (fbm, dist, escala...)
e, linkados numa metallib so, isso da 'duplicated symbols'. Com `static` cada
uma fica local ao seu arquivo. Funcoes fragment/kernel/vertex ficam como estao.
Uso: python3 -I Tools/static_helpers.py Shaders
"""
import re, sys, pathlib

SKIP = re.compile(r'^(fragment|kernel|vertex|static|inline|struct|constant|using|typedef|'
                  r'template|return|if|else|for|while|namespace|enum|class|union|const)\b')
DECL = re.compile(r'^([A-Za-z_][\w:<>,]*(?:\s*[\*&])?\s+)+([A-Za-z_]\w*)\s*\(')

def fix(text):
    out, n = [], 0
    for line in text.split('\n'):
        if line and not line[0].isspace() and not SKIP.match(line) and DECL.match(line) \
           and '=' not in line.split('(')[0]:
            line = 'static ' + line; n += 1
        out.append(line)
    return '\n'.join(out), n

total = 0
for p in sorted(pathlib.Path(sys.argv[1]).glob('fx_*.metal')):
    s = p.read_text(encoding='utf-8')
    t, n = fix(s)
    if n:
        p.write_text(t, encoding='utf-8', newline='\n'); total += n
print('funcoes marcadas static:', total)
