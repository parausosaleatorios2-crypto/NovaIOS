// ---------------------------------------------------------------------------
// Lightning (Procedural)
// origem : assets/effects/toji-lighting.xml
// id     : com.alightcreative.effects.lightning_procedural
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_lightingParams {
    float colorR;
    float colorG;
    float colorB;
    float intensity;
    float width;
    float speed;
    float octaves;
    float warp;
    float rotate;
};

// --- funcoes auxiliares do efeito
// ShaderToy -> Alight Motion mapping
    // iResolution.xy -> eng.acScreenSize
    // iTime -> eng.acTime
    // fragCoord -> in.acScreenNorm * eng.acScreenSize

    float hash11(float p)
    {
        p = fract(p * 0.1031);
        p *= p + 33.33;
        p *= p + p;
        return fract(p);
    }

    float hash12(float2 p)
    {
        float3 p3 = fract(float3(p.xyx) * 0.1031);
        p3 += dot(p3, p3.yzx + 33.33);
        return fract((p3.x + p3.y) * p3.z);
    }

    float2x2 rotate2d(float theta)
    {
        float c = cos(theta);
        float s = sin(theta);
        return float2x2(c, -s, s, c);
    }

    float noise2(float2 p)
    {
        float2 ip = floor(p);
        float2 fp = fract(p);
        float a = hash12(ip);
        float b = hash12(ip + float2(1.0, 0.0));
        float c = hash12(ip + float2(0.0, 1.0));
        float d = hash12(ip + float2(1.0, 1.0));
        float2 t = smoothstep(0.0, 1.0, fp);
        return mix(mix(a, b, t.x), mix(c, d, t.x), t.y);
    }

    float fbm(float2 p, int octaveCount, float rotAngle)
    {
        float value = 0.0;
        float amplitude = 0.5;
        float2x2 R = rotate2d(rotAngle);
        for (int i = 0; i < 12; ++i)
        {
            if(i >= octaveCount) break;
            value += amplitude * noise2(p);
            p = R * p * 2.0;
            amplitude *= 0.5;
        }
        return value;
    }

    void imagePass(out float4 __nv_out, float2 fragCoord)
    {
        float2 iResolution = eng.acScreenSize;
        // Normalized pixel coordinates (from -1 to 1), aspect-corrected
        float2 uv = fragCoord / iResolution.xy;
        uv = 2.0 * uv - 1.0;
        uv.x *= iResolution.x / iResolution.y;

        // Animated domain u.warp via FBM
        float t = eng.acTime * u.speed;
        int   oct = int(u.octaves + 0.5);
        float wobble = fbm(uv + t, oct, u.rotate);
        uv += u.warp * (wobble - 0.5) * 2.0; // center around 0

        // Distance from bolt centerline (x=0)
        float dist = max(1e-4, abs(uv.x));

        // Base color and u.intensity with subtle jitter
        float3 baseCol = float3(u.colorR, u.colorG, u.colorB);
        float jitter = mix(0.0, u.intensity, hash11(eng.acTime));
        float glow = pow(jitter * u.width / dist, 1.0);

        float3 col = baseCol * glow;
        __nv_out = float4(col, 1.0);
    }

fragment float4 fx_toji_lighting(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_lightingParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 fragCoord = in.acScreenNorm * eng.acScreenSize;
      float4 c; imagePass(c, fragCoord); __nv_out = c; return __nv_out;
    return __nv_out;
}
