// ---------------------------------------------------------------------------
// colorama
// origem : assets/effects/toji-colorama.xml
// id     : com.alightcreative.effects.procedural_perlin_hsv_noise
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_coloramaParams {
    float octaves;
    float scale;
    float lacunarity;
    float gain;
    float timeSpeed;
    float seed;
    int colorizeHSV;
    float hueScale;
    float saturation;
    float value;
    float blend;
    float alpha;
};

// --- funcoes auxiliares do efeito
// Perlin/fractal noise HSV colorizer — AM port of provided Shadertoy

    // Hash helpers without uint bit tricks (for GLES compatibility)
    static float hash11(float n) {
      return fract(sin(n) * 43758.5453123);
    }
    static float hash21(float2 p) {
      return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453123);
    }
    static float hash31(float3 p) {
      return fract(sin(dot(p, float3(127.1, 311.7, 74.7))) * 43758.5453123);
    }

    // Random unit vectors
    static float2 randVec2(float2 p){
      float a = hash21(p) * 6.28318530718; // 2*pi
      return float2(cos(a), sin(a));
    }
    static float3 randVec3(float3 p){
      float a = hash31(p);
      float b = hash31(p + 17.17);
      float theta = a * 6.28318530718;
      float phi = acos(1.0 - 2.0 * b);
      return float3(sin(phi)*cos(theta), sin(phi)*sin(theta), cos(phi));
    }

    // Quintic smoother like in the code (x*x*x*((6x-15)x+10))
    static float2 smooth2(float2 x){ return x*x*x*((6.0*x - 15.0)*x + 10.0); }
    static float3 smooth3(float3 x){ return x*x*x*((6.0*x - 15.0)*x + 10.0); }

    // 2D Perlin
    static float perlin2(float2 p){
      float2 ip = floor(p);
      float2 f = fract(p);
      float2 u = smooth2(f);

      float2 g00 = randVec2(ip);
      float2 g10 = randVec2(ip + float2(1.0, 0.0));
      float2 g01 = randVec2(ip + float2(0.0, 1.0));
      float2 g11 = randVec2(ip + float2(1.0, 1.0));

      float n00 = dot(g00, f);
      float n10 = dot(g10, f - float2(1.0, 0.0));
      float n01 = dot(g01, f - float2(0.0, 1.0));
      float n11 = dot(g11, f - float2(1.0, 1.0));

      float nx0 = mix(n00, n10, u.x);
      float nx1 = mix(n01, n11, u.x);
      float nxy = mix(nx0, nx1, u.y);
      // normalize to ~[0,1]
      return nxy * 1.41421356 * 0.5 + 0.5;
    }

    // 3D Perlin
    static float perlin3(float3 p){
      float3 ip = floor(p);
      float3 f = fract(p);
      float3 u = smooth3(f);

      float3 g000 = randVec3(ip);
      float3 g100 = randVec3(ip + float3(1.0, 0.0, 0.0));
      float3 g010 = randVec3(ip + float3(0.0, 1.0, 0.0));
      float3 g110 = randVec3(ip + float3(1.0, 1.0, 0.0));
      float3 g001 = randVec3(ip + float3(0.0, 0.0, 1.0));
      float3 g101 = randVec3(ip + float3(1.0, 0.0, 1.0));
      float3 g011 = randVec3(ip + float3(0.0, 1.0, 1.0));
      float3 g111 = randVec3(ip + float3(1.0, 1.0, 1.0));

      float n000 = dot(g000, f);
      float n100 = dot(g100, f - float3(1.0, 0.0, 0.0));
      float n010 = dot(g010, f - float3(0.0, 1.0, 0.0));
      float n110 = dot(g110, f - float3(1.0, 1.0, 0.0));
      float n001 = dot(g001, f - float3(0.0, 0.0, 1.0));
      float n101 = dot(g101, f - float3(1.0, 0.0, 1.0));
      float n011 = dot(g011, f - float3(0.0, 1.0, 1.0));
      float n111 = dot(g111, f - float3(1.0, 1.0, 1.0));

      float nx00 = mix(n000, n100, u.x);
      float nx10 = mix(n010, n110, u.x);
      float nx01 = mix(n001, n101, u.x);
      float nx11 = mix(n011, n111, u.x);
      float nxy0 = mix(nx00, nx10, u.y);
      float nxy1 = mix(nx01, nx11, u.y);
      float nxyz = mix(nxy0, nxy1, u.z);

      return nxyz * 1.154700538 * 0.5 + 0.5;
    }

    // Fractal sum (FBM) with adjustable u.lacunarity/u.gain
    static float fbm2(float2 p, int oct){
      float sum = 0.0;
      float amp = 1.0;
      float tot = 0.0;
      float freq = 1.0;
      for(int i=0;i<8;i++){
        if(i>=oct) break;
        sum += perlin2(p*freq) * amp;
        tot += amp;
        freq *= u.lacunarity;
        amp *= u.gain;
      }
      return sum / max(tot, 1e-6);
    }
    static float fbm3(float3 p, int oct){
      float sum = 0.0;
      float amp = 1.0;
      float tot = 0.0;
      float freq = 1.0;
      for(int i=0;i<8;i++){
        if(i>=oct) break;
        sum += perlin3(p*freq) * amp;
        tot += amp;
        freq *= u.lacunarity;
        amp *= u.gain;
      }
      return sum / max(tot, 1e-6);
    }

    static float3 hsv2rgb(float3 c){
      float4 K = float4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
      float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
      return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
    }

fragment float4 fx_toji_colorama(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_coloramaParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      // Make UV u.scale invariant like fragCoord/iResolution.y
      float2 uv = in.acScreenNorm;
      uv.x *= eng.acScreenSize.x / eng.acScreenSize.y;

      int oct = int(clamp(float(u.octaves), 1.0, 8.0));
      float t = eng.acTime * u.timeSpeed;
      float3 p3 = float3(uv * u.scale + u.seed, t);
      float n = fbm3(p3, oct);

      float3 col;
      if(u.colorizeHSV){
        col = hsv2rgb(float3(n * u.hueScale, clamp(u.saturation,0.0,1.0), u.value));
      } else {
        col = float3(n);
      }

      float4 src = inputImg.sample(__nv_smp, in.acScreenNorm);
      float3 outRGB = mix(src.rgb, col, clamp(u.blend, 0.0, 1.0));
      float a = src.a * u.alpha;
      __nv_out = float4(outRGB, 1.0) * a;
    return __nv_out;
}
