// ---------------------------------------------------------------------------
// @string/name
// origem : assets/effects/toji-fractalwarp2.xml
// id     : com.alightcreative.effects.fractalwarp2
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_fractalwarp2Params {
    float mag;
    float offsx;
    float offsy;
    float parrx;
    float parry;
    float octaves;
    float intensity;
    float scale;
    int screenSpace;
};

// --- funcoes auxiliares do efeito
static float random (in float2 st) {
            return fract(sin(dot(st.xy,
                                 float2(12.9898,78.233)))*
                43758.5453123);
        }

        // Based on Morgan McGuire @morgan3d
        // https://www.shadertoy.com/view/4dS3Wd
        static float noise (float2 st) {
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

        static float fbm (float2 st, float2 parallax, int octaveCount, float intens) {
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

fragment float4 fx_toji_fractalwarp2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_fractalwarp2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            float2 st;
            if( u.screenSpace ) {
                st = in.acScreenNorm;
                st.x *= eng.acScreenSize.x/eng.acScreenSize.y;
            } else {
                st = in.acLayerNorm;
                st.x *= eng.acLayerSize.x/eng.acLayerSize.y;
            }

            st += float2(u.offsx,u.offsy);

            float2 parallax = float2(u.parrx, u.parry);

            float dx = fbm( (st-float2(0.5,0.5))*3.0*u.scale+float2(0.5,0.5), parallax, int(u.octaves), u.intensity);
            float dy = fbm( ((st+float2(25.3,12.9))-float2(0.5,0.5))*3.0*u.scale+float2(0.5,0.5), parallax, int(u.octaves), u.intensity);

            float2 sample;
            if( u.screenSpace ) {
                sample = in.acScreenNorm;
            } else {
                sample = in.acLayerNorm;
            }
            sample = sample + float2(dx-0.5,dy-0.5) * u.mag;

            if( !u.screenSpace ) {
                sample = (float4(sample,0.0,1.0) * eng.acLayerToScreen).st;
            }

            float4 texColor = inputImg.sample(__nv_smp, sample);

            __nv_out = texColor;

            //float4 rcolor = mix(color1,color2,);
            //rcolor *= texColor.a;
            //__nv_out = rcolor + texColor*(1.0-rcolor.a);
    return __nv_out;
}
