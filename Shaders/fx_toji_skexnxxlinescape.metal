// ---------------------------------------------------------------------------
// Linescape
// origem : assets/effects/toji-skexnxxlinescape.xml
// id     : com.alightcreative.effects.linescape
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxlinescapeParams {
    float AMOUNT;
    float progressa;
    float progressb;
    float scale;
    float bright;
    float alpha;
    float angle;
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
    
    float2 l2s( float2 v ) {
        return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
    }
    
   #define fragCoord __nv_fragCoord
    
   /////////////////////////
   
   const float PI = 3.141592654;
    
    // Noise from IQ
    float2 hash( float2 p )
    {
    	p = float2( dot(p,float2(127.1,311.7)),
    			 dot(p,float2(269.5,183.3)) );
    	return -1.0 + 2.0*fract(sin(p)*43758.5453123);
    }
    
    float noise( in float2 p )
    {
    	const float K1 = 0.366025404;
    	const float K2 = 0.211324865;
    	
    	float2 i = floor( p + (p.x+p.y)*K1 );
    	
    	float2 a = p - i + (i.x+i.y)*K2;
    	float2 o = (a.x>a.y) ? float2(1.0,0.0) : float2(0.0,1.0);
    	float2 b = a - o + K2;
    	float2 c = a - 1.0 + 2.0*K2;
    	
    	float3 h = max( 0.5-float3(dot(a,a), dot(b,b), dot(c,c) ), 0.0 );
    	
    	float3 n = h*h*h*h*float3( dot(a,hash(i+0.0)), dot(b,hash(i+o)), dot(c,hash(i+1.0)));
    	
    	return dot( n, float3(70.0) );
    }
    
    const float2x2 m = float2x2( 0.80,  0.60, -0.60,  0.80 );
    
    float fbm4( in float2 p )
    {
        float f = 0.0;
        f += 0.5000*noise( p ); p = m*p*2.02;
        f += 0.2500*noise( p ); p = m*p*2.03;
        f += 0.1250*noise( p ); p = m*p*2.01;
        f += 0.0625*noise( p );
        return f;
    }
    
    float fbm6( in float2 p )
    {
        float f = 0.0;
        f += 0.5000*noise( p ); p = m*p*2.02;
        f += 0.2500*noise( p ); p = m*p*2.03;
        f += 0.1250*noise( p ); p = m*p*2.01;
        f += 0.0625*noise( p ); p = m*p*2.04;
        f += 0.031250*noise( p ); p = m*p*2.01;
        f += 0.015625*noise( p );
        return f;
    }
    
    float4x4 CreatePerspectiveMatrix(in float fov, in float aspect, in float near, in float far)
    {
        float4x4 m = float4x4(0.0);
        float u.angle = (fov / 180.0) * PI;
        float f = 1. / tan( u.angle * 0.5 );
        m[0][0] = f / aspect;
        m[1][1] = f;
        m[2][2] = (far + near) / (near - far);
        m[2][3] = -1.;
        m[3][2] = (2. * far*near) / (near - far);
        return m;
    }
    
    float4x4 CamControl( float3 eye, float pitch)
    {
        float cosPitch = cos(pitch);
        float sinPitch = sin(pitch);
        float3 xaxis = float3( 1, 0, 0. );
        float3 yaxis = float3( 0., cosPitch, sinPitch );
        float3 zaxis = float3( 0., -sinPitch, cosPitch );
        // Create a 4x4 view matrix from the right, up, forward and eye position vectors
        float4x4 viewMatrix = float4x4(
            float4(       xaxis.x,            yaxis.x,            zaxis.x,      0 ),
            float4(       xaxis.y,            yaxis.y,            zaxis.y,      0 ),
            float4(       xaxis.z,            yaxis.z,            zaxis.z,      0 ),
            float4( -dot( xaxis, eye ), -dot( yaxis, eye ), -dot( zaxis, eye ), 1 )
        );
        return viewMatrix;
    }
   
   /////////////////////////

fragment float4 fx_toji_skexnxxlinescape(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxlinescapeParams&  u    [[buffer(1)]],
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
        syamjaidtz *= rot2m((-180.0+u.angle)*0.0174533);
        syamjaidtz += float2((-250.0), (200.0))*float2(-1.,1.)/500.;
        // syamjaidtz += float2((-250.0+position.x), (200.0+position.y))*float2(-1.,1.)/500.;

        
        /////////////////////////

    	float4 __nv_out;
    	
    	float2 uv = syamjaidtz;
        float2 p = 2.*uv-1.;
    	p.x *= eng.acScreenSize.x/eng.acScreenSize.y;
    		 
    	float3 eye = float3(0., 0.25+0.25*cos(0.5*u.progressa), -1.);
        float4x4 projmat = CreatePerspectiveMatrix(50., eng.acScreenSize.x/eng.acScreenSize.y, 0.1, 10.);
        float4x4 viewmat = CamControl(eye, -5.*PI/180.);
        float4x4 vpmat = viewmat*projmat;
        
    	float3 col = float3(0.);
    	float3 acc = float3(0.);
    	float d;
    	
        float4 pos = float4(0.);
    	float lh = -eng.acScreenSize.y;
    	float off = 0.1*u.progressb;
    	float h = 0.;
    	float z = 0.1;
    	float zi = 0.05;
    	for (float i=0.0; i<(u.AMOUNT); ++i)
    	{
            pos = float4(p.x, 0.5*fbm4(0.5*float2(eye.x+p.x, z+off)), eye.z+z, 1.);
            h = (vpmat*pos).y - p.y;
    		if (h>lh)
    		{
    			d = abs(h);
    			col = float3( d<0.005?smoothstep(1.,0.,d*192.):0. );
    			col *= exp(-0.1*float(i));
                acc += col;
    			lh = h;
    		}
    		z += zi;
    	}
    	col = sqrt(clamp(acc, 0., 1.));
        // Background
    	float3 bkg = float3(0.0,0.0,0.0);
    	// float3 bkg = float3(0.0,0.0,0.0) + p.y*0.1;
    	// col += bkg;
    	// Vignetting
    	float2 r = -1.0 + 2.0*(uv);
    	float vb = max(abs(r.x), abs(r.y));
    	col *= (0.15 + 0.85*(1.0-exp(-(1.0-vb)*30.0)));
    	__nv_out = float4(col,1.0);
        
    	    const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);
            float4 gradmap;
            float luminance = dot(__nv_out.rgb, luminanceWeighting);
            gradmap = mix(u.color1,u.color2,luminance)*__nv_out.a;
    	    float4 factor = mix(texColorX,gradmap,u.alpha);
    	// float4 factor = mix(texColorX,__nv_out,u.alpha);
    	
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
    return __nv_out;
}
