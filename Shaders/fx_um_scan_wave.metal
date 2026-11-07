// ---------------------------------------------------------------------------
// Onda Varredura (Ultra Motion)
// origem : assets/effects/um-scan-wave.xml
// id     : nova.effect.ultramotion.scanwave
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_scan_waveParams {
    float speed;
    float width;
    float angle;
    float4 tint;
    float gain;
};

fragment float4 fx_um_scan_wave(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_scan_waveParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 orig = inputImg.sample(__nv_smp, in.acScreenNorm);
    float a = radians(u.angle);
    float2 n = float2(cos(a), sin(a));
    float t = dot(in.acScreenNorm - 0.5, n) + 0.5;
    float pos = fract(eng.acTime * u.speed);
    float d = abs(t - pos);
    d = min(d, 1.0 - d);
    float faixa = smoothstep(u.width, 0.0, d);
    float3 cor = orig.rgb + u.tint.rgb * faixa * u.gain * u.tint.a;
    __nv_out = float4(cor, orig.a);
    return __nv_out;
}
