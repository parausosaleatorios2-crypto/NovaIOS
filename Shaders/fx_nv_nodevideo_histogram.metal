// ---------------------------------------------------------------------------
// Histogram (NV)
// origem : assets/effects/nv-nodevideo-histogram.xml
// id     : nv.effect.nodevideo-histogram
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_histogramParams {
    float2 _Size;
    float4 _ColorR;
    float4 _ColorG;
    float4 _ColorB;
    float4 _ColorL;
};

// --- funcoes auxiliares do efeito
#ifdef GL_ARB_shader_storage_buffer_object
#extension GL_ARB_shader_storage_buffer_object : enable
#endif
#ifdef GL_ARB_shader_image_load_store
#extension GL_ARB_shader_image_load_store : enable
#endif

float4 ImmCB_0[4];






 struct _Histogram_type {
	uint[4] value;
};

layout(std430, binding = 0) readonly buffer _Histogram {
	_Histogram_type _Histogram_buf[];
};

float4 u_xlat0;
uint2 u_xlatu0;
bool u_xlatb0;
float3 u_xlat16_1;
float4 u_xlat2;
uint u_xlatu3;
float u_xlat16_4;
int u_xlati6;
float u_xlat16_7;

fragment float4 fx_nv_nodevideo_histogram(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_histogramParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

ImmCB_0[0] = float4(1.0,0.0,0.0,0.0);
ImmCB_0[1] = float4(0.0,1.0,0.0,0.0);
ImmCB_0[2] = float4(0.0,0.0,1.0,0.0);
ImmCB_0[3] = float4(0.0,0.0,0.0,1.0);
    u_xlat0.x = in.acScreenNorm.x * 255.0;
    u_xlat16_1.x = floor(u_xlat0.x);
    u_xlat16_4 = fract(u_xlat0.x);
    u_xlatu0.x = uint(u_xlat16_1.x);
    u_xlatu3 = u_xlatu0.x + 1u;
    u_xlatu3 = min(u_xlatu3, 255u);
    u_xlati6 = int(int(_Channel) << (2 & int(0x1F)));
    u_xlatu0.y = _Histogram_buf[u_xlatu3].value[(u_xlati6 >> 2) + 0];
    u_xlatu0.x = _Histogram_buf[u_xlatu0.x].value[(u_xlati6 >> 2) + 0];
    u_xlat16_1.xz = float2(u_xlatu0.xy);
    u_xlat16_7 = u_xlat16_4 * u_xlat16_1.z;
    u_xlat16_4 = (-u_xlat16_4) + 1.0;
    u_xlat16_1.x = u_xlat16_1.x * u_xlat16_4 + u_xlat16_7;
    u_xlat0.x = in.acScreenNorm.y * u._Size.y;
    u_xlat0.x = rint(u_xlat0.x);
    u_xlatu0.x = uint(u_xlat0.x);
    u_xlat16_4 = float(u_xlatu0.x);
    u_xlatb0 = u_xlat16_1.x>=u_xlat16_4;
    u_xlat16_1.x = (u_xlatb0) ? 1.0 : 0.0;
    u_xlatu0.x = _Channel;
    u_xlat2 = u._ColorR * ImmCB_0[int(u_xlatu0.x)].xxxx;
    u_xlat2 = ImmCB_0[int(u_xlatu0.x)].yyyy * u._ColorG + u_xlat2;
    u_xlat2 = ImmCB_0[int(u_xlatu0.x)].zzzz * u._ColorB + u_xlat2;
    u_xlat0 = ImmCB_0[int(u_xlatu0.x)].wwww * u._ColorL + u_xlat2;
    __nv_out = u_xlat0 * u_xlat16_1.xxxx;
    return __nv_out;
    return __nv_out;
}
