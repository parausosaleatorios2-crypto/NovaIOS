// ---------------------------------------------------------------------------
// toji-skexnxxsrefractionwarp.xml
// origem : assets/effects/toji-skexnxxsrefractionwarp.xml
// id     : 636f6d2e616c6967687463726561746976652e656666656374732e616476616e636577617270
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxsrefractionwarpParams {
    int autop;
    float PROGRESS;
    float SPEEED;
    float scale;
    float2 position;
    float intensity;
    float frequency;
    float emboss;
    float steps;
    float angle;
    float delta;
    float gain;
    float reflectionCutOff;
    float reflectionIntensity;
    float speed;
    float speed_x;
    float speed_y;
    float alpha;
};

// --- funcoes auxiliares do efeito
//////////////////////////
    static float4 newLayer( float4 a, float4 b) { return a * (1. - b.a) + b;  }
    static float2x2 rot2m(float a){ float s = sin(a); float c = cos(a); return float2x2(c, -s, s, c); }
    static float2 l2s( float2 v ) { return (float4(v,0.,1.)*eng.acLayerToScreen).xy; }
    #define fragCoord __nv_fragCoord.xy
    
   /////////////////////////
   
        const float PI = 3.1415926535897932;
        
          static float col(float2 coord,float time)
          {
            float delta_theta = 2.0 * PI / u.angle;
            float col = 0.0;
            float theta = 0.0;
            for (int i = 0; i < int(u.steps); i++)
            {
              float2 adjc = coord;
              theta = delta_theta*float(i);
              adjc.x += cos(theta)*time*u.speed + time * u.speed_x;
              adjc.y -= sin(theta)*time*u.speed - time * u.speed_y;
              col = col + cos( (adjc.x*cos(theta) - adjc.y*sin(theta))*u.frequency)*u.intensity;
            }
        
            return cos(col);
          }
    //////////////////////////

fragment float4 fx_toji_skexnxxsrefractionwarp(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxsrefractionwarpParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> xcipher [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& xcipher_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

        if( eng.acPass == 0 ) { __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm.st); } else if( eng.acPass==1 ) {
        float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
        float4 texColorX = float4(0.0,0.0,0.0,1.0) * texColor.a;
        
        float2 image_size = __nv_getTexSize(inputImg_info.size);
        float2 iResolution = float2(eng.acScreenSize.x, eng.acScreenSize.y);
        float2 iMouse = float2(0.5, 0.5);
        float time = u.autop? u.PROGRESS + (eng.acTime*u.SPEEED) : u.PROGRESS;
        
        float2 syamjaidtz;
        syamjaidtz = in.acScreenNorm.st; 
        syamjaidtz /= u.scale;
        syamjaidtz *= rot2m((-180.0)*0.0174533);
        syamjaidtz += float2((0.0+u.position.x), (0.0-u.position.y))*float2(-1.,1.)/500.;
        
        /////////////////////////
        
    	float4 __nv_out;
    	
        float2 p = float2(-syamjaidtz.x,syamjaidtz.y);
        // float2 p = syamjaidtz;
        float2 c1 = p;
        float2 c2 = p;
        float cc1 = col(c1,time);
        
        c2.x += iResolution.x/u.delta;
        float dx = u.emboss*(cc1-col(c2,time))/u.delta;
        
        c2.x = p.x;
        c2.y += iResolution.y/u.delta;
        float dy = u.emboss*(cc1-col(c2,time))/u.delta;
        
        c1.x += dx*2.;
        c1.y = -(c1.y+dy*2.);
        
        float alphaa = 1.+dot(dx,dy)*u.gain;
        	
        float ddx = dx - u.reflectionCutOff;
        float ddy = dy - u.reflectionCutOff;
        if (ddx > 0. && ddy > 0.)
        	alphaa = pow(u.alpha, ddx*ddy*(u.reflectionIntensity*1000.0));
        	
        float4 col = inputImg.sample(__nv_smp, c1)*(alphaa);
        __nv_out = col;
        
    	    float4 factor = mix(texColorX,__nv_out,1.0);

    	__nv_out = mix(texColor, factor, u.alpha);
          }
    return __nv_out;
}
