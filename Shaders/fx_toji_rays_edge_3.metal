// ---------------------------------------------------------------------------
// Rays Edge
// origem : assets/effects/toji-rays_edge_3.xml
// id     : com.alightcreative.effects.rays_edge
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_rays_edge_3Params {
    float edgeThreshold;
    float brightThreshold;
    float feather;
    int useLuma;
    float2 centerPoint;
    float strength;
    float intensity;
    float threshold;
    float4 thresholdColor;
    float4 fillColor;
    float blend;
    float quality;
};

// --- funcoes auxiliares do efeito
const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);
    float4 src(float2 uv){ return inputImg.sample(__nv_smp, uv); }
    float4 eTex(float2 uv){ return edge.sample(__nv_smp, uv); }

fragment float4 fx_toji_rays_edge_3(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_rays_edge_3Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> edge [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& edge_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 texelSize = 1.0 / __nv_getTexSize(inputImg_info.size);
      float2 center = float2(0.5 + u.centerPoint.x/500., 0.5 - u.centerPoint.y/500.);
      float2 v = in.acScreenNorm.st - (float4(center,0.0,1.0) * eng.acLayerToScreen).xy;
      float speed = length(u.strength / 2.0 / texelSize);
      speed *= length( in.acLayerNorm.st - center );
      int nSamples = int(u.quality);
      float4 baseColor = src(in.acScreenNorm.st);
      float2 vnorm = normalize(v)*texelSize*speed;
      float2 offsetScale = float2(1., 1.);
      if( eng.acScreenSize.y > eng.acScreenSize.x ) {
        offsetScale.x *= eng.acScreenSize.x / eng.acScreenSize.y;
      } else {
        offsetScale.y *= eng.acScreenSize.y / eng.acScreenSize.x;
      }
      float actualSamples = 1.0;
      float4 outColor = float4(0.0);
      for(int i=1; i<800; i++ ) {
        if(i>=nSamples) break;
        float p = float(i) / float(nSamples - 1);
        float2 offs = vnorm * p;
        offs *= offsetScale;
        float4 texColor = src(in.acScreenNorm.st-offs);
        float4 edgeColor = eTex(in.acScreenNorm.st-offs);
        float luminance = dot(edgeColor.rgb - u.thresholdColor.rgb, luminanceWeighting);
        outColor += luminance > u.threshold ? mix(texColor,u.fillColor,u.blend)*(1.-p) : float4(0.0);
        actualSamples += luminance > u.threshold ? 1.0 : 0.0;
      }
      __nv_out = baseColor + outColor * u.intensity / float(nSamples);
    return __nv_out;
}
