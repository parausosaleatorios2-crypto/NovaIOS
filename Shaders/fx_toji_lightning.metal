// ---------------------------------------------------------------------------
// @am:string/effect_lightning_name
// origem : assets/effects/toji-lightning.xml
// id     : com.alightcreative.effects.lightning
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_lightningParams {
    float2 start;
    float2 end;
    float evolution;
    float seed;
    float4 color1;
    float4 color2;
    float4 color3;
    float limit;
    float intensity;
    float glow;
    float core;
    float alpha;
    float count;
    float octaves;
    int smooth;
    int blendMode;
};

// --- funcoes auxiliares do efeito
static float sdLine( in float2 p, in float2 a, in float2 b )
        {
            float2 pa = p-a, ba = b-a;
            float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
            return length( pa - ba*h );
        }

        float2 projectAndClamp(float2 a, float2 b) {
            return clamp(dot(a,b)/dot(b,b),0.0,1.0) * b;
        }

        // 2D Random
        float random (float2 st) {
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

            // Interpolation
            float2 u;
            if(u.smooth){
                // Cubic Hermine Curve.  Same as SmoothStep()
                //u = f*f*(3.0-2.0*f);
                u = smoothstep(0., 1., f);
            } else {
                // Jagged noise for lightning
                u = f;
            }

            // Mix 4 coorners percentages
            return mix(a, b, u.x) +
                    (c - a)* u.y * (1.0 - u.x) +
                    (d - b) * u.x * u.y;
        }

        //float xnoise(float2 st) {
        //    float n = noise(st);
        //    n = abs(n);
        //    n = 0.9-n;
        //    n = n*n;
        //    n = __nv_mod(n, 1.) * 2. - 1.;
        //    return n;
        //}

        float fractNoise (float2 st, int u.octaves) {
            st *= 4.;
            float result = noise(st);
            if ( u.octaves >= 2 )
                result += noise(st*2.)*0.5;
            if ( u.octaves >= 3 )
                result += noise(st*4.)*0.3;
            if ( u.octaves >= 4 )
                result += noise(st*8.)*0.2;
            if ( u.octaves >= 5 )
                result += noise(st*16.)*0.1;
            return result;
        }


        float2 l2s( float2 v, float4x4 eng.acLTS ) {
            return (float4(v,0.,1.)*eng.acLTS).xy;
        }

        float3 lightning( float2 st, float2 a, float2 b, float scale, float u.seed, float width, float u.limit ) {

            float2 ab = b - a;
            float2 n = normalize(ab).yx;
            n.y *= -1.;

            float2 p = projectAndClamp(st-a, ab)+a;
            float t = distance(p,a)/distance(b,a);
            float f = smoothstep(0.,0.5,0.5-abs(t-0.5));

            st += n*(fractNoise(float2(t,u.seed),int(u.octaves))-1.)* scale * 0.3 * length(ab)*f;

            //float c = sdLine(st,a,b);
            float c = length(st - p);
            float l = smoothstep(clamp(u.limit,0.,0.5)-0.5, .5, abs(0.5-t));
            float xl = clamp(u.limit-0.5, 0., 1.);
            l = l * (1. - xl) + xl;
            return float3(smoothstep(0.006*width*u.core,0.,c),smoothstep(0.034*width,-0.032,c),smoothstep(0.034*width*u.glow,0.,c)) * l;
        }

fragment float4 fx_toji_lightning(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_lightningParams&  u    [[buffer(1)]],
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

            float3 lcolor = float3(0.);

            float adjseed = __nv_mod(258.35 + 42.78*u.seed, 138.971);
            float w = 0.1;
            float slimit = 0.2;

            float2 a = u.start / 1000.;
            float2 b = u.end / 1000.;

            a.y *= -1.;
            b.y *= -1.;

            int icount = int(u.count);
            for( int i=0; i<icount; i++ ) {
                w += 0.2;
                slimit += 7.4;
                adjseed = __nv_mod(adjseed * sin(adjseed+1.2)+4.3, 45.32);
                lcolor += lightning(st,a,b, 1., u.evolution+adjseed, pow((noise(float2(w,u.evolution))+1.)/2.,1.584), pow((noise(float2(slimit,u.evolution))*u.limit+1.)/2.584,1.584)) * u.intensity;
            }

            //if( tint.r >= tint.g && tint.g >= tint.b ) {
            //} else if( tint.r >= tint.b && tint.b >= tint.g ) {
            //}

            //float4 color = float4(lcolor,max(max(lcolor.r,lcolor.g),lcolor.b));

            float4 color = ((u.color1 * lcolor.r) + (u.color2 * lcolor.g) + (u.color3 * lcolor.b)) / 3.;  // max(1., lcolor.r + lcolor.g + lcolor.b);

            color *= u.alpha;

            float4 result;
            if( u.blendMode==0 ) {                // normal
                color *= texColor.a;
                result = color + (texColor*(1.0-color.a));
            } else if( u.blendMode==1 ) {         // multiply
                float4 c = color + float4(1.)*(1.-color.a);
                result = float4((texColor.rgb/texColor.a)*c.rgb,1.0) * texColor.a;
            } else if( u.blendMode==2 ) {         // screen
                result = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-color.rgb)),1.0) * texColor.a;
            //} else if( u.blendMode==3 ) {         // overflow
            //    result = color;
            } else if( u.blendMode==4 ) {         // punchout
                result = texColor * (1.0-color.a);
            } else if( u.blendMode==6 ) {         // sourceonly
                result = color;
            } else if( u.blendMode==5 ) {         // overlay
                float3 top = color.rgb / color.a;
                float3 bot = texColor.rgb / texColor.a;
                float3 t = smoothstep(0.5,0.5,bot);
                float3 r3 =
                        t * (1. - (1.-2.*(bot-0.5)) * (1.-top)) +
                        (1.-t) * ((2.*bot) * top);
                float4 r4 = float4(r3, 1.0) * color.a * texColor.a;
                result = texColor * (1.-r4.a) + r4;
            }

            __nv_out = result;
    return __nv_out;
}
