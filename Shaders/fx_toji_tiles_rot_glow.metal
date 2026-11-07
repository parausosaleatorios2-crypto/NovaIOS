// ---------------------------------------------------------------------------
// Rotating Tiled Boxes Glow
// origem : assets/effects/toji-tiles-rot-glow.xml
// id     : com.alightcreative.effects.tiles_rot_glow
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_tiles_rot_glowParams {
    float SCALE;
    float ROT_SPEED;
    float BORDER;
    float DIST_COEF;
    float EDGE_FREQ;
    float EDGE_TIME;
    float EDGE_POW;
    float EDGE_GAIN;
    float POW_R;
    float POW_G;
    float POW_B;
};

// --- funcoes auxiliares do efeito
// Rotating tiled boxes glow - AM single pass

float sdBox(in float2 p, in float b){
    float2 d = abs(p) - float2(b);
    return length(max(d, 0.0));
}

float2x2 rot(float a){ return float2x2(cos(a), -sin(a), sin(a), cos(a)); }

fragment float4 fx_toji_tiles_rot_glow(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_tiles_rot_glowParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 R = eng.acScreenSize;
    float2 frag = in.acScreenNorm * R;
    float2 uv = (frag - 0.5 * R) / max(R.x, 1.0);

    float a = u.ROT_SPEED * eng.acTime;
    uv = rot(a) * uv;
    uv += 0.5 / u.SCALE;

    float2 scaled_uv = u.SCALE * uv;
    float2 tile = fract(scaled_uv) - 0.5;
    float square_dist = length(floor(scaled_uv));

    float square_dist_distortion = square_dist * u.EDGE_FREQ * (1.0 + pow(sin(eng.acTime * u.EDGE_TIME), 2.0));

    float edge = sin(0.5 * eng.acTime + square_dist_distortion);
    edge *= edge;
    edge = pow(edge, u.EDGE_POW) * u.EDGE_GAIN;

    float border = u.BORDER;
    float value = 1.5 - smoothstep(0.0 - border, 0.0 + border, sdBox(tile, edge));

    value -= square_dist * u.DIST_COEF;
    value = max(value, 0.0);

    float3 col = float3(pow(value, u.POW_R), pow(value, u.POW_G), pow(value, u.POW_B));
    __nv_out = float4(col, 1.0);
    return __nv_out;
}
