// ---------------------------------------------------------------------------
// @am:string/effect_360viewer_name
// origem : assets/effects/toji-vr-player.xml
// id     : com.alightcreative.effects.vrplayer
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_vr_playerParams {
    float4 orient;
    float3 rotate;
    float dist;
    int aspectRatio;
    float scale;
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

fragment float4 fx_toji_vr_player(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_vr_playerParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            float2 st = (float2(1.0-in.acLayerNorm.x, in.acLayerNorm.y)-0.5) / u.scale + 0.5;

            float2 uv = st.xy * 2.0 - 1.0;

            //to spherical
            float3 camDir = normalize(float3(uv.xy * float2(tan(0.5 * hfovDegrees * DEG2RAD), tan(0.5 * vfovDegrees * DEG2RAD)), 1.0 / u.dist));

            float3 r = u.rotate * 0.0174533;
            float4x4 rx = rotationAxisAngle(float3(1.,0.,0.),r.x);
            float4x4 ry = rotationAxisAngle(float3(0.,1.,0.),r.y);
            float4x4 rz = rotationAxisAngle(float3(0.,0.,1.),r.z);

            float3 rd = (float4(camDir,0.) * u.orient * rz * rx * ry).xyz;

            float2 cutting = float2(0.0, 0.0);
            
            float inWidth = eng.acLayerSize.x;
            float inHeight = eng.acLayerSize.x;
            float width;
            float height;
            if( u.aspectRatio==0 ) {
                width = 16.0;
                height = 9.0;
            } else if( u.aspectRatio==1 ) {
                width = 4.0;
                height = 3.0;
            } else if( u.aspectRatio==2 ) {
                width = 1.0;
                height = 1.0;
            } else if( u.aspectRatio==3 ) {
                width = 3.0;
                height = 4.0;
            } else if( u.aspectRatio==4 ) {
                width = 4.0;
                height = 5.0;
            } else if( u.aspectRatio==5 ) {
                width = 9.0;
                height = 16.0;
            } else {
                width = 9.0;
                height = 16.0;
            }
            float fitHeight = height * inWidth / width;
            float fitWidth = width * inHeight / height;
            float2 clipDimens;
            if( fitHeight >= inHeight ) {
                clipDimens = float2(fitWidth,inHeight);
            } else {
                clipDimens = float2(inWidth,fitHeight);
            }
            clipDimens /= eng.acLayerSize;

            //radial azmuth polar
            float2 conv_uv = float2(__nv_atan(rd.z, rd.x) + M_PI, acos(-rd.y)) / float2(2.0 * M_PI, M_PI);
            conv_uv.x = clamp(conv_uv.x, 1.0 / eng.acLayerSize.x, 1.0 - 1.0 / eng.acLayerSize.x );
            conv_uv.y = clamp(conv_uv.y, 1.0 / eng.acLayerSize.y, 1.0 - 1.0 / eng.acLayerSize.y );
            float inside = step(-clipDimens.x,uv.x) * step(uv.x,clipDimens.x) * step(-clipDimens.y,uv.y) * step(uv.y,clipDimens.y);
            __nv_out = inputImg.sample(__nv_smp, l2s(conv_uv)) * inside;
    return __nv_out;
}
