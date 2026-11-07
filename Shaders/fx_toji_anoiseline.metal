// ---------------------------------------------------------------------------
// Glitch Noise Lines
// origem : assets/effects/toji-anoiseline.xml
// id     : com.alightcreative.effects.glitch_noise_lines
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_anoiselineParams {
    float SPEED;
    float DISPLACE;
    float INTERF;
    float SHIFT;
    float LINE_SCALE;
};

// --- funcoes auxiliares do efeito
// Ported from Ashima simplex noise snippet + Shadertoy glitch logic

static float3 mod289(float3 x){ return x - floor(x * (1.0/289.0)) * 289.0; }
static float2 mod289(float2 x){ return x - floor(x * (1.0/289.0)) * 289.0; }
static float3 permute(float3 x){ return mod289(((x*34.0)+1.0)*x); }

static float snoise(float2 v){
    const float4 C = float4(0.211324865405187, 0.366025403784439,
                        -0.577350269189626, 0.024390243902439);
    float2 i  = floor(v + dot(v, C.yy));
    float2 x0 = v - i + dot(i, C.xx);
    float2 i1 = (x0.x > x0.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);
    float4 x12 = x0.xyxy + C.xxzz; x12.xy -= i1;
    i = mod289(i);
    float3 p = permute( permute( i.y + float3(0.0, i1.y, 1.0 ))
                    + i.x + float3(0.0, i1.x, 1.0 ));
    float3 m = max(0.5 - float3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
    m = m*m; m = m*m;
    float3 x = 2.0 * fract(p * C.www) - 1.0;
    float3 h = abs(x) - 0.5;
    float3 ox = floor(x + 0.5);
    float3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * (a0*a0 + h*h);
    float3 g; g.x = a0.x * x0.x + h.x * x0.y; g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

static float rand(float2 co){ return fract(sin(dot(co, float2(12.9898,78.233))) * 43758.5453); }

fragment float4 fx_toji_anoiseline(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_anoiselineParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;                   // normalized [0..1]
    float2 fragCoord = uv * eng.acScreenSize;       // pixel coords
    float time = eng.acTime * u.SPEED;

    // Large incidental waves
    float n = max(0.0, snoise(float2(time, uv.y * 0.3)) - 0.3) * (1.0/0.7);
    // Smaller constant waves
    n += (snoise(float2(time * 10.0, uv.y * 2.4)) - 0.5) * 0.15;

    // Horizontal displacement
    float xpos = uv.x - n * n * u.DISPLACE;
    float2 sUV = float2(xpos, uv.y);

    float4 c = inputImg.sample(__nv_smp, clamp(sUV, 0.0, 1.0));

    // Random line interference
    c.rgb = mix(c.rgb, float3(rand(float2(uv.y * time))), n * u.INTERF);

    // Line pattern every ~4px (controlled by u.LINE_SCALE)
    if (floor(__nv_mod(fragCoord.y * u.LINE_SCALE, 2.0)) == 0.0) {
        c.rgb *= 1.0 - (0.15 * n);
    }

    // Channel shifts (using red as base)
    float sh = n * u.SHIFT;
    float gx = clamp(xpos + sh, 0.0, 1.0);
    float bx = clamp(xpos - sh, 0.0, 1.0);
    c.g = mix(c.r, inputImg.sample(__nv_smp, float2(gx, uv.y)).g, 0.25);
    c.b = mix(c.r, inputImg.sample(__nv_smp, float2(bx, uv.y)).b, 0.25);

    __nv_out = c;
    return __nv_out;
}
