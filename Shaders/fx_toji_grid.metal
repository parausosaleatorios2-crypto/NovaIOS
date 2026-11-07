// ---------------------------------------------------------------------------
// @am:string/effect_grid_name
// origem : assets/effects/toji-grid.xml
// id     : com.alightcreative.effects.grid
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_gridParams {
    float2 position;
    float spacing;
    float width;
    float4 color;
    int punchout;
    float smoothing;
    int screenSpace;
};

// --- funcoes auxiliares do efeito
static float2 l2s( float2 v ) {
            return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
        }

fragment float4 fx_toji_grid(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_gridParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float2 st;
            if(u.screenSpace) {
                //st = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/length(eng.acLayerSize);
                st = in.acScreenNorm;
                st.x *= eng.acScreenSize.x/eng.acScreenSize.y;
                st.y = 1. - st.y;
            } else {
                st = in.acLayerNorm;
                st.x *= eng.acLayerSize.x/eng.acLayerSize.y;
                st.y = 1. - st.y;
            }
            st -= 0.5;
            st -= u.position/1000.;

            float px = __nv_mod(st.x, u.spacing) / u.spacing;
            float py = __nv_mod(st.y, u.spacing) / u.spacing;

            px = 1.- abs(px - 0.5)*2.;
            py = 1.- abs(py - 0.5)*2.;

            float w = clamp(u.width/u.spacing,0.,1.);
            float s = w*u.smoothing;

            s = mix(s,max(s,0.5*w),smoothstep(0.012,0.01,u.width));
            s = mix(s,max(s,w),smoothstep(0.006,0.005,u.width));

            //px = smoothstep(w,w-s,px)*smoothstep(0.0,s,px);
            //py = smoothstep(w,w-s,py)*smoothstep(0.0,s,py);

            px = smoothstep(1.-w-s, 1.-w+s,px);
            py = smoothstep(1.-w-s, 1.-w+s,py);

            float p = max(px,py);

            float4 c = u.color * p;
            if( u.punchout ) {
                __nv_out = texColor * (1.0-p);
            } else {
                c *= texColor.a;
                __nv_out = c + (texColor*(1.0-c.a));
            }
    return __nv_out;
}
