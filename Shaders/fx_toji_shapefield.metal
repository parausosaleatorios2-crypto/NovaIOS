// ---------------------------------------------------------------------------
// @am:string/effect_scatter_field_name
// origem : assets/effects/toji-shapefield.xml
// id     : com.alightcreative.effects.shapefield
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_shapefieldParams {
    float3 pos;
    float density;
    float evolution;
    float seed;
    float scale;
    float shapeSize;
    float shapeAngle;
    float sizeVariance;
    float angleVariance;
    float layerCount;
    float fade;
    float alpha;
    float slack;
    int blendMode;
    int coloring;
    float4 color1;
    float4 color2;
    float4 color3;
    int lockLuminance;
    int lockSaturation;
    int interpHue;
};

// --- funcoes auxiliares do efeito
static float rand2(float2 co){
            return fract(sin(dot(co.xy ,float2(12.9898,78.233))) * 43758.5453);
        }

        float rand3 (float3 v) {
            return fract(sin(dot(v,float3(12.9898,78.233,193.71)))*43758.5453123);
        }

        float rand4 (float4 v) {
            return fract(sin(dot(v,float4(12.9898,78.233,193.71,397.318)))*43758.5453123);
        }

        float2 randVec2(float3 v) {
            return float2( rand4(float4(v,5.124)), rand4(float4(v,3.0)));
        }

        float3 randVec3(float3 v) {
            return float3( rand4(float4(v,5.124)), rand4(float4(v,7.23464)), rand4(float4(v,3.0)));
        }
        
        float2 l2s( float2 v ) {
            return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
        }
        
        float2x2 rot(float a) {
            float c = cos(a);
            float s = sin(a);
            return float2x2(
                c, -s,
                s, c
            );
        }
        
        float3 hsv2rgb(float3 c)
        {
            float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
            float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
            return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
        }

        float3 rgb2hsv(float3 c)
        {
            float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
            float4 p = mix(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
            float4 q = mix(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

            float d = q.x - min(q.w, q.y);
            float e = 1.0e-10;
            return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
        }
        
        float4 mixColors(float4 a, float4 b, float t) {
            float4 result;
            if( u.interpHue ) {
                result = float4(hsv2rgb(mix(rgb2hsv(a.rgb),rgb2hsv(b.rgb),t)),mix(a.a,b.a,t));
            } else {
                result = mix(a,b,t);
            }
            return result;
        }
        
        float4 getColor(float3 id, float layerDepth) {
            float4 result;
            if( u.coloring==0 ) {
                result = float4(0.);
            } else if( u.coloring==1 ) {  // Solid
                result = u.color1;
            } else if( u.coloring==2 ) {  // Random 1-color
                result = u.color1 * rand4(float4(id,0.1974));
            } else if( u.coloring==3 ) {  // Random 2-color
                result = mixColors(u.color1,u.color2,rand4(float4(id,0.1974)));
            } else if( u.coloring==4 ) {  // Random 3-color
                float2 rr = randVec2(id);
                result = mixColors(mixColors(u.color1,u.color2,rr.x),u.color3,rr.y);
            } else if( u.coloring==5 ) {  // Depth 1-color
                result = u.color1 * layerDepth;
            } else if( u.coloring==6 ) {  // Depth 2-color
                result = mixColors(u.color1,u.color2,layerDepth);
            } else if( u.coloring==7 ) {  // Depth 3-color
                result = layerDepth < 0.5 ? mixColors(u.color1,u.color2,layerDepth*2.) : mixColors(u.color2,u.color3,(layerDepth-0.5)*2.);
            } else if( u.coloring==8 ) {  // Depth+Random
                result = mixColors(u.color3,mixColors(u.color1,u.color2,rand4(float4(id,0.1974))),layerDepth);
            } else {
                result = float4(0.);
            }
            return result;
        }

        float4 shapeGrid(float2 st, float layer, float layerDepth) {
            st *= 10.;
            float2 uv = fract(st);
            float3 id = float3(floor(st),layer);
            float size = u.sizeVariance < 0.0001 ? u.shapeSize : min(u.shapeSize, u.shapeSize * (1.+((rand4(float4(id,0.351))-0.5)*u.sizeVariance)));
            float angle = u.angleVariance < 0.0001 ? 0. : ((rand4(float4(id,0.2793))-0.5)*u.angleVariance*12.56636);
            float rr = rand3(id);
            size *= smoothstep(rr,rr+0.008,u.density);
            if( size < 0.00001 ) return float4(0.);
            uv -= 0.5;
            uv *= eng.acLayerSize.x > eng.acLayerSize.y ? float2(1.,eng.acLayerSize.x/eng.acLayerSize.y) : float2(eng.acLayerSize.y/eng.acLayerSize.x,1.);
            uv /= size;
            float maxDisplace = (1./size - 1.);
            float2 displace;
            if( abs(u.evolution) > 0.001 ) {
                displace = mix(randVec2(id+floor(u.evolution)),randVec2(id+floor(u.evolution+1.)),fract(u.evolution));
            } else {
                displace = randVec2(id);
            }
            uv += clamp((displace-0.5)*max(1.0,maxDisplace)*u.slack,-maxDisplace,maxDisplace);
            uv *= rot(angle + (u.shapeAngle * 0.0174532925));
            uv += 0.5;
            uv.y = 1. - uv.y;
            float4 texColor = inputImg.sample(__nv_smp, l2s(uv));
            float4 blendColor = getColor(id,layerDepth);
            
            float4 result;
            if(u.lockLuminance || u.lockSaturation) {
                float3 texHsv = rgb2hsv(texColor.a <= 0.0 ? float3(0.) : (texColor.rgb/texColor.a));
                float3 blendHsv = rgb2hsv(blendColor.a <= 0.0 ? float3(0.) : (blendColor.rgb/blendColor.a));
                if( u.lockLuminance ) blendHsv.z = texHsv.z;
                if( u.lockSaturation ) blendHsv.y = texHsv.y;
                result = float4(hsv2rgb(mix(texHsv, blendHsv, blendColor.a)),1.) * texColor.a;
            } else {
                result = float4(mix(texColor.a <= 0.0 ? float3(0.) : (texColor.rgb/texColor.a), blendColor.a <= 0.0 ? float3(0.) : (blendColor.rgb/blendColor.a), blendColor.a),1.) * texColor.a;
            }
            return result;
            
            //return inputImg.sample(__nv_smp, l2s(uv)) * step(rand3(id),u.density);
        }

fragment float4 fx_toji_shapefield(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_shapefieldParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            //float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            
            //float2 st = (in.acScreenNorm - 0.5) * float2(1., -1.);
            float2 st = in.acLayerNorm;
            st.y = 1. - st.y;
            st -= 0.5;
            st.x *= eng.acLayerSize.x/eng.acLayerSize.y;

            st /= u.scale*6.;
            
            float2 parallax = (u.pos.xy / 1000.) + 25.35;
            float depth = u.pos.z / 100.;

            float4 result = float4(0.);

            float f = fract(depth);
            float layer = floor(depth);
            float filteredSeed = u.seed/5.0;
            
            for( float i=u.layerCount-1.; i>=0.; i -= 1. ) {
                float2 uv = st;
                uv *= ((1.+i)-f)/9.;
                uv += parallax;
                float layerDepth = smoothstep(u.layerCount,u.layerCount*(0.9999-u.fade),(i+1.)-f);
                float4 color = shapeGrid(uv, layer+i+filteredSeed, layerDepth)*u.alpha*layerDepth;
                
                if( u.blendMode==1 ) {
                    float3 fg = color.a<0.0001 ? float3(0.) : color.rgb/color.a;
                    float3 bg = result.a<0.0001 ? float3(1.) : result.rgb/result.a;
                    result = result * (1.-color.a) + float4(fg*bg,1.0)*color.a;
                } else if( u.blendMode==2 ) {
                    float3 fg = color.a<0.0001 ? float3(1.) : color.rgb/color.a;
                    float3 bg = result.a<0.0001 ? float3(0.) : result.rgb/result.a;
                    result = result * (1.-color.a) + float4(1.-(1.-fg)*(1.-bg),1.0)*color.a;
                } else {
                    result = result * (1.-color.a) + color;
                }

            }
            
            __nv_out = result;
    return __nv_out;
}
