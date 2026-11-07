// ---------------------------------------------------------------------------
// toji-skexnxxshexagonlens.xml
// origem : assets/effects/toji-skexnxxshexagonlens.xml
// id     : 636f6d2e616c6967687463726561746976652e656666656374732e68657861676f6e6c656e73
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxshexagonlensParams {
    float2 position;
    float2 orient;
    float MAX_ITERATIONS;
    float4 bgColor;
    float4 lightColor;
    float XXK;
    float XXH;
    float XXI;
    float lensFlareScale;
    float XXA;
    float XXB;
    float XXC;
    float XXD;
    float XXE;
    float lensFlareExposure;
    float lensFlareBrightness;
    float scale;
    float angle;
    float2 stretch;
    float alpha;
    float hardness;
    int blendMode;
};

// --- funcoes auxiliares do efeito
//////////////////////////
    float4 newLayer( float4 a, float4 b) { return a * (1. - b.a) + b;  }
    float2x2 rot2m(float a){ float s = sin(a); float c = cos(a); return float2x2(c, -s, s, c); }
    float2 l2s( float2 v ) { return (float4(v,0.0,1.0)*eng.acLayerToScreen).xy; }
    #define fragCoord __nv_fragCoord.xy
    
   /////////////////////////
   
        float rnd(float w){
            //Use bluenoise texture for fast lds random values in range [0,1]
            return noisexx.sample(__nv_smp, float2(w)).r;
        }
        
        float regularPolygon(float2 p, int N){// Produces a regular polygon defined by N points on the unit circle.
            float a=__nv_atan(p.x, p.y)+0.2;
            float b=6.28319/float(N);
            return smoothstep(0.5,0.51, cos(floor(0.5+a/b)*b-a)*length(p.xy));        
        }
        
        float renderSmallCircle(float2 pos, float2 ltpos, float dist, float2 offsetFromCenter, float size)
        {
        	float2 coord = pos - ltpos * dist/2.0 + offsetFromCenter;
        	float radiusVal =  u.XXA / length(coord)*size;
        	radiusVal = max(radiusVal, 0.0);//filter negative vals.
        	return radiusVal;
        }
        
        float renderBigCircle(float2 pos, float2 ltpos, float dist, float2 offsetFromCenter, float size)
        {
        	float2 coord = pos + ltpos*dist + offsetFromCenter;
        	float radiusVal =  u.XXB - pow(length(coord), size * 1.4);
        	radiusVal = max(radiusVal, 0.0);//filter negative vals.
        	return radiusVal;	
        }
        
        float renderRing(float r, float offsetFromCenter, float fade)
        {
        	float radiusVal = 0.001 - pow(r - offsetFromCenter, 1.0/fade) + sin(r * 30.0);
        	radiusVal = max(radiusVal, 0.0);//filter negative vals.
        	return radiusVal * u.XXC;
        }
        
        float renderHexagon(float2 uv, float2 lightPos, float2 offsetFromCenter, 
        	float hexagonIntervalDist, float size)
        {
        	const int hexagonPoints = 6;
        	float2 hexagonCoord = uv*size + lightPos*hexagonIntervalDist*size + offsetFromCenter;
        	float hexValue = 0.01 - regularPolygon(hexagonCoord, hexagonPoints);
           	hexValue = max(hexValue, 0.0);//filter negative vals.
        	return hexValue;
        }
        
        float3 chromaticAberration(float3 color, float2 pos, float2 ltpos, int iter)
        {   // NOTE: This function still needs some work.
        
        	float intensity = u.XXD;//adjust as needed.
        	float amount = intensity * length(pos-ltpos) * 
        		rnd(float(iter)*0.713) * float(iter);	
        
        	// Rotate which channels are being offset per iteration (i).
        	float3 cyclic_amt = (float3(-0.95,-0.98,-1.0) + amount * 
        		float3(iter/3,(iter+1)/3,(iter+2)/3));//float3 of ints ranged [-1,1]
        
            float3 col = color + cyclic_amt;
        	return col * (1.0 - amount * 0.5);
        }
        
        float3 LensHighlight(float2 pos, float2 lightPos, float3 color, float size, float dist, int i)
        {   
            // Create a big circle, ring, small circle, and hexagon and control blending with a float4.
        	const float4 blend_val = 0.01 * float4(2500.0, 20.0, 1.50, 2000.0);//adjust as necessary per-object.
        	
            float bigCircle_size = size * u.XXE * float(i);
            float2 bigCircle_offset = -lightPos * float2(2.0);
            float bigCircle = renderBigCircle(pos,lightPos,dist,bigCircle_offset, bigCircle_size) * blend_val.x;    
            
            float ring_fade = 7.0 * float(i);
        	float2 ring_offset = 
                //float2(0.0);//<== rings around light source.
                -lightPos * float2(2.5) * float(i);//<== ring halos in light ray.
            float ring_size = size * 5.0 * float(i);
            float lt_coord = length(pos - lightPos - ring_offset);
            float ring_radius  = lt_coord + ring_size; 
        	float ring = renderRing(ring_radius, ring_size, ring_fade) * blend_val.y;   
        
        	float2 smallCircle_offset = lightPos * float2(0.0159);
            float smallCircle_size = 84.0;
        	float smallCircle = renderSmallCircle(pos,lightPos,dist,smallCircle_offset, smallCircle_size) * blend_val.z;
            
            // Draws hexagons in order closest to light to farthest.
        	float2 hexagon_offset = -lightPos * float2(1.5) * float(i) + lightPos * 0.32;
        	float hexagon_size = 11.0 - u.XXH * float(i);
                float hexagon_fade = u.XXI * pow(float(i), 2.5);
        	float hexagon  = renderHexagon(pos,lightPos,hexagon_offset,dist,hexagon_size)*hexagon_fade*blend_val.w;
            
        	// Slightly offset colors to simulate chromatic abberration.
        	color = chromaticAberration(color, pos, lightPos, i);
         	return (smallCircle + bigCircle + ring + hexagon) * color;
        }
        
        float3 Lensflare(float2 currPos, float2 lightPos, float distToLight)
        {
        
        	float3 flareColor = float3(0.0);
        	float lt_dist = distToLight+1.0;//prevent division by val < 1.
        	float proximity_divisor = length(currPos-lightPos);
        	float loopVal = 1.0;
        	int i = 1;
        
        	const float epsiln = 0.0001;
        	while(loopVal > epsiln && i < int(u.MAX_ITERATIONS))
        	{
        		float xnxx = float(i);
        		float2 pos = currPos;//square value to produce appropriate warping effect
        		float2 lpos = lightPos;
        		float3 color_rand = 2.0 * xnxx * float3(rnd(xnxx * 3.0913));
        		float3 col = u.lightColor.rgb + clamp(color_rand, 0.0, 1.0);
        		float flareSize = 
        			 xnxx*xnxx*pow(rnd(xnxx * 21.773) * 1.8, 1.0) + 0.5;
        		float flareInterval = 
        			((u.lensFlareScale+0.01)/lt_dist) * pow(rnd(xnxx * 7.11) * 3.0, u.XXK) + 0.05;
        					
        		float3 passColor = LensHighlight(pos,lpos,col,flareSize,flareInterval,i); 
        
        		passColor *= u.lensFlareBrightness / (xnxx * 1.15);
        		flareColor += passColor;
        		loopVal /= proximity_divisor;
        		i++;
        	}
        
        	return flareColor;
        }
        float scaleDepth(float depth)
        {// Intended to map values in range d = (0,1] to range (1,0] to rolloff values by distance.
        	return exp(-abs(depth * 1.0 * 0.01));
        }
    //////////////////////////

fragment float4 fx_toji_skexnxxshexagonlens(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxshexagonlensParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> noisexx [[texture(0)]],
    texture2d<float> inputImg [[texture(1)]],
    texture2d<float> xcipher [[texture(2)]],
    constant NovaTexInfo& noisexx_info [[buffer(2)]],
    constant NovaTexInfo& inputImg_info [[buffer(3)]],
    constant NovaTexInfo& xcipher_info [[buffer(4)]])
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
        
        float2 syamjaidtz;
        syamjaidtz = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
        syamjaidtz.y*=eng.acLayerSize.y/eng.acLayerSize.x;
        syamjaidtz /= u.scale;
        syamjaidtz *= rot2m((0.0+u.angle)*0.0174533);
        syamjaidtz += float2((0.0+u.position.x), (0.0-u.position.y))*float2(-1.0,1.0)/500.0;
        float2 scaleVec;
        scaleVec = float2(u.scale*u.stretch.x,u.scale*u.stretch.y);
        syamjaidtz /= scaleVec;
        
        /////////////////////////
        
    	float4 __nv_out;
    	
        	float3 uv = float3(syamjaidtz,0.0);
        	// float3 uv = float3(fragCoord/iResolution.xy,0)-0.5;
        	uv.x *= eng.acScreenSize.x/eng.acScreenSize.y; // aspect correct
            
        	// Get screen space light u.position.
            float3 lightPosition = 0.25*(float3(float2(u.orient.x+1.45,u.orient.y-0.85),-0.1) - 0.5);//hardcoded for shader
            // float3 lightPosition = 0.25*(float3(u.orient,-0.1) - 0.5);//hardcoded for shader
        	float3 lightPos = lightPosition;
            //float3 lightPos = modelToScreen(lightPosition3D)-0.5; <== implementation for world space light pos	
            lightPos.x *= eng.acScreenSize.x/eng.acScreenSize.y; // aspect correct
        
        	// float distToLight = length(lightPosition - (ROTATE/100.0));
        	// float distToLight = length(lightPosition - cameraPosition);
        	float distToLight = length(lightPosition - float3(0.0));
        
        	// Bail early conditions.
        	if((u.lensFlareScale+0.01) <= 0.000001 || distToLight <= 0.00001)
        		return __nv_out;
        
        	// Calculate lens flare effect.
        	float depthFade = scaleDepth(distToLight);
        	float3 color = Lensflare(uv.xy, lightPos.xy, distToLight);
        	
        	// Post-process, scaling strength by distance of observer to light source.
        	color *= depthFade;//Adjust lens flare for camera distance to light.
        	color = float3(1.0) - exp(-color.rgb * u.lensFlareExposure * depthFade);// exposure tone mapping
        	color = max(color, 0.0);//remove negative values
        
            // Add faked light source.
            float uvDistToLight = length(uv.xy - lightPos.xy);
            float lightsrc = clamp(1.0-uvDistToLight*7.0, 0.0, 1.0);
            
            // Add rays from light source -- a rough approximation of volumetric light rays.
            float ray_factor = 1.00;
            float a = ray_factor * __nv_atan(uv.y-lightPos.y, uv.x-lightPos.x);
            lightsrc += max(0.1/pow(length(uvDistToLight)*5.0, 5.0), 0.0)*abs(sin(a*5.0+cos(a*9.0)))/20.0;
            lightsrc += max(0.1/pow(length(uvDistToLight)*10.0, 1.0/20.0), 0.0)+abs(sin(a*3.0+cos(a*9.0)))/8.0*(abs(sin(a*9.0)))/1.0;
            float lightsrc_attenuation = depthFade * (1.0-uvDistToLight*uvDistToLight) * 1.0;
            color += lightsrc * lightsrc_attenuation;
        
            // Output final color.
        	float alphax = depthFade*(color.r + color.g + color.b) / 3.0; //optional u.alpha blending.
        	__nv_out = float4(color.rgb, alphax);
        
    	float4 factorx = mix(texColorX,__nv_out,1.0);
    	float4 factor = newLayer(u.bgColor, factorx);
    	
        float4 resultfinal;
          if( u.blendMode==0 ) {
            resultfinal = (factor * u.hardness) * texColor.a; }
          else if( u.blendMode==1 ) { factor *= u.hardness;
            float4 c = factor + float4(1.0)*(1.0-factor.a);
            resultfinal = float4((texColor.rgb/texColor.a)*c.rgb,1.0) * texColor.a; }
          else if( u.blendMode==2 ) { factor *= u.hardness; 
            resultfinal = float4( 1.0-((1.0-(texColor.rgb/texColor.a))*(1.0-factor.rgb)),1.0) * texColor.a; }
          else if( u.blendMode==3 ) { factor *= u.hardness; 
            resultfinal = newLayer(texColor, factor) * texColor.a; }
            
    	__nv_out = mix(texColor, resultfinal, u.alpha) * texColor.a;
          }
    return __nv_out;
}
