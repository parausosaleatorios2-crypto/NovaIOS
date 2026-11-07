// ============================================================================================================
//  uni.Chromatic Aberration (Red Giant Universe 2) — o que todos os passes dividem (vem depois de
//  `mblooks/meia.glsl` e antes de cada shader desta pasta). A engine foi lida na Gpu_Shader_Engine_x64.dll e
//  conferida no After Effects: tools/uchromab/benchmark/LEIAME.md.
//
//  Precisão (medida na AMD do PC, que roda o Universe do AE):
//    - a cor sai do shader truncada para float16 (`meia`); até a primeira elipse os alvos da engine são RGBA8
//      (`oito`, depois de `meia`), daí em diante RGBA16F;
//    - o bilinear da GPU usa 8 bits de fração no peso (`peso8`) e a borda presa.
//  Coordenadas: `pxAe()` é o pixel da camada como a engine o vê (linha 0 = topo); a cena "de pé" inverte.
// ============================================================================================================

uniform highp sampler2D uEntrada;
uniform ivec2 uTamanho;
uniform bool uDePe;

ivec2 pxAe() {
    ivec2 p = ivec2(gl_FragCoord.xy);
    if (uDePe) p.y = uTamanho.y - 1 - p.y;
    return p;
}

/** O texel (x, y) da engine numa textura interna (do tamanho da camada), com a borda presa. */
vec4 lerAe(highp sampler2D t, ivec2 p) {
    p = clamp(p, ivec2(0), uTamanho - 1);
    if (uDePe) p.y = uTamanho.y - 1 - p.y;
    return texelFetch(t, p, 0);
}

/** O que um alvo RGBA8 da engine guarda (depois do `meia` da saída do shader). */
vec4 oito(vec4 v) { return floor(clamp(v, 0.0, 1.0) * 255.0 + 0.5) / 255.0; }

/** O peso do filtro linear da GPU: 8 bits de fração, arredondado (empate para o par). */
float peso8(float f) { return roundEven(f * 256.0) / 256.0; }

/** `mix` como a engine o usa (o compilador do PC: x + (y − x)·a). */
vec3 mistura(vec3 x, vec3 y, float a) { return x + (y - x) * a; }
vec4 mistura(vec4 x, vec4 y, float a) { return x + (y - x) * a; }

/** Filtro bilinear numa posição em pixels da engine (centro do texel em +0,5), borda presa. */
vec4 bilinear(highp sampler2D t, vec2 pos) {
    vec2 q = pos - 0.5;
    vec2 i0 = floor(q);
    vec2 f = vec2(peso8(q.x - i0.x), peso8(q.y - i0.y));
    ivec2 a = ivec2(i0);
    vec4 v00 = lerAe(t, a);
    vec4 v10 = lerAe(t, a + ivec2(1, 0));
    vec4 v01 = lerAe(t, a + ivec2(0, 1));
    vec4 v11 = lerAe(t, a + ivec2(1, 1));
    vec4 c0 = v00 * (1.0 - f.x) + v10 * f.x;
    vec4 c1 = v01 * (1.0 - f.x) + v11 * f.x;
    return c0 * (1.0 - f.y) + c1 * f.y;
}

/** Divide a cor pelo alfa (o "unpremultiply" da engine). */
vec4 despre(vec4 v) { return vec4(v.a != 0.0 ? v.rgb / v.a : v.rgb, v.a); }

/** O sin da AMD: o argumento vira voltas (× 1/2π) e só a fração entra. */
float senoAmd(float x) {
    float t = x * 0.15915494309189535;
    return sin(6.283185307179586 * fract(t));
}

/**
 * A máscara elíptica da engine (Gpu_MatteEllipseShader + fx.invertAlpha, fundidos num passe): devolve o ALFA
 * da máscara (1 − elipse), como fica no alvo RGBA16F. `a` = (cx, cy, 1/(W·raio), aspecto); `b` = (×1/f1, s,
 * ruído, expoente); `c` = (s − 1, 1/s, 1/(s − 1), —). Contas em 0x1803068a0.
 */
float mascara(vec2 uv, vec4 a, vec4 b, vec4 c) {
    vec2 centro = uv - a.xy;
    centro.x *= a.w;
    float len = 1.0 - length(centro) * a.z;
    vec2 t1 = clamp(vec2(len, len), 0.0, 1.0);
    t1 *= vec2(b.x);
    t1 = clamp(t1, 0.0, 1.0);
    t1.y -= 1.0;
    t1 *= vec2(c.y, c.z);
    t1 = pow(t1, vec2(b.w));
    t1 *= vec2(b.y, c.x);
    t1.y += 1.0;
    float t2 = max(t1.y, b.y) - b.y;
    float e = min(t1.x, b.y) + t2;
    if (e > 0.0 && e < 1.0 && b.z != 0.0) {
        float n = fract(senoAmd(dot(uv, vec2(12.9898, 78.233))) * 43758.5453) * 2.0 - 1.0;
        n *= b.z;
        e = clamp(e + n, 0.0, 1.0);
    }
    return meia(1.0 - e);
}
