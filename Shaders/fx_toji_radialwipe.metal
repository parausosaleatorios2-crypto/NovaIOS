// ---------------------------------------------------------------------------
// @am:string/effect_radialwipe_name
// origem : assets/effects/toji-radialwipe.xml
// id     : com.alightcreative.effects.radialwipe
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_radialwipeParams {
    float progress;
    float offset;
    float2 centerPoint;
    float feather;
    int direction;
    float repeatCount;
};

// --- funcoes auxiliares do efeito
float2 project(float2 a, float2 b) {
            return (dot(a,b)/dot(b,b)) * b;
        }

        const float twopi = 6.2831853072;

fragment float4 fx_toji_radialwipe(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_radialwipeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 st = in.acLayerNorm;
            st.y = 1. - st.y;
            st -= 0.5;
            st.x *= eng.acLayerSize.x/eng.acLayerSize.y;
            st -= u.centerPoint / 1200.0;

            float adjProgress = (u.direction==1) ? 360.0-u.progress : u.progress;

            float start = 0.0;
            float end = adjProgress;

            end -= 180.0;
            end *= (360.0+u.feather)/360.0;
            end += 180.0;

            float offsetRad = (u.offset-90.0+(u.direction==2?end/2.0/u.repeatCount:0.0)) * 0.0174533;
            float2x2 offsetRot = float2x2(cos(offsetRad),-sin(offsetRad),sin(offsetRad),cos(offsetRad));

            st *= offsetRot;

            float adjFeather = max(0.01,u.feather * 0.0174533);
            float halfFeather = adjFeather / 2.0;

            float startRad = start * 0.0174533;
            float endRad= end * 0.0174533;

            float a = __nv_atan(st.y, st.x) + 3.14159;

            a = __nv_mod(a * u.repeatCount, twopi);

            float p0 = smoothstep(adjFeather,0.0,a);
            float p1 = smoothstep(endRad-halfFeather,endRad+halfFeather,a); // a<adjFeather?a+twopi:
            float p2 = smoothstep(endRad-twopi+halfFeather,endRad-twopi-halfFeather,a); // a<adjFeather?a+twopi:
            float pp = adjProgress<=0.0001?1.0:adjProgress>=359.999?0.0:min(1.0,p1+p0-p2);
            if( u.direction==1 ) {
                pp = 1.0-pp;
            }
            __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm.st)*pp;
    return __nv_out;
}
