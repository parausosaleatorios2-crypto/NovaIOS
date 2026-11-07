// ---------------------------------------------------------------------------
// Smoke Particle
// origem : assets/effects/toji-skexnxxsmokeparticle.xml
// id     : com.alightcreative.effects.smokeparticle
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxsmokeparticleParams {
    float4 color1;
    float4 color2;
    float2 position;
    float progressa;
    float scale;
    float bright;
    float alpha;
    float angle;
    int blendMode;
};

// --- funcoes auxiliares do efeito
static float2x2 rot2m(float a){
        
	float s = sin(a);
	float c = cos(a);
	
	return float2x2(c, -s, s, c);
    }
    
    static float2 l2s( float2 v ) {
        return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
    }
    
   #define fragCoord __nv_fragCoord
    
   /////////////////////////
   
      #define bpm 128.
      #define beat floor(u.progressa*bpm/60.)
      #define ttime u.progressa*bpm/60.
      static float2x2 r(float a){
      float c=cos(a),s=sin(a);
      return float2x2(c,-s,s,c);
      }
      static float fig(float2 uv){
          uv*=r(-3.1415*.9);
      return min(1.,.1/abs( (__nv_atan(uv.x, uv.y)/2.*3.1415)-sin(- ttime+(min(.6,length(uv)))*3.141592*8.)));
      }

   
   /////////////////////////

fragment float4 fx_toji_skexnxxsmokeparticle(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxsmokeparticleParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            
        float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
        float4 texColorX = float4(0.0,0.0,0.0,1.0) * texColor.a;
        
        float2 syamjaidtz;
        syamjaidtz = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
        syamjaidtz.y*=eng.acLayerSize.y/eng.acLayerSize.x;

        syamjaidtz /= u.scale;
        syamjaidtz *= rot2m((0.0+u.angle)*0.0174533);
        syamjaidtz += float2((0.0+u.position.x), (0.0+u.position.y))*float2(-1.,1.)/500.;

        
        /////////////////////////
        
        // if(u.progressa <= 0.0) { __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm); }
        // else if(u.progressa >= 0.0001) { 

    	float4 __nv_out;
    	
          float2 uv = syamjaidtz;
          // float2 uv = (fragCoord.xy-.5* iResolution.xy)/iResolution.y;
          uv+=float2(cos(u.progressa*.1),sin(u.progressa*.1));
          uv*=r(u.progressa*.01);
          float3 col = float3(-.0);
          for(float y=-1.;y<=1.;y++){
          for(float x=-1.;x<=1.;x++){
          float2 offset = float2(x,y);
          float2 id = floor((uv+offset)*r(length(uv+offset)));
          float2 gv = fract((uv+offset)*r(length(uv+offset)))-.5;
              gv*=r(cos(length(id)*10.));
          float d = fig(gv);+fig(gv+float2(sin(ttime+length(id))*.1,cos(u.progressa)*.1));
          col += float3(d)/exp(length(gv)*6.);
      
          
          }}
          col = mix(float3(u.color1.rgb),float3(u.color2.rgb),col);
          // col = mix(float3(.1,.01,.02),float3(.8,.4,.2),col);
          __nv_out = float4(col,1.0);

        
         	// const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);
            // float4 gradmap;
            // float luminance = dot(__nv_out.rgb, luminanceWeighting);
            // gradmap = mix(u.color1,u.color2,luminance)*__nv_out.a;
        
    	// float4 factorx = mix(__nv_out,gradmap,alphab);
    	float4 factor = mix(texColorX,__nv_out,u.alpha);

        float4 resultfinal;
        if( u.blendMode==0 ) {                // normal
            resultfinal = (factor * u.bright) * texColor.a;
        } else if( u.blendMode==1 ) {         // multiply
            factor *= u.bright;
            float4 c = factor + float4(1.)*(1.-factor.a);
            resultfinal = float4((texColor.rgb/texColor.a)*c.rgb,1.0) * texColor.a;
        } else if( u.blendMode==2 ) {         // screen
            factor *= u.bright;
            resultfinal = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-factor.rgb)),1.0) * texColor.a;
        }
            
    	__nv_out = resultfinal;
    	// }
    return __nv_out;
}
