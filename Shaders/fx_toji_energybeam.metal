// ---------------------------------------------------------------------------
// @am:string/effect_energy_beam_name
// origem : assets/effects/toji-energybeam.xml
// id     : com.alightcreative.effects.energybeam
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_energybeamParams {
    float2 start;
    float2 end;
    float4 color1;
    float4 color2;
    float spread;
    float alpha;
    float glowAlpha;
    float haloAlpha;
    float haloSpread;
    float4 color3;
    float clip;
    float progress;
    float blur;
    int blendMode;
    float fstr;
    float freq;
    float vstr;
    float vfreq;
    float vphase;
    float randness;
    float evolution;
};

// --- funcoes auxiliares do efeito
// 2D Random
        static float random (float2 st) {
            return fract(sin(dot(st.xy,
                                 float2(12.9898,78.233)))
                         * 43758.5453123);
        }

        // 2D Noise based on Morgan McGuire @morgan3d
        // https://www.shadertoy.com/view/4dS3Wd
        static float noise (float2 st) {
            float2 i = floor(st);
            float2 f = fract(st);

            // Four corners in 2D of a tile
            float a = random(i);
            float b = random(i + float2(1.0, 0.0));
            float c = random(i + float2(0.0, 1.0));
            float d = random(i + float2(1.0, 1.0));

            // Interpolation
            float2 u = smoothstep(0., 1., f);

            // Mix 4 coorners percentages
            return mix(a, b, u.x) +
                    (c - a)* u.y * (1.0 - u.x) +
                    (d - b) * u.x * u.y;
        }


        static float sdSegment( in float2 p, in float2 a, in float2 b )
        {
            float2 pa = p-a, ba = b-a;
            float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
            return length( pa - ba*h );
        }

        static float4 colorForPhase( float2 st, float phase, float2 a, float2 v ) {
        
            float low = 0.5 + phase - u.clip/2.0;
            float high = low + u.clip;
            float2 aa = a + v*saturate(low);
            float2 bb = a + v*saturate(high);
            
            float dist = dot(st-a,v)/length(v);

            float p = min(sdSegment(st,aa,bb),0.5);

            p += saturate(0.-high);
            p += saturate(low-1.);
            
            float variation = 1. + (sin(dist*u.vfreq*3.14159+u.vphase)*u.vstr);
            
            if( u.randness > 0.0 ) {
                float v2 = 1. + (noise(float2(dist*u.vfreq*2. + u.vphase, u.evolution*17.956))-0.5)*u.vstr*2.;
                variation = mix(variation,v2,u.randness);
            }
            
            float falloff = (max(0.0001,51.-u.spread));
            float haloFalloff = (max(0.0001,51.-u.haloSpread));

            float h = pow((1.-abs(pow(1.-p,haloFalloff)-0.5))*0.5,2.232)*2.5*u.haloAlpha;
            float sf = sin(u.freq*eng.acTime*3.14159);
            
            float ga = u.glowAlpha * (1. + sf*u.fstr);
            float ca = 1. + sf*u.fstr*0.5;
            float f2 = pow(falloff,1.5);

            float4 color = float4(pow(float3(pow(1.-clamp(p*variation,0.0001,0.5),f2)),1./u.color1.rgb)*ca + (pow(float3(pow(1.-clamp(p,0.0001,0.5),f2/5.)),1./u.color2.rgb)*ga) + (h*u.color3.rgb), 1.);

            color *= u.alpha;
            
            return clamp(color,0.0,1.0); 

        }

fragment float4 fx_toji_energybeam(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_energybeamParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float2 st = in.acLayerNorm;
            st -= 0.5;
            st.x *= eng.acLayerSize.x/eng.acLayerSize.y;
            st.y *= -1.;

            float2 a = u.start / 1000.;
            float2 b = u.end / 1000.;
            float2 v = b-a;
            
            float toffs = (u.progress-0.5)*2.;
            
            float4 color;
            if( u.blur <= 0. ) {
                color = colorForPhase(st,toffs,a,v);
            } else {
                color = float4(0.);
                int steps = 20;
                for( int i = 1; i<=steps; i++ ) {
                    float d = float(i)*u.blur*0.01;
                    color += saturate(colorForPhase(st,toffs+d,a,v));
                    color += saturate(colorForPhase(st,toffs-d,a,v));
                }
                color /= float(steps)*2.;
            }

            float4 result;
            if( u.blendMode==0 ) {                // normal
                color *= texColor.a;
                result = color + (texColor*(1.0-color.a));
            } else if( u.blendMode==1 ) {         // multiply
                float4 c = color + float4(1.)*(1.-color.a);
                result = float4((texColor.rgb/texColor.a)*c.rgb,1.0) * texColor.a;
            } else if( u.blendMode==2 ) {         // screen
                result = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-color.rgb)),1.0) * texColor.a;
            }

            __nv_out = result;
    return __nv_out;
}
