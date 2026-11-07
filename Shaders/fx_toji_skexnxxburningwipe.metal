// ---------------------------------------------------------------------------
// Burning Wipe+
// origem : assets/effects/toji-skexnxxburningwipe.xml
// id     : com.alightcreative.effects.burningwipe
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxburningwipeParams {
    float4 color;
    float4 colorbg;
    float progressa;
    float deltab;
    float deltac;
    float deltad;
    float scale;
    float2 position;
    float2 stretch;
    float alpha;
    float angle;
};

// --- funcoes auxiliares do efeito
float4 newLayer( float4 a, float4 b) {
    return a * (1. - b.a) + b;
    }
    
    float2x2 rot2m(float a){
        
	float s = sin(a);
	float c = cos(a);
	
	return float2x2(c, -s, s, c);
    }
    
    float2 l2s( float2 v ) {
        return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
    }
    
   #define fragCoord __nv_fragCoord.xy
    
   /////////////////////////
   
        float Hash( float2 p)
        {
        	float3 p2 = float3(p.xy,u.deltad);
            return fract(sin(dot(p2,float3(37.1,61.7, 12.4)))*3758.5453123);
        }
        
        float noise(in float2 p)
        {
            float2 i = floor(p);
        	float2 f = fract(p);
        	f *= f * (3.0-2.0*f);
        
            return mix(mix(Hash(i + float2(0.,0.)), Hash(i + float2(1.,0.)),f.x),
        		mix(Hash(i + float2(0.,1.)), Hash(i + float2(1.,1.)),f.x),
        		f.y);
        }
        
        float fbm(float2 p) 
        {
        	float v = 0.0;
        	v += noise(p*1.)*.5;
        	v += noise(p*2.)*.25;
        	v += noise(p*4.)*.125;
        	return v;
        }
   
   /////////////////////////

fragment float4 fx_toji_skexnxxburningwipe(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxburningwipeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> comp [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& comp_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            
        float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
        
        float2 syamjaidtz;
        syamjaidtz = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
        syamjaidtz.y*=eng.acLayerSize.y/eng.acLayerSize.x;

        syamjaidtz /= u.scale;
        syamjaidtz *= rot2m((70.0+u.angle)*0.0174533);
        syamjaidtz += float2((520.0+u.position.x), (0.0+u.position.y))*float2(-1.,1.)/500.;
        
        float2 scaleVec;
        scaleVec = float2(u.scale*u.stretch.x,u.scale*u.stretch.y);
        syamjaidtz /= scaleVec;
        
        /////////////////////////
        
    	float4 __nv_out;
    	
                float2 uv = syamjaidtz;
        	
        	float3 src = inputImg.sample(__nv_smp, in.acScreenNorm).rgb;
            
        	float4 tgt = float4(u.colorbg.rgb, 0.0);
        	
        	float4 col = float4(src, 1.0);
        	
        	float ctime = __nv_mod(u.progressa*.5, 2.5);
        	
        	float d = uv.x+uv.y*0.5 + u.deltab*fbm(uv*u.deltac) + ctime*1.3;
        	if (d >0.35) col.rgb = clamp(col.rgb-(d-0.35)*10.,0.0,1.0);
        	if (d >0.47) {
        	if (d < 0.5 ) col.rgb += (d-0.4)*33.0*0.5*(0.0+noise(100.*uv+float2(-ctime*2.,0.)))*float3(u.color.rgb);
        	else col += tgt; }
        	
        	__nv_out = col * texColor.a;
                    
         	__nv_out = mix(texColor, __nv_out, u.alpha);
    return __nv_out;
}
