// ---------------------------------------------------------------------------
// @am:string/effect_clouds_name
// origem : assets/effects/toji-clouds3.xml
// id     : com.alightcreative.effects.clouds3
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_clouds3Params {
    float2 parr;
    float2 offs;
    float scale;
    float2 stretch;
    float intensity;
    float seed;
    float4 color1;
    float4 color2;
    float octaves;
};

// --- funcoes auxiliares do efeito
static float random (in float2 st) {
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
            // Loop of u.octaves
            for (int i = 0; i < octaveCount; i++) {
                value += amplitude * noise(st);
                st *= 2.0;
                st += parallax;
                amplitude *= intens;
            }
            return value;
        }

fragment float4 fx_toji_clouds3(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_clouds3Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float2 st = in.acLayerNorm;
            st.x *= eng.acLayerSize.x/eng.acLayerSize.y;

            st += u.offs*float2(-1.,1.)/500.; //float2(offsx,offsy);

            st += __nv_mod(float2(821.921*u.seed,437.317*u.seed), float2(4.365,7.701));

            float2 parallax = u.parr*float2(-1.,1.)/100.; //float2(parrx, parry);

            float2 scaleVec;
            scaleVec = float2(u.scale*u.stretch.x,u.scale*u.stretch.y);
            
            float4 rcolor = mix(u.color1,u.color2,fbm( (st-float2(0.5,0.5))*3.0/scaleVec+float2(0.5,0.5), parallax, int(u.octaves), u.intensity));

            rcolor *= texColor.a;

            __nv_out = rcolor + texColor*(1.0-rcolor.a);
    return __nv_out;
}
