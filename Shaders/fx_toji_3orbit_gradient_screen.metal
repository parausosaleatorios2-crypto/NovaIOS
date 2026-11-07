// ---------------------------------------------------------------------------
// New Gradient
// origem : assets/effects/toji-3orbit_gradient_screen.xml
// id     : com.alightcreative.effects.orbit_gradient_screen
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_3orbit_gradient_screenParams {
    float4 color1;
    float4 color2;
    float radius;
    float falloff1;
    float falloff2;
    float speed;
    float progress;
    float angle;
    float noiseAmt;
    int blendMode;
    float alphab;
};

// --- funcoes auxiliares do efeito
static float4 sample(float2 uv){ return inputImg.sample(__nv_smp, uv); }
    static float rnd(float2 p){ return fract(sin(dot(p, float2(12.9898,78.233))) * 43758.5453); }

    static float3 rgb2hsv(float3 c){
      float4 k = float4(0.0, -1.0/3.0, 2.0/3.0, -1.0);
      float4 p = mix(float4(c.bg, k.wz), float4(c.gb, k.xy), step(c.b, c.g));
      float4 q = mix(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
      float d = q.x - min(q.w, q.y);
      float e = 1.0e-10;
      return float3(abs(q.z + (q.w - q.y) / (6.0*d + e)), d / (q.x + e), q.x);
    }
    static float3 hsv2rgb(float3 c){
      float4 k = float4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
      float3 p = abs(fract(c.xxx + k.xyz) * 6.0 - k.www);
      return c.z * mix(k.xxx, clamp(p - k.xxx, 0.0, 1.0), c.y);
    }

    static float3 screenBlend(float3 a, float3 b){ return 1.0 - (1.0 - a) * (1.0 - b); }

fragment float4 fx_toji_3orbit_gradient_screen(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_3orbit_gradient_screenParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 uv = in.acScreenNorm;
      float2 res = eng.acScreenSize;
      float aspect = res.x / res.y;

      float a = radians(u.angle) + u.progress * 6.28318530718 + eng.acTime * u.speed;
      float2 center = float2(0.5, 0.5);
      float2 pos1 = center + float2(cos(a), sin(a)) * u.radius;
      float2 pos2 = center + float2(cos(a + 3.14159265359), sin(a + 3.14159265359)) * u.radius;

      float2 uvA = uv * float2(aspect, 1.0);
      float2 p1A = pos1 * float2(aspect, 1.0);
      float2 p2A = pos2 * float2(aspect, 1.0);

      float d1 = distance(uvA, p1A);
      float d2 = distance(uvA, p2A);

      float s1 = exp(-d1 * u.falloff1);
      float s2 = exp(-d2 * u.falloff2);

      float3 c1 = u.color1.rgb * s1;
      float3 c2 = u.color2.rgb * s2;
      float3 grad = clamp(c1 + c2, 0.0, 1.0);

      float n = rnd(uv);
      grad += n * u.noiseAmt;

      float3 base = sample(uv).rgb;
      float3 comp;
      int bm = int(u.blendMode);
      if(bm == 0){
        comp = grad;
      } else if(bm == 1){
        comp = base * grad;
      } else if(bm == 2){
        comp = screenBlend(base, grad);
      } else if(bm == 3){
        comp = mix(2.0 * base * grad, 1.0 - 2.0 * (1.0 - base) * (1.0 - grad), step(0.5, base));
      } else if(bm == 4){
        float3 hb = rgb2hsv(base);
        float3 hg = rgb2hsv(grad);
        comp = hsv2rgb(float3(hg.x, hg.y, hb.z));
      } else if(bm == 5 || bm == 13){
        comp = max(base, grad);
      } else if(bm == 6){
        comp = clamp(base / max(1.0 - grad, 1e-6), 0.0, 1.0);
      } else if(bm == 7){
        comp = clamp(1.0 - (1.0 - base) / max(grad, 1e-6), 0.0, 1.0);
      } else if(bm == 8){
        comp = clamp(base + grad, 0.0, 1.0);
      } else if(bm == 9){
        comp = clamp(base + grad - 1.0, 0.0, 1.0);
      } else if(bm == 10){
        comp = clamp(base + 2.0 * grad - 1.0, 0.0, 1.0);
      } else if(bm == 11 || bm == 12){
        comp = min(base, grad);
      } else if(bm == 14){
        comp = clamp((1.0 - 2.0 * grad) * base * base + 2.0 * grad * base, 0.0, 1.0);
      } else if(bm == 15){
        comp = mix(2.0 * base * grad, 1.0 - 2.0 * (1.0 - base) * (1.0 - grad), step(0.5, grad));
      } else if(bm == 16){
        comp = mix(2.0 * base * grad, 1.0 - 2.0 * (1.0 - base) * (1.0 - grad), step(0.5, grad));
      } else if(bm == 17){
        float3 hb = rgb2hsv(base);
        float3 hg = rgb2hsv(grad);
        comp = hsv2rgb(float3(hg.x, hb.y, hb.z));
      } else if(bm == 18){
        comp = abs(base - grad);
      } else if(bm == 19){
        float3 hb = rgb2hsv(base);
        float3 hg = rgb2hsv(grad);
        comp = hsv2rgb(float3(hb.x, hb.y, hg.z));
      } else if(bm == 20){
        float3 hb = rgb2hsv(base);
        float3 hg = rgb2hsv(grad);
        comp = hsv2rgb(float3(hb.x, hg.y, hb.z));
      } else if(bm == 21){
        float3 low = clamp(1.0 - (1.0 - base) / max(2.0 * grad, 1e-6), 0.0, 1.0);
        float3 high = clamp(base / max(2.0 * (1.0 - grad), 1e-6), 0.0, 1.0);
        comp = mix(low, high, step(0.5, grad));
      } else if(bm == 22){
        comp = mix(min(base, 2.0 * grad), max(base, 2.0 * grad - 1.0), step(0.5, grad));
      } else if(bm == 23){
        comp = clamp(base / max(grad, 1e-6), 0.0, 1.0);
      } else if(bm == 24){
        comp = clamp(base - grad, 0.0, 1.0);
      } else {
        comp = screenBlend(base, grad);
      }

      float3 outc = mix(base, comp, u.alphab);
      __nv_out = float4(outc, 1.0);
    return __nv_out;
}
