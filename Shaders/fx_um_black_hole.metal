// ---------------------------------------------------------------------------
// Buraco Negro (Ultra Motion)
// origem : assets/effects/um-black-hole.xml
// id     : nova.effect.ultramotion.blackhole
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_black_holeParams {
    float pull;
    float swirl;
    float radius;
    float2 center;
};

fragment float4 fx_um_black_hole(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_black_holeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 p = in.acScreenNorm - u.center;
    p.x *= eng.acAspect;
    float r = length(p);
    if (r <= 0.001) { __nv_out = float4(0.0, 0.0, 0.0, 1.0); return __nv_out; }

    float t = clamp(1.0 - r / u.radius, 0.0, 1.0);
    float ang = __nv_atan(p.y, p.x) + u.swirl * t;
    float raioNovo = r / (1.0 + u.pull * t * t);
    float2 q = float2(cos(ang), sin(ang)) * raioNovo;
    q.x /= eng.acAspect;

    float4 c = inputImg.sample(__nv_smp, q + u.center);
    // Núcleo negro no meio
    float nucleo = smoothstep(0.02, 0.06, r);
    __nv_out = float4(c.rgb * nucleo, c.a);
    return __nv_out;
}
