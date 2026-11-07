// ---------------------------------------------------------------------------
// BCC LED
// origem : assets/effects/toji-bcc_led.xml
// id     : com.alightcreative.effects.bcc_led
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_bcc_ledParams {
    float ledSizeX;
    float ledSizeY;
    float dotSize;
    float antialias;
    int ledShape;
    float4 tintColor;
    float tintAmount;
    float flickerSpeed;
    float flickerAmount;
    float glowAlpha;
    float glowSize;
    float glowBrightness;
    float brightness;
};

// --- funcoes auxiliares do efeito
static float2 getResolution(){
      float2 s = __nv_getTexSize(inputImg_info.size);
      if (s.x <= 0.0 || s.y <= 0.0) s = float2(1920.0, 1080.0);
      return s;
    }
    static float rand(float2 co){ return fract(sin(dot(co.xy, float2(12.9898,78.233))) * 43758.5453); }

fragment float4 fx_toji_bcc_led(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_bcc_ledParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 res = getResolution();
      float2 fragCoord = in.acScreenNorm * res;
      float2 uv = in.acScreenNorm;

      float cellW = res.x / max(u.ledSizeX, 1.0);
      float cellH = res.y / max(u.ledSizeY, 1.0);
      float2 cellSize = float2(cellW, cellH);

      float2 cellIndex = floor(fragCoord / cellSize);
      float2 cellCenterPos = (cellIndex + 0.5) * cellSize;
      float2 cellUVn = (fragCoord - cellCenterPos) / cellSize; // normalized -0.5..0.5 both axes

      float2 textureUV = cellCenterPos / res;
      float3 baseCol = inputImg.sample(__nv_smp, textureUV).rgb;
      baseCol = mix(baseCol, u.tintColor.rgb, u.tintAmount);

      float tBlock = floor(eng.acTime * max(u.flickerSpeed, 0.0));
      float flickerRnd = rand(cellIndex + float2(tBlock, tBlock*0.37));
      float flicker = mix(1.0 - u.flickerAmount, 1.0, flickerRnd);

      float dMask;
      if (int(u.ledShape) == 0){
        float dist = length(cellUVn);
        dMask = smoothstep(u.dotSize, u.dotSize - u.antialias, dist);
      } else {
        float m = max(abs(cellUVn.x), abs(cellUVn.y));
        dMask = smoothstep(u.dotSize, u.dotSize - u.antialias, m);
      }

      float glowMask;
      if (int(u.ledShape) == 0){
        float dist = length(cellUVn);
        glowMask = smoothstep(u.dotSize + u.glowSize, u.dotSize + u.glowSize - u.antialias, dist);
      } else {
        float m = max(abs(cellUVn.x), abs(cellUVn.y));
        glowMask = smoothstep(u.dotSize + u.glowSize, u.dotSize + u.glowSize - u.antialias, m);
      }

      float3 col = baseCol * dMask * flicker;
      col += baseCol * u.glowBrightness * glowMask * u.glowAlpha;
      col *= u.brightness;

      float outA = max(dMask, u.glowAlpha * glowMask);
      __nv_out = float4(col, outA);
    return __nv_out;
}
