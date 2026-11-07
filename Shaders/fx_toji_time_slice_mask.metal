// ---------------------------------------------------------------------------
// Time Slice Mask
// origem : assets/effects/toji-time_slice_mask.xml
// id     : com.alightcreative.effects.time_slice_mask
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_time_slice_maskParams {
    float count;
    float smoothness;
    float speed;
    float angle;
    float feather;
    float reverse;
};

fragment float4 fx_toji_time_slice_mask(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_time_slice_maskParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> inputImg2 [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 uv = in.acLayerNorm;
      float progress = fract(eng.acTime * u.speed);
      float rad = u.angle * 0.017453292519943295;
      float2 v = normalize(float2(cos(rad), -sin(rad)));
      float p = dot(uv - float2(0.5), v) + 0.5;
      float pr = smoothstep(-u.smoothness, 0.0, p - progress * (1.0 + u.smoothness));
      float cell = fract(u.count * p);
      float useFeather = step(1e-6, u.feather);
      float sHard = step(pr, cell);
      float sSoft = smoothstep(pr, pr + u.feather, cell);
      float s = mix(sHard, sSoft, useFeather);
      __nv_out = float4(float3(s), s);
    return __nv_out;
}
