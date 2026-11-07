// ---------------------------------------------------------------------------
// @am:string/effect_color_balance_name
// origem : assets/effects/toji-colorbalance.xml
// id     : com.alightcreative.effects.colorbalance
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_colorbalanceParams {
    float crLow;
    float mgLow;
    float ybLow;
    float crMid;
    float mgMid;
    float ybMid;
    float crHigh;
    float mgHigh;
    float ybHigh;
    int fixLum;
};

fragment float4 fx_toji_colorbalance(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_colorbalanceParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float3x3 rgb2yuv = float3x3(
                 0.299,     0.587,    0.114,
                -0.14713,  -0.28886,  0.436,
                 0.615,    -0.51499, -0.10001
            );
            float3x3 yuv2rgb = float3x3(
                1.0,  0.0,      1.13983,
                1.0, -0.39465, -0.58060,
                1.0,  2.03211,  0.0
            );
            
            float4 baseColor = inputImg.sample(__nv_smp, in.acScreenNorm.st);
            float3 yuv = baseColor.rgb*rgb2yuv;
            
            float low = (1.0 - smoothstep(0.222, 0.444, yuv.x));
            float midLow = smoothstep(0.222, 0.444, yuv.x)*step(yuv.x, 0.555);
            float midHigh = (1.0-smoothstep(0.555, 0.777, yuv.x))*step(0.555, yuv.x) * step(yuv.x, 0.777);
            float high = smoothstep(0.555, 0.777, yuv.x);
            float3 filter = float3(u.crLow, u.mgLow, u.ybLow) * low + float3(u.crMid, u.mgMid, u.ybMid)*(midLow+midHigh)+float3(u.crHigh, u.mgHigh, u.ybHigh)*high;
            filter = max(min(filter, 100.0), -100.0);
            float3 conv = (filter+float3(100.0))/100.0;
            float3 converted = baseColor.rgb*conv;
            float3 convYuv = converted*rgb2yuv;
            if(u.fixLum) convYuv.x = yuv.x;
            float4 outColor = float4(convYuv*yuv2rgb, baseColor.a);
            __nv_out = outColor;
    return __nv_out;
}
