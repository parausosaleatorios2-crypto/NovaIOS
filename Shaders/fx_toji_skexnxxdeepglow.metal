// ---------------------------------------------------------------------------
// Deep Glow+
// origem : assets/effects/toji-skexnxxdeepglow.xml
// id     : com.alightcreative.effects.deepglow
// passes : 3  (iterativo)
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxdeepglowParams {
    float strength;
    float rrr;
    float2 higsha;
    float2 satvib;
    float hue;
    float2 position;
    float oalpha;
    float calpha;
    int sshadow;
    float power;
    float alphaa;
    int cblend;
    float4 color;
    float alpb;
    int thrs;
    float lowThreshold;
    float highThreshold;
    float feather;
    float iter;
};

// --- funcoes auxiliares do efeito
static float2x2 rot2m(float a){
        
	float s = sin(a);
	float c = cos(a);
	
	return float2x2(c, -s, s, c);
    }
               float2 l2s( float2 v ) {
        return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
    }
    
       float4 newLayer( float4 a, float4 b) {
    return a * (1. - b.a) + b;
    }

fragment float4 fx_toji_skexnxxdeepglow(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxdeepglowParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> vblur [[texture(1)]],
    texture2d<float> hblur [[texture(2)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& vblur_info [[buffer(3)]],
    constant NovaTexInfo& hblur_info [[buffer(4)]])
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
            
                float2 syamjaidtz = in.acScreenNorm;
                // syamjaidtz = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
                // syamjaidtz.y*=eng.acLayerSize.y/eng.acLayerSize.x;
                syamjaidtz += float2((0.0+(u.position.x/15.0)), (0.0+(u.position.y/15.0)))*float2(-1.,1.)/500.;
                // float2 scaleVec;
                // scaleVec = float2(1.0*stretch.x,1.0*stretch.y);
                // syamjaidtz /= scaleVec;
                
            // float2 UV = in.acScreenNorm;
            // float2 center = eng.acLayerCenterNorm-(centerPoint/1000. * float2(-1.,1.));

            // UV -= center;
            // UV.x *= eng.acScreenSize.x / eng.acScreenSize.y;
        
            ////// OLD
            float4 baseColor;
            float4 compColorr;
            float4 shadow;
            // float rr = length(u.rrr - UV);
            float rr = length(u.rrr - in.acScreenNorm.st);
            
            baseColor = inputImg.sample(__nv_smp, in.acScreenNorm.st)*u.calpha;
            compColorr = vblur.sample(__nv_smp, syamjaidtz);
            ///SATVIB
            float3 rgb = compColorr.rgb ;
            float3 yuv = rgb * rgb2yuv;
            
            yuv = yuv * huemat; //HUE

            float origSat = min(1.0,length(yuv.yz)*2.5); //
            float2 satUV = yuv.yz * u.satvib.y;
            yuv.yz = mix(satUV,yuv.yz,origSat);
            yuv.yz = yuv.yz * (u.satvib.x+1.0);
            rgb = yuv * yuv2rgb;
            
            float4 newComp = float4(rgb, compColorr.a);
            
            // compColorr = vblur.sample(__nv_smp, in.acScreenNorm.st);
            
            shadow = newComp * (float4(0.,0.,0,1.0) * u.higsha.y) * compColorr.a;
            // shadow = compColorr * (float4(0.,0.,0,1.0) * u.higsha.y) * compColorr.a;
            float4 c = shadow + float4(1.)*(1.-shadow.a);

            float4 dblur = float4(newComp.rgb / compColorr.a,1.) * (rr - 0.5);
            // float4 dblur = float4(compColorr.rgb / compColorr.a,1.) * (rr - 0.5);
            
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
            if (u.thrs) {
            dblurr *= lumafx; }
            
            ///OLD
            float4 blendC = float4((dblurr.rgb/dblurr.a)*c.rgb,1.0) * dblurr.a;
            float4 resultfinalx = float4(u.color.rgb,dblurr.a) * dblurr.a;
            // float4 resultfinalx = float4(cross(u.color.rgb,blendC.rgb),1.0) * dblurr.a;
            // float4 resultfinalx = float4(saturate(u.color.rgb,blendC.rgb),1.0) * dblurr.a;
            // float4 resultfinalx = float4(u.color.rgb*blendC.rgb, alpc) * dblurr.a;
            float4 resultfinal = mix(blendC, resultfinalx, u.alpb ) * dblurr.a;
            float4 rrfinal = u.cblend? resultfinal : blendC;
            // float4 resultfinal = float4(saturate(u.color.rgb*blendC.rgb), progressa) * dblurr.a;
            
            // float4 resultfinal = float4((dblurr.rgb/dblurr.a)*c.rgb,1.0) * dblurr.a;
            // float4 blendC = float3(resultfinal.rgb, progressa) * dblurr.a;
            
            float4 L2 = ((baseColor*u.higsha.x) + (rrfinal*u.oalpha)) * compColorr.a;
            L2 += baseColor;
            
            float4 L1 = hblur.sample(__nv_smp, in.acScreenNorm.st);
            L1 = float4(float3(0.,0.,0), L1.a);
            L1 *= u.alphaa;

            __nv_out = u.sshadow? newLayer(L1, L2) : L2;
    return __nv_out;
}
