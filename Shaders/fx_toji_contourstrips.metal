// ---------------------------------------------------------------------------
// @am:string/effect_contour_strips_name
// origem : assets/effects/toji-contourstrips.xml
// id     : com.alightcreative.effects.contourstrips
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_contourstripsParams {
    float amount;
    float width;
    float angle;
    float thickness;
    float phase;
    int invert;
    float4 lineColor;
    float4 color1;
    float4 color2;
    float4 lightColor;
    float lightAngle;
    float strength;
    int heightSource;
    int maskToLayer;
};

// --- funcoes auxiliares do efeito
static float2 l2s( float2 v ) {
            return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
        }
        
        float2x2 rot2d(float a) {
            float c = cos(a);
            float s = sin(a);
            return float2x2( c, -s, s, c );
        }

        const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);
        
        float2 perpCCW(float2 v) {
            return float2(v.y,-v.x);
        }

        float2 perpCW(float2 v) {
            return float2(-v.y,v.x);
        }
        
        float4 composite( float4 a, float4 b) {
            return a * (1. - b.a) + b;
        }
        
        float4 premult( float4 c ) {
            return float4(c.rgb * c.a, c.a);
        }

fragment float4 fx_toji_contourstrips(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_contourstripsParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> blurBuf [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& blurBuf_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

        
            float2 st = in.acLayerNorm;
            
            float a = (u.angle+180.0) * 0.0174532925;
            float la = (u.lightAngle) * 0.0174532925;
            float2 lightVec = float2(1.,0.) * rot2d(la);
            float band = 1. / u.amount;
            
            st -= 0.5;
            st *= rot2d(a);
            st += 0.5;

            st.y += (u.phase + 0.055) / 10. + 0.5/eng.acLayerSize.y;
            
            float4 result = float4(0.);
            
            float pixel = 1./min(eng.acLayerSize.x, eng.acLayerSize.y);
            float soffs = pixel * 4.0 * max(1.0,u.width);
            float bandPixel = pixel/u.amount/u.width;
            float baseThickness = u.thickness / u.width * u.amount / 20.;

            for( float i=-1.0; i<u.width+1.0; i += 1.0 ) {
            
                float2 uv = st;
                
                float bandId = floor(uv.y / band) + i;
                float py = __nv_mod(uv.y, band);
                uv.y -= py;
                uv.y += band * i;
                py /= band;
                
                uv.y -= (u.phase + 0.055) / 10. + 0.5/eng.acLayerSize.y;
                uv -= 0.5;
                uv *= rot2d(-a);
                uv += 0.5;
                                
                py = 1.-((1.-py) + i)/u.width;

                float4 texColor = inputImg.sample(__nv_smp, l2s(uv));
                float4 texColorL = blurBuf.sample(__nv_smp, l2s(uv+float2(-soffs,0.)));
                float4 texColorR = blurBuf.sample(__nv_smp, l2s(uv+float2(soffs,0.)));
                float luminance = u.heightSource==0 ? texColor.a : dot(texColor.rgb, luminanceWeighting);
                float lumL = u.heightSource==0 ? texColorL.a : dot(texColorL.rgb, luminanceWeighting);
                float lumR = u.heightSource==0 ? texColorR.a : dot(texColorR.rgb, luminanceWeighting);
                if( !u.invert ) {
                    lumL = 1. - lumL;
                    lumR = 1. - lumR;
                    luminance = 1. - luminance;
                }
                
                float2 aa = float2(-soffs, lumL*band*u.width);
                float2 cc = float2(soffs, lumR*band*u.width);
                float2 n = normalize(perpCCW(cc-aa));
                
                float2 dac = cc-aa;
                float slope = abs(dac.y) / abs(dac.x);
                
                float th = baseThickness * (1.+slope*0.5);

                float line = smoothstep(luminance-th-bandPixel,luminance-th,py) * smoothstep(luminance+th+bandPixel,luminance+th,py);

                float2 vn = n*0.5 + 0.5;
                float4 lc = saturate(mix(u.lineColor,composite(u.lineColor,premult(u.lightColor)),saturate(dot(n,lightVec))) * saturate(line));

                float p = smoothstep(luminance-0.02,luminance+0.01,py);
            
                float4 c = texColor * p;
                if(u.heightSource == 0) {
                    c = mix(composite(texColor,premult(u.color1)), composite(texColor,premult(u.color2)), py) * p;
                } else {
                    c = mix(premult(u.color1), premult(u.color2), py) * p;
                }
                if(u.maskToLayer) {
                    c *= texColor.a;
                    lc *= texColor.a;
                }
                result = result * (1.-c.a) + c;
                result = result * (1.-lc.a) + lc;
            }
            

            __nv_out = result;
    return __nv_out;
}
