// ---------------------------------------------------------------------------
// @am:string/effect_hexarray_name
// origem : assets/effects/toji-hexarray.xml
// id     : com.alightcreative.effects.hexarray
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_hexarrayParams {
    float2 position;
    float size;
    float stretch;
    int colorMode;
    float4 color1;
    float4 color2;
    float4 color3;
    float alpha;
    int blendMode;
    int alphaScale;
    int copyAlpha;
    float lineWidth;
    float feather;
    float angle;
    int screenSpace;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159;
        const float ulp = PI/240.;

        const float2 hexRatio = float2(1.0, 1.73);
        const float2 hexRatioNorm = normalize(hexRatio);

        float hexDist(float2 p) {
            return max(dot(abs(p), hexRatioNorm), abs(p.x));
        }

        void hexTile(float2 st, out float2 uv, out float2 huv, out float2 id) {
            float2 grid = __nv_mod(st, hexRatio)-hexRatio/2.;
            float2 offsetGrid = __nv_mod(st-hexRatio/2., hexRatio)-hexRatio/2.;
            uv = length(grid) < length(offsetGrid) ? grid : offsetGrid;
            huv = float2(__nv_atan(uv.x, uv.y), (.5-hexDist(uv))*2.);
            id = float2(st.x-uv.x, st.y-uv.y);
        }

        float2x2 rot(float a) {
            float c = cos(a);
            float s = sin(a);
            return float2x2(
                c, -s,
                s, c
            );
        }

        float2 l2s( float2 v, float4x4 eng.acLTS ) {
            return (float4(v,0.,1.)*eng.acLTS).xy;
        }

fragment float4 fx_toji_hexarray(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_hexarrayParams&  u    [[buffer(1)]],
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
            
            float2 scale = float2(u.size/100., u.size/100. * u.stretch);
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

            float2 screenCoord;
            screenCoord = st-uv;
            screenCoord += modPos;
            screenCoord *= rot(-u.angle * 0.0174533);
            screenCoord *= scale;
            screenCoord.x /= eng.acLayerSize.x/eng.acLayerSize.y;
            screenCoord += 0.5;
            screenCoord = l2s(screenCoord,eng.acLayerToScreen);
            float4 centerColor = inputImg.sample(__nv_smp, screenCoord);

            float pp;
            if( u.alphaScale ) {
                pp = max(1. - centerColor.a, u.lineWidth);
            } else if (u.blendMode == 3) {
                pp = max(1. - step(0.001,centerColor.a), u.lineWidth);
            } else {
                pp = u.lineWidth;
            }
            //float p = smoothstep(pp,pp+(1.0-pp)*u.feather,huv.y);
            pp = ((pp-0.5) * (1.0+u.feather)) + 0.5;
            //pp *= 1.0 - u.feather;
            //pp += u.feather / 2.;
            float p = smoothstep(pp-u.feather/2.,pp+u.feather/2.,huv.y);

            float4 color;
            if( u.colorMode == 0 ) {
                color = centerColor;
            } else if ( u.colorMode == 1 ) {
                color = u.color1;
                color.rgb *= color.a;
            } else if ( u.colorMode == 2 ) {
                float ys = step(1.73/2.,__nv_mod(id.y, 1.73));
                color = mix(u.color1,u.color2,ys);
                color.rgb *= color.a;
            } else if ( u.colorMode == 3 ) {
                float ys = step(1.73/2.,__nv_mod(id.y, 1.73));
                color = u.color1;
                color = mix(color,u.color2,step(0.33,__nv_mod(id.x + ys*1.66, 3.)));
                color = mix(u.color3,color,step(0.33,__nv_mod(id.x + 1.16 + ys*1.66, 3.)));
                color.rgb *= color.a;
            } else if ( u.colorMode == 4 ) {
                color = u.color1;
                color = mix(color,u.color3,smoothstep( PI*2./3. - ulp, PI*2./3. + ulp, huv.x + PI));
                color = mix(color,u.color2,smoothstep( PI/3. - ulp, PI/3. + ulp, huv.x));
                color.rgb *= color.a;
            } else if ( u.colorMode == 5 ) {
                float section = floor((huv.x + PI) * 3. / PI);
                if( section < 1. ) {
                    color = u.color1;
                } else if (section < 2. ) {
                    color = u.color2;
                } else if (section < 3. ) {
                    color = u.color1;
                } else if (section < 4. ) {
                    color = u.color3;
                } else if (section < 5. ) {
                    color = u.color1;
                } else {
                    color = u.color2;
                }
                color.rgb *= color.a;
            } else if ( u.colorMode == 6 ) {
                float section = floor((huv.x + PI) * 6. / PI);
                if( section < 1. ) {
                    color = u.color1;
                } else if (section < 5. ) {
                    color = u.color2;
                } else if (section < 9. ) {
                    color = u.color3;
                } else {
                    color = u.color1;
                }
                color.rgb *= color.a;
            //} else if ( u.colorMode == 7 ) {
            //    color = mix(u.color1,u.color2,(sin(id.x/2.0)+1.)/2.);
            }

            //float4 c = color * p;

            color *= p;

            if( u.copyAlpha ) {
                color *= centerColor.a;
            }

            color *= u.alpha;

            float4 result;
            if( u.blendMode==0 ) {                // normal
                color *= texColor.a;
                result = color + (texColor*(1.0-color.a));
            } else if( u.blendMode==1 ) {         // multiply
                float4 c = color + float4(1.)*(1.-color.a);
                result = float4((texColor.rgb/texColor.a)*c.rgb,1.0) * texColor.a;
            } else if( u.blendMode==2 ) {         // screen
                result = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-color.rgb)),1.0) * texColor.a;
            } else if( u.blendMode==3 ) {         // overflow
                result = color;
            } else if( u.blendMode==4 ) {         // punchout
                result = texColor * (1.0-p);
            } else if( u.blendMode==5 ) {         // overlay
                float3 top = color.rgb / color.a;
                float3 bot = texColor.rgb / texColor.a;
                float3 t = smoothstep(0.5,0.5,bot);
                float3 r3 =
                        t * (1. - (1.-2.*(bot-0.5)) * (1.-top)) +
                        (1.-t) * ((2.*bot) * top);
                float4 r4 = float4(r3, 1.0) * color.a * texColor.a;
                result = texColor * (1.-r4.a) + r4;
            }

            __nv_out = result;
    return __nv_out;
}
