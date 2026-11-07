// ---------------------------------------------------------------------------
// uni.Chromatic Aberration
// origem : assets/effects/uni-chromatic-aberration.xml
// id     : nova.effect.unichromab
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct uni_chromatic_aberrationParams {
    float masterDistortion;
    float masterScale;
    float redDistortion;
    float redScale;
    float greenDistortion;
    float greenScale;
    float blueDistortion;
    float blueScale;
    float lensDistortion;
    float flatten;
    float edgeBlur;
    float radialBlur;
    float edgeRadius;
    float edgeFalloff;
    float aspect;
    int lensTexture;
    float textureAmount;
    float maskRadius;
    float maskFalloff;
    int textureMask;
    int linkAspect;
    float maskAspect;
    int stretchMap;
};

fragment float4 fx_uni_chromatic_aberration(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant uni_chromatic_aberrationParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> textureLayer [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm);
    return __nv_out;
}
