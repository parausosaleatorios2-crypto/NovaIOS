// ---------------------------------------------------------------------------
// Cosine Web (Zozuar 2)
// origem : assets/effects/toji-3zozaur2.xml
// id     : com.alightcreative.effects.cos_web_zozuar_2
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_3zozaur2Params {
    float TIME_SPEED;
    float ITER;
    float ROT;
    float S0;
    float S_GROW;
    float4 COLOR_MUL;
    float ADD_BIAS;
    float DETAIL;
    float GAMMA;
};

// --- funcoes auxiliares do efeito
// Cosine Web (Zozuar 2) - AM single pass, GLES-safe loops

float2x2 rotate2D(float r){ return float2x2(cos(r), sin(r), -sin(r), cos(r)); }

fragment float4 fx_toji_3zozaur2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_3zozaur2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 R = eng.acScreenSize;
    float2 uv = (in.acScreenNorm * R - 0.5 * R) / max(R.y, 1.0);
    float3 col = float3(0.0);
    float t = eng.acTime * u.TIME_SPEED;

    float2 n = float2(0.0), q;
    float2 N = float2(0.0);
    float2 p = uv + t / 10.0;
    float S = u.S0;
    float2x2 m = rotate2D(u.ROT);

    int iters = int(clamp(u.ITER, 1.0, 64.0));
    const int MAX_IT = 64;
    for (int j = 0; j < MAX_IT; ++j){
        if (j >= iters) break;
        p = m * p;
        n = m * n;
        q = p * S + float(j) + n + t;
        n += sin(q);
        N += cos(q) / S;
        S *= u.S_GROW;
    }

    float3 cm = u.COLOR_MUL.rgb; // default ~ float3(1,2,4)
    float invLen = (length(N) > 1e-6) ? (u.DETAIL / length(N)) : 0.0;
    col = cm * ((N.x + N.y + u.ADD_BIAS) + invLen);

    col = pow(max(col, 0.0), float3(u.GAMMA));
    __nv_out = float4(col, 1.0);
    return __nv_out;
}
