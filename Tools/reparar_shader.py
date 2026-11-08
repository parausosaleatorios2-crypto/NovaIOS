"""Repara um fx_*.metal traduzido do GLSL que nao compila no Metal.

Em GLSL os uniforms, texturas e variaveis globais sao visiveis em todas as
funcoes; no Metal eles sao parametros da funcao fragment e variaveis globais
mutaveis sao proibidas. Aqui cada funcao de entrada vira:

    struct __ctx_NOME {
        <parametros da entrada como membros>
        <globais do efeito como membros>
        <funcoes auxiliares como metodos>
        RET __run() { <corpo original> }
    };
    fragment RET NOME(<parametros>) { __ctx_NOME __c{...}; return __c.__run(); }

Tambem troca swizzles GLSL .st/.stp/.stpq por .xy/.xyz/.xyzw.
Uso: python3 -I Tools/reparar_shader.py entrada.metal saida.metal
"""
import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import reparar_glsl_extra  # noqa: E402

ENTRY = re.compile(r'^\s*(fragment|kernel|vertex)\b')
SWZ = re.compile(r'(?<=[\w\)\]])\.([stpq]{2,4})\b')


def split_top(src):
    """Divide o arquivo em itens de nivel superior (texto, preservando comentarios)."""
    items, i, n, start, depth = [], 0, len(src), 0, 0
    at_line_start = True
    while i < n:
        c = src[i]
        if at_line_start and depth == 0 and c == '#':
            j = src.find('\n', i)
            j = n if j < 0 else j
            while src[j - 1] == '\\' and j < n:  # continuacao de macro
                k = src.find('\n', j + 1)
                j = n if k < 0 else k
            pre = src[start:i]
            if pre:
                items.append(pre)
            items.append(src[i:j + 1])
            i = start = j + 1
            at_line_start = True
            continue
        if c == '/' and i + 1 < n and src[i + 1] == '/':
            j = src.find('\n', i)
            i = n if j < 0 else j
            continue
        if c == '/' and i + 1 < n and src[i + 1] == '*':
            j = src.find('*/', i + 2)
            i = n if j < 0 else j + 2
            continue
        if c == '\n':
            at_line_start = True
            i += 1
            continue
        if not c.isspace():
            at_line_start = False
        if c in '{([':
            depth += 1
        elif c in '})]':
            depth -= 1
            if c == '}' and depth == 0:
                k = i + 1
                while k < n and src[k] in ' \t\r\n':
                    k += 1
                if k >= n or src[k] != ';':
                    items.append(src[start:i + 1])
                    start = i + 1
        elif c == ';' and depth == 0:
            items.append(src[start:i + 1])
            start = i + 1
        i += 1
    if src[start:]:
        items.append(src[start:])
    return items


def code_of(item):
    """Item sem comentarios, para classificar."""
    s = re.sub(r'/\*.*?\*/', ' ', item, flags=re.S)
    s = re.sub(r'//[^\n]*', ' ', s)
    return s.strip()


def match_close(s, i, o, c):
    d = 0
    for k in range(i, len(s)):
        if s[k] == o:
            d += 1
        elif s[k] == c:
            d -= 1
            if d == 0:
                return k
    raise ValueError('sem fechamento')


def split_params(p):
    out, d, cur = [], 0, ''
    for ch in p:
        if ch in '([<':
            d += 1
        elif ch in ')]>':
            d -= 1
        if ch == ',' and d == 0:
            out.append(cur)
            cur = ''
        else:
            cur += ch
    if cur.strip():
        out.append(cur)
    return [x.strip() for x in out]


def repair(src):
    src = src.replace('#include "NovaShaderHelpers.h"', '#include "NovaShaderHelpers.h"\n#include "NovaGLSLCompat.h"', 1)
    # qualificadores GLSL que o tradutor deixou passar
    src = re.sub(r'^[ \t]*precision\s+\w+\s+\w+\s*;[ \t]*$', '', src, flags=re.M)
    src = re.sub(r'\bvarying\s+', '', src)
    src = re.sub(r'\b(inout|out)\s+(?:const\s+)?([A-Za-z_]\w*)\s+([A-Za-z_]\w*)(?=\s*(?:\[\d*\])?\s*[,)])',
                 r'thread \2& \3', src)
    src = re.sub(r'\b(?:const\s+)?in\s+(?=[A-Za-z_]\w*\s+[A-Za-z_]\w*\s*[,)])', '', src)
    if '--basico' not in sys.argv:
        src = reparar_glsl_extra.fix(src)
    src = SWZ.sub(lambda m: '.' + m.group(1).translate(str.maketrans('stpq', 'xyzw')), src)
    items = split_top(src)
    top, body_items, out_entries = [], [], []
    for it in items:
        code = code_of(it)
        if not code:
            (body_items if out_entries or body_items else top).append(it)
            continue
        if code.startswith('#include') or code.startswith('using ') or                 (code.startswith('#') and not body_items and not out_entries):
            top.append(it)
        elif code.startswith('#'):
            # #define no meio das funcoes fica no lugar (macro e textual).
            body_items.append(it)
        elif re.match(r'struct\s+\w+Params\b', code) and not body_items:
            top.append(it)
        elif code.startswith('constant '):
            top.append(it)
        elif ENTRY.match(code):
            out_entries.append((it, list(body_items)))
        else:
            body_items.append(it)

    if not out_entries:
        return None

    result = [''.join(t if t.endswith(chr(10)) else t + chr(10) for t in top)]
    for it, helpers in out_entries:
        code = code_of(it)
        po = code.index('(')
        pc = match_close(code, po, '(', ')')
        head = code[:po]
        m = re.match(r'\s*(fragment|kernel|vertex)\s+(.+?)\s+(\w+)\s*$', head, re.S)
        if not m:
            return None
        kind, ret, name = m.groups()
        params = split_params(code[po + 1:pc])
        bo = code.index('{', pc)
        bc = match_close(code, bo, '{', '}')
        body = code[bo:bc + 1]

        members, names = [], []
        for p in params:
            decl = re.sub(r'\[\[.*?\]\]', '', p).strip()
            pn = re.findall(r'\w+', decl)[-1]
            names.append(pn)
            members.append('    ' + decl + ';')

        ctx = []
        for h in helpers:
            hc = code_of(h)
            if not hc:
                ctx.append(h)
                continue
            # prototipos: metodos da struct ja se enxergam
            if hc.endswith(';') and '(' in hc and '=' not in hc and '{' not in hc \
               and not hc.startswith('struct'):
                continue
            if hc.endswith('}') and not hc.startswith('struct'):
                h = re.sub(r'^(\s*(?:/\*.*?\*/|//[^\n]*\n|\s)*)(?:static\s+|inline\s+)+', r'\1', h, flags=re.S)
            ctx.append(h)

        for var, typ in (('__nv_fragCoord', 'float4'), ('__nv_pointCoord', 'float2')):
            decl = re.compile(chr(92) + 'b' + typ + r'\s+' + var + r'\s*=')
            if decl.search(body):
                body = decl.sub(var + ' =', body, count=1)
                members.append('    %s %s;' % (typ, var))
        rett = 'void' if kind != 'fragment' and ret.strip() == 'void' else ret
        result.append('\nstruct __ctx_%s {\n%s\n%s\n    %s __run() %s\n};\n' % (
            name, '\n'.join(members), ''.join(ctx), rett, body))
        call = '__c.__run();' if rett.strip() == 'void' else 'return __c.__run();'
        result.append('%s %s %s(%s)\n{\n    __ctx_%s __c{%s};\n    %s\n}\n' % (
            kind, ret, name, ',\n    '.join(params), name, ', '.join(names), call))
    return ''.join(result)


if __name__ == '__main__':
    s = open(sys.argv[1], encoding='utf-8').read()
    r = repair(s)
    if r is None:
        sys.exit(2)
    open(sys.argv[2], 'w', encoding='utf-8', newline='\n').write(r)
