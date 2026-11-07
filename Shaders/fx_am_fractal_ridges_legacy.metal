// ---------------------------------------------------------------------------
// Cristais fractais (AM, versão antiga)
// origem : assets/effects/am-fractal-ridges-legacy.xml
// id     : nova.effect.am-fractal-ridges-legacy
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_fractal_ridges_legacyParams {
    float2 parr;
    float2 offs;
    float evolution;
    float scale;
    float stretch;
    float intensity;
    float seed;
    float4 color1;
    float4 color2;
    float octaves;
};

// --- funcoes auxiliares do efeito
// O simplex 3D do webgl-noise (Ashima Arts / Ian McEwan, licença MIT), como o AM o escreve: as mesmas constantes e
// a mesma ordem de operações (o ruído dá salto na divisa das células; a mesma ordem dá o mesmo float).
static float3 mod289(float3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
static float4 mod289(float4 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
static float4 permute(float4 x) { return mod289(((x * 34.0) + 1.0) * x); }
static float4 taylorInvSqrt(float4 r) { return 1.79284291400159 - 0.85373472095314 * r; }

static float snoise(float3 v) {
    const float2 C = float2(1.0 / 6.0, 1.0 / 3.0);
    const float4 D = float4(0.0, 0.5, 1.0, 2.0);
    float3 i = floor(v + dot(v, C.yyy));
    float3 x0 = v - i + dot(i, C.xxx);
    float3 g = step(x0.yzx, x0.xyz);
    float3 l = 1.0 - g;
    float3 i1 = min(g.xyz, l.zxy);
    float3 i2 = max(g.xyz, l.zxy);
    float3 x1 = x0 - i1 + C.xxx;
    float3 x2 = x0 - i2 + C.yyy;
    float3 x3 = x0 - D.yyy;
    i = mod289(i);
    float4 p = permute(permute(permute(
                 i.z + float4(0.0, i1.z, i2.z, 1.0))
               + i.y + float4(0.0, i1.y, i2.y, 1.0))
               + i.x + float4(0.0, i1.x, i2.x, 1.0));
    float n_ = 0.142857142857;
    float3 ns = n_ * D.wyz - D.xzx;
    float4 j = p - 49.0 * floor(p * ns.z * ns.z);
    float4 x_ = floor(j * ns.z);
    float4 y_ = floor(j - 7.0 * x_);
    float4 x = x_ * ns.x + ns.yyyy;
    float4 y = y_ * ns.x + ns.yyyy;
    float4 h = 1.0 - abs(x) - abs(y);
    float4 b0 = float4(x.xy, y.xy);
    float4 b1 = float4(x.zw, y.zw);
    float4 s0 = floor(b0) * 2.0 + 1.0;
    float4 s1 = floor(b1) * 2.0 + 1.0;
    float4 sh = -step(h, float4(0.0));
    float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
    float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
    float3 p0 = float3(a0.xy, h.x);
    float3 p1 = float3(a0.zw, h.y);
    float3 p2 = float3(a1.xy, h.z);
    float3 p3 = float3(a1.zw, h.w);
    float4 norm = taylorInvSqrt(float4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;
    float4 m = max(0.6 - float4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
    m = m * m;
    return 42.0 * dot(m * m, float4(dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3)));
}

// A crista do AM: |n| vira dobra, invertida para a dobra ficar em cima, e afinada ao quadrado.
static float ridge(float h, float offset) {
    h = abs(h);
    h = offset - h;
    h = h * h;
    return h;
}

// O ridged multifractal do AM, linha por linha (cada oitava pesa também pela crista da anterior).
static float ridgedMF(float2 p, int OCTAVES, float2 parallax, float evo) {
    float lacunarity = 2.0;
    float gain = 0.5;
    float offset = 0.9;
    float sum = 0.0;
    float freq = 1.0, amp = 0.5;
    float prev = 1.0;
    for (int i = 0; i < OCTAVES; i++) {
        float n = ridge(snoise(float3(p * freq, evo)), offset);
        sum += n * amp;
        sum += n * amp * prev;
        prev = n;
        freq *= lacunarity;
        p += parallax;
        amp *= gain;
    }
    return sum;
}

static float4 preMultiplicada(float4 c) { return float4(c.rgb * c.a, c.a); }

// O fundo (a cena montada atrás da camada) no pixel da tela, pré-multiplicado.
static float3 fundoNoPixel() {
    int2 T = int2(int(comp.get_width()), int(comp.get_height()));
    int2 px = clamp(int2(floor(__nv_acTela(in.acScreenNorm) * float2(T))), int2(0), T - 1);
    float4 f = comp.read(uint2(px), uint(0));
    return f.rgb * f.a;
}

// A saída pré-multiplicada do AM em cor reta (a conta da Caixa e do Virar camada). O comum (cor ≤ alfa) é só
// dividir. Na borda antialiased da camada, com o ruído acima de 1, a mistura passa da Cor 2 e a cor fica ACIMA do
// alfa (luz que a composição do AM soma ao fundo): este pixel leva junto o fundo dele — com o menor alfa `a` em que
// a cor reta `s = fundo + (p − fundo·alfa)/a` cabe entre 0 e 1, a composição Normal do Nova, `s·a·op +
// fundo·(1 − a·op)`, dá o mesmo `op·p + fundo·(1 − op·alfa)` do AM com qualquer opacidade. Não cabe só quando a
// soma passa de 1 com a opacidade abaixo da cheia.
static float4 paraReta(float4 p) {
    // Quem decide se a cor passou do alfa é o alvo de 8 bits do AM (um resto de conta abaixo de meio nível some lá).
    float4 q = floor(p * 255.0 + 0.5) / 255.0;
    if (all(lessThanEqual(q.rgb, float3(q.a)))) return p.a > 0.0 ? float4(min(p.rgb / p.a, float3(1.0)), p.a) : float4(0.0);
    float3 d = fundoNoPixel();
    float3 sobra = q.rgb - d * q.a;
    float3 folga = 1.0 - d;
    float a = q.a;
    for (int i = 0; i < 3; i++) {
        // Canal com o fundo cheio (1): lá e aqui a soma fica em 1 com qualquer alfa, então ele não pede nada.
        if (sobra[i] > 0.0 && folga[i] > 0.0) a = max(a, sobra[i] / folga[i]);
    }
    a = min(a, 1.0);
    return a > 0.0 ? float4(clamp(d + sobra / a, 0.0, 1.0), a) : float4(0.0);
}

// A volta da `eng.acCamadaParaTela`: UV da tela → UV do buffer da camada.
static float2 naCamada(float2 t) {
    float3 c = __nv_inverse(eng.acCamadaParaTela) * float3(t, 1.0);
    return c.xy / c.z;
}

fragment float4 fx_am_fractal_ridges_legacy(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_fractal_ridges_legacyParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> comp [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 texColor = preMultiplicada(inputImg.sample(__nv_smp, in.acScreenNorm));

    // O `in.acLayerNorm` do AM: o retângulo do conteúdo de 0 a 1, com o meio no meio do buffer (que cobre a
    // composição, `eng.acTamanhoDaTela`) e o Y para CIMA (o buffer do Nova cresce para baixo). A ponte dos Raios radiais.
    float2 eng.acLayerSize = max(eng.acTamanhoDaCamada, float2(1e-6));
    float2 camada = 0.5 + (naCamada(__nv_acTela(in.acScreenNorm)) - 0.5) * eng.acTamanhoDaTela / eng.acLayerSize;
    camada.y = 1.0 - camada.y;

    // Daqui em diante, o `main` do AM na mesma ordem.
    float2 st = camada;
    st.x *= eng.acLayerSize.x / eng.acLayerSize.y;
    st += u.offs * float2(-1., 1.) / 500.;
    st += __nv_mod(float2(821.921 * u.seed, 437.317 * u.seed), float2(4.365, 7.701));
    float2 parallax = u.parr * float2(-1., 1.) / 100.;
    float2 scaleVec;
    if (u.stretch < 0.0) {
        scaleVec = float2(u.scale - u.stretch, u.scale);
    } else {
        scaleVec = float2(u.scale, u.scale + u.stretch);
    }
    float p = ridgedMF((st - 0.5) * scaleVec + 0.5, int(u.octaves), parallax, u.evolution) * u.intensity;
    float4 rcolor = mix(u.color1, u.color2, p);
    rcolor *= texColor.a;
    float4 saida = rcolor + texColor * (1.0 - rcolor.a);

    // A gravação de 8 bits do AM corta cada canal pré-multiplicado em 0..1; depois, o alfa reto do Nova, com a luz
    // acima do alfa levada pelo fundo (`paraReta`).
    __nv_out = paraReta(clamp(saida, 0.0, 1.0));
    return __nv_out;
}
