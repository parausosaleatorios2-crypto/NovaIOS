// ---------------------------------------------------------------------------
// Camera Custom Particle (NV)
// origem : assets/effects/nv-nodevideo-camera-custom-particle.xml
// id     : nv.effect.nodevideo-camera-custom-particle
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_camera_custom_particleParams {
    float2 _ratio;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
bool2 u_xlatb1;
bool2 u_xlatb4;

fragment float4 fx_nv_nodevideo_camera_custom_particle(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_camera_custom_particleParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat0.xy = u_xlat0.xy / u._ratio.xy;
    u_xlat0.xy = u_xlat0.xy + float2(0.5, 0.5);
    u_xlatb4.xy = lessThan(u_xlat0.xyxy, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlatb1.xy = lessThan(float4(1.0, 1.0, 0.0, 0.0), u_xlat0.xyxx).xy;
    u_xlatb4.x = u_xlatb4.x || u_xlatb1.x;
    u_xlatb4.x = u_xlatb4.y || u_xlatb4.x;
    u_xlatb4.x = u_xlatb1.y || u_xlatb4.x;
    if(u_xlatb4.x){
        __nv_out = float4(0.0, 0.0, 0.0, 0.0);
        return __nv_out;
    }
    u_xlat0 = inputImg.sample(__nv_smp, u_xlat0.xy);
    __nv_out = u_xlat0 * in.vs_COLOR0;
    return __nv_out;
    return __nv_out;
}
