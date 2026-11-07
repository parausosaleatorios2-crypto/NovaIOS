// ---------------------------------------------------------------------------
// @am:string/effect_starfield_name
// origem : assets/effects/toji-starfield2.xml
// id     : com.alightcreative.effects.starfield2
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_starfield2Params {
    float2 offset;
    float zoom;
    float moblur;
    float brightness;
    float darkmatter;
};

// --- funcoes auxiliares do efeito
#define iterations 14
        #define formuparam 0.53

        #define volsteps 16
        #define stepsize 0.1

        //#define u.zoom   0.300
        #define tile   0.850
        //#define speed  0.010

        //#define u.brightness 0.0015
        //#define u.darkmatter 0.300
        #define distfading 0.730
        #define saturation 0.450

        static float hash(float2 p) {
            return fract(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
        }

fragment float4 fx_toji_starfield2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_starfield2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            if( texColor.a <= 0.0001 )
                discard_fragment();

            // --- Inputs ------------------------------------
            float2 fragCoord = __nv_fragCoord.xy;
            float2 iResolution = eng.acScreenSize;
            float iTime = eng.acTime;
            float2 iMouse = float2(.5,.5);

            // --- Shader -------------------------------------

            //get coords and direction

            float2 uv = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
            uv.y*=eng.acLayerSize.y/eng.acLayerSize.x;
            //float2 uv=fragCoord.xy/iResolution.xy-.5;
            //uv.y*=iResolution.y/iResolution.x;

            float3 dir=float3(uv*u.zoom,1.);
            //float time=iTime*speed+.25;

            //mouse rotation
            float a1=.5+iMouse.x/iResolution.x*2.;
            float a2=.8+iMouse.y/iResolution.y*2.;
            float2x2 rot1=float2x2(cos(a1),sin(a1),-sin(a1),cos(a1));
            float2x2 rot2=float2x2(cos(a2),sin(a2),-sin(a2),cos(a2));
            dir.xz*=rot1;
            dir.xy*=rot2;
            float3 from=float3(1.,.5,0.5);
            
            // Motion Blur jitter based on eng.acVelocity
            // We scale eng.acVelocity to match the scale of the starfield u.offset
            float2 velocity = eng.acVelocity * u.moblur / 1000.0;
            float jitter = hash(uv + iTime) - 0.5;
            float2 blurOffset = -u.offset / 1000.0 + velocity * jitter;

            from+=float3(blurOffset,-2.);
            from.xz*=rot1;
            from.xy*=rot2;

            //volumetric rendering
            float s=0.1,fade=1.;
            float3 v=float3(0.);
            //float3 rgb = userColor.rgb;
            for (int r=0; r<volsteps; r++) {
                float3 p=from+s*dir*.5;
                p = abs(float3(tile)-__nv_mod(p, float3(tile*2.))); // tiling fold
                float pa,a=pa=0.;
                for (int i=0; i<iterations; i++) {
                    p=abs(p)/dot(p,p)-formuparam; // the magic formula
                    a+=abs(length(p)-pa); // absolute sum of average change
                    pa=length(p);
                }
                float dm=max(0.,u.darkmatter-a*a*.001); //dark matter
                a*=a*a; // add contrast
                if (r>6) fade*=1.-dm; // dark matter, don't render near
                //v+=float3(dm,dm*.5,0.);
                v+=fade;
                //v+=float3(pow(s,1. + rgb.r*3.),pow(s,1. + rgb.g*3.),pow(s,1. + rgb.b*3.))*a*u.brightness*fade; // coloring based on distance
                v+=float3(s,s*s,s*s*s*s)*a*u.brightness*fade; // coloring based on distance
                fade*=distfading; // distance fading
                s+=stepsize;
            }
            v=mix(float3(0.,v.g,length(v)),v,saturation); //color adjust
            __nv_out = float4(v*.01,1.);
    return __nv_out;
}
