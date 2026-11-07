// ---------------------------------------------------------------------------
// @am:string/effect_fill_behind_name
// origem : assets/effects/toji-fillbehind.xml
// id     : com.alightcreative.effects.fillbehind
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_fillbehindParams {
    float strength;
    float feather;
    float saturation;
    float brightness;
    float gamma;
    float alpha;
    float fgAlpha;
    float4 tintColor;
    float tintStrength;
    float4 edgeColor;
    float edgeStrength;
    float scanLines;
    float scanLineCount;
    float2 fgOffset;
    float fgScale;
    float2 bgOffset;
    float bgScale;
};

// --- funcoes auxiliares do efeito
const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);
        
        static float4 composite( float4 a, float4 b) {
            return a * (1. - b.a) + b;
        }
        
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
        
        static float maxComponent( float2 v ) {
            return max(v.x,v.y);
        }

fragment float4 fx_toji_fillbehind(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_fillbehindParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> blurBuf [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& blurBuf_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

        
            float l2sScale = length(float4(1.,0.,0.,0.) * eng.acLayerToScreen);
            //float2 stretchToScreen = eng.acScreenSize/eng.acLayerSize * (1. + u.strength) / l2sScale;
            //stretchToScreen = normalize((float4(1., 1.,0.,0.)*eng.acLayerToScreen).xy)/l2sScale;
            float2 stretchToScreenA = (1.+u.strength) / (abs(float4(1., 1.,0.,0.)*eng.acLayerToScreen).xy);
            float2 stretchToScreenB = (1.+u.strength) / (abs(float4(-1., -1.,0.,0.)*eng.acLayerToScreen).xy);
            float2 stretchToScreenC = (1.+u.strength) / (abs(float4(1., -1.,0.,0.)*eng.acLayerToScreen).xy);
            float2 stretchToScreenD = (1.+u.strength) / (abs(float4(-1., 1.,0.,0.)*eng.acLayerToScreen).xy);
            float fillScreenScale = max(max(maxComponent(stretchToScreenA),maxComponent(stretchToScreenB)), max(maxComponent(stretchToScreenC),maxComponent(stretchToScreenD)));
            
            float2 stFG = (in.acScreenNorm - 0.5) / u.fgScale + 0.5 - u.fgOffset/500.*float2(1.,-1.);
            float2 stBG = (in.acScreenNorm - 0.5) / u.bgScale + 0.5 - u.bgOffset/500.*float2(1.,-1.);

            float insideFG = step(0.,stFG.x) * step(stFG.x,1.) * step(0.,stFG.y) * step(stFG.y,1.);
            
            float4 texColor = inputImg.sample(__nv_smp, stFG) * insideFG;
            float blurAlpha = blurBuf.sample(__nv_smp, stFG).a;
            float4 blurTexColor = blurBuf.sample(__nv_smp, (stBG-0.5)/fillScreenScale + eng.acLayerCenterNorm);
            
            float3 tintYuv = u.tintColor.rgb * rgb2yuv;
            
            float3 rgb = blurTexColor.rgb / blurTexColor.a;
            float3 yuv = rgb * rgb2yuv;
            yuv.yz = yuv.yz * (u.saturation+1.0);
            yuv.yz = mix(yuv.yz,tintYuv.yz,u.tintStrength);
            rgb = yuv * yuv2rgb;
            rgb = clamp(pow(rgb,float3(1.0/u.gamma)) + float3(u.brightness),0.,1.);
            float4 adjBlurColor = float4(rgb,1.) * blurTexColor.a;
            
            adjBlurColor.rgb *= 1. - (u.scanLines * cos(in.acScreenNorm.y*u.scanLineCount));
            
            float fa = u.feather < 0.0005 ? 1.0 : smoothstep(0.4999,0.5+min(0.999,u.feather/u.strength)*0.5,blurAlpha);
            
            
            __nv_out = composite(adjBlurColor*u.alpha,composite(u.edgeColor*blurAlpha*2.*u.edgeStrength,texColor*fa)*u.fgAlpha);
    return __nv_out;
}
