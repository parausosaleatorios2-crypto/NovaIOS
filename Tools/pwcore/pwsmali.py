# Traduz o pacote com.novaeditor.model.ccparticleworld (smali do APK NovaEditor 0.918.0) para C:
# todas as classes, metodo a metodo, instrucao a instrucao (como Tools/ofcore/ofsmali.py fez com o
# Optical Flares). Registradores viram R r[N] (union int32/float, union int64/double, ponteiro);
# objetos do pacote viram structs C_<Classe>; o que e de fora (java.*, kotlin) vira J_* em
# Sources/PWCore/pw_runtime.c.
#
# uso: python pwsmali.py <pasta com os .smali> <saida .c> <saida .h>
import re, sys, os, glob

PKG = 'Lcom/novaeditor/model/ccparticleworld/'
PULAR_CLASSES = {'ParametrosDoPw', 'ParametrosDoPw_Param', 'ParametrosDoPw_Tipo', 'ParametrosDoPw_WhenMappings'}

def simples(cls):
    c = cls.strip()
    if c.startswith('['): return 'ARR'
    c = c[1:-1] if c.startswith('L') and c.endswith(';') else c
    return c.split('/')[-1].replace('$', '_')

def do_pacote(cls): return cls.startswith(PKG)

def tipos(desc):
    out = []; i = 0
    while i < len(desc):
        ch = desc[i]
        if ch == 'L':
            j = desc.index(';', i); out.append(desc[i:j + 1]); i = j + 1
        elif ch == '[':
            j = i
            while desc[j] == '[': j += 1
            if desc[j] == 'L': k = desc.index(';', j); out.append(desc[i:k + 1]); i = k + 1
            else: out.append(desc[i:j + 1]); i = j + 1
        else: out.append(ch); i += 1
    return out

PRIM = {'F': 'float', 'I': 'int32_t', 'Z': 'int32_t', 'J': 'int64_t', 'D': 'double', 'V': 'void',
        'B': 'int32_t', 'C': 'int32_t', 'S': 'int32_t'}
def ctipo(t): return PRIM.get(t, 'void *')
def campo(t): return {'F': 'f', 'I': 'i', 'Z': 'i', 'B': 'i', 'C': 'i', 'S': 'i', 'J': 'j', 'D': 'd'}.get(t, 'o')
def largo(t): return t in ('J', 'D')

def mangle(desc):
    s = []
    for t in tipos(desc):
        if t.startswith('L'): s.append(simples(t))
        elif t.startswith('['): s.append('A' + (simples(t.lstrip('[')) if 'L' in t else t.lstrip('[')))
        else: s.append(t)
    return '_'.join(s)

def fnome(cls_simples, met, desc):
    m = met.replace('$', '_').replace('<', '').replace('>', '')
    return 'pw_%s_%s__%s' % (cls_simples, m, mangle(desc))

# ---------------- leitura das classes ----------------

class Classe:
    def __init__(s, nome): s.nome = nome; s.campos = []; s.estaticos = []; s.metodos = []

def ler(arq):
    L = open(arq, encoding='utf-8').read().split('\n')
    cs = []; c = None; i = 0
    while i < len(L):
        l = L[i]
        if l.startswith('.class '):
            c = Classe(simples(l.split()[-1])); cs.append(c)
        elif l.startswith('.field ') and c:
            m = re.match(r'\.field (.*?)([\w$]+):(\S+)(?: = (.*))?$', l)
            mods, nome, t, v = m.groups()
            (c.estaticos if 'static' in mods.split() else c.campos).append((nome, t, v))
        elif l.startswith('.method') and c:
            j = i
            while not L[j].startswith('.end method'): j += 1
            c.metodos.append(L[i:j + 1]); i = j
        i += 1
    return cs

def cabecalho(l):
    m = re.match(r'\.method (.*?)([\w$<>]+)\((.*?)\)(.*)$', l)
    return m.groups()

def literal(t, v):
    v = v.strip()
    if t in ('F', 'D'):
        v = v.rstrip('fFdD')
        if v in ('Infinity', '-Infinity', 'NaN'): return {'Infinity': 'INFINITY', '-Infinity': '-INFINITY', 'NaN': 'NAN'}[v]
        return v
    if t == 'J': return v.rstrip('L') + 'LL'
    if t == 'Z': return '1' if v == 'true' else '0'
    return v.rstrip('tsL')

# ---------------- traducao de um metodo ----------------

def traduzir(cls, linhas):
    mods, nome, pdesc, ret = cabecalho(linhas[0])
    est = 'static' in mods.split()
    pt = tipos(pdesc)
    corpo = '\n'.join(linhas)
    mreg = re.search(r'\.registers (\d+)', corpo)
    if not mreg: return None, None          # abstrato/interface
    nreg = int(mreg.group(1))
    ins = (0 if est else 1) + sum(2 if largo(t) else 1 for t in pt)
    base = nreg - ins
    params = []; init = []; k = base
    if not est:
        params.append('void *this_'); init.append('r[%d].o = this_;' % k); k += 1
    for n, t in enumerate(pt):
        params.append('%s a%d' % (ctipo(t), n)); init.append('r[%d].%s = a%d;' % (k, campo(t), n))
        k += 2 if largo(t) else 1
    cn = fnome(cls, nome, pdesc)
    proto = '%s %s(%s)' % (ctipo(ret), cn, ', '.join(params) or 'void')
    out = [proto + ' {', '    R r[%d]; R _res; memset(r, 0, sizeof r); _res.j = 0; _res.o = 0;' % (nreg + 1)] + ['    ' + x for x in init]
    resc = None

    def reg(x):
        x = x.strip()
        return base + int(x[1:]) if x.startswith('p') else int(x[1:])
    def regs(lista):
        lista = lista.strip()
        if not lista: return []
        if '..' in lista:
            a, b = [reg(y) for y in lista.split('..')]
            return list(range(a, b + 1))
        return [reg(y) for y in lista.split(',')]
    def lab(x): return 'L_' + x.strip()[1:].replace('-', '_')

    # tabelas: packed-switch, sparse-switch e array-data
    tabs = {}; esparsas = {}; dados = {}
    i = 0
    while i < len(linhas):
        s = linhas[i].strip()
        if s.startswith(':') and i + 1 < len(linhas):
            prox = linhas[i + 1].strip()
            if prox.startswith('.packed-switch'):
                b = int(prox.split()[1], 16)
                alvos = []; j = i + 2
                while not linhas[j].strip().startswith('.end packed-switch'):
                    alvos.append(lab(linhas[j].strip())); j += 1
                tabs[lab(s)] = (b, alvos); i = j
            elif prox.startswith('.sparse-switch'):
                pares = []; j = i + 2
                while not linhas[j].strip().startswith('.end sparse-switch'):
                    a_, b_ = linhas[j].strip().split('->')
                    pares.append((int(a_.strip(), 16), lab(b_.strip()))); j += 1
                esparsas[lab(s)] = pares; i = j
            elif prox.startswith('.array-data'):
                larg = int(prox.split()[1]); vals = []; j = i + 2
                while not linhas[j].strip().startswith('.end array-data'):
                    v = re.sub(r'\s*#.*$', '', linhas[j].strip()).rstrip('tsL')
                    if v: vals.append(int(v, 0) & ((1 << (8 * larg)) - 1))
                    j += 1
                by = b''.join(x.to_bytes(larg, 'little') for x in vals)
                dados[lab(s)] = by; i = j
        i += 1

    BIN = {'add': '+', 'sub': '-', 'mul': '*', 'div': '/', 'rem': '%', 'and': '&', 'or': '|', 'xor': '^',
           'shl': '<<', 'shr': '>>', 'ushr': '>>>'}
    pular = False; em_anot = False
    for l in linhas[1:]:
        s = l.strip()
        if s.startswith('.annotation'): em_anot = True; continue
        if s.startswith('.end annotation'): em_anot = False; continue
        if em_anot: continue
        if s.startswith(('.packed-switch', '.sparse-switch', '.array-data')): pular = True; continue
        if s.startswith(('.end packed-switch', '.end sparse-switch', '.end array-data')): pular = False; continue
        if pular: continue
        if not s.startswith('const-string'): s = re.sub(r'\s+#.*$', '', s)
        if not s or s.startswith('.') or s.startswith('#'): continue
        if s.startswith(':'):
            out.append('%s: ;' % lab(s)); continue
        op, _, rest = s.partition(' ')
        a = [x.strip() for x in re.split(r',\s*(?![^{]*\})', rest)] if rest else []
        o = None
        def F(t): return {'int': 'i', 'float': 'f', 'long': 'j', 'double': 'd'}[t]
        if op in ('move', 'move/from16', 'move/16'): o = 'r[%d].i = r[%d].i;' % (reg(a[0]), reg(a[1]))
        elif op.startswith('move-wide'): o = 'r[%d].j = r[%d].j;' % (reg(a[0]), reg(a[1]))
        elif op.startswith('move-object'): o = 'r[%d].o = r[%d].o;' % (reg(a[0]), reg(a[1]))
        elif op.startswith('move-result'):
            o = ('r[%d].%s = _res.%s;' % (reg(a[0]), resc, resc)) if resc else 'pw_falha("move-result sem chamada");'
        elif op == 'move-exception': o = 'r[%d].o = NULL;' % reg(a[0])
        elif op.startswith('const-wide'):
            v = a[1].rstrip('L')
            o = 'r[%d].j = (int64_t)%s;' % (reg(a[0]), ('-(int64_t)' + v[1:] + 'ULL') if v.startswith('-') else (v + 'ULL'))
        elif op.startswith('const-string'):
            o = 'r[%d].o = (void *)%s;' % (reg(a[0]), rest.split(',', 1)[1].strip())
        elif op.startswith('const'):
            v = a[1]
            o = 'r[%d].i = (int32_t)%s;' % (reg(a[0]), ('-(int64_t)' + v[1:]) if v.startswith('-') else ('(uint32_t)' + v))
        elif op.startswith('sget') or op.startswith('sput'):
            cl, fld = a[1].split('->')
            fn, ft = fld.split(':')
            nomef = 'S_%s_%s' % (simples(cl), fn.replace('$', '_'))
            if fn in ('INSTANCE', 'Companion') and do_pacote(cl): o = 'r[%d].o = NULL;' % reg(a[0])
            elif op.startswith('sget'): o = 'r[%d].%s = %s;' % (reg(a[0]), campo(ft), nomef)
            else: o = '%s = r[%d].%s;' % (nomef, reg(a[0]), campo(ft))
        elif op.startswith('iget') or op.startswith('iput'):
            cl, fld = a[2].split('->')
            fn, ft = fld.split(':')
            acc = '((C_%s *)PWOBJ(r[%d].o))->%s' % (simples(cl), reg(a[1]), fn.replace('$', '_'))
            f = campo(ft)
            o = ('r[%d].%s = %s;' % (reg(a[0]), f, acc)) if op.startswith('iget') else ('%s = r[%d].%s;' % (acc, reg(a[0]), f))
        elif op.startswith('return'):
            if op == 'return-void': o = 'return;'
            else: o = 'return r[%d].%s;' % (reg(a[0]), campo(ret) if ret in PRIM else 'o')
        elif op.startswith('goto'): o = 'goto %s;' % lab(a[0])
        elif op.startswith('if-'):
            cmp = {'eq': '==', 'ne': '!=', 'lt': '<', 'ge': '>=', 'gt': '>', 'le': '<='}
            c = op[3:5]
            if op.endswith('z'): o = 'if (ZV(r[%d]) %s 0) goto %s;' % (reg(a[0]), cmp[c], lab(a[1]))
            else: o = 'if (RV(r[%d]) %s RV(r[%d])) goto %s;' % (reg(a[0]), cmp[c], reg(a[1]), lab(a[2]))
        elif op in ('cmpl-float', 'cmpg-float', 'cmpl-double', 'cmpg-double'):
            nan = '-1' if op.startswith('cmpl') else '1'
            f = 'f' if 'float' in op else 'd'
            x, y = reg(a[1]), reg(a[2])
            o = 'r[{d}].i = (r[{x}].{f} > r[{y}].{f}) ? 1 : (r[{x}].{f} == r[{y}].{f}) ? 0 : (r[{x}].{f} < r[{y}].{f}) ? -1 : {n};'.format(d=reg(a[0]), x=x, y=y, f=f, n=nan)
        elif op == 'cmp-long':
            x, y = reg(a[1]), reg(a[2])
            o = 'r[%d].i = (r[%d].j > r[%d].j) ? 1 : (r[%d].j == r[%d].j) ? 0 : -1;' % (reg(a[0]), x, y, x, y)
        elif op.startswith('rsub-int'):
            o = 'r[%d].i = (int32_t)((uint32_t)(int32_t)%s - (uint32_t)r[%d].i);' % (reg(a[0]), a[2], reg(a[1]))
        elif re.match(r'(add|sub|mul|div|rem|and|or|xor|shl|shr|ushr)-(int|float|long|double)(/2addr|/lit8|/lit16)?$', op):
            bop, ty, var = re.match(r'(\w+)-(int|float|long|double)(/2addr|/lit8|/lit16)?$', op).groups()
            f = F(ty)
            if var == '/2addr': d, x, y = reg(a[0]), 'r[%d].%s' % (reg(a[0]), f), 'r[%d].%s' % (reg(a[1]), f)
            elif var: d, x, y = reg(a[0]), 'r[%d].%s' % (reg(a[1]), f), '(int32_t)%s' % (a[2] if not a[2].startswith('-0x') else '-' + a[2][1:])
            else: d, x, y = reg(a[0]), 'r[%d].%s' % (reg(a[1]), f), 'r[%d].%s' % (reg(a[2]), f)
            w = '64' if ty == 'long' else '32'
            if bop in ('shl', 'shr', 'ushr'):
                y = '((%s) & %d)' % (y.replace('.j', '.i'), 63 if ty == 'long' else 31)
                if bop == 'ushr': expr = '(int%s_t)((uint%s_t)%s >> %s)' % (w, w, x, y)
                elif bop == 'shl': expr = '(int%s_t)((uint%s_t)%s << %s)' % (w, w, x, y)
                else: expr = '%s >> %s' % (x, y)
            elif bop == 'rem' and ty in ('float', 'double'): expr = '%s(%s, %s)' % ('fmodf' if ty == 'float' else 'fmod', x, y)
            elif bop in ('add', 'sub', 'mul') and ty in ('int', 'long'):
                expr = '(int%s_t)((uint%s_t)%s %s (uint%s_t)%s)' % (w, w, x, BIN[bop], w, y)
            elif bop in ('div', 'rem') and ty in ('int', 'long'):
                expr = 'J%s%s(%s, %s)' % ('DIV' if bop == 'div' else 'REM', w, x, y)
            else: expr = '%s %s %s' % (x, BIN[bop], y)
            o = 'r[%d].%s = %s;' % (d, f, expr)
        elif re.match(r'neg-(int|float|long|double)$', op):
            f = F(op[4:])
            if f in ('i', 'j'): o = 'r[%d].%s = (int%s_t)(0u - (uint%s_t)r[%d].%s);' % (reg(a[0]), f, '32' if f == 'i' else '64', '32' if f == 'i' else '64', reg(a[1]), f)
            else: o = 'r[%d].%s = -r[%d].%s;' % (reg(a[0]), f, reg(a[1]), f)
        elif op == 'not-int': o = 'r[%d].i = ~r[%d].i;' % (reg(a[0]), reg(a[1]))
        elif op == 'not-long': o = 'r[%d].j = ~r[%d].j;' % (reg(a[0]), reg(a[1]))
        elif re.match(r'(int|float|long|double)-to-(int|float|long|double|byte|char|short)$', op):
            src, dst = op.split('-to-')
            if dst in ('byte', 'char', 'short'):
                o = 'r[%d].i = (%s)r[%d].i;' % (reg(a[0]), {'byte': 'int8_t', 'char': 'uint16_t', 'short': 'int16_t'}[dst], reg(a[1]))
            elif src in ('float', 'double') and dst in ('int', 'long'):
                o = 'r[%d].%s = J2%s(r[%d].%s);' % (reg(a[0]), F(dst), 'I' if dst == 'int' else 'L', reg(a[1]), F(src))
            else:
                ct = {'int': 'int32_t', 'float': 'float', 'long': 'int64_t', 'double': 'double'}[dst]
                o = 'r[%d].%s = (%s)r[%d].%s;' % (reg(a[0]), F(dst), ct, reg(a[1]), F(src))
        elif op == 'new-array':
            ct = {'[F': 'float', '[I': 'int32_t', '[B': 'int8_t', '[Z': 'int8_t', '[D': 'double', '[J': 'int64_t',
                  '[S': 'int16_t', '[C': 'uint16_t'}.get(a[2], 'void *')
            o = 'r[%d].o = ARENA(%s, r[%d].i);' % (reg(a[0]), ct, reg(a[1]))
        elif op.startswith('filled-new-array'):
            mm = re.match(r'[\w/-]+ \{(.*?)\}, (.*)$', s)
            rs = regs(mm.group(1)); t = mm.group(2)
            if t in ('[D', '[J'):
                o = '{ int64_t *_t = ARENA(int64_t, %d); %s _res.o = _t; }' % (len(rs), ' '.join('_t[%d] = r[%d].j;' % (n, x) for n, x in enumerate(rs)))
            elif t.startswith('[L') or t.startswith('[['):
                o = '{ void **_t = ARENA(void *, %d); %s _res.o = _t; }' % (len(rs), ' '.join('_t[%d] = r[%d].o;' % (n, x) for n, x in enumerate(rs)))
            else:
                o = '{ int32_t *_t = ARENA(int32_t, %d); %s _res.o = _t; }' % (len(rs), ' '.join('_t[%d] = r[%d].i;' % (n, x) for n, x in enumerate(rs)))
            resc = 'o'
        elif op == 'fill-array-data':
            by = dados[lab(a[1])]
            o = '{ static const uint8_t _d[%d] = {%s}; memcpy(r[%d].o, _d, %d); }' % (max(len(by), 1), ','.join(str(x) for x in by) or '0', reg(a[0]), len(by))
        elif op == 'array-length': o = 'r[%d].i = LEN(r[%d].o);' % (reg(a[0]), reg(a[1]))
        elif op.startswith('aget') or op.startswith('aput'):
            kind = op.split('-')[1] if '-' in op else ''
            t = {'': ('int32_t', 'i'), 'wide': ('int64_t', 'j'), 'object': ('void *', 'o'), 'boolean': ('int8_t', 'i'),
                 'byte': ('int8_t', 'i'), 'char': ('uint16_t', 'i'), 'short': ('int16_t', 'i')}[kind]
            arr = '((%s*)PWARR(r[%d].o, r[%d].i))[r[%d].i]' % (t[0], reg(a[1]), reg(a[2]), reg(a[2]))
            o = ('r[%d].%s = %s;' % (reg(a[0]), t[1], arr)) if op.startswith('aget') else ('%s = r[%d].%s;' % (arr, reg(a[0]), t[1]))
        elif op == 'packed-switch':
            b, alvos = tabs[lab(a[1])]
            o = 'switch (r[%d].i) { %s default: break; }' % (reg(a[0]), ' '.join('case %d: goto %s;' % (b + n, t) for n, t in enumerate(alvos)))
        elif op == 'sparse-switch':
            pares = esparsas[lab(a[1])]
            o = 'switch (r[%d].i) { %s default: break; }' % (reg(a[0]), ' '.join('case %d: goto %s;' % (v - (1 << 32) if v >= (1 << 31) else v, t) for v, t in pares))
        elif op.startswith('invoke'):
            mm = re.match(r'(invoke-[\w/]+) \{(.*?)\}, (L[^;]+;|\[[^-]+)->([\w$<>]+)\((.*?)\)(.*)$', s)
            iop, rl, cl, met, desc, rret = mm.groups()
            rs = regs(rl)
            if met == 'getClass' and cl == 'Ljava/lang/Object;': resc = None; continue
            pts = tipos(desc)
            args = []; idx = 0
            st = 'static' in iop
            recv = None
            if not st: recv = rs[0]; idx = 1
            for t in pts:
                args.append('r[%d].%s' % (rs[idx], campo(t))); idx += 2 if largo(t) else 1
            sc = simples(cl)
            alls = (['r[%d].o' % recv] if not st else []) + args
            if do_pacote(cl) and 'interface' not in iop:
                fn = fnome(sc, met, desc)
            else:
                fn = 'J_%s_%s__%s' % (sc, met.replace('$', '_').replace('<', '').replace('>', ''), mangle(desc))
            call = '%s(%s)' % (fn, ', '.join(alls))
            if rret == 'V' or met == '<init>': o = call + ';'; resc = None
            else:
                resc = campo(rret) if rret in PRIM else 'o'
                o = '_res.%s = %s;' % (resc, call)
        elif op == 'new-instance':
            sc = simples(a[1])
            o = ('r[%d].o = NEWOBJ(C_%s);' % (reg(a[0]), sc)) if do_pacote(a[1]) else ('r[%d].o = J_NEW_%s();' % (reg(a[0]), sc))
        elif op == 'throw': o = 'pw_falha("throw");'
        elif op in ('check-cast', 'nop', 'monitor-enter', 'monitor-exit'):
            continue
        elif op == 'instance-of':
            o = 'r[%d].i = r[%d].o != NULL;' % (reg(a[0]), reg(a[1]))
        else:
            raise SystemExit('instrucao nao traduzida em %s.%s: %s' % (cls, nome, s))
        mm2 = re.match(r'^r\[(\d+)\]\.([if]) = ', o)
        if mm2: o += ' r[%s].o = 0;' % mm2.group(1)
        mm2 = re.match(r'^r\[(\d+)\]\.o = ', o)
        if mm2: o += ' r[%s].i = 0;' % mm2.group(1)
        out.append('    ' + o)
    out.append('    return%s;' % ('' if ret == 'V' else (' (%s)0' % ctipo(ret))))
    out.append('}')
    return proto, '\n'.join(out)

if __name__ == '__main__':
    pasta, saida_c, saida_h = sys.argv[1:4]
    classes = []
    for arq in sorted(glob.glob(os.path.join(pasta, '*.smali'))):
        classes += ler(arq)
    classes = [c for c in classes if c.nome not in PULAR_CLASSES]
    # structs e estaticos
    H = ['/* Gerado do smali de com.novaeditor.model.ccparticleworld (APK NovaEditor 0.918.0) por',
         '   Tools/pwcore/pwsmali.py - nao editar a mao. */',
         '#ifndef PW_GERADO_H', '#define PW_GERADO_H', '#include "pw_runtime.h"', '']
    for c in classes:
        if c.nome in ('CameraDoPw', 'FonteDoPw'): continue   # interfaces: no runtime
        H.append('typedef struct C_%s { int32_t _vazio;%s } C_%s;' % (
            c.nome, ''.join(' %s %s;' % (ctipo(t), n.replace('$', '_')) for n, t, _ in c.campos), c.nome))
    H.append('')
    C = ['/* Gerado do smali de com.novaeditor.model.ccparticleworld por Tools/pwcore/pwsmali.py - nao editar. */',
         '#include "pw_gerado.h"', '']
    for c in classes:
        for n, t, v in c.estaticos:
            nm = 'S_%s_%s' % (c.nome, n.replace('$', '_'))
            H.append('extern %s %s;' % (ctipo(t), nm))
            C.append('%s %s = %s;' % (ctipo(t), nm, literal(t, v) if v is not None else '0'))
    H.append('')
    clinits = []
    corpos = []
    for c in classes:
        for m in c.metodos:
            _, nome, desc, _ = cabecalho(m[0])
            p, t = traduzir(c.nome, m)
            if p is None: continue
            H.append(p + ';'); corpos.append(t)
            if nome == '<clinit>': clinits.append(fnome(c.nome, nome, desc))
    H.append('static inline void pw_clinits(void) { %s }' % ' '.join(f + '();' for f in clinits))
    H.append('#endif')
    open(saida_h, 'w', encoding='utf-8', newline='\n').write('\n'.join(H) + '\n')
    open(saida_c, 'w', encoding='utf-8', newline='\n').write('\n'.join(C) + '\n\n' + '\n\n'.join(corpos) + '\n')
    print(len(corpos), 'metodos,', len(classes), 'classes,', len(clinits), 'clinits')
