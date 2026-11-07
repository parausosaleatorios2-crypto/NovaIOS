// ---------------------------------------------------------------------------
// Meteor
// origem : assets/effects/toji-skexnxxmeteor.xml
// id     : com.alightcreative.effects.meteor
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxmeteorParams {
    int autop;
    float PROGRESS;
    float xxa;
    float xxx;
    float xxc;
    float scale;
    float2 position;
    float2 stretch;
    float bright;
    float alpha;
    float angle;
    float4 color1;
    float4 color2;
    int mirrx;
    int mirry;
    int blendMode;
};

// --- funcoes auxiliares do efeito
static float4 newLayer( float4 a, float4 b) {
    return a * (1. - b.a) + b;
    }
    
    static float2x2 rot2m(float a){
        
	float s = sin(a);
	float c = cos(a);
	
	return float2x2(c, -s, s, c);
    }
    
    static float2 l2s( float2 v ) {
        return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
    }
    
   #define fragCoord __nv_fragCoord.xy
    
   /////////////////////////
   
        #define PI 3.14159
        #define TAU 6.28318
        
        static float3 spunk(float2 uv)
        {
          float3 col = float3(u.color1.rgb);    // Drop Colour
          // float3 col = float3(.55,0.35,1.225);    // Drop Colour
          uv.x += sin(0.2+uv.y*0.8)*u.xxa;
          uv.y += sin(0.2+uv.x*0.8)*u.xxx;
          // uv.x += sin(0.2+uv.y*0.8)*0.5;
            uv.x = uv.x*50.0;           // H-Count
            float dx = fract(uv.x);
            uv.x = floor(uv.x);
            float t =  u.autop? u.PROGRESS+(eng.acTime*0.5) : u.PROGRESS * 0.5;
            uv.y *= u.xxc;             // u.stretch
            // uv.y *= 0.15;             // u.stretch
            float o=sin(uv.x*215.4);        // offset
            float s=cos(uv.x*33.1)*0.3 + 0.7;      // speed
            float trail = mix(95.0,35.0,s);     // trail length
            float yv = fract(uv.y + t*s + o) * trail;
            yv = 1.0/yv;
            yv = smoothstep(0.0,1.0,yv*yv);
            yv = sin(yv*PI)*(s*5.0);
            float d2 = sin(dx*PI);
            yv *= d2*d2;
            col = col*yv;
          return col;
        }
   
   /////////////////////////

fragment float4 fx_toji_skexnxxmeteor(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxmeteorParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            
        float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
        float4 texColorX = float4(0.0,0.0,0.0,1.0) * texColor.a;
        
        float2 image_size = __nv_getTexSize(inputImg_info.size);
        float2 iRes = float2(eng.acScreenSize.x, eng.acScreenSize.y);
        
        float maxF = max(eng.acScreenSize.x, eng.acScreenSize.y);
        float2 texelSize = 1.0 / float2(maxF, maxF);
        
        float2 xnxx;
        xnxx = in.acScreenNorm; 
        
        float2 nxnn;
        nxnn = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
        nxnn.y *=eng.acLayerSize.y/eng.acLayerSize.x;
        nxnn /= 10.0;
        
        float2 syamjaidtz;
        syamjaidtz = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
        syamjaidtz.y *=eng.acLayerSize.y/eng.acLayerSize.x;

        syamjaidtz /= u.scale;
        syamjaidtz *= rot2m((0.0+u.angle)*0.0174533);
        syamjaidtz += float2((0.0+u.position.x), (0.0+u.position.y))*float2(-1.,1.)/500.;
        
        float2 scaleVec;
        scaleVec = float2(u.scale*u.stretch.x,u.scale*u.stretch.y);
        syamjaidtz /= scaleVec;
        
        if(u.mirrx) { syamjaidtz.x = 1. - syamjaidtz.x; }
        if(u.mirry) { syamjaidtz.y = 1. - syamjaidtz.y; }
        
        /////////////////////////
        
    	float4 __nv_out;
    	
            float time= u.autop? u.PROGRESS+(eng.acTime*0.5) : u.PROGRESS/10.0;
            // float2 resolution = syamjaidtz;
            float2 resolution = xnxx;
            float an = u.autop? sin(u.PROGRESS+(eng.acTime*0.5)*64564.8) : sin(u.PROGRESS*64564.8);
        
            float3 ro = float3( 16.0*cos(an), 0.0, 16.0*sin(an) );
            float3 ta = float3( 0.0, 0.0, 0.0 );
            // camera matrix
            float3 ww = normalize( ta - ro );
            float3 uu = normalize( cross(ww,float3(0.0,1.0,0.0) ) );
            float3 vv = normalize( cross(uu,ww));
        
            float3 tot = float3(0.0);
              // float2 ppp = xnxx;
              float2 ppp = syamjaidtz;
              // float2 ppp = (-iRes.xy + 2.*(fragCoord.xy))/iRes.y;
        
                float3 bbk = spunk(ppp.xy);
          
                // float2 p = xnxx;
                float2 p = nxnn;
                // float2 p = (-iRes.xy + 2.0*fragCoord.xy)/iRes.y;
        
                float3 rd = normalize( p.x*uu + p.y*vv + 1.5*ww );
                float v = 1.0-abs(p.y);
                float3 col = bbk*v*2.0 * 3.0; //float3(v*0.1);
                col = sqrt( col );
               tot += col;
              
          __nv_out = float4( tot, 0.0 );
        
    	float4 factor = mix(texColorX,__nv_out,1.0);

        float4 resultfinal;
        if( u.blendMode==0 ) {                // normal
            // resultfinal = (factor * u.bright) * texColor.a;
            resultfinal = (newLayer(u.color2, factor) * u.bright) * texColor.a;
        } else if( u.blendMode==1 ) {         // multiply
            factor *= u.bright;
            float4 c = factor + float4(1.)*(1.-factor.a);
            resultfinal = float4((texColor.rgb/texColor.a)*c.rgb,1.0) * texColor.a;
        } else if( u.blendMode==2 ) {         // screen
            factor *= u.bright;
            resultfinal = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-factor.rgb)),1.0) * texColor.a;
        }
            
    	__nv_out = mix(texColor, resultfinal, u.alpha);
    	//
    return __nv_out;
}
