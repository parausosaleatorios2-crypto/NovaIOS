// ---------------------------------------------------------------------------
// @am:string/effect_polar_name
// origem : assets/effects/toji-polar.xml
// id     : com.alightcreative.effects.polar
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_polarParams {
    float angle;
    float crop;
    float feather;
    float scale;
    float radius;
    float width;
    int stretch;
    int mirror;
    float repeat;
    float2 position;
};

// --- funcoes auxiliares do efeito
static float4 getSample( float a, float r ) {
            a *= 1. - (0.5/eng.acLayerSize.x);
            a += 0.5/eng.acLayerSize.x;
            float2 sampleCoord = float2(a,r);
            sampleCoord = (float4(sampleCoord,0.0,1.0) * eng.acLayerToScreen).xy;
            return inputImg.sample(__nv_smp, sampleCoord);
        }

        float smoothStep(float edge0, float edge1, float t) {
            if(edge0 == edge1) return 1.0;
            return smoothstep(edge0, edge1, t);
        }

fragment float4 fx_toji_polar(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_polarParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float rad = u.angle * 0.0174533;
            float2 pos = in.acLayerNorm - 0.5;
            if(!u.stretch) {
                pos.x *= eng.acLayerSize.x / eng.acLayerSize.y;
            }
            pos /= u.scale;
            pos += (u.position*float2(-1.0,1.0)) / 1000.0;
            float r = (length(pos)*2.0 - u.radius) / max(u.width,0.0000001);
            float a = __nv_mod(((__nv_atan(pos.y, pos.x)+rad)/6.28318)+0.5, 1.0);
            a = __nv_mod(a * u.repeat, 1.0);
            if(u.mirror) {
                a = abs(a * 2.0 - 1.0);
            }
            float cropFactor = (1.-(1./eng.acLayerSize.x*(u.crop)));
            float featherFactor = (1.-(1./eng.acLayerSize.x*(u.feather)));
            a = (a - 0.5) * featherFactor + 0.5;
            float featherDist = (1.0 - featherFactor);
            float f0 = smoothStep(0.0,featherDist,a);
            float f1 = smoothStep(1.0,1.0-featherDist,a);

            a = (a - 0.5) * cropFactor + 0.5;

            float cff = cropFactor * featherFactor;

            if( u.feather >= 0.0 && f0+f1 > 0.0 ) {
                __nv_out = mix( getSample(a+cff,r), mix( getSample(a-cff,r), getSample(a,r), f1 ), f0);
            } else {
                __nv_out = getSample(a,r);
            }
    return __nv_out;
}
