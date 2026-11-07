// ---------------------------------------------------------------------------
// Effect Blur Bubble Blur2 (NV)
// origem : assets/effects/nv-nodevideo-effect-blur-bubble-blur2.xml
// id     : nv.effect.nodevideo-effect-blur-bubble-blur2
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_blur_bubble_blur2Params {
    float _size;
    float _threshold;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
float4 u_xlat3;
float u_xlat4;

fragment float4 fx_nv_nodevideo_effect_blur_bubble_blur2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_blur_bubble_blur2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.x = u._threshold * u._size;
    u_xlat4 = _resolution.y * 0.5;
    u_xlat0.x = u_xlat0.x / u_xlat4;
    u_xlat1 = u_xlat0.xxxx * float4(1.25, 0.0, -1.25, 0.0) + in.acScreenNorm.xyxy;
    u_xlat2 = inputImg.sample(__nv_smp, u_xlat1.zw);
    u_xlat1 = inputImg.sample(__nv_smp, u_xlat1.xy);
    u_xlat2 = u_xlat2 * float4(0.189999998, 0.189999998, 0.189999998, 0.189999998);
    u_xlat1 = u_xlat1 * float4(0.189999998, 0.189999998, 0.189999998, 0.189999998) + u_xlat2;
    u_xlat2 = u_xlat0.xxxx * float4(2.5, 0.0, -2.5, 0.0) + in.acScreenNorm.xyxy;
    u_xlat3 = inputImg.sample(__nv_smp, u_xlat2.xy);
    u_xlat2 = inputImg.sample(__nv_smp, u_xlat2.zw);
    u_xlat1 = u_xlat3 * float4(0.170000002, 0.170000002, 0.170000002, 0.170000002) + u_xlat1;
    u_xlat1 = u_xlat2 * float4(0.170000002, 0.170000002, 0.170000002, 0.170000002) + u_xlat1;
    u_xlat2 = u_xlat0.xxxx * float4(3.75, 0.0, -3.75, 0.0) + in.acScreenNorm.xyxy;
    u_xlat3 = inputImg.sample(__nv_smp, u_xlat2.xy);
    u_xlat2 = inputImg.sample(__nv_smp, u_xlat2.zw);
    u_xlat1 = u_xlat3 * float4(0.150000006, 0.150000006, 0.150000006, 0.150000006) + u_xlat1;
    u_xlat1 = u_xlat2 * float4(0.150000006, 0.150000006, 0.150000006, 0.150000006) + u_xlat1;
    u_xlat2 = u_xlat0.xxxx * float4(5.0, 0.0, -5.0, 0.0) + in.acScreenNorm.xyxy;
    u_xlat3 = inputImg.sample(__nv_smp, u_xlat2.xy);
    u_xlat2 = inputImg.sample(__nv_smp, u_xlat2.zw);
    u_xlat1 = u_xlat3 * float4(0.129999995, 0.129999995, 0.129999995, 0.129999995) + u_xlat1;
    u_xlat1 = u_xlat2 * float4(0.129999995, 0.129999995, 0.129999995, 0.129999995) + u_xlat1;
    u_xlat2 = u_xlat0.xxxx * float4(6.25, 0.0, -6.25, 0.0) + in.acScreenNorm.xyxy;
    u_xlat3 = inputImg.sample(__nv_smp, u_xlat2.xy);
    u_xlat2 = inputImg.sample(__nv_smp, u_xlat2.zw);
    u_xlat1 = u_xlat3 * float4(0.109999999, 0.109999999, 0.109999999, 0.109999999) + u_xlat1;
    u_xlat1 = u_xlat2 * float4(0.109999999, 0.109999999, 0.109999999, 0.109999999) + u_xlat1;
    u_xlat2 = u_xlat0.xxxx * float4(7.5, 0.0, -7.5, 0.0) + in.acScreenNorm.xyxy;
    u_xlat3 = inputImg.sample(__nv_smp, u_xlat2.xy);
    u_xlat2 = inputImg.sample(__nv_smp, u_xlat2.zw);
    u_xlat1 = u_xlat3 * float4(0.0799999982, 0.0799999982, 0.0799999982, 0.0799999982) + u_xlat1;
    u_xlat1 = u_xlat2 * float4(0.0799999982, 0.0799999982, 0.0799999982, 0.0799999982) + u_xlat1;
    u_xlat2 = u_xlat0.xxxx * float4(8.75, 0.0, -8.75, 0.0) + in.acScreenNorm.xyxy;
    u_xlat0 = u_xlat0.xxxx * float4(10.0, 0.0, -10.0, 0.0) + in.acScreenNorm.xyxy;
    u_xlat3 = inputImg.sample(__nv_smp, u_xlat2.xy);
    u_xlat2 = inputImg.sample(__nv_smp, u_xlat2.zw);
    u_xlat1 = u_xlat3 * float4(0.0500000007, 0.0500000007, 0.0500000007, 0.0500000007) + u_xlat1;
    u_xlat1 = u_xlat2 * float4(0.0500000007, 0.0500000007, 0.0500000007, 0.0500000007) + u_xlat1;
    u_xlat2 = inputImg.sample(__nv_smp, u_xlat0.xy);
    u_xlat0 = inputImg.sample(__nv_smp, u_xlat0.zw);
    u_xlat1 = u_xlat2 * float4(0.0199999996, 0.0199999996, 0.0199999996, 0.0199999996) + u_xlat1;
    u_xlat0 = u_xlat0 * float4(0.0199999996, 0.0199999996, 0.0199999996, 0.0199999996) + u_xlat1;
    u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat0 = u_xlat1 * float4(0.200000003, 0.200000003, 0.200000003, 0.200000003) + u_xlat0;
    __nv_out = u_xlat0 * float4(0.5, 0.5, 0.5, 0.5);
    return __nv_out;
    return __nv_out;
}
