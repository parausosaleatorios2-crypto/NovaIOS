# Traduz a classe MotorDoOf (smali do APK) para C, metodo a metodo, instrucao a instrucao.
# Os registradores viram R r[N] (union int32/float/int64/double/ponteiro); objetos Java
# viram ponteiros e as chamadas para fora da classe viram funcoes J_<Classe>_<metodo> do runtime.
import re, sys, os
PREF = os.environ.get('PREF', 'mo_')
SEMTHIS = os.environ.get('SEMTHIS') == '1'

PKG = 'Lcom/novaeditor/model/opticalflares/'
PULAR = {'<clinit>', '<init>', 'POOL_delegate$lambda$0', 'POOL_delegate$lambda$0$0', 'c()', 'pintar',
         'pintar$lambda$0$0', 'access$getMAX_LINHAS$cp', 'access$setMAX_LINHAS$cp', 'access$getPOOL$delegate$cp',
         'access$irisRender', 'access$circuloRender', 'novaLinha', 'quadro$default'}

def simples(cls):
    c = cls.strip()
    if c.startswith('['): return 'ARR'
    c = c[1:-1] if c.startswith('L') and c.endswith(';') else c
    return c.split('/')[-1].replace('$', '_')

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

def ler_metodos(arq):
    L = open(arq, encoding='utf-8').read().split('\n')
    # so a classe principal (antes da primeira .class interna)
    fim = next((i for i, l in enumerate(L) if i > 5 and l.startswith('.class ')), len(L))
    L = L[:fim]
    ms = []; i = 0
    while i < len(L):
        if L[i].startswith('.method'):
            j = i
            while not L[j].startswith('.end method'): j += 1
            ms.append(L[i:j + 1]); i = j
        i += 1
    return ms

def cabecalho(l):
    m = re.match(r'\.method (.*?)([\w$<>]+)\((.*?)\)(.*)$', l)
    return m.groups()

def nome_metodo(nome, desc, sobrecarga):
    base = nome.replace('$', '_').replace('<', '').replace('>', '')
    if nome in sobrecarga:
        base += '__' + re.sub(r'[^A-Za-z0-9]', '', desc.replace('[', 'A').replace('/', '_'))
    return PREF + base

def traduzir(linhas, sobrecarga):
    mods, nome, pdesc, ret = cabecalho(linhas[0])
    est = 'static' in mods.split()
    pt = tipos(pdesc)
    nreg = int(re.search(r'\.registers (\d+)', '\n'.join(linhas)).group(1))
    ins = (0 if est else 1) + sum(2 if largo(t) else 1 for t in pt)
    base = nreg - ins
    params = []; init = []; k = base
    if not est:
        if SEMTHIS: init.append('r[%d].o = NULL;' % k)
        else: params.append('M *this_'); init.append('r[%d].o = this_;' % k)
        k += 1
    for n, t in enumerate(pt):
        params.append('%s a%d' % (ctipo(t), n)); init.append('r[%d].%s = a%d;' % (k, campo(t), n))
        k += 2 if largo(t) else 1
    cn = nome_metodo(nome, pdesc, sobrecarga)
    rt = ctipo(ret)
    proto = '%s %s(%s)' % (rt, cn, ', '.join(params) or 'void')
    out = [proto + ' {', '    R r[%d]; R _res; memset(r, 0, sizeof r); _res.j = 0;' % (nreg + 1)] + ['    ' + x for x in init]
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
    # tabelas de switch
    tabs = {}
    i = 0
    while i < len(linhas):
        s = linhas[i].strip()
        if s.startswith(':') and i + 1 < len(linhas) and linhas[i + 1].strip().startswith('.packed-switch'):
            b = int(linhas[i + 1].strip().split()[1], 16)
            alvos = []; j = i + 2
            while not linhas[j].strip().startswith('.end packed-switch'):
                alvos.append(lab(linhas[j].strip())); j += 1
            tabs[lab(s)] = (b, alvos)
            i = j
        i += 1
    BIN = {'add': '+', 'sub': '-', 'mul': '*', 'div': '/', 'rem': '%', 'and': '&', 'or': '|', 'xor': '^',
           'shl': '<<', 'shr': '>>', 'ushr': '>>>'}
    pular_ate_fim_tabela = False
    em_anot = False
    for l in linhas[1:]:
        s = l.strip()
        if s.startswith('.annotation'): em_anot = True; continue
        if s.startswith('.end annotation'): em_anot = False; continue
        if em_anot: continue
        if s.startswith('.packed-switch'): pular_ate_fim_tabela = True; continue
        if s.startswith('.end packed-switch'): pular_ate_fim_tabela = False; continue
        if pular_ate_fim_tabela: continue
        if not s.startswith('const-string'): s = re.sub(r'\s+#.*$', '', s)
        if not s or s.startswith('.') or s.startswith('#'): continue
        if s.startswith(':'):
            out.append('%s: ;' % lab(s)); continue
        op, _, rest = s.partition(' ')
        a = [x.strip() for x in re.split(r',\s*(?![^{]*\})', rest)] if rest else []
        o = None
        def F(t):
            return {'int': 'i', 'float': 'f', 'long': 'j', 'double': 'd'}[t]
        if op in ('move', 'move/from16', 'move/16'): o = 'r[%d].i = r[%d].i;' % (reg(a[0]), reg(a[1]))
        elif op.startswith('move-wide'): o = 'r[%d].j = r[%d].j;' % (reg(a[0]), reg(a[1]))
        elif op.startswith('move-object'): o = 'r[%d].o = r[%d].o;' % (reg(a[0]), reg(a[1]))
        elif op.startswith('move-result'):
            o = ('r[%d].%s = _res.%s;' % (reg(a[0]), resc, resc)) if resc else '/* TODO move-result */'
        elif op.startswith('const-wide'):
            o = 'r[%d].j = (int64_t)%sLL;' % (reg(a[0]), a[1].rstrip('L'))
        elif op == 'const-string':
            o = 'r[%d].o = (void *)%s;' % (reg(a[0]), rest.split(',', 1)[1].strip())
        elif op.startswith('const'):
            o = 'r[%d].i = (int32_t)%s;' % (reg(a[0]), a[1] if not a[1].startswith('-0x') else '-(int64_t)' + a[1][1:])
        elif op.startswith('sget') or op.startswith('sput'):
            cls, fld = a[1].split('->')
            fld = fld.split(':')[0]
            if cls.endswith('/K;'): o = 'r[%d].f = K_%s;' % (reg(a[0]), fld)
            elif fld == 'INSTANCE' or fld == 'Companion': o = 'r[%d].o = NULL;' % reg(a[0])
            elif op.startswith('sget'): o = 'r[%d].%s = S_%s_%s;' % (reg(a[0]), campo(a[1].split(':')[1]), simples(cls), fld.replace('$', '_'))
            else: o = 'S_%s_%s = r[%d].%s;' % (simples(cls), fld.replace('$', '_'), reg(a[0]), campo(a[1].split(':')[1]))
        elif op.startswith('iget') or op.startswith('iput'):
            cls, fld = a[2].split('->')
            fn, ft = fld.split(':')
            acc = '((C_%s *)r[%d].o)->%s' % (simples(cls), reg(a[1]), fn.replace('$', '_'))
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
            else: o = 'if (r[%d].i %s r[%d].i) goto %s;' % (reg(a[0]), cmp[c], reg(a[1]), lab(a[2]))
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
            f = F(op[4:]); o = 'r[%d].%s = -r[%d].%s;' % (reg(a[0]), f, reg(a[1]), f)
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
            ct = {'[F': 'float', '[I': 'int32_t', '[B': 'int8_t', '[D': 'double', '[J': 'int64_t'}.get(a[2], 'void *')
            o = 'r[%d].o = ARENA(%s, r[%d].i);' % (reg(a[0]), ct, reg(a[1]))
        elif op.startswith('filled-new-array'):
            mm = re.match(r'[\w/-]+ \{(.*?)\}, (.*)$', s)
            rs = regs(mm.group(1))
            o = '{ int32_t *_t = ARENA(int32_t, %d); %s _res.o = _t; }' % (len(rs), ' '.join('_t[%d] = r[%d].i;' % (n, x) for n, x in enumerate(rs)))
            resc = 'o'
        elif op == 'array-length': o = 'r[%d].i = LEN(r[%d].o);' % (reg(a[0]), reg(a[1]))
        elif op.startswith('aget') or op.startswith('aput'):
            kind = op.split('-')[1] if '-' in op else ''
            t = {'': ('int32_t', 'i'), 'wide': ('int64_t', 'j'), 'object': ('void *', 'o'), 'boolean': ('int8_t', 'i'),
                 'byte': ('int8_t', 'i'), 'char': ('uint16_t', 'i'), 'short': ('int16_t', 'i')}[kind]
            arr = '((%s*)r[%d].o)[r[%d].i]' % (t[0], reg(a[1]), reg(a[2]))
            o = ('r[%d].%s = %s;' % (reg(a[0]), t[1], arr)) if op.startswith('aget') else ('%s = r[%d].%s;' % (arr, reg(a[0]), t[1]))
        elif op == 'packed-switch':
            b, alvos = tabs[lab(a[1])]
            o = 'switch (r[%d].i) { %s }' % (reg(a[0]), ' '.join('case %d: goto %s;' % (b + n, t) for n, t in enumerate(alvos)))
        elif op.startswith('invoke'):
            mm = re.match(r'(invoke-[\w/]+) \{(.*?)\}, (L[^;]+;|\[[^-]+)->([\w$<>]+)\((.*?)\)(.*)$', s)
            iop, rl, cls, met, desc, rret = mm.groups()
            rs = regs(rl)
            if met == 'getClass': resc = None; continue
            pts = tipos(desc)
            args = []; idx = 0
            st = 'static' in iop
            if not st: recv = rs[0]; idx = 1
            for t in pts:
                args.append('r[%d].%s' % (rs[idx], campo(t))); idx += 2 if largo(t) else 1
            sc = simples(cls)
            if met == '<init>':
                o = 'INIT_%s(r[%d].o%s);' % (sc, recv, ''.join(', ' + x for x in args)); resc = None
            else:
                if SEMTHIS and sc == 'MatematicaDoOf':
                    fn = nome_metodo(met, desc, sobrecarga); alls = args
                elif cls == PKG + 'MotorDoOf;':
                    fn = nome_metodo(met, desc, sobrecarga)
                    alls = (['r[%d].o' % recv] if not st else []) + args
                elif sc == 'MatematicaDoOf':
                    fn = 'MDO_' + met; alls = args
                elif sc == 'MotorDoOf_Companion':
                    fn = 'J_Companion_' + met; alls = args
                else:
                    fn = 'J_%s_%s' % (sc, met.replace('$', '_').replace('<', '').replace('>', ''))
                    if sc == 'MotorDoOf_S' and met == 'i': fn += '1' if len(pts) == 1 else '2'
                    if sc == 'ParamsOf' and met == 'f': fn += '1' if len(pts) == 1 else '2'
                    if sc == 'Math': fn += '_' + ''.join(pts)
                    if sc == 'Arrays': fn += '_' + re.sub(r'[^A-Za-z]', '', pts[0])
                    alls = (['r[%d].o' % recv] if not st else []) + args
                call = '%s(%s)' % (fn, ', '.join(alls))
                if rret == 'V': o = call + ';'; resc = None
                else:
                    resc = campo(rret) if rret in PRIM else 'o'
                    o = '_res.%s = %s;' % (resc, call)
        elif op == 'new-instance':
            o = 'r[%d].o = NEW_%s();' % (reg(a[0]), simples(a[1]))
        elif op in ('check-cast', 'nop', 'monitor-enter', 'monitor-exit'):
            continue
        else:
            o = '/* TODO %s */' % s
        mm2 = re.match(r'^r\[(\d+)\]\.([if]) = ', o)
        if mm2: o += ' r[%s].o = 0;' % mm2.group(1)
        mm2 = re.match(r'^r\[(\d+)\]\.o = ', o)
        if mm2: o += ' r[%s].i = 0;' % mm2.group(1)
        out.append('    ' + o)
    out.append('}')
    # if-*z le o registrador de 32 bits (int, bool ou ponteiro): j_lo e o int32 baixo; para ponteiro usa .o
    txt = '\n'.join(out)
    return proto, txt

PULAR_EXTRA = set(os.environ.get('PULAR', '').split(',')) - {''}
if __name__ == '__main__':
    ms = ler_metodos(sys.argv[1])
    nomes = {}
    for m in ms:
        _, nome, desc, _ = cabecalho(m[0])
        nomes.setdefault(nome, set()).add(desc)
    sobre = {n for n, d in nomes.items() if len(d) > 1}
    protos = []; corpos = []
    for m in ms:
        _, nome, desc, _ = cabecalho(m[0])
        if nome in PULAR_EXTRA: continue
        if nome in PULAR or (nome + '()') in PULAR and desc == '': continue
        if nome == 'c' and desc == '': continue
        p, t = traduzir(m, sobre)
        protos.append(p + ';'); corpos.append(t)
    open(sys.argv[2], 'w', encoding='utf-8', newline='\n').write(
        '/* Gerado de MotorDoOf.smali (APK NovaEditor 0.918.0) por ofsmali.py - nao editar a mao. */\n'
        '#include "of_runtime.h"\n\n' + '\n\n'.join(corpos) + '\n')
    open(sys.argv[3], 'w', encoding='utf-8', newline='\n').write('\n'.join(protos) + '\n')
    print(len(corpos), 'metodos')
