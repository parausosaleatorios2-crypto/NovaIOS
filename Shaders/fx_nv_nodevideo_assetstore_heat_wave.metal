// ---------------------------------------------------------------------------
// Heat Wave (NV)
// origem : assets/effects/nv-nodevideo-assetstore-heat-wave.xml
// id     : nv.effect.nodevideo-assetstore-heat-wave
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_heat_waveParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _speed;
    float2 _offset;
    float _amplitude;
    float _scale;
    float _octaves;
    float _frequency;
    float _direction;
    float _keep_edge;
};

// --- funcoes auxiliares do efeito
// tempo do Node ligado ao motor (tools/nodevideo/ligar_tempo.py)
#define _cur_time eng.acTime
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode
float4 u_xlat0;
float4 u_xlat1;
float2 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
bool u_xlatb3;
float4 u_xlat4;
float4 u_xlat5;
float2 u_xlat6;
float u_xlat8;
float2 u_xlat9;
float u_xlat10;
bool u_xlatb12;
int u_xlati13;
bool2 u_xlatb13;
float2 u_xlat14;
int u_xlati14;
float2 u_xlat15;
float2 u_xlat16;
float u_xlat19;
float u_xlat20;
int u_xlati20;
bool u_xlatb20;
float u_xlat22;

fragment float4 fx_nv_nodevideo_assetstore_heat_wave(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_heat_waveParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.x = _cur_time * u._speed;
    u_xlat6.x = u._direction + -90.0;
    u_xlat6.x = u_xlat6.x * 0.0174532942;
    u_xlat6.y = sin((-u_xlat6.x));
    u_xlat6.x = cos(u_xlat6.x);
    u_xlat1 = u_xlat0.xxxx * u_xlat6.yxyx;
    u_xlat0 = in.acScreenNorm.xyxy * float4(_viewport_ratio.x, _viewport_ratio.y, _viewport_ratio.x, _viewport_ratio.y) + (-u_xlat1);
    u_xlat1.xy = float2(u._offset.x, u._offset.y) * float2(-1.0, 1.0);
    u_xlat0 = u_xlat0 + float4(-0.5, -0.5, 24.7999992, 12.3999996);
    u_xlat0 = u_xlat0 * float4(u._scale);
    u_xlat0 = u_xlat0 * float4(3.0, 3.0, 3.0, 3.0) + float4(0.5, 0.5, 0.5, 0.5);
    u_xlati13 = int(u._octaves);
    u_xlat2.xy = u_xlat0.xy;
    u_xlat19 = 0.0;
    u_xlat14.x = float(0.5);
    for(int u_xlati_loop_1 = int(0) ; u_xlati_loop_1<u_xlati13 ; u_xlati_loop_1++)
    {
        u_xlat3.xy = floor(u_xlat2.xy);
        u_xlat15.xy = fract(u_xlat2.xy);
        u_xlat4.x = dot(u_xlat3.xy, float2(12.9898005, 78.2330017));
        u_xlat4.x = sin(u_xlat4.x);
        u_xlat4.x = u_xlat4.x * 43758.5469;
        u_xlat5 = u_xlat3.xyxy + float4(1.0, 0.0, 0.0, 1.0);
        u_xlat10 = dot(u_xlat5.xy, float2(12.9898005, 78.2330017));
        u_xlat10 = sin(u_xlat10);
        u_xlat4.y = u_xlat10 * 43758.5469;
        u_xlat16.x = dot(u_xlat5.zw, float2(12.9898005, 78.2330017));
        u_xlat16.x = sin(u_xlat16.x);
        u_xlat4.z = u_xlat16.x * 43758.5469;
        u_xlat4.xyz = fract(u_xlat4.xyz);
        u_xlat3.xy = u_xlat3.xy + float2(1.0, 1.0);
        u_xlat3.x = dot(u_xlat3.xy, float2(12.9898005, 78.2330017));
        u_xlat3.x = sin(u_xlat3.x);
        u_xlat3.x = u_xlat3.x * 43758.5469;
        u_xlat3.x = fract(u_xlat3.x);
        u_xlat5.xy = u_xlat15.xy * u_xlat15.xy;
        u_xlat9.xy = (-u_xlat15.xy) * float2(2.0, 2.0) + float2(3.0, 3.0);
        u_xlat15.xy = u_xlat9.xy * u_xlat5.xy;
        u_xlat22 = (-u_xlat4.x) + u_xlat4.y;
        u_xlat22 = u_xlat15.x * u_xlat22 + u_xlat4.x;
        u_xlat4.x = (-u_xlat4.x) + u_xlat4.z;
        u_xlat4.x = u_xlat15.y * u_xlat4.x;
        u_xlat9.x = (-u_xlat5.x) * u_xlat9.x + 1.0;
        u_xlat9.x = u_xlat4.x * u_xlat9.x + u_xlat22;
        u_xlat3.x = (-u_xlat4.y) + u_xlat3.x;
        u_xlat3.x = u_xlat15.x * u_xlat3.x;
        u_xlat3.x = u_xlat3.x * u_xlat15.y + u_xlat9.x;
        u_xlat19 = u_xlat14.x * u_xlat3.x + u_xlat19;
        u_xlat2.xy = u_xlat2.xy * float2(2.0, 2.0) + u_xlat1.xy;
        u_xlat14.x = u_xlat14.x * u._frequency;
    }
    u_xlat0.xy = u_xlat0.zw;
    u_xlat2.x = float(0.0);
    u_xlat8 = float(0.5);
    for(int u_xlati_loop_2 = int(0) ; u_xlati_loop_2<u_xlati13 ; u_xlati_loop_2++)
    {
        u_xlat3.xy = floor(u_xlat0.xy);
        u_xlat15.xy = fract(u_xlat0.xy);
        u_xlat20 = dot(u_xlat3.xy, float2(12.9898005, 78.2330017));
        u_xlat20 = sin(u_xlat20);
        u_xlat20 = u_xlat20 * 43758.5469;
        u_xlat20 = fract(u_xlat20);
        u_xlat4 = u_xlat3.xyxy + float4(1.0, 0.0, 0.0, 1.0);
        u_xlat4.x = dot(u_xlat4.xy, float2(12.9898005, 78.2330017));
        u_xlat4.x = sin(u_xlat4.x);
        u_xlat4.x = u_xlat4.x * 43758.5469;
        u_xlat10 = dot(u_xlat4.zw, float2(12.9898005, 78.2330017));
        u_xlat10 = sin(u_xlat10);
        u_xlat4.y = u_xlat10 * 43758.5469;
        u_xlat4.xy = fract(u_xlat4.xy);
        u_xlat3.xy = u_xlat3.xy + float2(1.0, 1.0);
        u_xlat3.x = dot(u_xlat3.xy, float2(12.9898005, 78.2330017));
        u_xlat3.x = sin(u_xlat3.x);
        u_xlat3.x = u_xlat3.x * 43758.5469;
        u_xlat3.x = fract(u_xlat3.x);
        u_xlat16.xy = u_xlat15.xy * u_xlat15.xy;
        u_xlat9.xy = (-u_xlat15.xy) * float2(2.0, 2.0) + float2(3.0, 3.0);
        u_xlat15.xy = u_xlat9.xy * u_xlat16.xy;
        u_xlat22 = (-u_xlat20) + u_xlat4.x;
        u_xlat22 = u_xlat15.x * u_xlat22 + u_xlat20;
        u_xlat20 = (-u_xlat20) + u_xlat4.y;
        u_xlat20 = u_xlat15.y * u_xlat20;
        u_xlat9.x = (-u_xlat16.x) * u_xlat9.x + 1.0;
        u_xlat20 = u_xlat20 * u_xlat9.x + u_xlat22;
        u_xlat3.x = (-u_xlat4.x) + u_xlat3.x;
        u_xlat3.x = u_xlat15.x * u_xlat3.x;
        u_xlat20 = u_xlat3.x * u_xlat15.y + u_xlat20;
        u_xlat2.x = u_xlat8 * u_xlat20 + u_xlat2.x;
        u_xlat0.xy = u_xlat0.xy * float2(2.0, 2.0) + u_xlat1.xy;
        u_xlat8 = u_xlat8 * u._frequency;
    }
    u_xlat0.x = u_xlat19 + -0.5;
    u_xlat0.y = u_xlat2.x + -0.5;
    u_xlat0.xy = u_xlat0.xy * float2(float2(u._amplitude, u._amplitude)) + in.acScreenNorm.xy;
    u_xlatb12 = int(u._keep_edge)==1;
    u_xlat1.xy = u_xlat0.xy + float2(-0.5, -0.5);
    u_xlat1.xy = u_xlat1.xy * float2(1.00999999, 1.00999999) + float2(0.5, 0.5);
    u_xlatb13.xy = lessThan(u_xlat1.xyxy, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlatb2.xy = lessThan(float4(1.0, 1.0, 0.0, 0.0), u_xlat1.xyxx).xy;
    u_xlat14.xy = fract(u_xlat1.xy);
    u_xlat14.xy = (-u_xlat14.xy) + float2(1.0, 1.0);
    u_xlat2.x = (u_xlatb2.x) ? u_xlat14.x : u_xlat1.x;
    u_xlat2.y = (u_xlatb2.y) ? u_xlat14.y : u_xlat1.y;
    {
        float4 hlslcc_movcTemp = u_xlat1;
        hlslcc_movcTemp.x = (u_xlatb13.x) ? (-u_xlat1.x) : u_xlat2.x;
        hlslcc_movcTemp.y = (u_xlatb13.y) ? (-u_xlat1.y) : u_xlat2.y;
        u_xlat1 = hlslcc_movcTemp;
    }
    u_xlat1.xy = u_xlat1.xy + float2(-0.5, -0.5);
    u_xlat1.xy = u_xlat1.xy * float2(0.990099013, 0.990099013) + float2(0.5, 0.5);
    u_xlat0.xy = (bool(u_xlatb12)) ? u_xlat1.xy : u_xlat0.xy;
    u_xlat0 = inputImg.sample(__nv_smp, u_xlat0.xy);
    if(int(u._use_inner_mask) != 0) {
        u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlatb2.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat3 = (u_xlatb2.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat0;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat1 = u_xlat1 * u_xlat5;
        u_xlat1 = u_xlat3 * u_xlat4 + u_xlat1;
        u_xlat2.x = u_xlat4.x * u_xlat1.w;
        __nv_out.w = (u_xlatb2.y) ? u_xlat2.x : u_xlat1.w;
        __nv_out.xyz = u_xlat1.xyz;
    } else {
        __nv_out = u_xlat0;
    }
    return __nv_out;
    return __nv_out;
}
