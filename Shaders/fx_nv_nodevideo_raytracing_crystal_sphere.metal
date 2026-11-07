// ---------------------------------------------------------------------------
// Raytracing Crystal Sphere (NV)
// origem : assets/effects/nv-nodevideo-raytracing-crystal-sphere.xml
// id     : nv.effect.nodevideo-raytracing-crystal-sphere
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_raytracing_crystal_sphereParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float3 _rotation;
    float _zoom;
    float _refraction;
    float2 _tex_scale;
    float2 _tex_offset;
    float4 _color;
    float _intensity;
    float _samples;
    float _wrap_texture;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode
#define _SourceTex_TexelSize (1.0 / float2(int2(int(inputImg.get_width()), int(inputImg.get_height()))))
// O Node lê o ambiente num cubemap; aqui ele chega como imagem 2D: a direção vira a UV equirretangular (0.910.0).
static float2 acDirParaUv(float3 d) { d = normalize(d); return float2(__nv_atan(d.x, d.z) * 0.15915494 + 0.5, acos(clamp(d.y, -1.0, 1.0)) * 0.31830989); }
float3 u_xlat0;
float4 u_xlat1;
float3 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float3 u_xlat6;
int u_xlati6;
float3 u_xlat7;
bool u_xlatb7;
float4 u_xlat8;
float3 u_xlat9;
float u_xlat10;
float3 u_xlat12;
float u_xlat16;
bool u_xlatb16;
float u_xlat21;
float u_xlat26;
bool u_xlatb26;
float2 u_xlat27;
bool2 u_xlatb27;
float2 u_xlat28;
float u_xlat30;
bool u_xlatb30;
float u_xlat31;
int u_xlati33;
float u_xlat34;
float u_xlat35;
float u_xlat36;
bool u_xlatb36;
float u_xlat37;
bool u_xlatb37;
float u_xlat38;
bool u_xlatb38;

fragment float4 fx_nv_nodevideo_raytracing_crystal_sphere(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_raytracing_crystal_sphereParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> cubemap0 [[texture(1)]],
    texture2d<float> Mask [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat0.xy = u_xlat0.xy * float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat0.xy = u_xlat0.xy + u_xlat0.xy;
    u_xlat1.xyz = u._rotation.xyz * float3(6.28318548, 6.28318548, 6.28318548);
    u_xlat2.x = sin(u_xlat1.z);
    u_xlat3.x = cos(u_xlat1.z);
    u_xlat4.x = (-u_xlat2.x);
    u_xlat5.x = cos(u_xlat1.x);
    u_xlat1.x = sin(u_xlat1.x);
    u_xlat6.y = u_xlat2.x * u_xlat5.x;
    u_xlat3.y = (-u_xlat1.x) * u_xlat2.x;
    u_xlat2.y = u_xlat3.x * u_xlat5.x;
    u_xlat4.y = (-u_xlat1.x) * u_xlat3.x;
    u_xlat7.x = sin(u_xlat1.y);
    u_xlat8.x = cos(u_xlat1.y);
    u_xlat9.x = (-u_xlat7.x);
    u_xlat9.y = u_xlat8.x;
    u_xlat6.x = dot(u_xlat3.yx, u_xlat9.xy);
    u_xlat9.z = u_xlat7.x;
    u_xlat6.z = dot(u_xlat3.yx, u_xlat9.yz);
    u_xlat2.x = dot(u_xlat4.yx, u_xlat9.xy);
    u_xlat2.z = dot(u_xlat4.yx, u_xlat9.yz);
    u_xlat3.x = u_xlat5.x * u_xlat9.x;
    u_xlat3.z = u_xlat5.x * u_xlat8.x;
    u_xlat0.z = 1.0;
    u_xlat30 = dot(u_xlat0.xyz, u_xlat0.xyz);
    u_xlat30 = rsqrt(u_xlat30);
    u_xlat0.xyz = float3(u_xlat30) * u_xlat0.xyz;
    u_xlat4.x = dot(u_xlat6.xyz, u_xlat0.xyz);
    u_xlat4.y = dot(u_xlat2.xyz, u_xlat0.xyz);
    u_xlat3.y = u_xlat1.x;
    u_xlat4.z = dot(u_xlat3.xyz, u_xlat0.xyz);
    u_xlat0.x = u_xlat6.z * u._zoom;
    u_xlat0.y = u_xlat2.z * u._zoom;
    u_xlat0.z = u_xlat3.z * u._zoom;
    u_xlat1.xy = in.acScreenNorm.xy / _SourceTex_TexelSize.xy;
    u_xlat30 = dot(u_xlat4.xyz, u_xlat4.xyz);
    u_xlat21 = dot(u_xlat4.xyz, u_xlat0.xyz);
    u_xlat31 = u_xlat21 + u_xlat21;
    u_xlat2.x = dot(u_xlat0.xyz, u_xlat0.xyz);
    u_xlat2.x = u_xlat2.x + -1.0;
    u_xlat2.x = u_xlat30 * u_xlat2.x;
    u_xlat2.x = u_xlat2.x * 4.0;
    u_xlat31 = u_xlat31 * u_xlat31 + (-u_xlat2.x);
    u_xlat2.x = max(u_xlat31, 0.0);
    u_xlat2.x = sqrt(u_xlat2.x);
    u_xlat21 = (-u_xlat21) * 2.0 + (-u_xlat2.x);
    u_xlat30 = u_xlat30 + u_xlat30;
    u_xlat30 = u_xlat21 / u_xlat30;
    u_xlat0.xyz = u_xlat4.xyz * float3(u_xlat30) + u_xlat0.xyz;
    u_xlatb30 = 0.100000001<u_xlat31;
    u_xlat21 = u._refraction + 1.0;
    u_xlat2.x = float(1.0) / u_xlat21;
    u_xlat12.xyz = u_xlat4.xyz;
    u_xlat3.xyz = u_xlat0.xyz;
    u_xlati33 = int(u._wrap_texture);
    u_xlat34 = 1.0;
    u_xlat5.x = float(0.0);
    u_xlat5.y = float(0.0);
    u_xlat5.z = float(0.0);
    u_xlat35 = float(1.0);
    for(int u_xlati_loop_1 = 0 ; u_xlati_loop_1<int(u._samples) ; u_xlati_loop_1++)
    {
        u_xlat16 = dot(u_xlat3.xyz, u_xlat3.xyz);
        u_xlat16 = sqrt(u_xlat16);
        u_xlat16 = u_xlat16 + -1.0;
        u_xlat16 = u_xlat34 * u_xlat16;
        u_xlatb26 = 0.0>=u_xlat16;
        if(u_xlatb26){
            u_xlat3.xyz = float3(u_xlat16) * u_xlat12.xyz + u_xlat3.xyz;
            u_xlat26 = dot(u_xlat3.xyz, u_xlat3.xyz);
            u_xlat26 = sqrt(u_xlat26);
            u_xlat26 = u_xlat26 + -1.0;
            u_xlat7.xyz = u_xlat3.xyz + float3(0.00999999978, 0.0, 0.0);
            u_xlat36 = dot(u_xlat7.xyz, u_xlat7.xyz);
            u_xlat36 = sqrt(u_xlat36);
            u_xlat7.x = u_xlat36 + -1.0;
            u_xlat8.xyz = u_xlat3.xyz + float3(0.0, 0.00999999978, 0.0);
            u_xlat36 = dot(u_xlat8.xyz, u_xlat8.xyz);
            u_xlat36 = sqrt(u_xlat36);
            u_xlat7.y = u_xlat36 + -1.0;
            u_xlat8.xyz = u_xlat3.xyz + float3(0.0, 0.0, 0.00999999978);
            u_xlat36 = dot(u_xlat8.xyz, u_xlat8.xyz);
            u_xlat36 = sqrt(u_xlat36);
            u_xlat7.z = u_xlat36 + -1.0;
            u_xlat7.xyz = (-float3(u_xlat26)) + u_xlat7.xyz;
            u_xlat26 = dot(u_xlat7.xyz, u_xlat7.xyz);
            u_xlat26 = rsqrt(u_xlat26);
            u_xlat7.xyz = float3(u_xlat26) * u_xlat7.xyz;
            u_xlat26 = dot(u_xlat7.xyz, u_xlat12.xyz);
            u_xlat36 = u_xlat34 * u_xlat26;
            u_xlatb36 = u_xlat36<0.0;
            if(u_xlatb36){
                u_xlat36 = u_xlat26 + u_xlat26;
                u_xlat8.xyz = u_xlat7.xyz * (-float3(u_xlat36)) + u_xlat12.xyz;
                u_xlat36 = u_xlat34 * u_xlat8.y;
                u_xlat36 = max(u_xlat36, 0.0);
                u_xlat26 = u_xlat26 * u_xlat34 + 1.0;
                u_xlat37 = u_xlat26 * u_xlat26;
                u_xlat37 = u_xlat37 * u_xlat37;
                u_xlat26 = u_xlat26 * u_xlat37;
                u_xlat26 = u_xlat26 * 0.99000001 + 0.00999999978;
                u_xlat8.xyz = cubemap0.sample(__nv_smp, acDirParaUv(u_xlat8.xyz)).xyz;
                u_xlat26 = u_xlat35 * u_xlat26;
                u_xlat26 = u_xlat36 * u_xlat26;
                u_xlat26 = u_xlat26 * 4.0;
                u_xlat8.xyz = log2(u_xlat8.xyz);
                u_xlat8.xyz = u_xlat8.xyz * float3(2.20000005, 2.20000005, 2.20000005);
                u_xlat8.xyz = exp2(u_xlat8.xyz);
                u_xlat5.xyz = float3(u_xlat26) * u_xlat8.xyz + u_xlat5.xyz;
                u_xlat8.xyz = u_xlat12.xyz * float3(u_xlat34);
                u_xlatb26 = u_xlat34<0.0;
                u_xlat26 = (u_xlatb26) ? u_xlat21 : u_xlat2.x;
                u_xlat36 = dot(u_xlat8.xyz, u_xlat7.xyz);
                u_xlat37 = u_xlat26 * u_xlat26;
                u_xlat38 = (-u_xlat36) * u_xlat36 + 1.0;
                u_xlat37 = (-u_xlat37) * u_xlat38 + 1.0;
                u_xlat38 = sqrt(u_xlat37);
                u_xlat36 = u_xlat26 * u_xlat36 + u_xlat38;
                u_xlatb37 = u_xlat37>=0.0;
                u_xlat7.xyz = u_xlat7.xyz * float3(u_xlat36);
                u_xlat7.xyz = float3(u_xlat26) * u_xlat8.xyz + (-u_xlat7.xyz);
                u_xlat7.xyz = bool(u_xlatb37) ? u_xlat7.xyz : float3(0.0, 0.0, 0.0);
                u_xlat26 = dot(u_xlat7.xyz, u_xlat7.xyz);
                u_xlat26 = rsqrt(u_xlat26);
                u_xlat7.xyz = float3(u_xlat26) * u_xlat7.xyz;
                u_xlat7.xyz = float3(u_xlat34) * u_xlat7.xyz;
                u_xlat12.xyz = (bool(u_xlatb30)) ? u_xlat7.xyz : u_xlat12.xyz;
                u_xlat34 = (-u_xlat34);
            }
        }
        u_xlat16 = abs(u_xlat16) * 0.949999988;
        u_xlat16 = max(u_xlat16, 0.00999999978);
        u_xlatb26 = u_xlat34<0.0;
        if(u_xlatb26){
            u_xlat26 = min(u_xlat16, 0.0500000007);
            u_xlat36 = dot(u_xlat12.xyz, u_xlat12.xyz);
            u_xlat36 = rsqrt(u_xlat36);
            u_xlat7.xyz = u_xlat12.xyz * float3(u_xlat36);
            u_xlat8.xy = float2(u_xlat26) * float2(-5.77078009, -0.721347511);
            u_xlat8.xy = exp2(u_xlat8.xy);
            u_xlat36 = min(abs(u_xlat7.z), abs(u_xlat7.x));
            u_xlat37 = max(abs(u_xlat7.z), abs(u_xlat7.x));
            u_xlat37 = float(1.0) / u_xlat37;
            u_xlat36 = u_xlat36 * u_xlat37;
            u_xlat37 = u_xlat36 * u_xlat36;
            u_xlat28.x = u_xlat37 * 0.0208350997 + -0.0851330012;
            u_xlat28.x = u_xlat37 * u_xlat28.x + 0.180141002;
            u_xlat28.x = u_xlat37 * u_xlat28.x + -0.330299497;
            u_xlat37 = u_xlat37 * u_xlat28.x + 0.999866009;
            u_xlat28.x = u_xlat36 * u_xlat37;
            u_xlatb38 = abs(u_xlat7.z)<abs(u_xlat7.x);
            u_xlat28.x = u_xlat28.x * -2.0 + 1.57079637;
            u_xlat28.x = u_xlatb38 ? u_xlat28.x : float(0.0);
            u_xlat36 = u_xlat36 * u_xlat37 + u_xlat28.x;
            u_xlatb37 = u_xlat7.z<(-u_xlat7.z);
            u_xlat37 = u_xlatb37 ? -3.14159274 : float(0.0);
            u_xlat36 = u_xlat36 + u_xlat37;
            u_xlat37 = min(u_xlat7.z, u_xlat7.x);
            u_xlat7.x = max(u_xlat7.z, u_xlat7.x);
            u_xlatb27.x = u_xlat37<(-u_xlat37);
            u_xlatb7 = u_xlat7.x>=(-u_xlat7.x);
            u_xlatb7 = u_xlatb7 && u_xlatb27.x;
            u_xlat36 = (u_xlatb7) ? (-u_xlat36) : u_xlat36;
            u_xlat9.x = u_xlat36 * 0.159154952 + 0.5;
            u_xlat9.y = u_xlat7.y * 0.5 + 0.5;
            u_xlat7.xy = (int(u_xlati33) != 0) ? u_xlat9.xy : in.acScreenNorm.xy;
            u_xlat7.xy = u_xlat7.xy + float2(-0.5, -0.5);
            u_xlat7.xy = u_xlat7.xy * float2(u._tex_scale.x, u._tex_scale.y) + u._tex_offset.xy;
            u_xlat7.xy = u_xlat7.xy + float2(0.5, 0.5);
            u_xlatb27.xy = greaterThanEqual(u_xlat7.xyxy, (-u_xlat7.xyxy)).xy;
            u_xlat7.xy = fract(abs(u_xlat7.xy));
            {
                float3 hlslcc_movcTemp = u_xlat7;
                hlslcc_movcTemp.x = (u_xlatb27.x) ? u_xlat7.x : (-u_xlat7.x);
                hlslcc_movcTemp.y = (u_xlatb27.y) ? u_xlat7.y : (-u_xlat7.y);
                u_xlat7 = hlslcc_movcTemp;
            }
            u_xlatb27.xy = lessThan(u_xlat7.xyxy, float4(0.0, 0.0, 0.0, 0.0)).xy;
            u_xlat28.xy = u_xlat7.xy + float2(1.0, 1.0);
            {
                float3 hlslcc_movcTemp = u_xlat7;
                hlslcc_movcTemp.x = (u_xlatb27.x) ? u_xlat28.x : u_xlat7.x;
                hlslcc_movcTemp.y = (u_xlatb27.y) ? u_xlat28.y : u_xlat7.y;
                u_xlat7 = hlslcc_movcTemp;
            }
            u_xlat27.xy = (-u_xlat8.xy) + float2(1.0, 1.0);
            u_xlat36 = u_xlat35 * u_xlat27.x;
            u_xlat7.xyz = inputImg.sample(__nv_smp, u_xlat7.xy).xyz;
            u_xlat7.xyz = float3(u_xlat36) * u_xlat7.xyz + u_xlat5.xyz;
            u_xlat36 = u_xlat35 * u_xlat8.x;
            u_xlat37 = u_xlat36 * u_xlat27.y;
            u_xlat8.xzw = float3(u_xlat37) * u._color.xyz;
            u_xlat5.xyz = u_xlat8.xzw * float3(u._intensity) + u_xlat7.xyz;
            u_xlat35 = u_xlat8.y * u_xlat36;
        } else {
            u_xlat26 = min(u_xlat16, 5.0);
        }
        u_xlat3.xyz = float3(u_xlat26) * u_xlat12.xyz + u_xlat3.xyz;
    }
    u_xlat0.x = u_xlat31 * 10.0;
    u_xlat0.x = clamp(u_xlat0.x, 0.0, 1.0);
    u_xlat10 = u_xlat0.x * -2.0 + 3.0;
    u_xlat0.x = u_xlat0.x * u_xlat0.x;
    u_xlat0.x = u_xlat0.x * u_xlat10;
    u_xlat10 = u_xlat1.y * 117.0 + u_xlat1.x;
    u_xlat10 = u_xlat10 * 0.134599999;
    u_xlat10 = sin(u_xlat10);
    u_xlat10 = u_xlat10 * 43758.5469;
    u_xlat10 = fract(u_xlat10);
    u_xlat10 = u_xlat10 * 0.0156862754;
    u_xlat0.xyz = u_xlat5.xyz * u_xlat0.xxx + float3(u_xlat10);
    if(int(u._use_inner_mask) != 0) {
        u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlatb2.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat3.xyz = (u_xlatb2.x) ? float3(1.0, 0.0, 1.0) : u_xlat0.xyz;
        u_xlat3.w = 1.0;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat1 = u_xlat1 * u_xlat5;
        u_xlat1 = u_xlat3 * u_xlat4 + u_xlat1;
        u_xlat30 = u_xlat4.x * u_xlat1.w;
        __nv_out.w = (u_xlatb2.y) ? u_xlat30 : u_xlat1.w;
        __nv_out.xyz = u_xlat1.xyz;
    } else {
        __nv_out.xyz = u_xlat0.xyz;
        __nv_out.w = 1.0;
    }
    return __nv_out;
    return __nv_out;
}
