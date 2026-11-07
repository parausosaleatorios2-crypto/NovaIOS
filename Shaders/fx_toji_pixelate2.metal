// ---------------------------------------------------------------------------
// @am:string/effect_pixelate_name
// origem : assets/effects/toji-pixelate2.xml
// id     : com.alightcreative.effects.pixelate2
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_pixelate2Params {
    float size;
    float2 stretch;
    float2 offset;
    float angle;
    float vignette;
    int screenSpace;
    float threshold;
    float saturation;
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

fragment float4 fx_toji_pixelate2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_pixelate2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

        
            float2 sizeVec = float2(u.size,u.size);
            sizeVec.x *= u.stretch.x;
            sizeVec.y *= u.stretch.y;
            
            float2 pixelSize = sizeVec / eng.acScreenSize;
            float2 st = in.acScreenNorm;
            if( !u.screenSpace )
                st -= eng.acLayerCenterNorm;
            st *= rot(u.angle * 0.0174533);
            st -= u.offset/1000.0;
            float2 posInPixel = __nv_mod(st, pixelSize);
            posInPixel -= pixelSize/2.0;
            posInPixel *= rot(-u.angle * 0.0174533);
            posInPixel += pixelSize/2.0;
            float2 pixelCenter = in.acScreenNorm - posInPixel + pixelSize / 2.0;

            float distCenter = smoothstep(0.0, 1.0, length((posInPixel/pixelSize) - float2(0.5,0.5)));

            float4 color = inputImg.sample(__nv_smp, pixelCenter);
            float tclamp = step(u.threshold, color.a);
            if( color.a > 0.0 && u.saturation > 0.0 ) {
                color /= color.a / max(color.a,u.saturation);
            }
            color = color * tclamp;
            //color = mix(color, float4(0.0,0.0,0.0,color.a), u.vignette * distCenter);
            color = mix(color, float4(min(color.rgb * color.rgb * color.rgb, float3(0.9, 0.9, 0.9)),color.a * color.a * color.a), step(1.5, u.size) * u.vignette * distCenter);
            //color = float4(color.rgb * (1.0-(u.vignette*distCenter)), color.a);
            __nv_out = color;
    return __nv_out;
}
