// ---------------------------------------------------------------------------
// Bokeh Parallax
// origem : assets/effects/toji-skexnxxbokehparralax.xml
// id     : com.alightcreative.effects.bokehparralax
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxbokehparralaxParams {
    float progressa;
    float progressb;
    float bright;
    float alpha;
    float angle;
    float4 color1;
    float4 color2;
    float4 color3;
    float4 color4;
    int blendMode;
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
    
   #define fragCoord __nv_fragCoord
    
   /////////////////////////
   
   const float MATH_PI	= float( 3.14159265359 );
    
    void Rotate( inout float2 p, float a ) 
    {
    	p = cos( a ) * p + sin( a ) * float2( p.y, -p.x );
    }
    
    float Circle( float2 p, float r )
    {
        return ( length( p / r ) - 1.0 ) * r;
    }
    
    float Rand( float2 c )
    {
    	return fract( sin( dot( c.xy, float2( 12.9898, 78.233 ) ) ) * 43758.5453 );
    }
    
    float saturate( float x )
    {
    	return clamp( x, 0.0, 1.0 );
    }
    
    void BokehLayer( inout float3 color, float2 p, float3 c )   
    {
        float wrap = 450.0;    
        if ( __nv_mod(floor( p.y / wrap + 0.5 ), 2.0) == 0.0 )
        {
            p.x += wrap * 0.5;
        }    
        
        float2 p2 = __nv_mod(p + 0.5 * wrap, wrap) - 0.5 * wrap;
        float2 cell = floor( p / wrap + 0.5 );
        float cellR = Rand( cell );
            
        c *= fract( cellR * 3.33 + 3.33 );    
        float radius = mix( 30.0, 70.0, fract( cellR * 7.77 + 7.77 ) );
        p2.x *= mix( 0.9, 1.1, fract( cellR * 11.13 + 11.13 ) );
        p2.y *= mix( 0.9, 1.1, fract( cellR * 17.17 + 17.17 ) );
        
        float sdf = Circle( p2, radius );
        float circle = 1.0 - smoothstep( 0.0, 1.0, sdf * 0.04 );
        float glow	 = exp( -sdf * 0.025 ) * 0.3 * ( 1.0 - circle );
        color += c * ( circle + glow );
    }
   
   /////////////////////////

fragment float4 fx_toji_skexnxxbokehparralax(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxbokehparralaxParams&  u    [[buffer(1)]],
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
        // if (adaptive) { 
        syamjaidtz = in.acScreenNorm;
         // }
        // else { 
        // syamjaidtz = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
        // syamjaidtz.y*=eng.acLayerSize.y/eng.acLayerSize.x;
        // }

        // syamjaidtz /= scale;
        syamjaidtz *= rot2m((0.0+u.angle)*0.0174533);
        // syamjaidtz += float2((0.0+position.x), (0.0+position.y))*float2(-1.,1.)/500.;

        
        /////////////////////////

    	float4 __nv_out;
    	
    	float2 uv = syamjaidtz;
    	float2 p = ( 2.0 * fragCoord.xy - syamjaidtz ) / eng.acScreenSize.x * (u.progressb * 100.0);
        
        // background
    	float3 color = mix( float3( u.color3.rgb ), float3( u.color4.rgb ), dot( uv, float2( 0.2, 0.7 ) ) );
    	// float3 color = mix( float3( 0.3, 0.1, 0.3 ), float3( 0.1, 0.4, 0.5 ), dot( uv, float2( 0.2, 0.7 ) ) );
    
        float time = u.progressa - 15.0;
        
        Rotate( p, 0.2 + time * 0.03 );
        BokehLayer( color, p + float2( -50.0 * time +  0.0, 0.0  ), 3.0 * float3( u.color1.rgb ) );
        // BokehLayer( color, p + float2( -50.0 * time +  0.0, 0.0  ), 3.0 * float3( 0.4, 0.1, 0.2 ) );
    	Rotate( p, 0.3 - time * 0.05 );
        BokehLayer( color, p + float2( -70.0 * time + 33.0, -33.0 ), 3.5 * float3( 0.6, 0.4, 0.2 ) );
    	Rotate( p, 0.5 + time * 0.07 );
        BokehLayer( color, p + float2( -60.0 * time + 55.0, 55.0 ), 3.0 * float3( 0.4, 0.3, 0.2 ) );
        Rotate( p, 0.9 - time * 0.03 );
        BokehLayer( color, p + float2( -25.0 * time + 77.0, 77.0 ), 3.0 * float3( 0.4, 0.2, 0.1 ) );    
        Rotate( p, 0.0 + time * 0.05 );
        BokehLayer( color, p + float2( -15.0 * time + 99.0, 99.0 ), 3.0 * float3( u.color2.rgb ) );     
        // BokehLayer( color, p + float2( -15.0 * time + 99.0, 99.0 ), 3.0 * float3( 0.2, 0.0, 0.4 ) );     
    
    	__nv_out = float4( color, 1.0 );
        
    	    // const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);
            // float4 gradmap;
            // float luminance = dot(__nv_out.rgb, luminanceWeighting);
            // gradmap = mix(u.color1,u.color2,luminance)*__nv_out.a;
    	    // float4 factor = mix(texColorX,gradmap,u.alpha);
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
    return __nv_out;
}
