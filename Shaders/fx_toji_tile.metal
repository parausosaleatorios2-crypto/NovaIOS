// ---------------------------------------------------------------------------
// @am:string/effect_tiles_name
// origem : assets/effects/toji-tile.xml
// id     : com.alightcreative.effects.tile
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_tileParams {
    float scale;
    float phase;
    int mirror;
    int vertoffs;
    float angle;
};

fragment float4 fx_toji_tile(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_tileParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 pixelSize = 1.0/__nv_getTexSize(inputImg_info.size);
            float2 tiledCoord = in.acLayerNorm;
            if( u.vertoffs ) {
                tiledCoord.y += step(1., __nv_mod(tiledCoord.x, 2.0)) * u.phase;
            } else {
                tiledCoord.x += step(1., __nv_mod(tiledCoord.y, 2.0)) * u.phase;
            }
            if(u.mirror) {
                tiledCoord = abs(__nv_mod(tiledCoord-float2(1.0,1.0), float2(2.0,2.0))-float2(1.0,1.0));
            } else {
                tiledCoord = __nv_mod(tiledCoord, float2(1.0,1.0));
            }
            float a = u.angle * 0.0174533;
            float2x2 rot = float2x2(
                cos(a), -sin(a),
                sin(a), cos(a)
            );
            float2 scaledCoord = tiledCoord;
            scaledCoord -= float2(0.5,0.5);
            scaledCoord *= float2(1.0)/(u.scale+pixelSize*4.0);
            scaledCoord.x *= eng.acLayerSize.x / eng.acLayerSize.y;
            scaledCoord *= rot;
            scaledCoord.x *= eng.acLayerSize.y / eng.acLayerSize.x;
            scaledCoord += float2(0.5,0.5);

            __nv_out = inputImg.sample(__nv_smp, (float4(scaledCoord,0.0,1.0)*eng.acLayerToScreen).xy);
    return __nv_out;
}
