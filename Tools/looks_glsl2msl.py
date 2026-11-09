"""Converte os shaders do motor do Looks (Resources/mblooks/*.frag, GLSL ES 3.0
do app Android) para Metal.

Cada `<nome>.frag` (com `meia.glsl` e `comum.glsl` na frente, como o Android
monta) vira `Shaders/looks_<nome>.metal`:

    struct looks_<nome>_U { <uniforms nao-textura, na ordem> };
    struct __ctx_looks_<nome> {
        <texturas>; float4 gl_FragCoord; <uniforms como membros>;
        <funcoes do comum/meia/frag como metodos>
        float4 principal() { <main> }
    };
    fragment float4 looks_<nome>(float4 fc [[position]],
                                 constant looks_<nome>_U& U [[buffer(0)]],
                                 texture2d<float> uEntrada [[texture(0)]], ...)

e `Resources/mblooks/uniformes.json` guarda, por shader, a ordem e o tipo dos
uniforms e das texturas (o Swift empacota o buffer com o alinhamento do MSL).

Uso: python -I Tools/looks_glsl2msl.py
"""
import json
import pathlib
import re

RAIZ = pathlib.Path(__file__).resolve().parent.parent
PASTA = RAIZ / 'Resources' / 'mblooks'
SAIDA = RAIZ / 'Shaders'

TIPOS = {
    'float': 'float', 'vec2': 'float2', 'vec3': 'float3', 'vec4': 'float4',
    'int': 'int', 'ivec2': 'int2', 'ivec3': 'int3', 'ivec4': 'int4',
    'uint': 'uint', 'uvec2': 'uint2', 'uvec3': 'uint3', 'bool': 'bool',
    'mat3': 'float3x3', 'mat4': 'float4x4',
}
UNIF = re.compile(r'^\s*uniform\s+(?:(?:highp|mediump|lowp)\s+)?(\w+)\s+(\w+)\s*;.*$', re.M)


def fechar(s, i, a='(', b=')'):
    d = 0
    for j in range(i, len(s)):
        if s[j] == a:
            d += 1
        elif s[j] == b:
            d -= 1
            if d == 0:
                return j
    raise ValueError('parentese sem par')


def args(s):
    """Divide 'a, f(b, c), d' nos argumentos de nivel superior."""
    out, d, cur = [], 0, ''
    for ch in s:
        if ch in '([':
            d += 1
        elif ch in ')]':
            d -= 1
        if ch == ',' and d == 0:
            out.append(cur.strip())
            cur = ''
        else:
            cur += ch
    if cur.strip():
        out.append(cur.strip())
    return out


def trocar_chamada(src, nome, f):
    """Troca toda chamada nome(...) por f(lista de argumentos)."""
    out, i = '', 0
    pat = re.compile(r'\b' + nome + r'\s*\(')
    while True:
        m = pat.search(src, i)
        if not m:
            return out + src[i:]
        a = m.end() - 1
        z = fechar(src, a)
        out += src[i:m.start()] + f(args(src[a + 1:z]))
        i = z + 1


def converter(nome):
    meia = (PASTA / 'meia.glsl').read_text(encoding='utf-8')
    comum = (PASTA / 'comum.glsl').read_text(encoding='utf-8')
    frag = (PASTA / (nome + '.frag')).read_text(encoding='utf-8')
    src = meia + '\n' + comum + '\n' + frag

    # comentarios fora (os // tem acentos; nao importam para o compilador)
    src = re.sub(r'/\*.*?\*/', '', src, flags=re.S)
    src = re.sub(r'//[^\n]*', '', src)
    src = re.sub(r'^\s*precision\s+[^;]*;\s*$', '', src, flags=re.M)
    src = re.sub(r'^\s*#version[^\n]*$', '', src, flags=re.M)
    src = re.sub(r'^\s*out\s+vec4\s+fragColor\s*;\s*$', '', src, flags=re.M)

    texturas, uniforms = [], []
    vistos = set()
    for tipo, n in UNIF.findall(src):
        if n in vistos:
            continue
        vistos.add(n)
        if tipo in ('sampler2D', 'sampler3D'):
            texturas.append((n, '3d' if tipo == 'sampler3D' else '2d'))
        else:
            uniforms.append((n, tipo))
    src = UNIF.sub('', src)
    tex3d = {n for n, d in texturas if d == '3d'}

    # texelFetch(t, p, 0) -> t.read(uint2(p))  /  3D: uint3
    def tf(a):
        t, p = a[0], a[1]
        if t in tex3d:
            return '%s.read(uint3(%s))' % (t, p)
        return '%s.read(uint2(%s))' % (t, p)
    src = trocar_chamada(src, 'texelFetch', tf)
    src = re.sub(r'textureSize\(\s*(\w+)\s*,\s*0\s*\)\.x', r'int(\1.get_width())', src)
    src = re.sub(r'textureSize\(\s*(\w+)\s*,\s*0\s*\)\.y', r'int(\1.get_height())', src)
    src = trocar_chamada(src, 'floatBitsToUint', lambda a: 'as_type<uint>(%s)' % a[0])
    src = trocar_chamada(src, 'uintBitsToFloat', lambda a: 'as_type<float>(%s)' % a[0])
    src = trocar_chamada(src, 'roundEven', lambda a: 'rint(%s)' % a[0])
    src = trocar_chamada(src, 'lessThan', lambda a: '((%s) < (%s))' % (a[0], a[1]))
    src = trocar_chamada(src, 'lessThanEqual', lambda a: '((%s) <= (%s))' % (a[0], a[1]))
    src = trocar_chamada(src, 'greaterThan', lambda a: '((%s) > (%s))' % (a[0], a[1]))
    src = trocar_chamada(src, 'greaterThanEqual', lambda a: '((%s) >= (%s))' % (a[0], a[1]))
    src = trocar_chamada(src, 'inversesqrt', lambda a: 'rsqrt(%s)' % a[0])
    # mod do GLSL (x - y*floor(x/y)) difere do fmod com negativos
    src = trocar_chamada(src, 'mod', lambda a: '((%s) - (%s) * floor((%s) / (%s)))' % (a[0], a[1], a[0], a[1]))

    # parametros de funcao do tipo sampler
    src = re.sub(r'(?:highp\s+|mediump\s+|lowp\s+)?sampler2D\s+(\w+)', r'texture2d<float> \1', src)
    src = re.sub(r'(?:highp\s+|mediump\s+|lowp\s+)?sampler3D\s+(\w+)', r'texture3d<float> \1', src)
    # parametros out/inout
    src = re.sub(r'\binout\s+(\w+)\s+(\w+)', r'thread \1& \2', src)
    src = re.sub(r'(?<=[(,])\s*out\s+(\w+)\s+(\w+)', r' thread \1& \2', src)
    # tipos
    for g, m in sorted(TIPOS.items(), key=lambda kv: -len(kv[0])):
        src = re.sub(r'\b' + g + r'\b', m, src)
    src = re.sub(r'\b(?:highp|mediump|lowp)\s+', '', src)

    # constantes globais -> constant (ficam fora do struct)
    consts = []
    def const_global(m):
        consts.append('constant ' + m.group(1) + ';')
        return ''
    src = re.sub(r'^const\s+([^;]+);', const_global, src, flags=re.M)

    # main -> principal, fragColor local
    src = re.sub(r'\bvoid\s+main\s*\(\s*\)', 'float4 principal()', src)
    i = src.index('float4 principal()')
    a = src.index('{', i)
    z = fechar(src, a, '{', '}')
    corpo = src[a + 1:z]
    corpo = re.sub(r'\breturn\s*;', 'return fragColor;', corpo)
    corpo = '\n        float4 fragColor = float4(0.0);' + corpo + '    return fragColor;\n    '
    src = src[:a + 1] + corpo + src[z:]

    # as funcoes viram metodos: tira "static"
    src = re.sub(r'\bstatic\s+', '', src)

    fn = 'looks_' + nome
    membros = []
    for n, d in texturas:
        membros.append('    texture%s<float> %s;' % (d, n))
    membros.append('    float4 gl_FragCoord;')
    for n, t in uniforms:
        membros.append('    %s %s;' % (TIPOS.get(t, t), n))

    campos = []
    for n, t in uniforms:
        mt = 'int' if t == 'bool' else TIPOS.get(t, t)
        campos.append('    %s %s;' % (mt, n))
    if not campos:
        campos.append('    int __vazio;')

    params = ['    float4 fc [[position]]', '    constant %s_U& U [[buffer(0)]]' % fn]
    for k, (n, d) in enumerate(texturas):
        params.append('    texture%s<float> %s [[texture(%d)]]' % (d, n, k))
    inits = [n for n, _ in texturas] + ['fc']
    for n, t in uniforms:
        inits.append('(U.%s != 0)' % n if t == 'bool' else 'U.%s' % n)

    corpo_struct = '\n'.join('    ' + l if l.strip() else '' for l in src.strip('\n').split('\n'))
    msl = ('// Gerado por Tools/looks_glsl2msl.py a partir de Resources/mblooks/%s.frag\n'
           '// (motor do Looks do app Android). NAO editar: edite o .frag e gere de novo.\n'
           '#include <metal_stdlib>\nusing namespace metal;\n\n'
           '%s\n\n'
           'struct %s_U {\n%s\n};\n\n'
           'struct __ctx_%s {\n%s\n\n%s\n};\n\n'
           'fragment float4 %s(\n%s)\n{\n    __ctx_%s __c{%s};\n    return __c.principal();\n}\n') % (
        nome, '\n'.join(consts), fn, '\n'.join(campos), fn, '\n'.join(membros), corpo_struct,
        fn, ',\n'.join(params), fn, ', '.join(inits))
    (SAIDA / (fn + '.metal')).write_text(msl, encoding='utf-8', newline='\n')
    return {
        'texturas': [n for n, _ in texturas],
        'uniforms': [[n, 'bool' if t == 'bool' else TIPOS.get(t, t)] for n, t in uniforms],
    }


def main():
    esquema = {}
    for f in sorted(PASTA.glob('*.frag')):
        esquema[f.stem] = converter(f.stem)
    (PASTA / 'uniformes.json').write_text(json.dumps(esquema, indent=1, ensure_ascii=False) + '\n',
                                          encoding='utf-8', newline='\n')
    print('convertidos:', len(esquema))


if __name__ == '__main__':
    main()
