// ---------------------------------------------------------------------------
// Motion Blur ae
// origem : assets/effects/toji-aemoblur.xml
// id     : com.alightcreative.effects.moblurae
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_aemoblurParams {
    float tune;
    float2 PANGLE;
    float2 PSCALE;
    float samples;
    float shutter;
    float phase;
    float shutterSamples;
    float shutterBias;
    float shutterCurve;
    float shutterShape;
    float gaussSigma;
    float exposureComp;
    float softenHi;
    float blueNoiseSeed;
    int useHybrid;
    float hybridMix;
    float zoomMix;
    int usePos;
    int useScale;
    int useAngle;
    float swirlStrength;
    float quality;
};

// --- funcoes auxiliares do efeito
// Helpers for AE-like integration
        static float3 toLinear(float3 c){ return pow(max(c, 0.0), float3(2.2)); }
        static float3 toSRGB(float3 c){ return pow(max(c, 0.0), float3(1.0/2.2)); }
        static float halton(int i, int b){
            // GLSL ES 1.00 does not support the integer modulo operator '%'.
            // Use float mod() to extract base-b digits for the Halton sequence.
            float f = 1.0; 
            float r = 0.0; 
            int n = i;
            for(int j=0; j<20; j++){
                if(n <= 0) break; 
                f /= float(b);
                float digit = __nv_mod(float(n), float(b));
                r += f * digit; 
                n = n / b; 
            }
            return r;
        }
        static float shutterWeight(float t, int shape, float curve, float sigma){
            t = clamp(t, -0.5, 0.5);
            float x = abs(t*2.0);
            if(shape==0) return 1.0;                          // Box
            if(shape==1) return pow(max(0.0, 1.0-x), curve);   // Triangle/Tent
            if(shape==2) return max(0.0, cos(3.14159265*t));   // Cosine
            float g = exp(-(t*t)/(2.0*sigma*sigma));           // Gaussian
            return pow(g, curve);
        }

fragment float4 fx_toji_aemoblur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_aemoblurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            // Rotational blur length driven by angular velocity and u.shutter angle (AE-like)
            float angle = abs(eng.acAngularVelocity) * (u.shutter/360.0) * u.tune; // degrees
            float cx = u.PANGLE.x + eng.acLayerPivot.x/eng.acLayerSize.x;
            float cy = u.PANGLE.y - eng.acLayerPivot.y/eng.acLayerSize.y;
            float2 image_size = __nv_getTexSize(inputImg_info.size);
            float maxF = max(eng.acScreenSize.x, eng.acScreenSize.y);
            float2 texelSize = 1.0 / float2(maxF, maxF);
            float2 center = (float4(cx,cy,0.0,1.0) * eng.acLayerToScreen).xy;
            float2 v = in.acScreenNorm.st - center;
            v.y *= image_size.y / image_size.x;
            float r = length(v);
            float rN = clamp(r, 0.0, 1.0);
            float swirl = 1.0 + u.swirlStrength * rN;
            float d = 6.283185*r;
            float l = d*angle/360.0;
            float a = angle * 0.0174533; // radians total
            float speed = l/texelSize.x;
            int q = int(u.quality + 0.5);
            float samplesQ = float(u.samples);
            float capQ = float(u.shutterSamples);
            float curveQ = u.shutterCurve;
            if (q == 0) { samplesQ = max(4.0, samplesQ * 0.5); capQ = max(4.0, capQ * 0.5); curveQ = max(0.25, curveQ * 0.8); }
            else if (q == 2) { samplesQ = samplesQ * 1.5; capQ = capQ * 2.0; curveQ = curveQ * 1.5; }
            int nMax = int(samplesQ + 0.5);
            int nSamples = int(clamp(speed, 1.01, float(nMax)+0.01));
            int nCap = int(capQ + 0.5);
            nSamples = min(nSamples, nCap);
            float4 accum = float4(0.0);
            float wsum = 0.0;
            int shape = int(u.shutterShape + 0.5);
            // Sampling loop with Halton sequence + jitter; linear-space premult accumulation
            for (int i = 0; i < nSamples; i++) {
                float u = halton(i, 2);
                float k = mix(0.5, 2.0, (u.shutterBias + 1.0) * 0.5);
                u = pow(u, k);
                float jitter = (fract(sin(dot(__nv_fragCoord.xy+float(i)+u.blueNoiseSeed, float2(12.9898,78.233))) * 43758.5453) - 0.5) / float(nSamples);
                float t = clamp(u - 0.5 + u.phase + jitter, -0.5, 0.5);
                float sampleAngle = t * a * swirl;
                float s = sin(sampleAngle);
                float c = cos(sampleAngle);
                float2x2 rot = float2x2(c, -s, s, c);
                float2 temp = v*rot;
                temp.y = temp.y * image_size.x / image_size.y;
                float2 sampleUV = center + temp;
                float w = shutterWeight(t, shape, curveQ, u.gaussSigma);
                // Simple LOD softening at high speed
                float lod = clamp(speed/150.0, 0.0, 1.0) * u.softenHi;
                float2 px = float2(1.0) / max(float2(image_size.x, image_size.y), 1.0);
                float4 raw = inputImg.sample(__nv_smp, sampleUV);
                float4 soft = (raw + inputImg.sample(__nv_smp, sampleUV + px) + inputImg.sample(__nv_smp, sampleUV - px)) / 3.0;
                float4 col = mix(raw, soft, lod);
                // Premultiplied alpha accumulation in linear space (AE-like)
                accum.rgb += toLinear(col.rgb) * col.a * w;
                accum.a   += col.a * w;
                wsum += w;
            }
            // Include a base sample for stability (AE-like exposure integration)
            float4 base = inputImg.sample(__nv_smp, in.acScreenNorm.st);
            accum.rgb += toLinear(base.rgb) * base.a;
            accum.a   += base.a;
            wsum += 1.0;
            float3 outPremultLin = accum.rgb / max(wsum, 1e-6);
            float outA = accum.a / max(wsum, 1e-6);
            float3 outLin = outPremultLin / max(outA, 1e-6);
            float3 outSRGB = toSRGB(outLin) * u.exposureComp;
            __nv_out = float4(outSRGB, outA);
    return __nv_out;
}
