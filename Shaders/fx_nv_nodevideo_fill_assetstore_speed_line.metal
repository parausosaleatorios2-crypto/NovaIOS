// ---------------------------------------------------------------------------
// Fill Assetstore Speed Line (NV)
// origem : assets/effects/nv-nodevideo-fill-assetstore-speed-line.xml
// id     : nv.effect.nodevideo-fill-assetstore-speed-line
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_fill_assetstore_speed_lineParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float4 _color;
    float _amount;
    float _radius;
    float _length;
    float _smoothing;
    float _noise;
    float _speed;
    float _keep_aspect;
    float _blend_mode;
};

// --- funcoes auxiliares do efeito
// tempo do Node ligado ao motor (tools/nodevideo/ligar_tempo.py)
#define _cur_time eng.acTime
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode
float4 u_xlat0;
bool u_xlatb0;
float4 u_xlat1;
bool2 u_xlatb1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float u_xlat6;
int u_xlati6;
bool u_xlatb6;
bool u_xlatb8;
float u_xlat9;
float u_xlat12;
bool2 u_xlatb12;
float u_xlat13;
bool u_xlatb13;
float2 u_xlat14;
float u_xlat15;
float u_xlat19;
bool u_xlatb19;

fragment float4 fx_nv_nodevideo_fill_assetstore_speed_line(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_fill_assetstore_speed_lineParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.yx * float2(2.0, 2.0) + float2(-1.0, -1.0);
    u_xlatb12.xy = equal(int4(int(u._keep_aspect), int(u._blend_mode), int(u._keep_aspect), int(u._blend_mode)), int4(1, 1, 1, 1)).xy;
    u_xlat1.xy = u_xlat0.xy * float2(_viewport_ratio.y, _viewport_ratio.x);
    u_xlat0.xy = (u_xlatb12.x) ? u_xlat1.xy : u_xlat0.xy;
    u_xlat12 = dot(u_xlat0.xy, u_xlat0.xy);
    u_xlat12 = sqrt(u_xlat12);
    u_xlat1.x = _cur_time * u._speed;
    u_xlat1.x = u_xlat1.x * 10.0;
    u_xlat1.x = floor(u_xlat1.x);
    u_xlat1.x = u_xlat1.x * 0.100000001;
    u_xlat1.x = u._noise * u_xlat12 + u_xlat1.x;
    u_xlat13 = min(abs(u_xlat0.y), abs(u_xlat0.x));
    u_xlat19 = max(abs(u_xlat0.y), abs(u_xlat0.x));
    u_xlat19 = float(1.0) / u_xlat19;
    u_xlat13 = u_xlat19 * u_xlat13;
    u_xlat19 = u_xlat13 * u_xlat13;
    u_xlat2.x = u_xlat19 * 0.0208350997 + -0.0851330012;
    u_xlat2.x = u_xlat19 * u_xlat2.x + 0.180141002;
    u_xlat2.x = u_xlat19 * u_xlat2.x + -0.330299497;
    u_xlat19 = u_xlat19 * u_xlat2.x + 0.999866009;
    u_xlat2.x = u_xlat19 * u_xlat13;
    u_xlatb8 = abs(u_xlat0.y)<abs(u_xlat0.x);
    u_xlat2.x = u_xlat2.x * -2.0 + 1.57079637;
    u_xlat2.x = u_xlatb8 ? u_xlat2.x : float(0.0);
    u_xlat13 = u_xlat13 * u_xlat19 + u_xlat2.x;
    u_xlatb19 = u_xlat0.y<(-u_xlat0.y);
    u_xlat19 = u_xlatb19 ? -3.14159274 : float(0.0);
    u_xlat13 = u_xlat19 + u_xlat13;
    u_xlat19 = min(u_xlat0.y, u_xlat0.x);
    u_xlat0.x = max(u_xlat0.y, u_xlat0.x);
    u_xlatb6 = u_xlat19<(-u_xlat19);
    u_xlatb0 = u_xlat0.x>=(-u_xlat0.x);
    u_xlatb0 = u_xlatb0 && u_xlatb6;
    u_xlat0.x = (u_xlatb0) ? (-u_xlat13) : u_xlat13;
    u_xlat1.y = u_xlat0.x * u._amount;
    u_xlat0.x = float(0.0);
    for(int u_xlati_loop_1 = int(1) ; u_xlati_loop_1<7 ; u_xlati_loop_1++)
    {
        u_xlat13 = float(u_xlati_loop_1);
        u_xlat2.xy = float2(u_xlat13) + u_xlat1.xy;
        u_xlat13 = exp2(u_xlat13);
        u_xlat19 = u_xlat13 + u_xlat13;
        u_xlat14.xy = float2(u_xlat19) * u_xlat2.xy;
        u_xlat3.xy = floor(u_xlat14.xy);
        u_xlat3.xy = u_xlat3.xy / float2(u_xlat19);
        u_xlat3.x = dot(u_xlat3.xy, float2(89.4400024, 19.3600006));
        u_xlat3.x = sin(u_xlat3.x);
        u_xlat3.x = u_xlat3.x * 22189.2207;
        u_xlat4 = u_xlat2.xyxy * float4(u_xlat19) + float4(0.0, 1.0, 1.0, 0.0);
        u_xlat4 = floor(u_xlat4);
        u_xlat4 = u_xlat4 / float4(u_xlat19);
        u_xlat9 = dot(u_xlat4.xy, float2(89.4400024, 19.3600006));
        u_xlat9 = sin(u_xlat9);
        u_xlat3.y = u_xlat9 * 22189.2207;
        u_xlat15 = dot(u_xlat4.zw, float2(89.4400024, 19.3600006));
        u_xlat15 = sin(u_xlat15);
        u_xlat3.z = u_xlat15 * 22189.2207;
        u_xlat3.xyz = fract(u_xlat3.xyz);
        u_xlat2.xy = u_xlat2.xy * float2(u_xlat19) + float2(1.0, 1.0);
        u_xlat2.xy = floor(u_xlat2.xy);
        u_xlat2.xy = u_xlat2.xy / float2(u_xlat19);
        u_xlat19 = dot(u_xlat2.xy, float2(89.4400024, 19.3600006));
        u_xlat19 = sin(u_xlat19);
        u_xlat19 = u_xlat19 * 22189.2207;
        u_xlat19 = fract(u_xlat19);
        u_xlatb2.xy = greaterThanEqual(u_xlat14.xyxx, (-u_xlat14.xyxx)).xy;
        u_xlat14.xy = fract(abs(u_xlat14.xy));
        u_xlat2.x = (u_xlatb2.x) ? u_xlat14.x : (-u_xlat14.x);
        u_xlat2.y = (u_xlatb2.y) ? u_xlat14.y : (-u_xlat14.y);
        u_xlat2.xy = max(u_xlat2.xy, float2(0.0, 0.0));
        u_xlat14.xy = u_xlat2.xy * float2(-2.0, -2.0) + float2(3.0, 3.0);
        u_xlat2.xy = u_xlat2.xy * u_xlat2.xy;
        u_xlat2.xy = u_xlat2.xy * u_xlat14.xy;
        u_xlat14.x = (-u_xlat3.x) + u_xlat3.y;
        u_xlat14.x = u_xlat2.y * u_xlat14.x + u_xlat3.x;
        u_xlat19 = (-u_xlat3.z) + u_xlat19;
        u_xlat19 = u_xlat2.y * u_xlat19 + u_xlat3.z;
        u_xlat19 = (-u_xlat14.x) + u_xlat19;
        u_xlat19 = u_xlat2.x * u_xlat19 + u_xlat14.x;
        u_xlat13 = u_xlat19 / u_xlat13;
        u_xlat0.x = u_xlat0.x + u_xlat13;
    }
    u_xlat6 = u_xlat12 + (-u._radius);
    u_xlat0.x = u_xlat0.x + -0.5;
    u_xlat0.x = (-u._length) * u_xlat0.x + u_xlat6;
    u_xlat6 = u._smoothing + u._smoothing;
    u_xlat0.x = u_xlat0.x + u._smoothing;
    u_xlat6 = float(1.0) / u_xlat6;
    u_xlat0.x = u_xlat6 * u_xlat0.x;
    u_xlat0.x = clamp(u_xlat0.x, 0.0, 1.0);
    u_xlat6 = u_xlat0.x * -2.0 + 3.0;
    u_xlat0.x = u_xlat0.x * u_xlat0.x;
    u_xlat1.w = u_xlat0.x * u_xlat6;
    u_xlat1.xyz = u_xlat1.www * u._color.xyz;
    u_xlat2 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat3 = u_xlat1 * u_xlat2;
    u_xlat4.xyz = u_xlat1.www * u._color.xyz + u_xlat2.xyz;
    u_xlat4.w = u_xlat2.w;
    u_xlat0 = (u_xlatb12.y) ? u_xlat3 : u_xlat4;
    u_xlat3.xyz = u_xlat1.xyz;
    u_xlat0 = (int(u._blend_mode) != 0) ? u_xlat0 : u_xlat3;
    if(int(u._use_inner_mask) != 0) {
        u_xlatb1.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat3 = (u_xlatb1.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat0;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat2 = u_xlat2 * u_xlat5;
        u_xlat2 = u_xlat3 * u_xlat4 + u_xlat2;
        u_xlat1.x = u_xlat4.x * u_xlat2.w;
        __nv_out.w = (u_xlatb1.y) ? u_xlat1.x : u_xlat2.w;
        __nv_out.xyz = u_xlat2.xyz;
    } else {
        __nv_out = u_xlat0;
    }
    return __nv_out;
    return __nv_out;
}
