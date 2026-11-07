// ---------------------------------------------------------------------------
// @am:string/effect_volumetricclouds_name
// origem : assets/effects/toji-volumetric-clouds.xml
// id     : com.alightcreative.effects.volumetricclouds
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_volumetric_cloudsParams {
    float3 camera;
    float densityParam;
    float seed;
    float4 shadowColor;
    float4 lightColor;
    float fill;
};

// --- funcoes auxiliares do efeito
#define STEPS 50

        float noise( in float3 x )
        {
            float3 p = floor(x);
            float3 f = fract(x);
            f = f*f*(3.0-2.0*f);
            float2 uv = (p.xy+float2(37.0,17.0)*p.z) + f.xy;
            uv = (uv+0.5)/256.0;
            float2 rg = rgbanoise.sample(__nv_smp, uv).yx;
            return mix( rg.x, rg.y, f.z );
        }

		float fbm( float3 p ) {
            return noise(p)/2.
                + noise(p*2.)/4.
                + noise(p*4.)/8.
                + noise(p*8.)/16.
                ;
        }

        float4 comp( float4 bg, float4 fg ) {
            return bg * (1.-fg.a) + fg;
        }

        float calcDensity(float3 p) {
            //p.y *= 1.;
            float density = max(0.,fbm(p) - u.densityParam);
            return density;
        }

fragment float4 fx_toji_volumetric_clouds(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_volumetric_cloudsParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> rgbanoise [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& rgbanoise_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float2 st = in.acLayerNorm;
            st -= 0.5;
            st.x *= eng.acLayerSize.x/eng.acLayerSize.y;

            float3 ro = u.camera/100.;
            float3 rd = normalize(float3(st, 1.));

            float3 dd = rd / float(STEPS) * 6.;

            float4 color = float4(0.);

            float3 light = float3(20.0,120.0,-200.5);
            float radius = 1.464;

            for( int i=0; i<STEPS; i++ ) {
                float3 p = ro + dd * float(i);
                float3 lightDir = normalize(light-p);
                float t = 1.-float(i)/float(STEPS);
                float density = calcDensity(p);
                float lightGrad = density - calcDensity(p+lightDir*dd);
                float4 c = mix(u.lightColor,u.shadowColor,lightGrad*6. - u.densityParam);
                //float4 c = u.lightColor;
                density *= smoothstep(0.2,0.50,t);
                color = comp(c*density,color);
            }

            __nv_out = comp(texColor * u.fill,color * texColor.a);
    return __nv_out;
}
