// ---------------------------------------------------------------------------
// Noise Tunnel Blue
// origem : assets/effects/toji-noisetunnelblue.xml
// id     : com.alightcreative.effects.noise_tunnel_blue
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_noisetunnelblueParams {
    float SPEED;
    float CYCLE;
    float ROT_Y;
    float ROT_X;
    float ROT_SPEED;
    float FBM_SCALE;
    float FBM_OCT;
    float FBM_PERSIST;
    float FOCAL_DEPTH;
    float DISK_MIN;
    float DISK_SCALE;
    float4 COLOR_BASE;
    float WHITE_GAIN;
    float GAMMA;
    int WHITEOUT;
};

// --- funcoes auxiliares do efeito
// Blue Simplex FBM Tunnel - AM single pass
#define PI 3.141592653589793
#define TAU 6.283185307179586

// Hash and simplex noise (hash33-based)
#define MOD3 float3(0.1031, 0.11369, 0.13787)
static float3 hash33(float3 p3){
    p3 = fract(p3 * MOD3);
    p3 += dot(p3, p3.yxz + 19.19);
    return -1.0 + 2.0 * fract(float3(
        (p3.x + p3.y) * p3.z,
        (p3.x + p3.z) * p3.y,
        (p3.y + p3.z) * p3.x
    ));
}

static float simplexNoise(float3 p){
    const float K1 = 0.333333333;
    const float K2 = 0.166666667;
    float3 i = floor(p + (p.x + p.y + p.z) * K1);
    float3 d0 = p - (i - (i.x + i.y + i.z) * K2);
    float3 e = step(float3(0.0), d0 - d0.yzx);
    float3 i1 = e * (1.0 - e.zxy);
    float3 i2 = 1.0 - e.zxy * (1.0 - e);
    float3 d1 = d0 - (i1 - float3(1.0) * K2);
    float3 d2 = d0 - (i2 - float3(2.0) * K2);
    float3 d3 = d0 - (float3(1.0) - float3(3.0) * K2);
    float4 h = max(0.6 - float4(dot(d0,d0), dot(d1,d1), dot(d2,d2), dot(d3,d3)), 0.0);
    float4 n = h * h * h * h * float4(dot(d0, hash33(i)), dot(d1, hash33(i + i1)), dot(d2, hash33(i + i2)), dot(d3, hash33(i + float3(1.0))));
    return dot(float4(31.316), n);
}

static float fbm3(float3 p){
    float f = 0.0;
    float scale = u.FBM_SCALE;
    float amp = 0.75;
    int oct = int(clamp(u.FBM_OCT, 1.0, 8.0));
    const int MAX_OCT = 8;
    for (int i=0; i<MAX_OCT; ++i){
        if (i >= oct) break;
        f += simplexNoise(p * scale) * amp;
        amp *= u.FBM_PERSIST;
        scale *= 2.0;
    }
    return min(f, 1.0);
}

static float3x3 rotY(float a){ return float3x3(cos(a),0.0,sin(a), 0.0,1.0,0.0, -sin(a),0.0,cos(a)); }
static float3x3 rotX(float a){ return float3x3(1.0,0.0,0.0, 0.0,cos(a),sin(a), 0.0,-sin(a),cos(a)); }

fragment float4 fx_toji_noisetunnelblue(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_noisetunnelblueParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 R = eng.acScreenSize;
    float2 frag = in.acScreenNorm * R;

    float t2 = max(u.CYCLE, 1e-3);
    float t = __nv_mod(eng.acTime, t2) / t2; // normalized 0..1

    float2 q = frag / R; // unused but retained
    float2 p = (2.0 * frag - R) / min(R.y, R.x);
    p += float2(0.0, -0.1);

    float ay = u.ROT_Y;
    float ax = u.ROT_X;

    float3x3 m = rotX(ax) * rotY(ay);
    float3 v = float3(p, 1.0);
    v = m * v;
    float v_xy = length(v.xy);
    float z = v.z / max(v_xy, 1e-5);

    float focal_depth = u.FOCAL_DEPTH;
    float whiteoutSel = float(u.WHITEOUT);
    if (whiteoutSel > 0.5){
        float wf = smoothstep(0.65, 0.9, t);
        focal_depth = mix(0.15, 0.015, wf);
    }

    float2 polar;
    float p_len = length(v.xy);
    polar.y = z * focal_depth + eng.acTime * u.SPEED;

    float a = __nv_atan(v.y, v.x);
    a = 0.5 + 0.5 * a / PI;
    a -= eng.acTime * u.ROT_SPEED;
    float x = fract(a);
    if (x >= 0.5) x = 1.0 - x;
    polar.x = x;

    float val = 0.45 + 0.55 * fbm3(float3(float2(2.0, 0.5) * polar, 0.15 * eng.acTime));
    val = clamp(val, 0.0, 1.0);

    float3 baseCol = u.COLOR_BASE.rgb;
    float3 col = baseCol * float3(val);

    float3 white = u.WHITE_GAIN * float3(smoothstep(0.55, 1.0, val));
    col += white;
    col = clamp(col, 0.0, 1.0);

    float w_total = 0.0;
    float w_out = 0.0;
    if (whiteoutSel > 0.5){
        float w_in = abs(1.0 - smoothstep(0.0, 0.25, t));
        w_out = abs(smoothstep(0.8, 1.0, t));
        w_total = max(w_in, w_out);
    }

    float disk_size = max(u.DISK_MIN, u.DISK_SCALE * w_out);
    float disk_col = exp(-(p_len - disk_size) * 4.0);
    col += clamp(float3(disk_col), 0.0, 1.0);

    if (whiteoutSel > 0.5){
        col = mix(col, float3(1.0), w_total);
    }

    col = pow(max(col, 0.0), float3(u.GAMMA));
    __nv_out = float4(col, 1.0);
    return __nv_out;
}
