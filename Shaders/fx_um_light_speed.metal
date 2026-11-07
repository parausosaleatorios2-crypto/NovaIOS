// ---------------------------------------------------------------------------
// Velocidade da Luz (Ultra Motion)
// origem : assets/effects/um-light-speed.xml
// id     : nova.effect.ultramotion.lightspeed
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_light_speedParams {
    float density;
    float reach;
    float speed;
    float inner;
    float4 tint;
    float2 center;
};

// --- funcoes auxiliares do efeito
static float hash11(float x) { return fract(sin(x * 127.1) * 43758.5453); }

fragment float4 fx_um_light_speed(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_light_speedParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 orig = inputImg.sample(__nv_smp, in.acScreenNorm);
    float2 p = in.acScreenNorm - u.center;
    p.x *= eng.acAspect;
    float r = length(p);
    if (r < u.inner) { __nv_out = orig; return __nv_out; }

    float ang = __nv_atan(p.y, p.x);
    float fatia = floor(ang / (6.2831853 / u.density));
    float semente = hash11(fatia * 7.1);
    float t = fract(semente + eng.acTime * u.speed * (0.5 + semente));
    // o fim da linha fica no raio = length * t (fora do u.inner)
    float ponta = u.inner + (u.reach - u.inner) * t;
    float d = abs(r - ponta);
    float traco = smoothstep(0.02, 0.0, d) * smoothstep(u.inner, u.inner + 0.1, r) * (1.0 - t);

    float3 cor = orig.rgb + u.tint.rgb * u.tint.a * traco * 1.5;
    __nv_out = float4(cor, orig.a);
    return __nv_out;
}
