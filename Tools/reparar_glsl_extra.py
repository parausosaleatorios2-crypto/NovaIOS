"""Correcoes de GLSL que o tradutor deixou passar. Usado por reparar_shader.py.

- `uniform T x;` solto no topo -> `T x;` (vira membro da struct, zerado)
- `T[N](a, b, ...)` (construtor de vetor do GLSL) -> `{a, b, ...}`
- parametro renomeado pelo tradutor para `u.algo` -> `u_algo` naquela funcao
- parametro chamado `u` (esconde os uniforms) -> `u_p` naquela funcao
"""
import re

ARRAY_CTOR = re.compile(r'=\s*(?:const\s+)?\w+\s*\[\s*\d*\s*\]\s*\(')
PARAM_U_DOT = re.compile(r'([(,]\s*(?:const\s+)?(?:thread\s+)?\w+&?\s+)u\.(\w+)(\s*[,)])')
FUNC_HEAD = re.compile(r'^[^\n;{}]*\b\w+\s*\(([^)]*)\)\s*\{', re.M)


def _array_ctors(src):
    out, i = [], 0
    while True:
        m = ARRAY_CTOR.search(src, i)
        if not m:
            out.append(src[i:])
            return ''.join(out)
        start = m.end() - 1          # posicao do '('
        depth, j = 0, start
        while j < len(src):
            if src[j] == '(':
                depth += 1
            elif src[j] == ')':
                depth -= 1
                if depth == 0:
                    break
            j += 1
        if j >= len(src):
            out.append(src[i:])
            return ''.join(out)
        out.append(src[i:m.start()] + '= {' + src[start + 1:j] + '}')
        i = j + 1


def _fix_functions(src):
    """Renomeia parametros problematicos dentro de cada funcao."""
    res, pos = [], 0
    for m in FUNC_HEAD.finditer(src):
        # acha o corpo da funcao
        b = m.end() - 1
        depth, j = 0, b
        while j < len(src):
            if src[j] == '{':
                depth += 1
            elif src[j] == '}':
                depth -= 1
                if depth == 0:
                    break
            j += 1
        if j >= len(src) or m.start() < pos:
            continue
        head, body = src[m.start():b], src[b:j + 1]
        nomes = PARAM_U_DOT.findall(head)
        if nomes:
            head = PARAM_U_DOT.sub(lambda k: k.group(1) + 'u_' + k.group(2) + k.group(3), head)
            for _, n, _ in nomes:
                body = re.sub(r'\bu\.' + n + r'\b', 'u_' + n, body)
        if re.search(r'[(,]\s*(?:const\s+)?\w+&?\s+u\s*[,)]', head):
            head = re.sub(r'([(,]\s*(?:const\s+)?\w+&?\s+)u(\s*[,)])', r'\1u_p\2', head)
            body = re.sub(r'\bu\b(?!\s*\.)', 'u_p', body)
        res.append(src[pos:m.start()] + head + body)
        pos = j + 1
    res.append(src[pos:])
    return ''.join(res)


def fix(src):
    src = re.sub(r'^(\s*)uniform\s+', r'\1', src, flags=re.M)
    src = _array_ctors(src)
    src = _fix_functions(src)
    return src
