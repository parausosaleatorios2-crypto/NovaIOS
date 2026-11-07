// ---------------------------------------------------------------------------
// Barril (Ultra Motion)
// origem : assets/effects/um-barrel.xml
// id     : nova.effect.ultramotion.barrel
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_barrelParams {
    float k1;
    float k2;
    float chroma;
    float2 center;
};

// --- funcoes auxiliares do efeito
static float2 distorcer(float2 p, float coef) {
    float r2 = dot(p, p);
    float f = 1.0 + u.k1 * r2 + u.k2 * r2 * r2;
    return p * (f + coef);
}

fragment float4 fx_um_barrel(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_barrelParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 p = in.acScreenNorm - u.center;
    p.x *= eng.acAspect;
    float2 pr = distorcer(p,  u.chroma);
    float2 pg = distorcer(p,  0.0);
    float2 pb = distorcer(p, -u.chroma);
    pr.x /= eng.acAspect; pg.x /= eng.acAspect; pb.x /= eng.acAspect;
    float r = inputImg.sample(__nv_smp, pr + u.center).r;
    float g = inputImg.sample(__nv_smp, pg + u.center).g;
    float b = inputImg.sample(__nv_smp, pb + u.center).b;
    float a = inputImg.sample(__nv_smp, pg + u.center).a;
    __nv_out = float4(r, g, b, a);
    return __nv_out;
}
