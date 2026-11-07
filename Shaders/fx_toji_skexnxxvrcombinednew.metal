// ---------------------------------------------------------------------------
// @am:string/effect_vrcombined_name
// origem : assets/effects/toji-skexnxxvrcombinednew.xml
// id     : com.alightcreative.effects.vrcombinednew
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxvrcombinednewParams {
    float4 orient;
    float3 rotate;
    int flatten;
    float dist;
    float w;
    float h;
};

// --- funcoes auxiliares do efeito
static float4x4 rotationAxisAngle( float3 v, float angle )
        {
            float s = sin( angle );
            float c = cos( angle );
            float ic = 1.0 - c;

            return float4x4( v.x*v.x*ic + c,     v.y*v.x*ic - s*v.z, v.z*v.x*ic + s*v.y, 0.0,
                         v.x*v.y*ic + s*v.z, v.y*v.y*ic + c,     v.z*v.y*ic - s*v.x, 0.0,
                         v.x*v.z*ic - s*v.y, v.y*v.z*ic + s*v.x, v.z*v.z*ic + c,     0.0,
                         0.0,                0.0,                0.0,                1.0 );
        }

        float2 l2s( float2 v ) {
            return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
        }

        #define M_PI 3.14159265358979323846

        #define DEG2RAD 0.01745329251994329576923690768489

        float hfovDegrees = 120.0;
        float vfovDegrees = 60.0;

fragment float4 fx_toji_skexnxxvrcombinednew(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxvrcombinednewParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            float2 st = in.acLayerNorm;
            if(u.flatten == false)
            {
                float lon = st.x * M_PI * 2.0;
                float lat = asin((st.y - 0.5) * 2.0);
                float3 xyz = float3(cos(lon)*cos(lat), sin(lon)*cos(lat), sin(lat));

                float3 r = u.rotate * 0.0174533;
                float4x4 rx = rotationAxisAngle(float3(1.,0.,0.),r.x);
                float4x4 ry = rotationAxisAngle(float3(0.,1.,0.),r.y);
                float4x4 rz = rotationAxisAngle(float3(0.,0.,1.),r.z);

                xyz = (float4(xyz,0.) * u.orient * rz * rx * ry).xyz;
                lat = asin(xyz.z);
                lon = __nv_atan(xyz.y, xyz.x);
                if(lon < 0.0)
                    lon += (2.0 * M_PI);

                float2 conv_uv = float2(lon/(M_PI*2.0), sin(lat)/2.0 + 0.5);
                float inside = step(0.,st.x) * step(st.x,1.) * step(0.,st.y) * step(st.y,1.);
                __nv_out = inputImg.sample(__nv_smp, l2s(conv_uv)) * inside;
            }
            else
            {
                float2 uv = st.xy * 2.0 - 1.0;

                //to spherical
                float3 camDir = normalize(float3(uv.xy * float2(tan(0.5 * hfovDegrees * DEG2RAD), tan(0.5 * vfovDegrees * DEG2RAD)), 1.0 / u.dist));

                float3 r = u.rotate * 0.0174533;
                float4x4 rx = rotationAxisAngle(float3(1.,0.,0.),r.x);
                float4x4 ry = rotationAxisAngle(float3(0.,1.,0.),r.y);
                float4x4 rz = rotationAxisAngle(float3(0.,0.,1.),r.z);

                float3 rd = (float4(camDir,0.) * u.orient * rz * rx * ry).xyz;

                float2 cutting = float2(0.0, 0.0);
                float2 imgSize = __nv_getTexSize(inputImg_info.size);
                float asp_i = imgSize.y / imgSize.x;
                float asp_o = u.h / u.w;

                if(asp_i > asp_o)
                {
                    cutting.x = 0.0;
                    cutting.y = 0.5 * (1.0 -  asp_o / asp_i);
                }
                else
                {
                    cutting.y = 0.0;
                    cutting.x = 0.5 * (1.0 - (asp_i / asp_o));
                }

                //radial azmuth polar
                float2 conv_uv = float2(__nv_atan(rd.z, rd.x) + M_PI, acos(-rd.y)) / float2(2.0 * M_PI, M_PI);
                float inside = step(cutting.x,st.x) * step(st.x,1.0 - cutting.x) * step(cutting.y,st.y) * step(st.y,1.0 - cutting.y);
                __nv_out = inputImg.sample(__nv_smp, l2s(conv_uv)) * inside;
            }
    return __nv_out;
}
