// ---------------------------------------------------------------------------
// Glitch de Varredura
// origem : assets/effects/nv-um-scanline-glitch.xml
// id     : nova.effect.um-scanline-glitch
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_um_scanline_glitchParams {
    float intensity;
    float bandCount;
    float speed;
    float rgbShift;
};

// --- funcoes auxiliares do efeito
float hash(float x) { return fract(sin(x * 91.3458) * 47453.5453); }

fragment float4 fx_nv_um_scanline_glitch(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_um_scanline_glitchParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;
    float band = floor(uv.y * u.bandCount);
    float seed = band + floor(eng.acTime * u.speed * u.bandCount * 0.1);
    float r = hash(seed);
    float ativo = step(1.0 - u.intensity, r);
    float shift = (hash(seed + 7.0) - 0.5) * u.intensity * 0.2 * ativo;

    float2 uvS = float2(uv.x + shift, uv.y);
    float rshift = u.rgbShift * ativo / eng.acResolution.x;

    float cr = inputImg.sample(__nv_smp, uvS + float2(rshift, 0.0)).r;
    float4 cg = inputImg.sample(__nv_smp, uvS);
    float cb = inputImg.sample(__nv_smp, uvS - float2(rshift, 0.0)).b;

    __nv_out = float4(cr, cg.g, cb, cg.a);
    return __nv_out;
}
