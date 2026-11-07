// ---------------------------------------------------------------------------
// @am:string/effect_dots_name
// origem : assets/effects/toji-dots2.xml
// id     : com.alightcreative.effects.dots2
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_dots2Params {
    float scale;
    float phase;
    float radius;
    float feather;
    float4 color;
    float4 color2;
    float density;
    float2 position;
    float fill;
    float alpha;
    int blendMode;
    float seed;
    float slack;
};

// --- funcoes auxiliares do efeito
//float rand(float2 co)
        //{
        //    float a = 719.310;
        //    float b = 178.233;
        //    float c = 33758.5453;
        //    float dt= dot(co.xy ,float2(a,b));
        //    float sn= __nv_mod(dt, 3.14);
        //    return fract(sin(sn) * c);
        //}
        //
        //float rand_alt(float2 co)
        //{
        //    float a = 317.541;
        //    float b = 142.123;
        //    float c = 31758.5362;
        //    float dt= dot(co.xy ,float2(a,b));
        //    float sn= __nv_mod(dt, 3.14);
        //    return fract(sin(sn) * c);
        //}
        //
        //float2 rand2v(float2 co) {
        //    return float2(rand(co),rand_alt(co));
        //}


        float random (in float2 st) {
            return fract(sin(dot(st.xy,
                                 float2(12.9898,78.233)))*
                43758.5453123);
        }

        // Based on Morgan McGuire @morgan3d
        // https://www.shadertoy.com/view/4dS3Wd
        float noise (float2 st) {
            float2 i = floor(st);
            float2 f = fract(st);

            // Four corners in 2D of a tile
            float a = random(i);
            float b = random(i + float2(1.0, 0.0));
            float c = random(i + float2(0.0, 1.0));
            float d = random(i + float2(1.0, 1.0));

            float2 u = f * f * (3.0 - 2.0 * f);

            return mix(a, b, u.x) +
                    (c - a)* u.y * (1.0 - u.x) +
                    (d - b) * u.x * u.y;
        }

        float fbm (float2 st, float2 parallax, int octaveCount, float intens) {
            // Initial values
            float value = 0.;
            float amplitude = 0.5;
            float frequency = 0.;
            //
            // Loop of octaves
            for (int i = 0; i < octaveCount; i++) {
                value += amplitude * noise(st);
                st *= 2.0;
                st += parallax;
                amplitude *= intens;
            }
            return value;
        }


        float2 rand2v(float2 co) {
            return float2(noise(co),noise(co+float2(613.312,736.019)));
        }

fragment float4 fx_toji_dots2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_dots2Params&  u    [[buffer(1)]],
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
            st -= (u.position*float2(1.0,-1.0)/1000.0);
            st /= (u.scale*0.07);

            float2 tile = floor(st);
            float2 tpart = fract(st);

            float maxDist = 100.0;
            float2 nearestTile = float2(0.0,0.0);
            float nearest_k = 0.;

            int densitySteps = int(max(1.0,u.density-10.0));
            float threshold = min(1.0,u.density/11.0);

            float actualPhase = u.phase * 6.28318;

            for( int i=-1; i<=1; i++ ) {
                for( int j=-1; j<=1; j++ ) {
                    float2 checkTileOffs = float2(float(i),float(j));
                    for( int k=0; k<densitySteps; k++ ) {
                        float2 p = rand2v(tile + float2(523.135,621.265)*float(k) + checkTileOffs + float2(123.215,272.055)*u.seed);
                        p = 0.5 + (0.5*sin(actualPhase + 6.2831*p)*max(0.00001,u.slack));
                        float dist = length(checkTileOffs + p - tpart);
                        float2 tileId = checkTileOffs + tile;
                        float flk = float(k);
                        float ck = random(tileId + float2(flk,-flk) + float2(541.117,163.713)*(u.seed+0.1));
                        if( dist < maxDist && ck<=threshold ) {
                            maxDist = dist;
                            nearest_k = float(k);
                            nearestTile = tileId;
                        }
                    }
                }
            }

            float colorPct =  random(nearestTile + float2(nearest_k,-nearest_k) + float2(721.117,433.215)*u.seed);

            float intensity = smoothstep(1.0-u.radius,1.0-(u.radius*(1.0-u.feather)),1.-maxDist);

            //intensity *= random(nearestTile + float2(nearest_k,-nearest_k) + float2(541.117,163.713)*u.seed) > threshold ? 0.0 : 1.0;

            float4 over = texColor * u.fill;
            float4 rcolor = mix(u.color,u.color2,colorPct)*intensity*texColor.a;

            float4 result;
            if( u.blendMode==1 ) {
                result = float4((texColor.rgb/texColor.a)*(rcolor.rgb/rcolor.a),1.0) * rcolor.a * texColor.a;
                result = clamp(result,0.0,1.0);
                result = result+(over*(1.0-result.a));
                result = clamp(result,0.0,1.0);
            } else if( u.blendMode==2 ) {
                result = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-(rcolor.rgb/rcolor.a))),1.0) * rcolor.a * texColor.a;
                result = clamp(result,0.0,1.0);
                result = result+(over*(1.0-result.a));
                result = clamp(result,0.0,1.0);
            } else {
                result = rcolor+(over*(1.0-rcolor.a));
            }
            __nv_out = mix(over,result,u.alpha);


            //__nv_out = result+(over*(1.0-result.a));
    return __nv_out;
}
