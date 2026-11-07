// ---------------------------------------------------------------------------
// @string/name
// origem : assets/effects/toji-fractalwarp.xml
// id     : com.alightcreative.effects.fractalwarp
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_fractalwarpParams {
    float GAIN;
    float LACUNARITY;
    float AMP;
    float SPEED;
    float FREQ;
    float LUMA;
};

// --- funcoes auxiliares do efeito
static float random (in float2 st) {
            return fract(sin(dot(st.xy,
                                 float2(12.9898,78.233)))
                         * 43758.5453123);
        }

        // 2D Noise based on Morgan McGuire @morgan3d
        // https://www.shadertoy.com/view/4dS3Wd
        float noise (float2 st) {
            float2 i = floor(st);
            float2 f = fract(st);

            // Four corners in 2D of a tile
            float a = random(i);
            float b = random(i + float2(1.0, 0.0));
            float c = random(i + float2(0.0, 1.0));
            float d = random(i + float2(1.0, 1.0));

            // Smooth Interpolation

            // Cubic Hermine Curve.  Same as SmoothStep()
            float2 u = f*f*(3.0-2.0*f);
            // u = smoothstep(0.,1.,f);

            // Mix 4 coorners porcentages
            return mix(a, b, u.x) +
                    (c - a)* u.y * (1.0 - u.x) +
                    (d - b) * u.x * u.y;
        }

        #define OCTAVES 4
        //#define u.GAIN 0.452
        //#define u.LACUNARITY 4.012

        float fbm(float2 st) {
            float luma = u.LUMA;
            float amplitude = u.AMP;
            float frequency = u.FREQ;
            for (int i = 0; i < OCTAVES; i++) {
                luma += amplitude * noise(frequency*st);
                frequency *= u.LACUNARITY;
                amplitude *= u.GAIN;
            }
            return luma;
        }

fragment float4 fx_toji_fractalwarp(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_fractalwarpParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            //float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            //if( texColor.a <= 0.0001 )
            //    discard_fragment();

            // --- Shader -------------------------------------
            float t = eng.acTime * u.SPEED;

            float2 st = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
            st.y*=eng.acLayerSize.y/eng.acLayerSize.x;

            float2 qq = float2(st.y * sin(st.x*18.280+t*2.),
                           st.x * sin(st.y*4.+t*1.));
            float2 vv = float2(st.y * sin(st.x*18.280+qq.x*2.),
                           st.x * sin(st.y*4.+qq.y*1.));

            qq = float2(st.y + t*.1,
                           st.x + t*.2);
            vv = float2(st.x*fbm(qq*2.1),st.y*fbm(qq*3.4));

            //vv = st;
            //float aa = fbm(vv*3.1);
            //float bb = fbm(vv);
            //float cc = fbm(vv*.4);

            __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm.xy + vv);
    return __nv_out;
}
