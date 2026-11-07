// ---------------------------------------------------------------------------
// Fast Adjusting++
// origem : assets/effects/toji-Fastadjust.xml
// id     : com.alightcreative.effects.fastadjusting
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_FastadjustParams {
    int mode;
    float exposure;
    float gamma;
    float brightness;
    float contrast;
    float highlights;
    float shadows;
    float offset;
    float saturation;
    float vib;
    float temperature;
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
    float hue;
    float redGamma;
    float greenGamma;
    float blueGamma;
    int red;
    int green;
    int blue;
    int alpha;
};

// --- funcoes auxiliares do efeito
const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);
        
        static float3 colorTemperatureToRGB(const in float u.temperature){
            float3x3 m = (u.temperature <= 6500.0) ? float3x3(float3(0.0, -2902.1955373783176, -8257.7997278925690),
                                                  float3(0.0, 1669.5803561666639, 2575.2827530017594),
                                                  float3(1.0, 1.3302673723350029, 1.8993753891711275)) :
                                             float3x3(float3(1745.0425298314172, 1216.6168361476490, -8257.7997278925690),
                                                  float3(-2666.3474220535695, -2173.1012343082230, 2575.2827530017594),
                                                  float3(0.55995389139931482, 0.70381203140554553, 1.8993753891711275));
            return mix(clamp(float3(m[0] / (float3(clamp(u.temperature, 1000.0, 40000.0)) + m[1]) + m[2]), float3(0.0), float3(1.0)), float3(1.0), smoothstep(1000.0, 0.0, u.temperature));
        }
        
        static float3 rotUV( float3 yuv, float degrees ) {
            float rad = degrees * 0.0174533;
            float3x3 rmat = float3x3(
                1.0,  0.0,       0.0,
                0.0,  cos(rad),  sin(rad),
                0.0,  -sin(rad), cos(rad)
            );
            return yuv * rmat;
        }

        static float3 hsv2rgb(float3 c)
        {
            float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
            float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
            return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
        }

fragment float4 fx_toji_Fastadjust(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_FastadjustParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> comp [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& comp_info [[buffer(3)]])
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
            
            float4 channel;
            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float4 lift = mix(comp.sample(__nv_smp, in.acScreenNorm)*texColor.a,texColor,0.0);
            
            float4 realTexture = u.mode? lift : texColor;
            
            float luminanceX = dot(realTexture.rgb, luminanceWeighting);
            float2 s = step(float2(0.,0.), in.acLayerNorm) - step(float2(1.,1.), in.acLayerNorm);
            float maskFactor = s.x * s.y;
            float4 outColor = float4(0.0);

            if( realTexture.a > 0.0 )
                realTexture.rgb /= realTexture.a;

            if( u.red==0 ) {
                outColor.r = realTexture.r;
            } else if( u.red==1 ) {
                outColor.r = realTexture.g;
            } else if( u.red==2 ) {
                outColor.r = realTexture.b;
            } else if( u.red==3 ) {
                outColor.r = realTexture.a;
            } else if( u.red==4 ) {
                outColor.r = luminanceX;
            } else if( u.red==5 ) {
                outColor.r = 0.0;
            } else {
                outColor.r = 1.0;
            }

            if( u.green==0 ) {
                outColor.g = realTexture.r;
            } else if( u.green==1 ) {
                outColor.g = realTexture.g;
            } else if( u.green==2 ) {
                outColor.g = realTexture.b;
            } else if( u.green==3 ) {
                outColor.g = realTexture.a;
            } else if( u.green==4 ) {
                outColor.g = luminanceX;
            } else if( u.green==5 ) {
                outColor.g = 0.0;
            } else {
                outColor.g = 1.0;
            }

            if( u.blue==0 ) {
                outColor.b = realTexture.r;
            } else if( u.blue==1 ) {
                outColor.b = realTexture.g;
            } else if( u.blue==2 ) {
                outColor.b = realTexture.b;
            } else if( u.blue==3 ) {
                outColor.b = realTexture.a;
            } else if( u.blue==4 ) {
                outColor.b = luminanceX;
            } else if( u.blue==5 ) {
                outColor.b = 0.0;
            } else {
                outColor.b = 1.0;
            }

            if( u.alpha==0 ) {
                outColor.a = realTexture.r;
            } else if( u.alpha==1 ) {
                outColor.a = realTexture.g;
            } else if( u.alpha==2 ) {
                outColor.a = realTexture.b;
            } else if( u.alpha==3 ) {
                outColor.a = realTexture.a;
            } else if( u.alpha==4 ) {
                outColor.a = luminanceX;
            } else if( u.alpha==5 ) {
                outColor.a = 0.0;
            } else {
                outColor.a = 1.0;
            }

            outColor.rgb *= outColor.a;

            channel = outColor * maskFactor;

                    float4 highshadow;
                    // float4 source = inputImg.sample(__nv_smp, in.acScreenNorm);
                    float luminance = dot(channel.rgb, luminanceWeighting);
        
                    float clampedShadows = clamp(u.shadows,1.0,2.0);
                    float shadow = clamp((pow(luminance, 1.0/clampedShadows) + (-0.76)*pow(luminance, 2.0/clampedShadows)) - luminance, 0.0, 1.0);
                    float highlight = clamp((1.0 - (pow(1.0-luminance, 1.0/(2.0-u.highlights)) + (-0.8)*pow(1.0-luminance, 2.0/(2.0-u.highlights)))) - luminance, -1.0, 0.0);
                    float3 result = float3(0.0, 0.0, 0.0) + ((luminance + shadow + highlight) - 0.0) * ((channel.rgb - float3(0.0, 0.0, 0.0))/(luminance - 0.0));
        
                    float contrastedLuminance = ((luminance - 0.5) * 1.5) + 0.5;
                    float whiteInterp = contrastedLuminance*contrastedLuminance*contrastedLuminance;
                    float whiteTarget = clamp(u.highlights, 1.0, 2.0) - 1.0;
                    result = mix(result, float3(1.0), whiteInterp*whiteTarget);
        
                    float invContrastedLuminance = 1.0 - contrastedLuminance;
                    float blackInterp = invContrastedLuminance*invContrastedLuminance*invContrastedLuminance;
                    float blackTarget = 1.0 - clamp(u.shadows, 0.0, 1.0);
                    result = mix(result, float3(0.0), blackInterp*blackTarget);
        
                    highshadow = float4(result.rgb, channel.a);

            
            float4 exsat;
            // float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            
            float4 afterHs = mix(channel,highshadow,1.0) * channel.a;
            afterHs.rgb = pow(afterHs.rgb,float3(1.0/u.redGamma,1.0/u.greenGamma,1.0/u.blueGamma));
            
            float3 rgb = afterHs.rgb;
            float a = afterHs.a;
            float3 yuv = rgb * rgb2yuv;
            // yuv.x = (yuv.x-0.5*a) * (u.contrast+1.0) + 0.5*a + u.brightness*a;

            float origSat = min(1.0,length(yuv.yz)*2.5); //
            float2 satUV = yuv.yz * u.vib;
            
            yuv.yz = mix(satUV,yuv.yz,origSat);
            // yuv = yuv * huemat;
            yuv.yz = yuv.yz * (u.saturation+1.0);
            
            rgb = yuv * yuv2rgb;
            rgb = rgb + float3(u.offset)*a;
            rgb = pow(rgb,float3(1.0/u.gamma));
            rgb = rgb * pow(2.0,u.exposure);
            rgb = mix(rgb, rgb * colorTemperatureToRGB(u.temperature * 1000.0), 0.8);
            //////////////////////////
            
            exsat = float4(rgb,a);
            
                float4 bright;
                float3 rgbx = exsat.rgb;
                float ax = exsat.a;
                float3 yuvbc = rgbx * rgb2yuv;
    
                yuvbc.x = (yuvbc.x-0.5*ax) * (u.contrast+1.0) + 0.5*ax + u.brightness*ax;
                rgbx = yuvbc * yuv2rgb;
                bright = float4(rgbx,a);
            
            float4 colBal;
            float4 baseColor = bright;
            float3 XXX = baseColor.rgb*rgb2yuv;
            float XL = (1.0 - smoothstep(0.222, 0.444, XXX.x));
            float XML = smoothstep(0.222, 0.444, XXX.x)*step(XXX.x, 0.555);
            float XMH = (1.0-smoothstep(0.555, 0.777, XXX.x))*step(0.555, XXX.x) * step(XXX.x, 0.777);
            float XH = smoothstep(0.555, 0.777, XXX.x);
            float3 XF = float3(u.crLow, u.mgLow, u.ybLow) * XL + float3(u.crMid, u.mgMid, u.ybMid)*(XML+XMH)+float3(u.crHigh, u.mgHigh, u.ybHigh)*XH;
            XF = max(min(XF, 100.0), -100.0);
            float3 conv = (XF+float3(100.0))/100.0;
            float3 converted = baseColor.rgb*conv;
            float3 convYuv = converted*rgb2yuv;
            if(u.fixLum) convYuv.x = XXX.x;
            float4 XFINAL = float4(convYuv*yuv2rgb, baseColor.a);
            colBal = XFINAL;
                
            float4 huecolor;
    	    float3 rgbxx = colBal.rgb;
            float axx = colBal.a;
            float3 yuvhue = rgbxx * rgb2yuv;

            yuvhue = yuvhue * huemat;
            rgbxx = yuvhue * yuv2rgb;

            huecolor = float4(rgbxx,a);
                                    
            __nv_out = huecolor;
    return __nv_out;
}
