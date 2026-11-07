// ---------------------------------------------------------------------------
// Texture Displace
// origem : assets/effects/toji-dualtexture.xml
// id     : com.alightcreative.effects.shadertoy_dualtexture_displace
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_dualtextureParams {
    float offsetX;
    float offsetY;
    float mapAmount;
    int useLayerBelow;
    int channelPair;
    int edgeMode;
    float edgeFeather;
};

// --- funcoes auxiliares do efeito
static float2 wrapUV(float2 p) {
            // u.edgeMode: 0 clamp, 1 repeat
            if (u.edgeMode == 0) {
                return clamp(p, 0.0, 1.0);
            } else {
                return fract(p);
            }
        }

        float2 pickChannels(float4 c) {
            // u.channelPair: 0 RG, 1 RB, 2 GB
            if (u.channelPair == 0) {
                return c.rg;
            } else if (u.channelPair == 1) {
                return c.rb;
            } else {
                return c.gb;
            }
        }

fragment float4 fx_toji_dualtexture(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_dualtextureParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> mapImg [[texture(1)]],
    texture2d<float> mapComp [[texture(2)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& mapImg_info [[buffer(3)]],
    constant NovaTexInfo& mapComp_info [[buffer(4)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 uv = in.acScreenNorm; // 0..1

            // choose map source
            float4 jc = u.useLayerBelow ? mapComp.sample(__nv_smp, uv)
                                    : mapImg.sample(__nv_smp, uv);

            // Shadertoy-like offset
            uv -= float2(u.offsetX, u.offsetY);

            // Channel routing and amount
            float2 disp = pickChannels(jc) * u.mapAmount;
            float2 dispUV = uv + disp;

            // Wrapped/clamped displaced sample
            float2 sampleUV = wrapUV(dispUV);
            float4 displacedCol = inputImg.sample(__nv_smp, sampleUV);

            // Edge feather: blend toward clamped sample when going out-of-bounds
            float2 overNeg = max(-dispUV, float2(0.0));
            float2 overPos = max(dispUV - float2(1.0), float2(0.0));
            float o = max(max(overNeg.x, overNeg.y), max(overPos.x, overPos.y));

            float2 clampUV = clamp(dispUV, 0.0, 1.0);
            float4 clampCol = inputImg.sample(__nv_smp, clampUV);

            float feather = u.edgeFeather; // 0..0.25 in UV space
            float m = feather > 0.0 ? smoothstep(0.0, feather, o) : 0.0;
            float4 col = mix(displacedCol, clampCol, m);

            __nv_out = col;
    return __nv_out;
}
