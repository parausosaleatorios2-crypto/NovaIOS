// ---------------------------------------------------------------------------
// Effect Blur Spot Blur (NV)
// origem : assets/effects/nv-nodevideo-effect-blur-spot-blur.xml
// id     : nv.effect.nodevideo-effect-blur-spot-blur
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_blur_spot_blurParams {
    float _intensity;
    float _highlight;
    float _radius;
    float _quality;
    float _enable;
    float _amount;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
float4 u_xlat3;
int u_xlati4;
float4 u_xlat5;
float4 u_xlat6;
float4 u_xlat7;
float u_xlat8;
float u_xlat12;
float u_xlat16;
float u_xlat20;
float u_xlat24;
float u_xlat28;
bool u_xlatb28;

fragment float4 fx_nv_nodevideo_effect_blur_spot_blur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_blur_spot_blurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.x = u._radius * 50.0;
    u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat1 = u_xlat1 * u_xlat1;
    u_xlat8 = u._quality / u._radius;
    u_xlat8 = u_xlat8 * 0.100000001;
    u_xlat8 = float(1.0) / u_xlat8;
    u_xlat16 = float(1.0) / u._amount;
    u_xlat24 = u._intensity + 1.0;
    u_xlat2 = u_xlat1;
    u_xlat3.x = float(1.0);
    u_xlat3.y = float(1.0);
    u_xlat3.z = float(1.0);
    u_xlat3.w = float(1.0);
    u_xlati4 = int(u._enable);
    u_xlat12 = u_xlat8;
    u_xlat20 = 0.799987733;
    while(true){
        u_xlatb28 = u_xlat12>=u_xlat0.x;
        if(u_xlatb28){break;}
        u_xlat5.x = sin(u_xlat20);
        u_xlat6.x = cos(u_xlat20);
        u_xlat6.y = u_xlat5.x;
        u_xlat5.xy = u_xlat6.xy / _resolution.xy;
        u_xlat5.xy = u_xlat5.xy * float2(u_xlat12) + in.acScreenNorm.xy;
        u_xlatb28 = 0<u_xlati4;
        if(u_xlatb28){
            u_xlat6 = inputImg.sample(__nv_smp, u_xlat5.xy);
        } else {
            u_xlat5 = inputImg.sample(__nv_smp, u_xlat5.xy);
            u_xlat6 = u_xlat5 * u_xlat5;
        }
        u_xlat5 = u_xlat6 * float4(float4(u._highlight, u._highlight, u._highlight, u._highlight));
        u_xlat6 = log2(u_xlat5);
        u_xlat6 = float4(u_xlat16) * u_xlat6;
        u_xlat6 = exp2(u_xlat6);
        u_xlat6 = u_xlat6 * float4(float4(u._radius, u._radius, u._radius, u._radius));
        u_xlat7 = u_xlat5 * u_xlat6;
        u_xlat7 = log2(u_xlat7);
        u_xlat7 = float4(u_xlat24) * u_xlat7;
        u_xlat7 = exp2(u_xlat7);
        u_xlat7 = u_xlat2 + u_xlat7;
        u_xlat5 = u_xlat5 * u_xlat6 + u_xlat2;
        u_xlat2 = (bool(u_xlatb28)) ? u_xlat7 : u_xlat5;
        u_xlat28 = (u_xlatb28) ? u._radius : 1.0;
        u_xlat3 = u_xlat6 * float4(u_xlat28) + u_xlat3;
        u_xlat28 = u_xlat8 / u_xlat12;
        u_xlat12 = u_xlat28 + u_xlat12;
        u_xlat20 = u_xlat20 + 2.39996314;
    }
    u_xlat0 = u_xlat2 / u_xlat3;
    __nv_out = sqrt(u_xlat0);
    return __nv_out;
    return __nv_out;
}
