// ---------------------------------------------------------------------------
// @am:string/effect_hexrotate_name
// origem : assets/effects/toji-hexrotate.xml
// id     : com.alightcreative.effects.hexrotate
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_hexrotateParams {
    float rotate;
    float warpAngle;
    float2 position;
    float size;
    float2 stretch;
    float angle;
    int screenSpace;
    float twirl;
    float seed;
    int maskToLayer;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159;
        const float ulp = PI/240.;

        const float2 hexRatio = float2(1.0, 1.73);
        const float2 hexRatioNorm = normalize(hexRatio);

        static float hexDist(float2 p) {
            return max(dot(abs(p), hexRatioNorm), abs(p.x));
        }

        static void hexTile(float2 st, out float2 uv, out float2 huv, out float2 id) {
            float2 grid = __nv_mod(st, hexRatio)-hexRatio/2.;
            float2 offsetGrid = __nv_mod(st-hexRatio/2., hexRatio)-hexRatio/2.;
            uv = length(grid) < length(offsetGrid) ? grid : offsetGrid;
            huv = float2(__nv_atan(uv.x, uv.y), (.5-hexDist(uv))*2.);
            id = float2(st.x-uv.x, st.y-uv.y);
        }

        static float2x2 rot(float a) {
            float c = cos(a);
            float s = sin(a);
            return float2x2(
                c, -s,
                s, c
            );
        }

        static float2 l2s( float2 v, float4x4 eng.acLTS ) {
            return (float4(v,0.,1.)*eng.acLTS).xy;
        }

        static float rand(float2 co)
        {
            float a = 719.310;
            float b = 178.233;
            float c = 33758.5453;
            float dt= dot(co.xy ,float2(a,b));
            float sn= __nv_mod(dt, 3.14);
            return fract(sin(sn) * c);
        }

fragment float4 fx_toji_hexrotate(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_hexrotateParams&  u    [[buffer(1)]],
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
                st = in.acScreenNorm;
                st -= 0.5;
                st.x *= eng.acScreenSize.x/eng.acScreenSize.y;
            } else {
                st = in.acLayerNorm;
                st -= 0.5;
                st.x *= eng.acLayerSize.x/eng.acLayerSize.y;
            }
            
            float2 scale = float2(u.size/100. * u.stretch.x, u.size/100. * u.stretch.y);
            float2 pos = (u.position/500.) * float2(1., -1.);

            st /= scale;

            st *= rot(u.angle * 0.0174533);

            pos *= rot(-u.angle * 0.0174533);

            float2 modPos = __nv_mod(pos, hexRatio*2.);
            float2 basePos = pos - modPos;
            float2 stepPos = basePos;// hexRatio;
            st -= modPos;

            float2 uv;
            float2 huv;
            float2 id;
            hexTile(st,uv,huv,id);

            id -= stepPos;// * float2(1.,-1.);
            id += 1000.;

            float2 hexCenterScreenCoord;
            hexCenterScreenCoord = st-uv;
            hexCenterScreenCoord += modPos;
            hexCenterScreenCoord *= rot(-u.angle * 0.0174533);
            hexCenterScreenCoord *= scale;
            hexCenterScreenCoord.x /= eng.acLayerSize.x/eng.acLayerSize.y;
            hexCenterScreenCoord += 0.5;
            hexCenterScreenCoord = l2s(hexCenterScreenCoord,eng.acLayerToScreen);

            float randAngle = (0.5 - rand( float2(id.x,id.y+1937.7249*(u.seed+0.01)) ))*2.0*6.28318;

            float adjWarpAngle = u.warpAngle*smoothstep(0.,1.,length(uv));
            float2 dc = in.acScreenNorm - hexCenterScreenCoord;
            dc.x *= eng.acScreenSize.x/eng.acScreenSize.y;
            dc *= rot( ((u.rotate+adjWarpAngle) * 0.0174533) + (u.twirl/360.0 * randAngle) );
            dc.x /= eng.acScreenSize.x/eng.acScreenSize.y;
            float2 sampCoord = hexCenterScreenCoord + dc;

            //float px = id.x;
            //float py = id.y;
            //float dx = rand(float2(px,py+3937.7249*(u.seed+0.01)));
            //float dy = rand(float2(px+328.7319+432.7249*(u.seed+0.01),py-971.382));
            //float2 dv = (float2(dx,dy) - 0.5)*2.0;

            //float2 sampCoord = in.acScreenNorm+dv*strength;
            //sampCoord = abs(__nv_mod(sampCoord-1.0, 2.0)-1.0);
            sampCoord = abs(__nv_mod(sampCoord-1.0, 2.0)-1.0);
            float4 sampColor = inputImg.sample(__nv_smp, sampCoord);

            if( u.maskToLayer ) {
                sampColor *= texColor.a;
                __nv_out = texColor * (1.-sampColor.a) + sampColor;
            } else {
                __nv_out = sampColor;
            }

            //__nv_out = sampColor; // * texColor.a;
    return __nv_out;
}
