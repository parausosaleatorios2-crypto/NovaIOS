// ---------------------------------------------------------------------------
// Time Slice Wipe
// origem : assets/effects/toji-atimeslice.xml
// id     : com.alightcreative.effects.time_slice_wipe
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_atimesliceParams {
    float count;
    float smoothness;
    float speed;
    float angle;
    float feather;
    float reverse;
};

// --- funcoes auxiliares do efeito
static float4 getFromColor(float2 coord){ return inputImg.sample(__nv_smp, coord); }
    float4 getToColor(float2 coord){ return inputImg2.sample(__nv_smp, coord); }
    float4 getMask(float2 coord){ return mask.sample(__nv_smp, coord); }

fragment float4 fx_toji_atimeslice(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_atimesliceParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> inputImg2 [[texture(1)]],
    texture2d<float> mask [[texture(2)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& inputImg2_info [[buffer(3)]],
    constant NovaTexInfo& mask_info [[buffer(4)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 uv = in.acLayerNorm;
      float s = getMask(uv).a;
      float4 fromCol = getFromColor(uv);
      float4 toCol = getToColor(uv);
      float rev = step(0.5, u.reverse);
      float4 f = mix(fromCol, toCol, rev);
      float4 t = mix(toCol, fromCol, rev);
      float4 col = mix(f, t, s);
      __nv_out = col;
    return __nv_out;
}
