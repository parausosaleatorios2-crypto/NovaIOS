// ---------------------------------------------------------------------------
// Sparks
// origem : assets/effects/toji-Sparks.xml
// id     : com.alightcreative.effects.sparkfire
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_SparksParams {
    float PROGRESS;
    float PARTICLE_SIZE;
    float SIZE_MOD;
    float ALPHA_MOD;
    float LAYERS_COUNT;
    float scale;
    float2 position;
    float2 stretch;
    float bright;
    float alpha;
    float angle;
    float4 color1;
    float4 color2;
    int blendMode;
    float2 MOVEMENT_DIRECTION;
    float2 PARTICLE_SCALE;
    float2 PARTICLE_SCALE_VAR;
    float2 PARTICLE_BLOOM_SCALE;
    float2 PARTICLE_BLOOM_SCALE_VAR;
};

// --- funcoes auxiliares do efeito
//////////////////////////
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
   
        //Shader License: CC BY 3.0
        //Author: Jan Mróz (jaszunio15)
        
        #define PI 3.1415927
        #define TWO_PI 6.283185
        
        #define ANIMATION_SPEED 1.5
        #define MOVEMENT_SPEED 1.0
        
        #define SPARK_COLOR float3(u.color1.rgb) * 1.5
        #define BLOOM_COLOR float3(u.color2.rgb) * 0.8
        #define SMOKE_COLOR float3(0.,0.,0.) * 1.0
        // #define SMOKE_COLOR float3(color3.rgb) * 0.8
        
        // #define u.MOVEMENT_DIRECTION float2(0.7, -1.0)
        // #define u.PARTICLE_SIZE 0.009
        // #define u.PARTICLE_SCALE (float2(0.5, 1.6))
        // #define u.PARTICLE_SCALE_VAR (float2(0.25, 0.2))
        // #define u.PARTICLE_BLOOM_SCALE (float2(0.5, 0.8))
        // #define u.PARTICLE_BLOOM_SCALE_VAR (float2(0.3, 0.1))
        // #define SPARK_COLOR float3(1.0, 0.4, 0.05) * 1.5
        // #define BLOOM_COLOR float3(1.0, 0.4, 0.05) * 0.8
        // #define SMOKE_COLOR float3(1.0, 0.43, 0.1) * 0.8
        // #define u.SIZE_MOD 1.05
        // #define u.ALPHA_MOD 0.9
        // #define u.LAYERS_COUNT 15
        
          static float hash1_2(in float2 x)
        {
         	return fract(sin(dot(x, float2(52.127, 61.2871))) * 521.582);   
        }
        
        static float2 hash2_2(in float2 x)
        {
            return fract(sin(x * float2x2(20.52, 24.1994, 70.291, 80.171)) * 492.194);
        }
        
        //Simple interpolated noise
        static float2 noise2_2(float2 uv)
        {
            //float2 f = fract(uv);
            float2 f = smoothstep(0.0, 1.0, fract(uv));
            
         	float2 uv00 = floor(uv);
            float2 uv01 = uv00 + float2(0,1);
            float2 uv10 = uv00 + float2(1,0);
            float2 uv11 = uv00 + 1.0;
            float2 v00 = hash2_2(uv00);
            float2 v01 = hash2_2(uv01);
            float2 v10 = hash2_2(uv10);
            float2 v11 = hash2_2(uv11);
            
            float2 v0 = mix(v00, v01, f.y);
            float2 v1 = mix(v10, v11, f.y);
            float2 v = mix(v0, v1, f.x);
            
            return v;
        }
        
        //Simple interpolated noise
        static float noise1_2(in float2 uv)
        {
            float2 f = fract(uv);
            //float2 f = smoothstep(0.0, 1.0, fract(uv));
            
         	float2 uv00 = floor(uv);
            float2 uv01 = uv00 + float2(0,1);
            float2 uv10 = uv00 + float2(1,0);
            float2 uv11 = uv00 + 1.0;
            
            float v00 = hash1_2(uv00);
            float v01 = hash1_2(uv01);
            float v10 = hash1_2(uv10);
            float v11 = hash1_2(uv11);
            
            float v0 = mix(v00, v01, f.y);
            float v1 = mix(v10, v11, f.y);
            float v = mix(v0, v1, f.x);
            
            return v;
        }
        
        //////////////////////////
        
        
        static float layeredNoise1_2(in float2 uv, in float sizeMod, in float alphaMod, in int layers, in float animation)
        {
         	float noise = 0.0;
            float alpha = 1.0;
            float size = 1.0;
            float2 offset;
            for (int i = 0; i < layers; i++)
            {
                offset += hash2_2(float2(alpha, size)) * 10.0;
                
                //Adding noise with movement
             	noise += noise1_2(uv * size + u.PROGRESS * animation * 8.0 * u.MOVEMENT_DIRECTION * MOVEMENT_SPEED + offset) * alpha;
                alpha *= alphaMod;
                size *= sizeMod;
            }
            
            noise *= (1.0 - alphaMod)/(1.0 - pow(alphaMod, float(layers)));
            return noise;
        }
        
        //Rotates point around 0,0
        static float2 rotate(in float2 point, in float deg)
        {
         	float s = sin(deg);
            float c = cos(deg);
            return float2x2(s, c, -c, s) * point;
        }
        
        //Cell center from point on the grid
        static float2 voronoiPointFromRoot(in float2 root, in float deg)
        {
          	float2 point = hash2_2(root) - 0.5;
            float s = sin(deg);
            float c = cos(deg);
            point = float2x2(s, c, -c, s) * point * 0.66;
            point += root + 0.5;
            return point;
        }
        
        //Voronoi cell point rotation degrees
        static float degFromRootUV(in float2 uv)
        {
         	return u.PROGRESS * ANIMATION_SPEED * (hash1_2(uv) - 0.5) * 2.0;   
        }
        
        static float2 randomAround2_2(in float2 point, in float2 range, in float2 uv)
        {
         	return point + (hash2_2(uv) - 0.5) * range;
        }
        
        
        static float3 fireParticles(in float2 uv, in float2 originalUV)
        {
            float3 particles = float3(0.0);
            float2 rootUV = floor(uv);
            float deg = degFromRootUV(rootUV);
            float2 pointUV = voronoiPointFromRoot(rootUV, deg);
            float dist = 2.0;
            float distBloom = 0.0;
           
           	//UV manipulation for the faster particle movement
            float2 tempUV = uv + (noise2_2(uv * 2.0) - 0.5) * 0.1;
            tempUV += -(noise2_2(uv * 3.0 + u.PROGRESS) - 0.5) * 0.07;
        
            //Sparks sdf
            dist = length(rotate(tempUV - pointUV, 0.7) * randomAround2_2(u.PARTICLE_SCALE, u.PARTICLE_SCALE_VAR, rootUV));
            
            //Bloom sdf
            distBloom = length(rotate(tempUV - pointUV, 0.7) * randomAround2_2(u.PARTICLE_BLOOM_SCALE, u.PARTICLE_BLOOM_SCALE_VAR, rootUV));
        
            //Add sparks
            particles += (1.0 - smoothstep(u.PARTICLE_SIZE * 0.6, u.PARTICLE_SIZE * 3.0, dist)) * SPARK_COLOR;
            
            //Add bloom
            particles += pow((1.0 - smoothstep(0.0, u.PARTICLE_SIZE * 6.0, distBloom)) * 1.0, 3.0) * BLOOM_COLOR;
        
            //Upper disappear curve randomization
            float border = (hash1_2(rootUV) - 0.5) * 2.0;
         	float disappear = 1.0 - smoothstep(border, border + 0.5, originalUV.y);
        	
            //Lower appear curve randomization
            border = (hash1_2(rootUV + 0.214) - 1.8) * 0.7;
            float appear = smoothstep(border, border + 0.4, originalUV.y);
            
            return particles * disappear * appear;
        }
        
        
        //Layering particles to imitate 3D view
        static float3 layeredParticles(in float2 uv, in float sizeMod, in float alphaMod, in int layers, in float smoke) 
        { 
            float3 particles = float3(0);
            float size = 1.0;
            float alpha = 1.0;
            float2 offset = float2(0.0);
            float2 noiseOffset;
            float2 bokehUV;
            
            for (int i = 0; i < layers; i++)
            {
                //Particle noise movement
                noiseOffset = (noise2_2(uv * size * 2.0 + 0.5) - 0.5) * 0.15;
                
                //UV with applied movement
                bokehUV = (uv * size + u.PROGRESS * u.MOVEMENT_DIRECTION * MOVEMENT_SPEED) + offset + noiseOffset; 
                
                //Adding particles								if there is more smoke, remove smaller particles
        		particles += fireParticles(bokehUV, uv) * alpha * (1.0 - smoothstep(0.0, 1.0, smoke) * (float(i) / float(layers)));
                
                //Moving uv origin to avoid generating the same particles
                offset += hash2_2(float2(alpha, alpha)) * 10.0;
                
                alpha *= alphaMod;
                size *= sizeMod;
            }
            
            return particles;
        }
    //////////////////////////

fragment float4 fx_toji_Sparks(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_SparksParams&  u    [[buffer(1)]],
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
        float2 iRes = float2(eng.acScreenSize.x, eng.acScreenSize.y);
        
        float2 umefx;
        umefx = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
        umefx.y*=eng.acLayerSize.y/eng.acLayerSize.x;

        umefx /= u.scale;
        umefx *= rot2m((0.0+u.angle)*0.0174533);
        umefx += float2((0.0+u.position.x), (0.0+u.position.y))*float2(-1.,1.)/500.;
        
        float2 scaleVec;
        scaleVec = float2(u.scale*u.stretch.x,u.scale*u.stretch.y);
        umefx /= scaleVec;
        
        /////////////////////////
        
    	float4 __nv_out;
    	
            float2 uv = umefx;
            
            float vignette = 1.0 - smoothstep(0.4, 1.4, length(uv + float2(0.0, 0.3)));
            
            uv *= 1.8;
            
            float smokeIntensity = layeredNoise1_2(uv * 10.0 + u.PROGRESS * 4.0 * u.MOVEMENT_DIRECTION * MOVEMENT_SPEED, 1.7, 0.7, 6, 0.2);
            smokeIntensity *= pow(1.0 - smoothstep(-1.0, 1.6, uv.y), 2.0); 
            float3 smoke = smokeIntensity * SMOKE_COLOR * 0.8 * vignette;
            
            //Cutting holes in smoke
            smoke *= pow(layeredNoise1_2(uv * 4.0 + u.PROGRESS * 0.5 * u.MOVEMENT_DIRECTION * MOVEMENT_SPEED, 1.8, 0.5, 3, 0.2), 2.0) * 1.5;
            
            float3 particles = layeredParticles(uv, u.SIZE_MOD, u.ALPHA_MOD, int(u.LAYERS_COUNT), smokeIntensity);
            
            float3 col = particles + smoke + SMOKE_COLOR * 0.02;
        	col *= vignette;
            
            col = smoothstep(-0.08, 1.0, col);
        
            __nv_out = float4(col, 1.0);
        
    	float4 factor = mix(texColorX,__nv_out,1.0);

        float4 resultfinal;
        if( u.blendMode==0 ) {                // normal
            resultfinal = (factor * u.bright) * texColor.a;
            // resultfinal = (newLayer(texColor, factor) * u.bright) * texColor.a;
        } else if( u.blendMode==1 ) {         // multiply
            factor *= u.bright;
            float4 c = factor + float4(1.)*(1.-factor.a);
            resultfinal = float4((texColor.rgb/texColor.a)*c.rgb,1.0) * texColor.a;
        } else if( u.blendMode==2 ) {         // screen
            factor *= u.bright;
            resultfinal = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-factor.rgb)),1.0) * texColor.a;
        }
            
    	__nv_out = mix(texColor, resultfinal, alpha);
          }
    return __nv_out;
}
