// ============================================================================================================
//  Magic Bullet Looks — o que todos os passes dividem (vem depois de `meia.glsl` e antes de cada shader de
//  fragmento desta pasta).
//
//  O motor do Looks foi lido no MBLooksUI_5_0.dll e conferido no After Effects (tools/looks/LEIAME.md):
//    - em 8 bpc todo buffer entre passes é float16 ARREDONDADO PARA ZERO (`meia`). Sem isso ~25% dos px saem
//      1 nível acima do AE; com isso, idênticos. Aqui os alvos são RGBA16F e cada passe grava `meia(...)`:
//      o valor já cabe em float16, e a GPU o guarda sem mexer;
//    - os kernels de blur e da Optical Diffusion gravam float16 com o arredondamento deles (ver `meiaPerto`);
//    - a GPU do AE filtra textura com 8 bits de fração no peso: aqui a amostragem é feita à mão (`amostra1d`,
//      `bilinear`).
//
//  Coordenadas: `pxAe()` é o pixel como o AE o numera (linha 0 = topo). O buffer de uma camada mora com o topo
//  na linha 0 (ver QuadGeometry); a cena "de pé" (camada de ajuste, grupo solto) inverte (`uDePe`).
// ============================================================================================================

uniform highp sampler2D uEntrada;
uniform ivec2 uTamanho;
uniform bool uDePe;

ivec2 pxMemoria() { return ivec2(gl_FragCoord.xy); }

ivec2 pxAe() {
    ivec2 p = ivec2(gl_FragCoord.xy);
    if (uDePe) p.y = uTamanho.y - 1 - p.y;
    return p;
}

/** O pixel (x, y) do AE em `t` (na numeração do AE). */
vec4 lerAe(highp sampler2D t, ivec2 p) {
    if (uDePe) p.y = uTamanho.y - 1 - p.y;
    return texelFetch(t, p, 0);
}

/** `CoreKernel_sRGB_to_Linear`: sRGB padrão, negativo vira 0. A forma da divisão por 1,055 dá 1 exato em 1. */
float srgbParaLinear(float v) {
    float reto = v * 0.077399380;
    float curva = exp2(log2((max(v, 0.0) + 0.055) / 1.055) * 2.4);
    return max(v < 0.04045 ? reto : curva, 0.0);
}

/** `CoreKernel_Linear_to_sRGB`. */
float linearParaSrgb(float l) {
    float reto = l * 12.92;
    float curva = exp2(log2(max(l, 0.0)) * 0.416666667) * 1.055 - 0.055;
    return max(l < 0.0031308 ? reto : curva, 0.0);
}

/**
 * O sRGB que os kernels de vinheta (Lens Vignette, Mojo) fazem por conta própria: × 0,94787 em vez de ÷ 1,055 e
 * 0,41667 em vez de 1/2,4 — não é o do motor, e a diferença aparece no 8 bits.
 */
float decodVinheta(float v) {
    float l = v < 0.04045 ? v * 0.0774 : exp2(log2((max(v, 0.0) + 0.055) * 0.94787) * 2.4);
    return max(l, 0.0);
}

float codVinheta(float o) {
    float s = o < 0.0031308 ? o * 12.92 : exp2(log2(max(o, 0.0)) * 0.41667) * 1.055 + -0.055;
    return max(s, 0.0);
}

vec3 decodVinheta(vec3 v) { return vec3(decodVinheta(v.r), decodVinheta(v.g), decodVinheta(v.b)); }
vec3 codVinheta(vec3 o) { return vec3(codVinheta(o.r), codVinheta(o.g), codVinheta(o.b)); }

vec3 srgbParaLinear(vec3 v) { return vec3(srgbParaLinear(v.x), srgbParaLinear(v.y), srgbParaLinear(v.z)); }
vec3 linearParaSrgb(vec3 v) { return vec3(linearParaSrgb(v.x), linearParaSrgb(v.y), linearParaSrgb(v.z)); }

/** O peso do filtro linear como a GPU do AE o usa: 8 bits de fração, arredondado (empate para o par). */
float peso8(float f) { return roundEven(f * 256.0) / 256.0; }

/**
 * Uma curva de 1024 entradas (linha `linha` da textura `t`), filtro linear com a coordenada presa na borda —
 * o `sampleLevel` dos kernels do Looks.
 */
vec4 amostra1d(highp sampler2D t, int linha, float u) {
    int n = textureSize(t, 0).x;
    float x = u * float(n) - 0.5;
    float i0 = floor(x);
    float f = peso8(x - i0);
    int a = clamp(int(i0), 0, n - 1);
    int b = clamp(int(i0) + 1, 0, n - 1);
    vec4 va = texelFetch(t, ivec2(a, linha), 0);
    vec4 vb = texelFetch(t, ivec2(b, linha), 0);
    return va * (1.0 - f) + vb * f;
}

/** Filtro bilinear numa posição em pixels do AE (centro do texel em +0,5), borda presa. */
vec4 bilinear(highp sampler2D t, vec2 pos) {
    vec2 q = pos - 0.5;
    vec2 i0 = floor(q);
    vec2 f = vec2(peso8(q.x - i0.x), peso8(q.y - i0.y));
    ivec2 a = clamp(ivec2(i0), ivec2(0), uTamanho - 1);
    ivec2 b = clamp(ivec2(i0) + 1, ivec2(0), uTamanho - 1);
    vec4 v00 = lerAe(t, ivec2(a.x, a.y));
    vec4 v10 = lerAe(t, ivec2(b.x, a.y));
    vec4 v01 = lerAe(t, ivec2(a.x, b.y));
    vec4 v11 = lerAe(t, ivec2(b.x, b.y));
    vec4 c0 = v00 * (1.0 - f.x) + v10 * f.x;
    vec4 c1 = v01 * (1.0 - f.x) + v11 * f.x;
    return c0 * (1.0 - f.y) + c1 * f.y;
}
