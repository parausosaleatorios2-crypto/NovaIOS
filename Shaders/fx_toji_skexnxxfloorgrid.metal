// ---------------------------------------------------------------------------
// 360° Floor Grid
// origem : assets/effects/toji-skexnxxfloorgrid.xml
// id     : com.alightcreative.effects.floorgrid
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxfloorgridParams {
    float4 colora;
    float3 position;
    float progressa;
    float progressb;
    float angle;
    float progressh;
    float progressg;
    float bright;
    float alpha;
    int gradient;
    float4 color1;
    float4 color2;
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
    
   /////////////////////////
    
    // Created by Per Bloksgaard/2020
    
    #define PI 3.14159265358979
    
    static float derivative(float2 p)
    {
        float2 dx = float2(0,0);
        float2 dy = float2(0,0);
     	float2 d = p - floor(p);
        return exp2(-u.progressh * min((1.-d.x) * d.x, (1.-d.y) * d.y) / (dot(dx,dy) + dot(dy,dy) + 2e-3));
    }

fragment float4 fx_toji_skexnxxfloorgrid(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxfloorgridParams&  u    [[buffer(1)]],
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
        // if (adaptive) { syamjaidtz = in.acScreenNorm; }
        // else { 
        syamjaidtz = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
        syamjaidtz.y*=eng.acLayerSize.y/eng.acLayerSize.x;
        // }

        syamjaidtz /= (u.position.z/100.0);
        // syamjaidtz /= scale;
        syamjaidtz *= rot2m((-180.0+u.angle)*0.0174533);
        syamjaidtz += float2(u.position.x,u.position.y) * float2(-1.,1.)/500.;
        
        /////////////////////////

    	float4 result;
    	
      // float3 tot = inputImg.sample(__nv_smp, syamjaidtz).rgb;
      float3 tot = float3(0.);
      float u = u.progressa*0.2;
      float v = -PI*0.6-cos(1.0*0.01)*PI*0.1;
      float f = clamp(cos(0.5),0.,1.)*u.progressb;
      float3 vCamTarget = float3(0.,0.2,0.);
      float3 vCamPos = float3(cos(u)*sin(v)*2.,0.4+f,sin(u)*sin(v));
      float3 vCamForward = normalize(vCamTarget-vCamPos);
      float3 vCamRight = normalize(cross(vCamForward,float3(0.,1.,0.)));
      float3 vCamUp = normalize(cross(vCamRight,vCamForward));    
      for(int m=-1; m<2; m++)
      {
        for(int n=-1; n<2; n++)
        {
          float2 o = float2(float(m),float(n)) * 0.5;
          
          float2 s = syamjaidtz;
          // float2 s = (-in.acScreenNorm + 2.0*(in.acScreenNorm+o));
          // float2 s = (-in.acScreenNorm + 2.0*(in.acScreenNorm+o))/eng.acScreenSize.y;
          
    	  float3 vRayDir = normalize(s.x*vCamRight+s.y*vCamUp+vCamForward*1.5);
          float d = -vCamPos.y / min(vRayDir.y,-1e-6);
          float3 vHitPos = vCamPos + vRayDir * d;
          float sV = u.progressg*derivative(vHitPos.xz*2.);
          float bV = derivative(vHitPos.xz);
          tot += mix(float3(u.colora.rgb), float3(1.-max(bV,sV)), exp2(-.12*length(vCamPos.xz - vHitPos.xz)));
          // tot += mix(float3(.79,.88,1.), float3(1.-max(bV,sV)), exp2(-.12*length(vCamPos.xz - vHitPos.xz)));
        }
      }
      tot *= float(1./9.);
      result = float4(float3(tot),1.);
        
    	const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);
            float4 gradmap;
            float luminance = dot(result.rgb, luminanceWeighting);
            gradmap = mix(u.color1,u.color2,luminance)*result.a;
        
    	float4 factor;
        if (u.gradient) { factor = mix(texColorX,gradmap,1.0) * u.bright; }
    	else { factor = mix(texColorX,result,1.0) * u.bright; }
    	
    	float4 oriTex = mix(texColor,factor,u.alpha);
    	
        float4 resultfinal;
        if( u.blendMode==0 ) {                // normal
            resultfinal = oriTex * texColor.a;
            // resultfinal = (factor * u.bright) * texColor.a;
        } else if( u.blendMode==1 ) {         // multiply
            // factor *= u.bright;
            float4 c = factor + float4(1.)*(1.-factor.a);
            resultfinal = float4((texColor.rgb/texColor.a)*c.rgb,1.0) * texColor.a;
        } else if( u.blendMode==2 ) {         // screen
            // factor *= u.bright;
            resultfinal = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-oriTex.rgb)),1.0) * texColor.a;
        }
            
    	__nv_out = resultfinal;
    return __nv_out;
}
