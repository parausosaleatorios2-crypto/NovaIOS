// ---------------------------------------------------------------------------
// Wipe Circle
// origem : assets/effects/toji-circlewipe.xml
// id     : com.alightcreative.effects.wipecircle
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_circlewipeParams {
    float size;
    float width;
    float height;
    float feather;
    float centerX;
    float centerY;
    int invert;
};

fragment float4 fx_toji_circlewipe(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_circlewipeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 uv = in.acScreenNorm;

      // Circle/ellipse center
      float2 center = float2(u.centerX, u.centerY);

      // Apply u.size scaling to u.width/u.height
      float2 radii = float2(u.width, u.height) * u.size;

      // Normalized ellipse distance
      float2 d = (uv - center) / max(radii, float2(1e-5));
      float dist = length(d);

      // Feathered edge transition
      float edge = smoothstep(1.0, 1.0 - u.feather, dist);

      if (u.invert) edge = 1.0 - edge;

      // Sample texture and apply alpha mask
      float4 tex = inputImg.sample(__nv_smp, uv);
      __nv_out = float4(tex.rgb * edge, tex.a * edge);
    return __nv_out;
}
