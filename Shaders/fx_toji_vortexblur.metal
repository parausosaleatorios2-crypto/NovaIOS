// ---------------------------------------------------------------------------
// Vortex Blur
// origem : assets/effects/toji-vortexblur.xml
// id     : com.alightcreative.effects.vortexblur
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_vortexblurParams {
    float2 centerPoint;
    float strength;
    float radius;
};

fragment float4 fx_toji_vortexblur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_vortexblurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            float2 texelSize = 1.0 / __nv_getTexSize(inputImg_info.size);
            float Radius = u.radius;
            float T = u.strength;

            float2 UV = in.acScreenNorm;

            float2 CENTER = u.centerPoint*float2(-1,-1);

            float2 diff1 = eng.acLayerCenter-CENTER;
            diff1.y = eng.acScreenSize.y - diff1.y;
            float2 diff = diff1 /eng.acScreenSize;

            UV -= diff;
            float2 convRate = float2(1,1);
            if(eng.acScreenSize.y > eng.acScreenSize.x)
                convRate.y=(eng.acScreenSize.y/eng.acScreenSize.x);
            else
                convRate.x=(eng.acScreenSize.x/eng.acScreenSize.y);
            UV *= convRate;

            float Dist = length(UV);

            float4 color = float4(0.0);
            
            if ( Dist < Radius )
            {
                float speed = 0.0;
                float localPower = (Radius - Dist) / Radius;
                {
                  float A = ( T <= 0.5 ) ? mix( 0.0, 1.0, T/0.5 ) : mix( 1.0, 0.0, (T-0.5)/0.5 );
                  float Theta = localPower * localPower * A * 8.0 * 3.14159;
                  float l = Dist * Theta;
                  speed = abs(l/texelSize.x*10.0);
                }
                float nSamples = float(clamp(speed, 1.01, 2000.01));
                
                float2 v = UV/nSamples;
                float2 c = float2(0.0);
                float count = 0.0;
                for(float d = max(Radius - abs(u.strength)*localPower, Dist); d <= Radius; d += 1.0/nSamples) {
                    float Percent = (Radius - d) / Radius;
                    float2 cc = UV - c;
                    c += v;
                    float A = ( T <= 0.5 ) ? mix( 0.0, 1.0, T/0.5 ) : mix( 1.0, 0.0, (T-0.5)/0.5 );
                    float Theta = Percent * Percent * A * 8.0 * 3.14159;
                    float S = sin( Theta );
                    float C = cos( Theta );
                    float2 res = float2( dot(cc, float2(C, -S)), dot(cc, float2(S, C)) );
                    res /= convRate;
                    res += diff;
                    color += inputImg.sample(__nv_smp, res);
                    count += 1.0;
                }
                color /= count;
            }
            else {
                UV /= convRate;
                UV += diff;
                color = inputImg.sample(__nv_smp, UV);
            }
            
            __nv_out = color;
    return __nv_out;
}
