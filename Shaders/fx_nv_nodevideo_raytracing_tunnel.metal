// ---------------------------------------------------------------------------
// Raytracing Tunnel (NV)
// origem : assets/effects/nv-nodevideo-raytracing-tunnel.xml
// id     : nv.effect.nodevideo-raytracing-tunnel
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_raytracing_tunnelParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _phase;
    float2 _scale;
    float4 _fog_color;
    float _fog;
    float _depth;
    float _twirl;
    float _wrap;
    float _crop;
    float _mirror;
    float _shape;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode
float4 u_xlat0;
float4 u_xlat1;
bool u_xlatb1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float2 u_xlat6;
bool u_xlatb6;
float u_xlat7;
bool u_xlatb7;
float2 u_xlat12;
bool2 u_xlatb13;
float u_xlat18;

fragment float4 fx_nv_nodevideo_raytracing_tunnel(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_raytracing_tunnelParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> SourceTexMirror [[texture(1)]],
    texture2d<float> Mask [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat0.xy = u_xlat0.xy * float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat0.xy = u_xlat0.xy * float2(u._scale.x, u._scale.y);
    u_xlat12.x = u._twirl * 0.0174532998;
    u_xlat18 = min(abs(u_xlat0.y), abs(u_xlat0.x));
    u_xlat1.x = max(abs(u_xlat0.y), abs(u_xlat0.x));
    u_xlat1.x = float(1.0) / u_xlat1.x;
    u_xlat18 = u_xlat18 * u_xlat1.x;
    u_xlat1.x = u_xlat18 * u_xlat18;
    u_xlat7 = u_xlat1.x * 0.0208350997 + -0.0851330012;
    u_xlat7 = u_xlat1.x * u_xlat7 + 0.180141002;
    u_xlat7 = u_xlat1.x * u_xlat7 + -0.330299497;
    u_xlat1.x = u_xlat1.x * u_xlat7 + 0.999866009;
    u_xlat7 = u_xlat18 * u_xlat1.x;
    u_xlatb13.x = abs(u_xlat0.y)<abs(u_xlat0.x);
    u_xlat7 = u_xlat7 * -2.0 + 1.57079637;
    u_xlat7 = u_xlatb13.x ? u_xlat7 : float(0.0);
    u_xlat18 = u_xlat18 * u_xlat1.x + u_xlat7;
    u_xlatb1 = u_xlat0.y<(-u_xlat0.y);
    u_xlat1.x = u_xlatb1 ? -3.14159274 : float(0.0);
    u_xlat18 = u_xlat18 + u_xlat1.x;
    u_xlat1.x = min(u_xlat0.y, u_xlat0.x);
    u_xlat7 = max(u_xlat0.y, u_xlat0.x);
    u_xlatb1 = u_xlat1.x<(-u_xlat1.x);
    u_xlatb7 = u_xlat7>=(-u_xlat7);
    u_xlatb1 = u_xlatb7 && u_xlatb1;
    u_xlat18 = (u_xlatb1) ? (-u_xlat18) : u_xlat18;
    u_xlat1.x = dot(u_xlat0.xy, u_xlat0.xy);
    u_xlat1.x = sqrt(u_xlat1.x);
    u_xlat0.xy = u_xlat0.xy * u_xlat0.xy;
    u_xlat0.xy = u_xlat0.xy * u_xlat0.xy;
    u_xlat0.xy = u_xlat0.xy * u_xlat0.xy;
    u_xlat0.x = u_xlat0.y + u_xlat0.x;
    u_xlat0.x = log2(u_xlat0.x);
    u_xlat0.x = u_xlat0.x * 0.125;
    u_xlat0.x = exp2(u_xlat0.x);
    u_xlat0.x = (int(u._shape) != 0) ? u_xlat0.x : u_xlat1.x;
    u_xlat6.x = u_xlat12.x * u_xlat0.x + u_xlat18;
    u_xlat12.x = u._depth / u_xlat0.x;
    u_xlat1.x = u_xlat12.x + u._phase;
    u_xlat12.x = 6.28318548 / u._wrap;
    u_xlat1.y = u_xlat6.x / u_xlat12.x;
    u_xlatb6 = 0<int(u._mirror);
    u_xlat12.xy = u_xlat1.xy * float2(0.5, 0.5);
    u_xlatb13.xy = greaterThanEqual(u_xlat12.xyxy, (-u_xlat12.xyxy)).xy;
    u_xlat12.xy = fract(abs(u_xlat12.xy));
    {
        float2 hlslcc_movcTemp = u_xlat12;
        hlslcc_movcTemp.x = (u_xlatb13.x) ? u_xlat12.x : (-u_xlat12.x);
        hlslcc_movcTemp.y = (u_xlatb13.y) ? u_xlat12.y : (-u_xlat12.y);
        u_xlat12 = hlslcc_movcTemp;
    }
    u_xlat12.xy = u_xlat12.xy * float2(2.0, 2.0) + float2(-1.0, -1.0);
    u_xlatb13.xy = greaterThanEqual(u_xlat1.xyxy, (-u_xlat1.xyxy)).xy;
    u_xlat1.xy = fract(abs(u_xlat1.xy));
    {
        float4 hlslcc_movcTemp = u_xlat1;
        hlslcc_movcTemp.x = (u_xlatb13.x) ? u_xlat1.x : (-u_xlat1.x);
        hlslcc_movcTemp.y = (u_xlatb13.y) ? u_xlat1.y : (-u_xlat1.y);
        u_xlat1 = hlslcc_movcTemp;
    }
    u_xlat6.xy = (bool(u_xlatb6)) ? abs(u_xlat12.xy) : u_xlat1.xy;
    u_xlat6.xy = u_xlat6.xy + float2(-0.5, -0.5);
    u_xlat6.xy = u_xlat6.xy * float2(u._crop) + float2(0.5, 0.5);
    u_xlat1 = SourceTexMirror.sample(__nv_smp, u_xlat6.xy);
    u_xlatb6 = 0.5<u_xlat0.x;
    u_xlat0.x = (-u_xlat0.x) * 2.0 + 1.0;
    u_xlat0.x = u_xlat0.x * u._fog;
    u_xlat0.x = clamp(u_xlat0.x, 0.0, 1.0);
    u_xlat12.x = u_xlat0.x * -2.0 + 3.0;
    u_xlat0.x = u_xlat0.x * u_xlat0.x;
    u_xlat0.x = u_xlat0.x * u_xlat12.x;
    u_xlat2 = (-u_xlat1) + u._fog_color;
    u_xlat1 = u_xlat0.xxxx * u_xlat2 + u_xlat1;
    u_xlat0 = (bool(u_xlatb6)) ? float4(0.0, 0.0, 0.0, 0.0) : u_xlat1;
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
