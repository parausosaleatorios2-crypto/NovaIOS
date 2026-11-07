// ---------------------------------------------------------------------------
// @am:string/effect_stretchsegment_name
// origem : assets/effects/toji-stretchsegment.xml
// id     : com.alightcreative.effects.stretchsegment
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_stretchsegmentParams {
    float angle;
    float stretch;
    float offset;
    float smooth;
};

// --- funcoes auxiliares do efeito
float2x2 rot(float a) {
            float c = cos(a);
            float s = sin(a);
            return float2x2(
                c, -s,
                s, c
            );
        }
        
        float sminCubic( float a, float b, float k )
        {
            float h = max( k-abs(a-b), 0.0 )/k;
            return min( a, b ) - h*h*h*k*(1.0/6.0);
        }

fragment float4 fx_toji_stretchsegment(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_stretchsegmentParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

        
            float2 v = float2(1.0,0.0) * rot(u.angle * 0.0174533);
        
            float2 st = in.acScreenNorm;
            st -= eng.acLayerCenterNorm;
            
            float dist = dot(st,v) + (u.offset/1000.0);
            //float d = min(u.stretch/500.0,abs(dist));
            
            float adjStretch = u.stretch/500.0;
            
            float d = sminCubic(adjStretch,abs(dist),max(0.00001,u.smooth * adjStretch));
            
            float4 color = inputImg.sample(__nv_smp, in.acScreenNorm + v * d * -sign(dist));
            
            if( eng.acShowGuides ) {
                float4 guideCenterColor = float4(1.0, 0.0, 0.0, 1.0);
                float4 guideStretchColor = float4(1.0, 1.0, 0.0, 1.0);
                __nv_out = mix(mix(color,guideStretchColor, min(0.3,1.0-step(u.stretch/500.0,abs(dist)))  ),guideCenterColor,1.0-step(2.0/length(eng.acScreenSize),abs(dist)));
            } else {
                __nv_out = color;
            }
    return __nv_out;
}
