// ---------------------------------------------------------------------------
// un.VHS
// origem : assets/effects/toji-1vhs.xml
// id     : com.alightcreative.effects.vhs
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_1vhsParams {
    float lumaShrink;
    float chromaShrink;
    float unsharpAmount;
    float unsharpRadius;
    float unsharpThreshold;
    float blackLevel;
    float whiteLevel;
    float saturation;
    float4 shadowTint;
    float sourceFps;
    float lineHeight;
    float noiseGrain;
    float noiseBlend;
    float trackingSpeed;
    float trackingOffset;
    float trackingJitter;
    float waveFreq;
    float waveOffset;
    float bottomWarpH;
    float bottomWarpOff;
    float bottomWarpJit;
    float noiseLineThick;
    float noiseLineOpac;
    int showOriginal;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265358979323846;
    const float3 W = float3(0.2126, 0.7152, 0.0722);
    static float lum(float3 c){ return dot(c, W); }
    static float lum4(float4 c){ return dot(c.rgb, W); }
    static float gold(float2 xy, float seed){ return fract(sin(dot(xy*seed, float2(12.9898,78.233))) * 43758.5453); }
    static float soft(float b, float l){ return (l<0.5)?(2.0*b*l + b*b*(1.0-2.0*l)):(sqrt(b)*(2.0*l-1.0)+2.0*b*(1.0-l)); }
    static float4 soft4(float4 base, float4 blend){ return float4(soft(base.r,blend.r), soft(base.g,blend.g), soft(base.b,blend.b), 1.0); }
    static float3 clipColor(float3 c){ float l = lum(c); float n = min(c.r, min(c.g, c.b)); float x = max(c.r, max(c.g, c.b)); if(n<0.0){ c.r = l + ((c.r - l) * l) / (l - n); c.g = l + ((c.g - l) * l) / (l - n); c.b = l + ((c.b - l) * l) / (l - n); } if(x>1.0){ c.r = l + ((c.r - l) * (1.0 - l)) / (x - l); c.g = l + ((c.g - l) * (1.0 - l)) / (x - l); c.b = l + ((c.b - l) * (1.0 - l)) / (x - l); } return c; }
    static float3 setLum(float3 c, float l){ float d = l - lum(c); c += float3(d); return clipColor(c); }
    static float4 blendColor(float4 base, float4 blend){ float3 c = setLum(blend.rgb, lum4(base)); return float4(c, blend.a); }
    static float4 blendLum(float4 base, float4 blend){ float3 c = setLum(base.rgb, lum4(blend)); return float4(c, blend.a); }

    static float4 sample(float2 uv){ return inputImg.sample(__nv_smp, uv); }

    static float4 shrink(float2 fragCoord, float shrinkRatio){ float scale = 1.0/eng.acScreenSize.x; float numBands = eng.acScreenSize.x * shrinkRatio; float bandWidth = eng.acScreenSize.x / numBands; float t = __nv_mod(fragCoord.x, bandWidth) / bandWidth; float2 uv = fragCoord / eng.acScreenSize; float4 a = sample(uv); uv.x += bandWidth * scale; float4 b = sample(uv); return mix(a, b, t); }

    static float4 gaussianBlur(float2 uv, float radius){ float2 s = 1.0 / eng.acScreenSize; float r = max(radius, 0.5); float4 c = float4(0.0); float wsum = 0.0; for(int j=-4;j<=4;j++){ for(int i=-4;i<=4;i++){ float dx=float(i), dy=float(j); float w = exp(-(dx*dx+dy*dy)/(2.0*r*r)); c += sample(uv + float2(dx*s.x, dy*s.y)) * w; wsum += w; } } return c/wsum; }

    static float2 trackingUV(float speed, float offset, float jitter, float2 fragCoord){ float t = 1.0 - __nv_mod(eng.acTime, speed)/speed; float start = __nv_mod(t*eng.acScreenSize.y, eng.acScreenSize.y); float j = gold(float2(5000.0,5000.0), 10.0 + fract(eng.acTime)) * jitter; start += j; float2 uv; if(fragCoord.y > start) uv = (fragCoord + float2(offset,0.0))/eng.acScreenSize; else uv = fragCoord/eng.acScreenSize; return uv; }
    static float2 waveUV(float freq, float offset, float2 fragCoord, float2 uv){ float phase = floor(fragCoord.y / (eng.acScreenSize.y / freq)); float onm = gold(float2(1.0 + phase, phase), 10.0); float off = sin((uv.y + fract(eng.acTime*0.05)) * PI * 2.0 * freq) * ((offset * onm) / eng.acScreenSize.x); return uv + float2(off, 0.0); }
    static float4 warpBottom(float height, float offset, float jitter, float2 uv){ float h = height / eng.acScreenSize.y; if(uv.y > h) return sample(uv); float t = uv.y / h; float off = t * (offset / eng.acScreenSize.x); float j = (gold(float2(500.0,500.0), fract(eng.acTime)) * jitter) / eng.acScreenSize.x; float2 u = float2(uv.x - off - j, uv.y); float4 px = sample(u); return px * t; }
    static float4 whiteNoise(float thick, float opac, float4 px, float2 fragCoord){ if(gold(float2(600.0,500.0), fract(eng.acTime) * 10.0) > 0.97){ float start = floor(gold(float2(800.0,50.0), fract(eng.acTime)) * eng.acScreenSize.y); float endv = floor(start + thick); if(floor(fragCoord.y) >= start && floor(fragCoord.y) < endv){ float freq = gold(float2(850.0,50.0), fract(eng.acTime)) * 3.0 + 1.0; float off = gold(float2(900.0,51.0), fract(eng.acTime)); float x = floor(fragCoord.x) / floor(eng.acScreenSize.x) + off; float w = pow(cos(PI * fract(x * freq) / 2.0), 10.0) * opac; float grit = gold(float2(floor(fragCoord.x / 3.0), 800.0), fract(eng.acTime)); w = max(w - grit * 0.3, 0.0); return px + w; } } return px; }

fragment float4 fx_toji_1vhs(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_1vhsParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      if (u.showOriginal) { float4 o = sample(in.acScreenNorm); __nv_out = o; return __nv_out; }
      float2 fragCoord = in.acScreenNorm * eng.acScreenSize;
      float2 uv = trackingUV(u.trackingSpeed, u.trackingOffset, u.trackingJitter, fragCoord);
      uv = waveUV(u.waveFreq, u.waveOffset, fragCoord, uv);
      float4 luma = shrink(fragCoord, u.lumaShrink);
      luma = blendLum(float4(0.5,0.5,0.5,1.0), luma);
      float4 chroma = shrink(fragCoord, u.chromaShrink);
      chroma = blendColor(luma, chroma);
      float4 pre = chroma;
      float4 blur = gaussianBlur(uv, u.unsharpRadius);
      float ld = abs(lum4(pre) - lum4(blur));
      float4 pixel = pre;
      if (ld >= u.unsharpThreshold) pixel = pre + (pre - blur) * u.unsharpAmount;
      pixel = mix(pixel, float4(1.0), u.blackLevel);
      pixel = mix(pixel, float4(0.0,0.0,0.0,1.0), 1.0 - u.whiteLevel);
      float3 inten = float3(dot(pixel.rgb, W));
      pixel = float4(mix(inten, pixel.rgb, u.saturation), 1.0);
      float3 st = u.shadowTint.rgb;
      float powr = 1.5;
      if (st.r > 0.0) pixel.r = mix(pixel.r, 1.0 - pow(abs(pixel.r - 1.0), powr), st.r);
      if (st.g > 0.0) pixel.g = mix(pixel.g, 1.0 - pow(abs(pixel.g - 1.0), powr), st.g);
      if (st.b > 0.0) pixel.b = mix(pixel.b, 1.0 - pow(abs(pixel.b - 1.0), powr), st.b);
      float fps = u.sourceFps;
      bool updateOdd = __nv_mod(floor(fract(eng.acTime) * fps), 2.0) < 1.0;
      bool oddLine = __nv_mod(floor(fragCoord.y), 2.0 * u.lineHeight) >= u.lineHeight;
      float4 noisePx = pixel;
      if ((oddLine && updateOdd) || (!oddLine && !updateOdd)) noisePx = pixel; else noisePx = pixel;
      float grainSize = max(1.0, u.noiseGrain);
      float seed = fps > 0.0 ? floor(fract(eng.acTime) * fps) / fps : eng.acTime;
      float2 uvNoise = fragCoord / eng.acScreenSize;
      float4 grain;
      if (grainSize > 1.0){ uvNoise.x = floor(fragCoord.x / grainSize) / eng.acScreenSize.x; uvNoise.y = floor(fragCoord.y / grainSize) / eng.acScreenSize.y; }
      float r = gold(uvNoise * (seed + 1.0), 1.0);
      float g = r;
      float b = r;
      grain = float4(r,g,b,1.0);
      noisePx = soft4(noisePx, grain) * u.noiseBlend + noisePx * (1.0 - u.noiseBlend);
      float4 warped = warpBottom(u.bottomWarpH, u.bottomWarpOff, u.bottomWarpJit, uv);
      float4 outPx = noisePx;
      outPx = whiteNoise(u.noiseLineThick, u.noiseLineOpac, outPx, fragCoord);
      float vign = pow(uv.x * (1.0 - uv.x) * uv.y * (1.0 - uv.y), 0.25) * 2.2;
      outPx *= vign;
      __nv_out = outPx;
    return __nv_out;
}
