// ---------------------------------------------------------------------------
// Glitch VHS
// origem : assets/effects/toji-skexnxxglitchvhs.xml
// id     : com.alightcreative.effects.glitchvhs
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxglitchvhsParams {
    float progressa;
    float AMOUNT;
    float alpha;
};

// --- funcoes auxiliares do efeito
float2x2 rot2m(float a){
        
	float s = sin(a);
	float c = cos(a);
	
	return float2x2(c, -s, s, c);
    }
    
    float2 l2s( float2 v ) {
        return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
    }
    
   /////////////////////////
    
   float sat( float t ) {
    	return clamp( t, 0.0, 1.0 );
    }
    
    float2 sat( float2 t ) {
    	return clamp( t, 0.0, 1.0 );
    }
    
    //remaps inteval [a;b] to [0;1]
    float remap  ( float t, float a, float b ) {
    	return sat( (t - a) / (b - a) );
    }
    
    //note: /\ t=[0;0.5;1], y=[0;1;0]
    float linterp( float t ) {
    	return sat( 1.0 - abs( 2.0*t - 1.0 ) );
    }
    
    float3 spectrum_offset( float t ) {
        float t0 = 3.0 * t - 1.5;
    	return clamp( float3( -t0, 1.0-abs(t0), t0), 0.0, 1.0);
        /*
    	float3 ret;
    	float lo = step(t,0.5);
    	float hi = 1.0-lo;
    	float w = linterp( remap( t, 1.0/6.0, 5.0/6.0 ) );
    	float neg_w = 1.0-w;
    	ret = float3(lo,1.0,hi) * float3(neg_w, w, neg_w);
    	return pow( ret, float3(1.0/2.2) );
    */
    }
    
    //note: [0;1]
    float rand( float2 n ) {
      return fract(sin(dot(n.xy, float2(12.9898, 78.233)))* 43758.5453);
    }
    
    //note: [-1;1]
    float srand( float2 n ) {
    	return rand(n) * 2.0 - 1.0;
    }
    
    float mytrunc( float x, float num_levels )
    {
    	return floor(x*num_levels) / num_levels;
    }
    float2 mytrunc( float2 x, float num_levels )
    {
    	return floor(x*num_levels) / num_levels;
    }

fragment float4 fx_toji_skexnxxglitchvhs(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxglitchvhsParams&  u    [[buffer(1)]],
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
        syamjaidtz = in.acScreenNorm; 
        
        /////////////////////////

    	float4 result;
    	
    	float aspect = eng.acScreenSize.x / eng.acScreenSize.y;
    	float2 uv = syamjaidtz;
    	
    	float time = __nv_mod(u.progressa, 32.0); // + modelmat[0].x + modelmat[0].z;
    
    	float GLITCH = 0.1 + 0.0 / syamjaidtz.x;
    	
        // float rdist = length( (uv - float2(0.5,0.5))*float2(aspect, 1.0) )/1.4;
        // GLITCH *= rdist;
        
    	float gnm = sat( GLITCH );
    	float rnd0 = rand( mytrunc( float2(time, time), 6.0 ) );
    	float r0 = sat((1.0-gnm)*0.7 + rnd0);
    	float rnd1 = rand( float2(mytrunc( uv.x, 10.0*r0 ), time) ); //horz
    	
    	// float r1 = 1.0f - sat( (1.0f-gnm)*0.5f + rnd1 );
    	float r1 = 0.5 - 0.5 * gnm + rnd1;
    	
    	r1 = 1.0 - max( 0.0, ((r1<1.0) ? r1 : 0.9999999) ); //note: weird ass bug on old drivers
    	float rnd2 = rand( float2(mytrunc( uv.y, 40.0*r1 ), time) ); //vert
    	float r2 = sat( rnd2 );
    
    	float rnd3 = rand( float2(mytrunc( uv.y, 10.0*r0 ), time) );
    	float r3 = (1.0-sat(rnd3+0.8)) - 0.1;
    
    	float pxrnd = rand( uv + time );
    
    	float ofs = 0.05 * r2 * GLITCH * ( rnd0 > 0.5 ? 1.0 : -1.0 );
    	ofs += 0.5 * pxrnd * ofs;
    
    	uv.y += 0.1 * r3 * GLITCH;
    
        // const int NUM_SAMPLES = 10;
        float RCP_NUM_SAMPLES_F = 1.0 / u.AMOUNT;
        // const float RCP_NUM_SAMPLES_F = 1.0 / float(NUM_SAMPLES);
        
    	float4 sum = float4(0.0);
    	float3 wsum = float3(0.0);
    	for( int i=0; i<int(u.AMOUNT); ++i )
    	{
    		float t = float(i) * RCP_NUM_SAMPLES_F;
    		uv.x = sat( uv.x + ofs * t );
    		float4 samplecol = inputImg.sample(__nv_smp, uv);
    		float3 s = spectrum_offset( t );
    		samplecol.rgb = samplecol.rgb * s;
    		sum += samplecol;
    		wsum += s;
    	}
    	sum.rgb /= wsum;
    	sum.a *= RCP_NUM_SAMPLES_F;
            
    	result.a = sum.a;
    	result.rgb = sum.rgb;
        
    	float4 factor = mix(texColorX,result,1.0);
    	
        float4 resultfinal = (factor * 1.0) * texColor.a;
            
    	__nv_out = mix(texColor,resultfinal,u.alpha);
    return __nv_out;
}
