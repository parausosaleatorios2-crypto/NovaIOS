// ---------------------------------------------------------------------------
// Wipe Plasma
// origem : assets/effects/toji-3wipeplasma.xml
// id     : com.alightcreative.effects.wipe_plasma
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_3wipeplasmaParams {
    float wipe_percent;
    float edge_softness;
    float frequency;
    float freq_rel_x;
    float octaves;
    float layers;
    float seed;
    float plasma_grad;
    float plasma_grad_angle;
    float grad_add;
    float grad_angle;
    float shift_x;
    float shift_y;
    float phase_start;
    float phase_speed;
    float warp_strength;
    float warp_freq;
    int lines_enable;
    float lines_density;
    float lines_width;
    float lines_alpha;
    float4 fill_color;
    float fill_alpha;
};

// --- funcoes auxiliares do efeito
// Plasma wipe: generates a procedural scalar field and reveals the source
    // where the field exceeds a threshold. Output remains transparent elsewhere.

    const float PI = 3.14159265358979323846;
    float hash11(float n){ return fract(sin(n * 127.1 + 311.7) * 43758.5453123); }

    float2x2 rot(float a){ float c = cos(a), s = sin(a); return float2x2(c,-s,s,c); }

    // Base plasma using trigonometric composition
    float plasmaBase(float2 p, float t){
      float val = 0.0;
      val += sin(p.x + t);
      val += sin(p.y + t*1.13);
      val += sin((p.x + p.y)*0.7 + t*0.7);
      return val * (1.0/3.0);
    }

    // fBm with sinusoidal basis: cheaper than true noise, good for plasma look
    float fbmPlasma(float2 p, float t, int oct){
      float sum = 0.0;
      float amp = 0.5;
      float freq = 1.0;
      for(int i=0;i<8;i++){
        if(i>=oct) break;
        float ang = hash11(float(i) + u.seed) * 6.2831853;
        float2 q = rot(ang) * p * freq + float2(hash11(float(i)+u.seed*2.0), hash11(float(i)+u.seed*3.0));
        sum += amp * plasmaBase(q, t * (1.0 + 0.35*float(i)) + float(i));
        freq *= 1.9;
        amp *= 0.55;
      }
      return sum;
    }

fragment float4 fx_toji_3wipeplasma(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_3wipeplasmaParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 uv = in.acScreenNorm;
      // Normalize pixel shifts to UV
      float2 shiftUV = float2(u.shift_x / max(eng.acScreenSize.x, 1.0), u.shift_y / max(eng.acScreenSize.y, 1.0));
      uv += shiftUV;

      // Anisotropic scale by u.frequency and X multiplier (keep aspect-ratio aware)
      float baseFreq = max(u.frequency, 0.0001);
      float fx = baseFreq * max(u.freq_rel_x, 0.0001) * (eng.acScreenSize.x / max(eng.acScreenSize.y, 1.0));
      float fy = baseFreq;
      float2 p = float2(uv.x * fx, uv.y * fy);

      float t = u.phase_start + eng.acTime * u.phase_speed;

      // Layered sinus field
      float layersF = float(u.layers);
      float layerSum = 0.0;
      for(float i=0.0;i<16.0;i+=1.0){
        if(i>=layersF) break;
        float ang = i * (PI * 2.0 / max(layersF,1.0));
        float2 dir = rot(ang) * float2(1.0, 0.0);
        float off = hash11(i + u.seed) * 10.0;
        layerSum += sin(dot(p, dir) + t + off);
      }
      layerSum /= max(layersF, 1.0);

      // Domain warp to get long meandering veins like the reference
      float2 warpVec;
      warpVec.x = fbmPlasma(p * u.warp_freq + 17.0, t*0.8, int(u.octaves));
      warpVec.y = fbmPlasma(p * (u.warp_freq*1.3) - 11.0, t*0.8 + 3.14, int(u.octaves));
      p += u.warp_strength * warpVec;

      float n = 0.55 * layerSum + 0.45 * fbmPlasma(p, t, int(u.octaves));

      // Directional gradient bias
      float gradA = u.plasma_grad_angle * (PI/180.0);
      float2 gdir = float2(cos(gradA), sin(gradA));
      n += u.plasma_grad * dot(uv - 0.5, gdir);

      // Secondary gradient add
      float gA2 = u.grad_angle * (PI/180.0);
      float2 gdir2 = float2(cos(gA2), sin(gA2));
      n += u.grad_add * dot(uv - 0.5, gdir2);

      // Normalize to 0..1
      n = 0.5 + 0.5 * clamp(n, -1.0, 1.0);

      // Threshold using wipe percent with optional soft edge
      float th = clamp(u.wipe_percent / 100.0, 0.0, 1.0);
      float s = max(u.edge_softness, 0.0);
      float mask = smoothstep(th - s, th + s, n);
      
      // Optional contour lines across the whole field
      float lc = 0.0;
      if(u.lines_enable){
        float den = max(u.lines_density, 0.001);
        float stripe = fract(n * den);
        float w = max(u.lines_width, 0.0001);
        float line = 1.0 - smoothstep(0.5 - w*0.5, 0.5 + w*0.5, stripe);
        lc = clamp(line, 0.0, 1.0) * u.lines_alpha;
      }

      // Reveal source where mask==1; unrevealed gets fill color (can be transparent)
      float4 src = inputImg.sample(__nv_smp, in.acScreenNorm);
      float4 revealed = float4(src.rgb * src.a, src.a) * mask;
      float4 fill = float4(u.fill_color.rgb * u.fill_alpha, u.fill_alpha) * (1.0 - mask);
      float4 base = revealed + fill;

      // Composite contour lines (black) on top using premult alpha
      float4 lines = float4(float3(0.0), lc);
      float4 outc = lines + base * (1.0 - lines.a);
      __nv_out = outc;
    return __nv_out;
}
