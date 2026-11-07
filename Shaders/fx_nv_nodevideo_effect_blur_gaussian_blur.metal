// ---------------------------------------------------------------------------
// Effect Blur Gaussian Blur (NV)
// origem : assets/effects/nv-nodevideo-effect-blur-gaussian-blur.xml
// id     : nv.effect.nodevideo-effect-blur-gaussian-blur
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_blur_gaussian_blurParams {
    float _z;
    float _amount;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
float4 u_xlat1;
int2 u_xlati2;
float4 u_xlat3;
int u_xlati8;
float u_xlat12;
bool u_xlatb12;

fragment float4 fx_nv_nodevideo_effect_blur_gaussian_blur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_blur_gaussian_blurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.y = 0.0;
    u_xlat1.x = float(0.0);
    u_xlat1.y = float(0.0);
    u_xlat1.z = float(0.0);
    u_xlat1.w = float(0.0);
    u_xlati8 = int(0xFFFFFFECu);
    while(true){
        u_xlatb12 = 20<u_xlati8;
        if(u_xlatb12){break;}
        u_xlati2.xy = int2(u_xlati8) + int2(20, 1);
        u_xlat12 = float(u_xlati8);
        u_xlat0.x = u_xlat12 * u._amount;
        u_xlat0.xw = in.acScreenNorm.xy * _resolution.xy + u_xlat0.xy;
        u_xlat0.xw = u_xlat0.xw / _resolution.xy;
        u_xlat3 = inputImg.sample(__nv_smp, u_xlat0.xw);
        u_xlat1 = float4(_kernel[u_xlati2.x]) * u_xlat3 + u_xlat1;
        u_xlati8 = u_xlati2.y;
    }
    __nv_out = u_xlat1 / float4(float4(u._z, u._z, u._z, u._z));
    return __nv_out;
    return __nv_out;
}
