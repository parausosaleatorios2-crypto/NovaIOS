// ---------------------------------------------------------------------------
// FBM Time Displace Fade
// origem : assets/effects/toji-fbm_time_displace_fade.xml
// id     : custom.fbm_time_displace_fade
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_fbm_time_displace_fadeParams {
    float time;
    float timeDiv;
    float timeScale;
    float fbmScale;
    float dispClamp;
    float fadeBias;
};

// --- funcoes auxiliares do efeito
// Port of provided ShaderToy-style effect (manual u.time control)
        // Original concepts: fbm noise, displacement, u.time-based fade

        static float random(float2 _st){
            return fract(sin(dot(_st.xy, float2(12.9898,78.233))) * 43758.5453123);
        }
        static float noise2d(float2 _st){
            float2 i = floor(_st);
            float2 f = fract(_st);
            float a = random(i);
            float b = random(i + float2(1.0, 0.0));
            float c = random(i + float2(0.0, 1.0));
            float d = random(i + float2(1.0, 1.0));
            float2 u = f * f * (3.0 - 2.0 * f);
            return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
        }
        #define NUM_OCTAVES 5
        static float fbm(float2 _st){
            float v = 0.0;
            float a = 0.5;
            float2 shift = float2(100.0);
            float2x2 rot = float2x2(cos(0.5), sin(0.5), -sin(0.5), cos(0.50));
            for (int i = 0; i < NUM_OCTAVES; ++i) {
                v += a * noise2d(_st);
                _st = rot * _st * 2.0 + shift;
                a *= 0.5;
            }
            return v;
        }
        static float workingPow3(float x){ return x * x * x; }

fragment float4 fx_toji_fbm_time_displace_fade(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_fbm_time_displace_fadeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 res = eng.acScreenSize;
            float2 fragCoord = in.acScreenNorm * res;
            float2 uv = fragCoord / res; // 0..1

            // Time mapping from params (no auto eng.acTime)
            float modifiedTime = workingPow3(fract(u.time / max(u.timeDiv, 0.0001)) - 0.5) * 4.0;

            // Secondary u.time scale (iTime/3. in source) kept for parity if needed
            float timeB = u.time / max(u.timeScale, 0.0001);
            (void)timeB; // not used directly but preserved for parity

            // FBM-based displacements
            float verticalDisp   = clamp(fbm(fragCoord / u.fbmScale)    * modifiedTime, -1.0, 1.0) / max(u.dispClamp, 0.0001);
            float horizontalDisp = clamp(fbm(fragCoord.yx / u.fbmScale) * modifiedTime, -1.0, 1.0) / max(u.dispClamp, 0.0001);

            float2 offsetCoords = uv - float2(horizontalDisp, verticalDisp);
            float4 tex = inputImg.sample(__nv_smp, offsetCoords);

            // Fade mask (procedural, similar structure to source)
            float mask = clamp(tex.a * (1.0 - (abs(modifiedTime) * 2.0 + fbm(uv * 3.0))) * u.fadeBias, 0.0, 1.0);

            float3 outRGB = mix(float3(0.0), tex.rgb, mask);
            __nv_out = float4(outRGB, 1.0);
    return __nv_out;
}
