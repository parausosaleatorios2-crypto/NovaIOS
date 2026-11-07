// ---------------------------------------------------------------------------
// Waveform (NV)
// origem : assets/effects/nv-nodevideo-waveform.xml
// id     : nv.effect.nodevideo-waveform
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_waveformParams {
    float4 _Params;
};

// --- funcoes auxiliares do efeito
#ifdef GL_ARB_shader_storage_buffer_object
#extension GL_ARB_shader_storage_buffer_object : enable
#endif
#ifdef GL_ARB_shader_image_load_store
#extension GL_ARB_shader_image_load_store : enable
#endif

 struct _WaveformBuffer_type {
	uint[4] value;
};

layout(std430, binding = 0) readonly buffer _WaveformBuffer {
	_WaveformBuffer_type _WaveformBuffer_buf[];
};

float4 u_xlat0;
uint3 u_xlatu0;
float3 u_xlat1;
float3 u_xlat2;
float u_xlat3;
bool u_xlatb3;
float u_xlat6;
uint u_xlatu6;
bool u_xlatb6;
float u_xlat9;

fragment float4 fx_nv_nodevideo_waveform(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_waveformParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

float4 hlslcc_FragCoord = float4(__nv_fragCoord.xyz, 1.0/__nv_fragCoord.w);
    u_xlatu0.xy = uint2(hlslcc_FragCoord.xy);
    u_xlat3 = float(u_xlatu0.y);
    u_xlat6 = u._Params.y + -1.0;
    u_xlatb6 = u_xlat6<u_xlat3;
    if(u_xlatb6){
        __nv_out = float4(0.0, 0.0, 0.0, 0.0);
        return __nv_out;
    }
    u_xlat0.x = float(u_xlatu0.x);
    u_xlat0.x = u_xlat0.x * u._Params.y + u_xlat3;
    u_xlatu0.x = uint(u_xlat0.x);
    u_xlat3 = float(u_xlatu0.x);
    u_xlat6 = u._Params.x * u._Params.y + -1.0;
    u_xlatb3 = u_xlat6<u_xlat3;
    u_xlatu6 = uint(u_xlat6);
    u_xlatu0.x = (u_xlatb3) ? u_xlatu6 : u_xlatu0.x;
    u_xlatu0.xyz = uint3(_WaveformBuffer_buf[u_xlatu0.x].value[(0 >> 2) + 0], _WaveformBuffer_buf[u_xlatu0.x].value[(0 >> 2) + 1], _WaveformBuffer_buf[u_xlatu0.x].value[(0 >> 2) + 2]);
    u_xlat0.xyz = float3(u_xlatu0.xyz);
    u_xlat1.xyz = u_xlat0.yyy * float3(0.0199999996, 1.10000002, 0.0500000007);
    u_xlat0.xyw = u_xlat0.xxx * float3(1.39999998, 0.0299999993, 0.0199999996) + u_xlat1.xyz;
    u_xlat0.xyz = u_xlat0.zzz * float3(0.0, 0.25, 1.5) + u_xlat0.xyw;
    u_xlat0.xyz = u_xlat0.xyz * u._Params.zzz + float3(-0.00400000019, -0.00400000019, -0.00400000019);
    u_xlat0.xyz = max(u_xlat0.xyz, float3(0.0, 0.0, 0.0));
    u_xlat1.xyz = u_xlat0.xyz * float3(6.19999981, 6.19999981, 6.19999981) + float3(0.5, 0.5, 0.5);
    u_xlat1.xyz = u_xlat0.xyz * u_xlat1.xyz;
    u_xlat2.xyz = u_xlat0.xyz * float3(6.19999981, 6.19999981, 6.19999981) + float3(1.70000005, 1.70000005, 1.70000005);
    u_xlat0.xyz = u_xlat0.xyz * u_xlat2.xyz + float3(0.0599999987, 0.0599999987, 0.0599999987);
    u_xlat0.xyz = u_xlat1.xyz / u_xlat0.xyz;
    u_xlat0.xyz = u_xlat0.xyz * u_xlat0.xyz;
    u_xlat9 = max(u_xlat0.z, u_xlat0.y);
    __nv_out.w = max(u_xlat9, u_xlat0.x);
    __nv_out.xyz = min(u_xlat0.xyz, float3(1.0, 1.0, 1.0));
    return __nv_out;
    return __nv_out;
}
