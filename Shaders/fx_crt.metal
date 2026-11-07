// ---------------------------------------------------------------------------
// Tela antiga (CRT)
// origem : assets/effects/crt.xml
// id     : nova.effect.crt
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct crtParams {
    float scanlines;
    float scanDepth;
    float curvature;
    float bleed;
    float flicker;
    float vignette;
};

fragment float4 fx_crt(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant crtParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;

    // Curvatura de tubo: empurra as bordas para fora a partir do centro.
    if (u.curvature > 0.0) {
        float2 centered = uv * 2.0 - 1.0;
        float2 offset = centered.yx * centered.yx * centered * u.curvature;
        uv = (centered + offset) * 0.5 + 0.5;

        // Fora do tubo não há imagem. Preto opaco, e não transparente: uma TV
        // desligada tem moldura, não tem buraco.
        if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
            __nv_out = float4(0.0, 0.0, 0.0, 1.0);
            return __nv_out;
        }
    }

    // Sangramento: os três canhões de cor do tubo nunca alinhavam direito.
    float2 shift = float2(u.bleed * eng.acEscalaDePixel, 0.0) * eng.acTexelSize;
    float4 base = inputImg.sample(__nv_smp, uv);
    float r = inputImg.sample(__nv_smp, uv + shift).r;
    float b = inputImg.sample(__nv_smp, uv - shift).b;
    float3 rgb = float3(r, base.g, b);

    // Linhas de varredura.
    float line = sin(uv.y * u.scanlines * 3.14159265);
    rgb *= 1.0 - u.scanDepth * (0.5 + 0.5 * line) * 0.5;

    // Tremida do sincronismo vertical, ligada ao tempo.
    rgb *= 1.0 - u.flicker * (0.5 + 0.5 * sin(eng.acTime * 47.0));

    // Vinheta do tubo.
    float2 fromCenter = (uv - 0.5) * 2.0;
    float dist = length(fromCenter * float2(eng.acAspect, 1.0));
    rgb *= 1.0 - u.vignette * smoothstep(0.6, 1.6, dist);

    __nv_out = float4(clamp(rgb, 0.0, 1.0), base.a);
    return __nv_out;
}
