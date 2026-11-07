// ---------------------------------------------------------------------------
// @am:string/effect_bend_name
// origem : assets/effects/toji-bend.xml
// id     : com.alightcreative.effects.bendwarp
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_bendParams {
    int originType;
    float amount;
    float offset;
    int oppositeType;
    float highLimit;
    float lowLimit;
};

// --- funcoes auxiliares do efeito
#define DEG2RAD 0.01745329251994329576923690768489

        static float2 l2s( float2 v ) {
            return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
        }

        static float2 bend(float2 p, float a, float l, float w, bool vertical) {

           if( abs(a)<0.001 )
           {
               float v = p.y;
               p.y -= clamp(p.y,0.0,l);
               return float2(p.x, v);
           }

           float2  sc = float2(sin(a),cos(a));

           if(vertical) {
               float ra = 0.5*l/a;
               p.x -= ra;
               float s = sign(a);
               float u = abs(ra)-length(p);
               float v = ra*__nv_atan(s*p.y, -s*p.x);
               u *= s;
               return float2(u, v);
           }
           else {
               float ra = 0.5*w/a;
               p.y -= ra;
               float s = sign(a);
               float v = abs(ra)-length(p);
               float u = ra*__nv_atan(s*p.x, -s*p.y);
               v *= s;
               return float2(u, v);

           }
        }

fragment float4 fx_toji_bend(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_bendParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            float2 a;
            float2 b;
            float2 c = float2(0);
            bool vertical;
            float angleVal = u.amount;
            float originOffset = u.offset;
            float adjOffset = u.offset * 0.99;
            if( u.originType==0 ) {
                a = float2(adjOffset,0.5);
                b = float2(1.0,0.5);
                c = float2(0.0, 0.5);

                vertical = false;
            } else if( u.originType==1 ) {
                a = float2(1.0 - adjOffset,0.5);
                b = float2(0.0,0.5);
                c = float2(1.0, 0.5);
                vertical = false;
                angleVal = -u.amount;
            } else if( u.originType==2 ) {
                a = float2(0.5,1.0 - adjOffset);
                b = float2(0.5,0.0);
                c = float2(0.5, 1.0);
                vertical = true;
            } else if( u.originType==3 ) {
                a = float2(0.5,adjOffset);
                b = float2(0.5,1.0);
                c = float2(0.5, 0.0);
                vertical = true;
                angleVal = -u.amount;
            }

            float2 a2b = b - a;
            float2 a2c = in.acLayerNorm - a;
            float checkOffset = dot(a2b, a2c);
            if(checkOffset < 0.0) {
                if(u.oppositeType == 0 || adjOffset <= 0.0 ) {
                    __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm);
                    return __nv_out;
                }
                else {
                    if(adjOffset < u.lowLimit)
                        angleVal *= (adjOffset / u.lowLimit);
                    b = c;
                    a2b = b - a;
                    angleVal = angleVal;
                    if(u.oppositeType == 2)
                        angleVal = -angleVal;
                }
            }
            else {

            if(adjOffset >= u.highLimit * 0.99)
                angleVal *= (1.0 - (adjOffset - u.highLimit * 0.99) / (0.99 - u.highLimit * 0.99));
            }

            angleVal = angleVal*DEG2RAD*0.5 / length(a2b);

            float2 vv = in.acLayerNorm;
            float2 av = a;
            if(vertical) {
                vv.x *= (eng.acLayerSize.x/eng.acLayerSize.y);
                av.x *= (eng.acLayerSize.x/eng.acLayerSize.y);
                float2 uv = bend(vv-av,angleVal,1.0,1.0, vertical);
                uv.x *= eng.acLayerSize.y/eng.acLayerSize.x;
                av.x *= eng.acLayerSize.y/eng.acLayerSize.x;
                uv=l2s(uv+av);
                float insideTexture = step(0.0,uv.x) * step(uv.x,1.0) * step(0.0,uv.y) * step(uv.y,1.0);
                __nv_out = inputImg.sample(__nv_smp, uv) * insideTexture;
            }
            else {
                vv.y *= (eng.acLayerSize.y/eng.acLayerSize.x);
                av.y *= (eng.acLayerSize.y/eng.acLayerSize.x);
                float2 uv = bend(vv-av,angleVal,1.0,1.0, vertical);
                uv.y *= eng.acLayerSize.x/eng.acLayerSize.y;
                av.y *= eng.acLayerSize.x/eng.acLayerSize.y;
                uv=l2s(uv+av);
                float insideTexture = step(0.0,uv.x) * step(uv.x,1.0) * step(0.0,uv.y) * step(uv.y,1.0);
                __nv_out = inputImg.sample(__nv_smp, uv) * insideTexture;
            }
    return __nv_out;
}
