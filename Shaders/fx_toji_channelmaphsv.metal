// ---------------------------------------------------------------------------
// @am:string/effect_channelmaphsv_name
// origem : assets/effects/toji-channelmaphsv.xml
// id     : com.alightcreative.effects.channelmaphsv
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_channelmaphsvParams {
    int hue;
    int sat;
    int val;
    int alpha;
};

// --- funcoes auxiliares do efeito
const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);

        float3 hsv2rgb(float3 c)
        {
            float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
            float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
            return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
        }

        float3 rgb2hsv(float3 c)
        {
            float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
            float4 p = mix(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
            float4 q = mix(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

            float d = q.x - min(q.w, q.y);
            float e = 1.0e-10;
            return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
        }

fragment float4 fx_toji_channelmaphsv(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_channelmaphsvParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);

            float luminance = dot(texColor.rgb, luminanceWeighting);

            float2 s = step(float2(0.,0.), in.acLayerNorm) - step(float2(1.,1.), in.acLayerNorm);
            float maskFactor = s.x * s.y;

            float4 outColor = float4(0.0);

            if( texColor.a > 0.0 )
                texColor.rgb /= texColor.a;

            texColor.rgb = rgb2hsv(texColor.rgb);

            if( u.hue==0 ) {
                outColor.r = texColor.r;
            } else if( u.hue==1 ) {
                outColor.r = texColor.g;
            } else if( u.hue==2 ) {
                outColor.r = texColor.b;
            } else if( u.hue==3 ) {
                outColor.r = texColor.a;
            } else if( u.hue==4 ) {
                outColor.r = luminance;
            } else if( u.hue==5 ) {
                outColor.r = 0.0;
            } else {
                outColor.r = 1.0;
            }

            if( u.sat==0 ) {
                outColor.g = texColor.r;
            } else if( u.sat==1 ) {
                outColor.g = texColor.g;
            } else if( u.sat==2 ) {
                outColor.g = texColor.b;
            } else if( u.sat==3 ) {
                outColor.g = texColor.a;
            } else if( u.sat==4 ) {
                outColor.g = luminance;
            } else if( u.sat==5 ) {
                outColor.g = 0.0;
            } else {
                outColor.g = 1.0;
            }

            if( u.val==0 ) {
                outColor.b = texColor.r;
            } else if( u.val==1 ) {
                outColor.b = texColor.g;
            } else if( u.val==2 ) {
                outColor.b = texColor.b;
            } else if( u.val==3 ) {
                outColor.b = texColor.a;
            } else if( u.val==4 ) {
                outColor.b = luminance;
            } else if( u.val==5 ) {
                outColor.b = 0.0;
            } else {
                outColor.b = 1.0;
            }

            if( u.alpha==0 ) {
                outColor.a = texColor.r;
            } else if( u.alpha==1 ) {
                outColor.a = texColor.g;
            } else if( u.alpha==2 ) {
                outColor.a = texColor.b;
            } else if( u.alpha==3 ) {
                outColor.a = texColor.a;
            } else if( u.alpha==4 ) {
                outColor.a = luminance;
            } else if( u.alpha==5 ) {
                outColor.a = 0.0;
            } else {
                outColor.a = 1.0;
            }

            outColor.rgb = hsv2rgb(outColor.rgb);

            outColor.rgb *= outColor.a;

            __nv_out = outColor * maskFactor;
    return __nv_out;
}
