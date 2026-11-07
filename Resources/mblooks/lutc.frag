// LUT (`lutc`, recebe LINEAR e devolve LINEAR) — o render `0x1803ef770` (tools/looks/benchmark/lutc.py) em um passe:
//  1. `ExpKernel_LinTo_sRGB` (`dxil/146`), que roda NO BUFFER, num passe próprio: não é o sRGB do motor — expoente
//     1/2,4 em float, corte em x > 0,0031308 e nenhum piso em 0 (negativo sai × 12,92) —, e o buffer guarda
//     float16 truncado (`meia`) antes do passo 2;
//  2. `FilmKernel_CubeLut` (`dxil/235`, chave de log desligada): c = x·(N − 1)/N + 1/(2N), a textura 3D com filtro
//     linear e borda presa — feita à mão com `texelFetch` (a tabela é RGB32F, sem filtro na GPU do aparelho) e com o
//     peso de 8 bits de fração da GPU do AE (`peso8`; medido na rodada `lutc`: com o peso em float, 1 nível em até
//     3% dos valores) —, e saída = x + (lut − x)·s;
//  3. a volta a linear com o sRGB do motor (o `converter.frag`), truncada de novo: o buffer que a LUT entrega à
//     próxima ferramenta é linear — uma de vídeo depois dela converte outra vez (medido em 01/11/2026, rodadas `blby_l`
//     e `spex_l`: deixando o buffer em vídeo, LUT → Mojo II saía 1 nível ACIMA do AE em 11% dos valores; assim, 0,02%).
// O host (`ContasDoLooks.lut`) dá N, as duas constantes do passo 2 e s = força·0,01.
precision highp sampler3D;

uniform highp sampler3D uLut;
uniform int uN;
uniform float uEscala;
uniform float uDesloc;
uniform float uS;
out vec4 fragColor;

float linParaSrgbDaLut(float x) {
    float curva = exp2(log2(x) * uintBitsToFloat(0x3ED55555u)) * 1.055 + -0.055;
    return x > 0.0031308 ? curva : x * 12.92;
}

vec3 tabela(int r, int g, int b) { return texelFetch(uLut, ivec3(r, g, b), 0).rgb; }

vec3 amostrar(vec3 c) {
    vec3 t = c * float(uN) - 0.5;
    vec3 i0 = floor(t);
    vec3 f = vec3(peso8(t.x - i0.x), peso8(t.y - i0.y), peso8(t.z - i0.z));
    ivec3 a = clamp(ivec3(i0), ivec3(0), ivec3(uN - 1));
    ivec3 b = clamp(ivec3(i0) + 1, ivec3(0), ivec3(uN - 1));
    vec3 c00 = tabela(a.x, a.y, a.z) * (1.0 - f.x) + tabela(b.x, a.y, a.z) * f.x;
    vec3 c10 = tabela(a.x, b.y, a.z) * (1.0 - f.x) + tabela(b.x, b.y, a.z) * f.x;
    vec3 c01 = tabela(a.x, a.y, b.z) * (1.0 - f.x) + tabela(b.x, a.y, b.z) * f.x;
    vec3 c11 = tabela(a.x, b.y, b.z) * (1.0 - f.x) + tabela(b.x, b.y, b.z) * f.x;
    vec3 c0 = c00 * (1.0 - f.y) + c10 * f.y;
    vec3 c1 = c01 * (1.0 - f.y) + c11 * f.y;
    return c0 * (1.0 - f.z) + c1 * f.z;
}

void main() {
    vec4 px = texelFetch(uEntrada, pxMemoria(), 0);
    vec3 v = meia(vec3(linParaSrgbDaLut(px.r), linParaSrgbDaLut(px.g), linParaSrgbDaLut(px.b)));
    vec3 lut = amostrar(v * uEscala + uDesloc);
    fragColor = vec4(meia(srgbParaLinear(meia(v + (lut - v) * uS))), px.a);
}
