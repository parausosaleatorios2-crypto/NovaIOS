// ---------------------------------------------------------------------------
// @am:string/effect_voronoi_name
// origem : assets/effects/toji-voronoi2.xml
// id     : com.alightcreative.effects.voronoi2
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_voronoi2Params {
    float scale;
    float phase;
    float lineWidth;
    float4 color;
    float4 color2;
    float4 lineColor;
    float seed;
};

// --- funcoes auxiliares do efeito
static float random (in float2 st) {
            return fract(sin(dot(st.xy,
                                 float2(12.9898,78.233)))*
                43758.5453123);
        }

        float2 rand2v(float2 co) {
            return float2(random(co),random(co+float2(361.312,173.019)));
        }

fragment float4 fx_toji_voronoi2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_voronoi2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);

            float2 st = in.acLayerNorm.st;
            st.x *= eng.acLayerSize.x/eng.acLayerSize.y;
            st -= float2(0.5,0.5);

            st /= (u.scale*0.07);

            float2 tile = floor(st);
            float2 tpart = fract(st);

            float maxDist = 100.0;
            float2 nearestTile = float2(0.0,0.0);
            //float2 nearestTileOffs = float2(0.0,0.0);
            //float2 nearest_r = float2(0.0,0.0);


            float actualPhase = u.phase * 6.28318;

            float2 seedVec = float2(123.215,272.055)*u.seed;

            for( int i=-1; i<=1; i++ ) {
                for( int j=-1; j<=1; j++ ) {
                    float2 checkTileOffs = float2(float(i),float(j));
                    float2 p = rand2v(tile + checkTileOffs + seedVec);
                    p = 0.5 + 0.5*sin(actualPhase + 6.2831*p);
                    float2 r = checkTileOffs + p - tpart;
                    float dist = dot(r,r);
                    if( dist < maxDist ) {
                        maxDist = dist;
                        //nearest_k = float(k);
                        //nearest_r = r;
                        nearestTile = checkTileOffs + tile;
                        //nearestTileOffs = checkTileOffs;
                    }
                }
            }

            float colorPct =  random(nearestTile + float2(721.117,433.215)*u.seed);

            float4 result = mix(u.color,u.color2,colorPct);

            //result = float4(actualMaxDist,abs(actualMaxDist),0.5,1.0);

            result = result * texColor.a;

            __nv_out = result;
    return __nv_out;
}
