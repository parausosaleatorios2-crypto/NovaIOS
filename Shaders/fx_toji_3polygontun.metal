// ---------------------------------------------------------------------------
// Polygon Tunnel Arrow
// origem : assets/effects/toji-3polygontun.xml
// id     : com.alightcreative.effects.polygon_tunnel_arrow
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_3polygontunParams {
    float SPEED;
    float TWIST_K;
    float TWIST_FREQ;
    float PHASE;
    float GRID_SCALE;
    float GRID_PHASE;
    float PREWARP_AMP;
    float PREWARP_FREQ;
    float ROT;
    float RECT_SIZE;
    float TRI_SIZE;
    float RECT_OFF_Y;
    float2 TRI_OFFSET;
    float COLOR_GAIN;
    float OUTER_BIAS;
    float GAMMA;
};

// --- funcoes auxiliares do efeito
// Polygon Tunnel Arrow - AM single pass
#define PI 3.141592653589793
#define TAU 6.283185307179586

static float polygon(float2 p, float vertices, float size){
    float a = __nv_atan(p.x, p.y) + 0.2;
    float b = TAU / max(vertices, 1.0);
    return cos(floor(0.5 + a / b) * b - a) * length(p) - size;
}

static float2x2 rot2(float r){ return float2x2(cos(r), sin(r), -sin(r), cos(r)); }

fragment float4 fx_toji_3polygontun(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_3polygontunParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float time = eng.acTime * u.SPEED;
    float2 R = eng.acScreenSize;
    float2 frag = in.acScreenNorm * R;

    // Normalized coordinates (-1..1 vertically)
    float2 p = (-R + 2.0 * frag) / max(R.y, 1.0);
    float2 uvOrig = p;

    // Twist
    float rotZ = 1.0 - u.TWIST_K * sin(u.TWIST_FREQ * sin(length(p * 1.5)));
    p *= rot2(rotZ);

    // Tunnel mapping (iq technique)
    float a = __nv_atan(p.y, p.x);
    float rSquare = pow(pow(p.x*p.x, 4.0) + pow(p.y*p.y, 4.0), 1.0/8.0);
    float rRound = length(p);
    float r = mix(rSquare, rRound, 0.5 + 0.5 * sin(time * u.PHASE));
    float2 uv = float2(0.3 / max(r, 1e-4) + time, a / PI);

    // Grid warps
    uv += float2(0.0, u.PREWARP_AMP * sin(time + uv.x * u.PREWARP_FREQ));
    float2 uvDraw = fract(uv * u.GRID_SCALE + u.GRID_PHASE * sin(time)) - 0.5;

    // Rotate drawing coords
    uvDraw *= rot2(u.ROT);

    float antialias = 8.0 / max(R.y, 1.0);
    float col = 0.0;

    // Rect (as polygon with 4 verts)
    float2 rectPos = uvDraw + float2(0.0, u.RECT_OFF_Y);
    col = max(col, smoothstep(antialias, 0.0, polygon(rectPos, 4.0, u.RECT_SIZE)));

    // Triangle
    float2 triPos = uvDraw + u.TRI_OFFSET;
    col = max(col, smoothstep(antialias, 0.0, polygon(triPos, 3.0, u.TRI_SIZE)));

    // Shading
    col = col * r * u.COLOR_GAIN;
    col += u.OUTER_BIAS * length(uvOrig);

    float3 outc = float3(col);
    outc = pow(max(outc, 0.0), float3(u.GAMMA));
    __nv_out = float4(outc, 1.0);
    return __nv_out;
}
