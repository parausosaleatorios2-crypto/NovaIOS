// ---------------------------------------------------------------------------
// Cosine Web (Zozuar)
// origem : assets/effects/toji-3zozaur.xml
// id     : com.alightcreative.effects.cos_web_zozuar
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_3zozaurParams {
    float TIME_SPEED;
    float ITER;
    float ROT;
    float S0;
    float S_GROW;
    float4 COLOR_MUL;
    float ADD_BIAS;
    float POST_SUB_D;
    float GAMMA;
};

// --- funcoes auxiliares do efeito
// Cosine Web (Zozuar) - AM single pass, GLES-safe loops

static float2x2 rotate2D(float r){ return float2x2(cos(r), sin(r), -sin(r), cos(r)); }

fragment float4 fx_toji_3zozaur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_3zozaurParams&  u    [[buffer(1)]],
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

    float2 n = float2(0.0);
    float2 q = float2(0.0);
    float2 p = uv;
    float d = dot(p, p);
    float S = u.S0;
    float aAcc = 0.0;
    float2x2 m = rotate2D(u.ROT);

    int iters = int(clamp(u.ITER, 1.0, 64.0));
    const int MAX_IT = 64;
    for (int j = 0; j < MAX_IT; j++){
        if (j >= iters) break;
        p = m * p;
        n = m * n;
        q = p * S + t * 4.0 + sin(t * 4.0 - d * 6.0) * 0.8 + float(j) + n;
        aAcc += dot(cos(q) / S, float2(0.2));
        n -= sin(q);
        S *= u.S_GROW;
    }

    float3 cm = u.COLOR_MUL.rgb;
    col = cm * (aAcc + u.ADD_BIAS) + aAcc + aAcc - d * u.POST_SUB_D;

    col = pow(max(col, 0.0), float3(u.GAMMA));
    __nv_out = float4(col, 1.0);
    return __nv_out;
}
