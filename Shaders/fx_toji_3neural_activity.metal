// ---------------------------------------------------------------------------
// Burn texture
// origem : assets/effects/toji-3neural_activity.xml
// id     : com.alightcreative.effects.neural_activity
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_3neural_activityParams {
    float phase;
    float timeScale;
    float rotSpeed;
    float rippleFreq;
    float rippleAmt;
    float fadeSpeed;
    float fadeMin;
    float fadeMax;
    int useSecondTexture;
    float4 altColor;
    float opacity;
};

// --- funcoes auxiliares do efeito
static float2x2 rot(float a){
      float c = cos(a);
      float s = sin(a);
      return float2x2(c, s, -s, c);
    }

    static float fx(float2 uv,float fadetime,float tt){
      float light = 0.05;
      float rip = 0.5+sin(length(uv)*u.rippleFreq+tt)*0.5;
      rip = 1.0+rip*u.rippleAmt;
      uv*=rip*0.5;
      uv *= rot(tt*u.rotSpeed);

      float vv2 = smoothstep(0.0,0.45,fadetime);
      float vv = mix(u.fadeMin,u.fadeMax,fadetime);

      float tth = tt*0.5;
      for (int i=0;i<12;i++){
        float x = 1.5 + 2.0*float(i);
        uv *= rot(x*4.0+length(uv)*0.126*sin(tth*0.05));
        float2 f = float2(cos(cos(tth*0.6+x + uv.x * x) - uv.y * dot(float2(x + uv.y), float2(sin(x), cos(x)))));
        light += (vv / distance(uv, f)) - (0.01 * distance(float2((cos(tth*0.3 + uv.y))), float2(uv)));
        light-=x*0.001 + 0.001;
      }

      light = clamp(light,0.0,1.0);
      return light*vv2;
    }

fragment float4 fx_toji_3neural_activity(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_3neural_activityParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputA [[texture(0)]],
    texture2d<float> inputB [[texture(1)]],
    constant NovaTexInfo& inputA_info [[buffer(2)]],
    constant NovaTexInfo& inputB_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 res = eng.acScreenSize;
      float2 uv = in.acScreenNorm;
      float4 a = inputA.sample(__nv_smp, uv);
      float4 bTex = inputB.sample(__nv_smp, uv);
      float3 bCol = (int(u.useSecondTexture)==1) ? bTex.rgb : u.altColor.rgb;

      float tt = u.phase * u.timeScale;
      float2 uvC = (uv*res - 0.5*res)/max(res.y,1.0);
      float fadetime = 0.5+sin(tt*u.fadeSpeed)*0.5;
      float fade = fx(uvC,fadetime,tt);

      float3 outRGB = mix(a.rgb, bCol, fade);
      float aOut = a.a * u.opacity;
      __nv_out = float4(outRGB, 1.0) * aOut;
    return __nv_out;
}
