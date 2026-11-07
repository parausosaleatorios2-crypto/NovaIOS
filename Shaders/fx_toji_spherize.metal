// ---------------------------------------------------------------------------
// @am:string/effect_spherize_name
// origem : assets/effects/toji-spherize.xml
// id     : com.alightcreative.effects.spherize
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_spherizeParams {
    float4 orient;
    float repeatx;
    float repeaty;
    int mirror;
    float zdist;
    int enableLight;
    float lightIntensity;
    float4 lightColor;
    float2 lightDir;
    float lightDepth;
};

// --- funcoes auxiliares do efeito
float2 l2s( float2 v ) {
            return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
        }

fragment float4 fx_toji_spherize(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_spherizeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            float r = 1.;

            float2 st = in.acLayerNorm;
            st -= 0.5;
            st *= 2.0;
            st.x *= eng.acLayerSize.x/eng.acLayerSize.y;

            st = st * 10.0 / max(0.0001,u.zdist+10.0);

            float dist = length(st)/r;
            if( dist > 1. )
                discard_fragment();

            float height = sqrt(1.-dist*dist);
            float3 norm = normalize(float3(st,height));

            float3 light = normalize(float3(u.lightDir.x,-u.lightDir.y,u.lightDepth+u.zdist));
            //light = (float4(light,1.)*lightOrient).xyz;
            float lum = dot(norm,light);

            norm = normalize((float4(norm,1.) * u.orient).xyz);

            float2 uv = float2(
                0.5 + __nv_atan(norm.z, norm.x) / 6.2831853072,
                0.5 + asin(norm.y)/3.14159
            );

            uv.x *= u.repeatx;
            uv.y *= u.repeaty;

            if( u.mirror ) {
                uv.x = abs(__nv_mod(uv.x, 2.0)-1.0);
                uv.y = abs(__nv_mod(uv.y, 2.0)-1.0);
            } else {
                uv.x = __nv_mod(uv.x, 1.0);
                uv.y = __nv_mod(uv.y, 1.0);
            }

            uv.x = 1.0-uv.x;

            float pix = 1.0/min(eng.acLayerSize.x,eng.acLayerSize.y);

            uv -= 0.5;
            uv *= 1.0-(2.0*pix);
            uv += 0.5;

            float4 texColor = inputImg.sample(__nv_smp, l2s(uv));
            if( u.enableLight ) {
                texColor.rgb *= lum*u.lightIntensity*u.lightColor.rgb;
            }
            __nv_out = texColor;
    return __nv_out;
}
