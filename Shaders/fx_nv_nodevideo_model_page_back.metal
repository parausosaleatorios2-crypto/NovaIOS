// ---------------------------------------------------------------------------
// Model Page Back (NV)
// origem : assets/effects/nv-nodevideo-model-page-back.xml
// id     : nv.effect.nodevideo-model-page-back
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_model_page_backParams {
    float _my_page;
};

// --- funcoes auxiliares do efeito
bool u_xlatb0;

fragment float4 fx_nv_nodevideo_model_page_back(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_model_page_backParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> page_back1 [[texture(1)]],
    texture2d<float> page_back2 [[texture(2)]],
    texture2d<float> page_back3 [[texture(3)]],
    texture2d<float> page_back4 [[texture(4)]],
    texture2d<float> page_back5 [[texture(5)]],
    texture2d<float> page_back6 [[texture(6)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if(int(u._my_page) == 0) {
        __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    } else {
        u_xlatb0 = int(u._my_page)==1;
        if(u_xlatb0){
            __nv_out = page_back1.sample(__nv_smp, in.acScreenNorm.xy);
        } else {
            u_xlatb0 = int(u._my_page)==2;
            if(u_xlatb0){
                __nv_out = page_back2.sample(__nv_smp, in.acScreenNorm.xy);
            } else {
                u_xlatb0 = int(u._my_page)==3;
                if(u_xlatb0){
                    __nv_out = page_back3.sample(__nv_smp, in.acScreenNorm.xy);
                } else {
                    u_xlatb0 = int(u._my_page)==4;
                    if(u_xlatb0){
                        __nv_out = page_back4.sample(__nv_smp, in.acScreenNorm.xy);
                    } else {
                        u_xlatb0 = int(u._my_page)==5;
                        if(u_xlatb0){
                            __nv_out = page_back5.sample(__nv_smp, in.acScreenNorm.xy);
                        } else {
                            u_xlatb0 = int(u._my_page)==6;
                            if(u_xlatb0){
                                __nv_out = page_back6.sample(__nv_smp, in.acScreenNorm.xy);
                            } else {
                                __nv_out = float4(0.0, 0.0, 0.0, 0.0);
                            }
                        }
                    }
                }
            }
        }
    }
    return __nv_out;
    return __nv_out;
}
