"""Gera o struct EngineUniforms de Shaders/NovaEngineUniforms.h a partir de
Sources/NovaEngine/EngineUniforms.swift.

O struct vai para o shader byte a byte (setFragmentBytes), entao a ORDEM e os
TIPOS dos campos tem de ser identicos nos dois lados. Antes isto era mantido a
mao e divergiu (o Swift comecava pelas matrizes, o header estava em ordem
alfabetica): todo efeito lia lixo em acTime, acScreenSize, acPass... e saia preto.

Uso:
    python3 -I Tools/gerar_uniforms_h.py          # regrava o header
    python3 -I Tools/gerar_uniforms_h.py --check  # so confere (CI); sai 1 se divergir
"""
import pathlib
import re
import sys

RAIZ = pathlib.Path(__file__).resolve().parent.parent
SWIFT = RAIZ / 'Sources/NovaEngine/EngineUniforms.swift'
HEADER = RAIZ / 'Shaders/NovaEngineUniforms.h'

TIPOS = [
    (re.compile(r'matrix_identity_float4x4|simd_float4x4|float4x4'), 'float4x4', 64, 16),
    (re.compile(r'SIMD4<Float>'), 'float4', 16, 16),
    (re.compile(r'SIMD3<Float>'), 'float3', 16, 16),
    (re.compile(r'SIMD2<Float>'), 'float2', 8, 8),
    (re.compile(r'\bInt32\b'), 'int', 4, 4),
    (re.compile(r'\bFloat\b'), 'float', 4, 4),
]


def campos_do_swift():
    texto = SWIFT.read_text(encoding='utf-8')
    corpo = texto[texto.index('public struct EngineUniforms'):]
    corpo = corpo[:corpo.index('public init()')]
    campos = []
    for linha in corpo.splitlines():
        m = re.match(r'\s*public var (\w+)\s*(?::\s*([^=]+?))?\s*=\s*(.+)$', linha)
        if not m:
            continue
        nome, anot, valor = m.group(1), (m.group(2) or ''), m.group(3)
        fonte = anot or valor
        for rx, msl, tam, al in TIPOS:
            if rx.search(fonte):
                campos.append((nome, msl, tam, al))
                break
        else:
            raise SystemExit('tipo desconhecido para %s: %r' % (nome, fonte))
    return campos


def gerar_struct(campos):
    linhas = ['// GERADO por Tools/gerar_uniforms_h.py a partir de EngineUniforms.swift.',
              '// NAO edite a mao: a ordem tem de ser a mesma do Swift (vai byte a byte).',
              'struct EngineUniforms {']
    off = 0
    for nome, msl, tam, al in campos:
        off = (off + al - 1) // al * al
        linhas.append('    %-9s %s;   // +%d' % (msl, nome, off))
        off += tam
    linhas.append('};')
    tamanho = (off + 15) // 16 * 16
    linhas.append('// tamanho: %d bytes' % tamanho)
    return '\n'.join(linhas), tamanho


def main():
    campos = campos_do_swift()
    header = HEADER.read_text(encoding='utf-8')
    m = re.search(r'(// GERADO por Tools/gerar_uniforms_h\.py.*?\n)?struct EngineUniforms \{.*?\};\n(// tamanho: \d+ bytes\n)?',
                  header, re.S)
    if not m:
        raise SystemExit('struct EngineUniforms nao encontrado no header')
    antigos = set(re.findall(r'^\s*\w+\s+(ac\w+);', m.group(0), re.M))
    novos = {n for n, *_ in campos}
    faltando = sorted(antigos - novos)
    if faltando:
        raise SystemExit('o Swift nao tem campos que os shaders usam: %s' % ', '.join(faltando))
    struct, tamanho = gerar_struct(campos)
    novo = header[:m.start()] + struct + '\n' + header[m.end():]
    if '--check' in sys.argv:
        if novo != header:
            print('NovaEngineUniforms.h diverge de EngineUniforms.swift; rode Tools/gerar_uniforms_h.py')
            sys.exit(1)
        print('EngineUniforms ok (%d campos, %d bytes)' % (len(campos), tamanho))
        return
    HEADER.write_text(novo, encoding='utf-8', newline='\n')
    print('EngineUniforms gerado: %d campos, %d bytes' % (len(campos), tamanho))


if __name__ == '__main__':
    main()
