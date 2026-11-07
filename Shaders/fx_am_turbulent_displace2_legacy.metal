// ---------------------------------------------------------------------------
// Deslocamento turbulento (AM, versão 2)
// origem : assets/effects/am-turbulent-displace2-legacy.xml
// id     : nova.effect.am-turbulent-displace2-legacy
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_turbulent_displace2_legacyParams {
    float2 parr;
    float2 position;
    float intensity;
    float evolution;
    int direction;
    float scale;
    float stretch;
    float seed;
    int singleAxis;
    int screenSpace;
    float octaves;
    float offs;
};

// --- funcoes auxiliares do efeito
// O simplex 3D do webgl-noise (Ashima Arts / Ian McEwan, licença MIT), como o AM o escreve: as mesmas constantes e
// a mesma ordem de operações (o ruído é contínuo, mas a mesma ordem dá o mesmo float no mesmo celular).
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

// A turbulência do AM: |ruído| somado em oitavas, a coordenada dobrada e somada à paralaxe a cada uma.
static float turbulence(float2 st, int OCTAVES, float2 parallax, float u.evolution) {
    float value = 0.0;
    float amplitude = .5;
    for (int i = 0; i < OCTAVES; i++) {
        value += amplitude * abs(snoise(float3(st, u.evolution)));
        st *= 2.;
        st += parallax;
        amplitude *= .5;
    }
    return value;
}

static float4 preMultiplicada(float4 c) { return float4(c.rgb * c.a, c.a); }

// O filtro linear da GPU, à mão, sobre a camada PRÉ-multiplicada (a textura do AM é assim): os 4 pixels em volta,
// presos à borda como o CLAMP_TO_EDGE.
static float4 camadaNoPonto(float2 uv) {
    int2 T = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    float2 p = uv * float2(T) - 0.5;
    float2 i = floor(p);
    float2 f = p - i;
    int2 a = int2(i);
    int2 m = T - 1;
    float4 c00 = preMultiplicada(inputImg.read(uint2(clamp(a, int2(0), m)), uint(0)));
    float4 c10 = preMultiplicada(inputImg.read(uint2(clamp(a + int2(1, 0), int2(0), m)), uint(0)));
    float4 c01 = preMultiplicada(inputImg.read(uint2(clamp(a + int2(0, 1), int2(0), m)), uint(0)));
    float4 c11 = preMultiplicada(inputImg.read(uint2(clamp(a + int2(1, 1), int2(0), m)), uint(0)));
    return mix(mix(c00, c10, f.x), mix(c01, c11, f.x), f.y);
}

// A volta da `eng.acCamadaParaTela`: UV da tela → UV do buffer da camada.
static float2 naCamada(float2 t) {
    float3 c = __nv_inverse(eng.acCamadaParaTela) * float3(t, 1.0);
    return c.xy / c.z;
}

fragment float4 fx_am_turbulent_displace2_legacy(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_turbulent_displace2_legacyParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    // Os uniforms do AM com os nomes do Nova e a coordenada da camada do AM (o Y para CIMA), como no atual.
    float2 acScreenSize = eng.acTamanhoDaTela;
    float2 eng.acLayerSize = max(eng.acTamanhoDaCamada, float2(1e-6));
    float2 tela = __nv_acTela(in.acScreenNorm);
    float2 camada = 0.5 + (naCamada(tela) - 0.5) * acScreenSize / eng.acLayerSize;
    camada.y = 1.0 - camada.y;

    float2 st;
    if (u.screenSpace) {
        st = tela;
        st.x *= acScreenSize.x / acScreenSize.y;
    } else {
        st = camada;
        st.x *= eng.acLayerSize.x / eng.acLayerSize.y;
    }
    st += u.position * float2(-1., 1.) / 500.;
    float2 parallax = u.parr * float2(-1., 1.) / 100.;

    // O Esticar antigo: um número só, que soma à Escala num eixo (negativo: no outro).
    float2 scaleVec;
    if (u.stretch < 0.0) {
        scaleVec = float2(u.scale - u.stretch, u.scale);
    } else {
        scaleVec = float2(u.scale, u.scale + u.stretch);
    }
    float2 sampleCoord;
    if (u.singleAxis) {
        if (u.direction == 0) {
            sampleCoord = float2(0., st.y - 0.5);              // X
        } else if (u.direction == 1) {
            sampleCoord = float2(st.x - 0.5, 0.);              // Y
        } else if (u.direction == 2) {
            sampleCoord = st - 0.5;                          // XY
        } else if (u.direction == 4) {
            sampleCoord = st - 0.5;                          // φr
        } else if (u.direction == 5) {
            sampleCoord = float2(0., length(st - 0.5));        // φ
        } else {
            float tt = abs(__nv_atan(st.x - 0.5, st.y - 0.5) / 6.28318) * 2.;
            sampleCoord = float2(tt, 0.);                      // r
        }
    } else {
        sampleCoord = st - 0.5;
    }

    // A versão 2 MULTIPLICA pela escala (a atual divide).
    float p = turbulence((sampleCoord - 0.5) * scaleVec + 0.5, int(u.octaves), parallax, u.evolution + 7391.935 * u.seed);
    p += (u.offs - 0.25);
    p *= u.intensity * 2.0;

    float2 uv = u.screenSpace ? tela : camada;
    if (u.direction == 0) {
        uv.x += p;                                           // X
    } else if (u.direction == 1) {
        uv.y += p;                                           // Y
    } else if (u.direction == 2) {
        float q = turbulence((sampleCoord) * scaleVec + 0.5, int(u.octaves), parallax, u.evolution + 3937.7249 * (u.seed + 6.3379));
        q += (u.offs - 0.25);
        q *= u.intensity * 2.0;
        uv.x += p;                                           // XY
        uv.y += q;
    } else if (u.direction == 4) {
        float q = turbulence((sampleCoord) * scaleVec + 0.5, int(u.octaves), parallax, u.evolution + 3937.7249 * (u.seed + 6.3379));
        q += (u.offs - 0.25);
        q *= u.intensity * 2.0;
        float cq = cos(q);
        float sq = sin(q);
        uv += normalize(uv - 0.5) * p;                       // φr
        uv *= float2x2(cq, sq, -sq, cq);
    } else if (u.direction == 5) {
        float cq = cos(p);
        float sq = sin(p);
        uv *= float2x2(cq, sq, -sq, cq);                         // φ
    } else {
        uv += normalize(uv - 0.5) * p;                       // r
    }

    // De volta à imagem de entrada, como no atual. Sem o corte na borda da tela (o atual tem): fora dela, a borda
    // se repete (CLAMP_TO_EDGE).
    bool naTela = eng.acParaTela == float3x3(1.0);
    float2 b = uv;
    if (!u.screenSpace) {
        b = 0.5 + (float2(uv.x, 1.0 - uv.y) - 0.5) * eng.acLayerSize / acScreenSize;
        if (naTela) {
            float3 c = eng.acCamadaParaTela * float3(b, 1.0);
            bool afim = eng.acCamadaParaTela[0].z == 0.0 && eng.acCamadaParaTela[1].z == 0.0 && eng.acCamadaParaTela[2].z == 1.0;
            b = afim ? c.xy : c.xy / c.z;
        }
    } else if (!naTela) {
        b = naCamada(uv);
    }

    bool foraDaConta = any(isinf(b)) || any(isnan(b));
    float4 c = foraDaConta ? preMultiplicada(inputImg.sample(__nv_smp, b)) : camadaNoPonto(b);
    __nv_out = c.a > 0.0 ? float4(min(c.rgb / c.a, float3(1.0)), c.a) : float4(0.0);
    return __nv_out;
}
