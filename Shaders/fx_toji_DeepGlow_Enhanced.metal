// ---------------------------------------------------------------------------
// DeepGlow Enhanced
// origem : assets/effects/toji-DeepGlow_Enhanced.xml
// id     : com.alightcreative.effects.deepglow_enc
// passes : 2  (iterativo)
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_DeepGlow_EnhancedParams {
    int bmode;
    int overd;
    float strength;
    float oalpha;
    float lowThreshold;
    float highThreshold;
    float feather;
    float2 position;
    float2 stretch;
    float2 satvib;
    float hue;
    float calpha;
    int GCE;
    int CHROM;
    float strengthhh;
    float angleee;
    float2 OFT;
    int centerChannel;
    int cblend;
    int cmode;
    float4 colblend;
    float alpb;
    float iter;
};

// --- funcoes auxiliares do efeito
const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);

       static float2x2 rot2m(float a){ float s = sin(a); float c = cos(a); return float2x2(c, -s, s, c); }
               static float2 l2s( float2 v ) { return (float4(v,0.0,1.)*eng.acLayerToScreen).xy; }
    
       static float4 newLayer( float4 a, float4 b) { return a * (1. - b.a) + b; }
    
         static float blendScreen(float base, float blend) {
             return 1.0 - ((1.0 - base) * (1.0 - blend)); }
         
       static float3 blendScreen(float3 base, float3 blend) {
         return float3( blendScreen(base.r, blend.r), blendScreen(base.g, blend.g), blendScreen(base.b, blend.b) ); }

fragment float4 fx_toji_DeepGlow_Enhanced(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_DeepGlow_EnhancedParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> vblur [[texture(1)]],
    texture2d<float> hblur [[texture(2)]],
    texture2d<float> blurBuf [[texture(3)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& vblur_info [[buffer(3)]],
    constant NovaTexInfo& hblur_info [[buffer(4)]],
    constant NovaTexInfo& blurBuf_info [[buffer(5)]])
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
            float rad = u.hue * 0.0174533;
            float3x3 huemat = float3x3(
                1.0,  0.0,       0.0,
                0.0,  cos(rad),  sin(rad),
                0.0,  -sin(rad), cos(rad)
            );
            
            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm.st);
            
                    /// GLOW UV
                    float2 umefx = in.acScreenNorm.st;
                    umefx += float2((0.0+u.position.x), (0.0+u.position.y))*float2(-1.,1.)/500.;
                    
                    umefx.y -= (umefx.y - 0.5) * 0.7 * fract(u.stretch.y * 0.5); 
                    umefx.x -= (umefx.x - 0.5) * 0.7 * fract(u.stretch.x * 0.5); 

            float4 baseColor;
            float4 vColor;
            
            baseColor = inputImg.sample(__nv_smp, in.acScreenNorm.st)*u.calpha;
            vColor = vblur.sample(__nv_smp, in.acScreenNorm.st);
                        
            /////// CHROMATIC FX
            float raddd = u.angleee * 0.0174533;
            float adjStrength = u.strengthhh / 8.0;
            float2 offset = float2(cos(raddd)*adjStrength,-sin(raddd)*adjStrength);
            offset += float2((0.0+u.OFT.x), (0.0+u.OFT.y))*float2(-1.,1.)/500.;
            float2 sampleLow = (float4(in.acLayerNorm - offset,0.0,1.0) * eng.acLayerToScreen).xy;
            float2 sampleHigh = (float4(in.acLayerNorm + offset,0.0,1.0) * eng.acLayerToScreen).xy;
            float4 colorLow = vblur.sample(__nv_smp, sampleLow);
            float4 colorHigh = vblur.sample(__nv_smp, sampleHigh);
            
            float4 colorMid = vblur.sample(__nv_smp, umefx);
            // float4 colorMid = vblur.sample(__nv_smp, in.acScreenNorm);
            
            float4 outColor;
            if( u.centerChannel==0 ) {
                outColor = float4(colorMid.r,colorLow.g,colorHigh.b,1.0);
            } else if( u.centerChannel==1 ) {
                outColor = float4(colorLow.r,colorMid.g,colorHigh.b,1.0);
            } else {
                outColor = float4(colorLow.r,colorHigh.g,colorMid.b,1.0);
            }
            
            float4 compColorr;
            float4 gammaComp;
            
            compColorr = u.CHROM? float4(outColor.rgb,colorMid.a) :
                            vblur.sample(__nv_smp, umefx);
                         // blurBuf.sample(__nv_smp, umefx);

             //////////////////////////
            
            ///GAMMA CORRECTION
            float3 normCol = compColorr.rgb;
            float3 gamcor = pow(normCol, float3(1.0 / 2.2));
            float4 gamcorComp = float4(gamcor, compColorr.a);
            
            gammaComp = u.GCE? gamcorComp*compColorr.a : compColorr;
            
            ///SATVIB
            // float3 rgb = compColorr.rgb;
            float3 rgb = gammaComp.rgb;
            float3 yuv = rgb * rgb2yuv;
            yuv = yuv * huemat; //HUE
            float origSat = min(1.0,length(yuv.yz)*2.5); //
            float2 satUV = yuv.yz * u.satvib.y;
            yuv.yz = mix(satUV,yuv.yz,origSat);
            yuv.yz = yuv.yz * (u.satvib.x+1.0);
            rgb = yuv * yuv2rgb;
            // float4 satComp = float4(rgb, compColorr.a);
            float4 satComp = float4(rgb, gammaComp.a);
            ///////
            
            float4 dblur = float4(satComp.rgb / satComp.a, 1.0);
            
            float4 targetLuma = dblur ;
            const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);
            float luma = dot(targetLuma.rgb, luminanceWeighting);
            float lowThresholdB = (u.lowThreshold*(1.0+u.feather))-0.0001;
            float lowThresholdA = lowThresholdB-max(u.feather,0.00001);
            float highThresholdA = (u.highThreshold*(1.0+u.feather)-u.feather)+0.0001;
            float highThresholdB = highThresholdA+max(u.feather,0.00001);
            float lowBlend = smoothstep( lowThresholdA, lowThresholdB, luma );
            float highBlend = 1. - smoothstep( highThresholdA, highThresholdB, luma );
            float lumafx = min(lowBlend,highBlend);
            float4 dblurr = targetLuma;
            if (u.lowThreshold > 0.001 || u.highThreshold < 0.001) { dblurr *= lumafx; }
            // if (thrs) { dblurr *= lumafx; }
            
            dblurr *= satComp.a;
            dblurr *= u.oalpha;
            
            /// GLOW BLENDCOLOR
            float3 blendGlow;
            if(u.cmode == 0) {
            blendGlow = float3(dblurr.rgb+u.colblend.rgb); }
            else if(u.cmode == 1) {
            blendGlow = float3(u.colblend.rgb); }
            
            float4 mixcblend = mix(dblurr, float4(blendGlow, dblurr.a), u.alpb);
            float4 blendComp = u.cblend? mixcblend * dblurr.a : dblurr;
            ///
            
            /// SHADOW
            // float4 shadowComp= hblur.sample(__nv_smp, in.acScreenNorm.st);
            // shadowComp = float4(float3(0.0, 0.0, 0.0), shadowComp.a);
            // shadowComp *= SDA;

            
            /////// BLEND SECTION
            float4 finalGlow;
            if(u.bmode == 0) {
            float3 colorScreen = blendScreen(baseColor.rgb, blendComp.rgb);
            finalGlow = newLayer(baseColor, float4(colorScreen.rgb, blendComp.a) ); }
            // finalGlow = float4( 1.-((1.-(baseColor.rgb/baseColor.a))*(1.-blendComp.rgb)),1.0);
            // finalGlow *= blendComp.a;
    return __nv_out;
}
