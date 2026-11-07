// ---------------------------------------------------------------------------
// toji-skexnxxscrossglitch.xml
// origem : assets/effects/toji-skexnxxscrossglitch.xml
// id     : 636f6d2e616c6967687463726561746976652e656666656374732e63726f7373676c69746368
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxscrossglitchParams {
    float progress;
    float xxc;
    float xxd;
    float xxf;
    float xxh;
    float iter;
    float alpha;
    float xxi;
    float xxj;
    float xxk;
    float xxl;
    float xxm;
    float xxn;
    float xxo;
    float xxp;
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
   
          //      Author : Ian McEwan, Ashima Arts.
          //  Maintainer : ijm
          //     Lastmod : 20110822 (ijm)
          //     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
          //               Distributed under the MIT License. See LICENSE file.
          //               https://github.com/ashima/webgl-noise
          //

        static float random (float2 st) {
            return fract(sin(dot(st.xy,
              float2(12.9898,78.233))) *  43758.5453123);
        }
        
        static float rand(float2 n) { 
            return fract(sin(dot(n, float2(12.9898, 4.1414))) * 43758.5453);
        }
          
          static float3 mod289(float3 x) {
            return x - floor(x * (1.0 / 289.0)) * 289.0;
          }

          static float4 mod289(float4 x) {
            return x - floor(x * (1.0 / 289.0)) * 289.0;
          }

          static float4 permute(float4 x) {
               return mod289(((x*34.0)+1.0)*x);
          }

          static float4 taylorInvSqrt(float4 r)
          {
            return 1.79284291400159 - 0.85373472095314 * r;
          }

          static float snoise3(float3 v)
            {
            const float2  C = float2(1.0/6.0, 1.0/3.0) ;
            const float4  D = float4(0.0, 0.5, 1.0, 2.0);

          // First corner
            float3 i  = floor(v + dot(v, C.yyy) );
            float3 x0 =   v - i + dot(i, C.xxx) ;

          // Other corners
            float3 g = step(x0.yzx, x0.xyz);
            float3 l = 1.0 - g;
            float3 i1 = min( g.xyz, l.zxy );
            float3 i2 = max( g.xyz, l.zxy );

            float3 x1 = x0 - i1 + C.xxx;
            float3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
            float3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y

          // Permutations
            i = mod289(i);
            float4 p = permute( permute( permute(
                       i.z + float4(0.0, i1.z, i2.z, 1.0 ))
                     + i.y + float4(0.0, i1.y, i2.y, 1.0 ))
                     + i.x + float4(0.0, i1.x, i2.x, 1.0 ));

          // Gradients: 7x7 points over a square, mapped onto an octahedron.
          // The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
            float n_ = 0.142857142857; // 1.0/7.0
            float3  ns = n_ * D.wyz - D.xzx;

            float4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  __nv_mod(p, 7*7)

            float4 x_ = floor(j * ns.z);
            float4 y_ = floor(j - u.xxd * x_ );    // __nv_mod(j, N)
            // float4 y_ = floor(j - 7.0 * x_ );    // __nv_mod(j, N)

            float4 x = x_ *ns.x + ns.yyyy;
            float4 y = y_ *ns.x + ns.yyyy;
            float4 h = 1.0 - abs(x) - abs(y);

            float4 b0 = float4( x.xy, y.xy );
            float4 b1 = float4( x.zw, y.zw );

            //float4 s0 = float4(lessThan(b0,0.0))*2.0 - 1.0;
            //float4 s1 = float4(lessThan(b1,0.0))*2.0 - 1.0;
            float4 s0 = floor(b0)*2.0 + 1.0;
            float4 s1 = floor(b1)*2.0 + 1.0;
            float4 sh = -step(h, float4(0.0));

            float4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
            float4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

            float3 p0 = float3(a0.xy,h.x);
            float3 p1 = float3(a0.zw,h.y);
            float3 p2 = float3(a1.xy,h.z);
            float3 p3 = float3(a1.zw,h.w);

          //Normalise gradients
            float4 norm = taylorInvSqrt(float4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
            p0 *= norm.x;
            p1 *= norm.y;
            p2 *= norm.z;
            p3 *= norm.w;

          // Mix final noise value
            float4 m = max(0.6 - float4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
            m = m * m;
            return 42.0 * dot( m*m, float4( dot(p0,x0), dot(p1,x1),
                                          dot(p2,x2), dot(p3,x3) ) );
            }
                    
          // const float interval = 3.0;
    //////////////////////////

fragment float4 fx_toji_skexnxxscrossglitch(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxscrossglitchParams&  u    [[buffer(1)]],
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
        float2 iRes = float2(eng.acScreenSize.x, eng.acScreenSize.y);
        
        float2 syamjaidtz;
        syamjaidtz = in.acScreenNorm; 
        
        /////////////////////////
        
    	float4 __nv_out;
    	
             float interval = u.xxc;
             // float interval = 3.0;
    	
             float time = u.progress;
             float strength = smoothstep(interval * 0.5, interval, interval - __nv_mod(time, interval));
            float2 shake = float2(strength * 8.0 + 0.5) * float2(
              random(float2(time)) * 2.0 - 1.0,
              random(float2(time * 2.0)) * 2.0 - 1.0
            ) / iRes;
          
            float y = syamjaidtz.y * eng.acScreenSize.y;
            float rgbWave = (
                snoise3(float3(0.0, y * u.xxf, time * 400.0)) * (2.0 + strength * 32.0) //
                // snoise3(float3(0.0, y * 0.01, time * 400.0)) * (2.0 + strength * 32.0)
                * snoise3(float3(0.0, y * 0.02, time * 200.0)) * (1.0 + strength * 4.0)
                + step(0.9995, sin(y * 0.005 + time * 1.6)) * 12.0
                + step(0.9999, sin(y * 0.005 + time * 2.0)) * -18.0
              ) / eng.acScreenSize.x;
            float rgbDiff = (6.0 + sin(time * 500.0 + syamjaidtz.y * 40.0) * (20.0 * strength + 1.0)) / eng.acScreenSize.x;
            float rgbUvX = syamjaidtz.x + rgbWave;
            float r = inputImg.sample(__nv_smp, float2(rgbUvX + rgbDiff, syamjaidtz.y) + shake).r;
            float g = inputImg.sample(__nv_smp, float2(rgbUvX, syamjaidtz.y) + shake).g;
            float b = inputImg.sample(__nv_smp, float2(rgbUvX - rgbDiff, syamjaidtz.y) + shake).b;
          
            float whiteNoise = (random(syamjaidtz + __nv_mod(time, 10.0)) * 2.0 - 1.0) * (0.15 + strength * u.xxh);
            // float whiteNoise = (random(syamjaidtz + __nv_mod(time, 10.0)) * 2.0 - 1.0) * (0.15 + strength * 0.15);
          
            float bnTime = floor(time * 20.0) * u.xxi;
            // float bnTime = floor(time * 20.0) * 200.0;
            float noiseX = step((snoise3(float3(0.0, syamjaidtz.x * 3.0, bnTime)) + 1.0) / u.xxj, 0.12 + strength * 0.3);
            float noiseY = step((snoise3(float3(0.0, syamjaidtz.y * 3.0, bnTime)) + 1.0) / u.xxk, 0.12 + strength * 0.3);
            // float noiseX = step((snoise3(float3(0.0, syamjaidtz.x * 3.0, bnTime)) + 1.0) / 2.0, 0.12 + strength * 0.3);
            // float noiseY = step((snoise3(float3(0.0, syamjaidtz.y * 3.0, bnTime)) + 1.0) / 2.0, 0.12 + strength * 0.3);
            
            float bnMask = noiseX * noiseY;
            float bnUvX = syamjaidtz.x + sin(bnTime) * u.xxl + rgbWave;
            // float bnUvX = syamjaidtz.x + sin(bnTime) * 0.2 + rgbWave;
            float bnR = inputImg.sample(__nv_smp, float2(bnUvX + rgbDiff, syamjaidtz.y)).r * bnMask;
            float bnG = inputImg.sample(__nv_smp, float2(bnUvX, syamjaidtz.y)).g * bnMask;
            float bnB = inputImg.sample(__nv_smp, float2(bnUvX - rgbDiff, syamjaidtz.y)).b * bnMask;
            float4 blockNoise = float4(bnR, bnG, bnB, 1.0);
          
            float bnTime2 = floor(time * 25.0) * 300.0;
            float noiseX2 = step((snoise3(float3(0.0, syamjaidtz.x * u.xxm, bnTime2)) + 1.0) / 2.0, 0.12 + strength * u.xxo);
            float noiseY2 = step((snoise3(float3(0.0, syamjaidtz.y * u.xxn, bnTime2)) + 1.0) / 2.0, 0.12 + strength * u.xxp);
            // float noiseX2 = step((snoise3(float3(0.0, syamjaidtz.x * 2.0, bnTime2)) + 1.0) / 2.0, 0.12 + strength * 0.5);
            // float noiseY2 = step((snoise3(float3(0.0, syamjaidtz.y * 8.0, bnTime2)) + 1.0) / 2.0, 0.12 + strength * 0.3);
            float bnMask2 = noiseX2 * noiseY2;
            float bnR2 = inputImg.sample(__nv_smp, float2(bnUvX + rgbDiff, syamjaidtz.y)).r * bnMask2;
            float bnG2 = inputImg.sample(__nv_smp, float2(bnUvX, syamjaidtz.y)).g * bnMask2;
            float bnB2 = inputImg.sample(__nv_smp, float2(bnUvX - rgbDiff, syamjaidtz.y)).b * bnMask2;
            float4 blockNoise2 = float4(bnR2, bnG2, bnB2, 1.0);
          
            float waveNoise = (sin(syamjaidtz.y * 1200.0) + 1.0) / 2.0 * (0.15 + strength * 0.2);
          
            __nv_out = float4(r, g, b, 1.0) * (1.0 - bnMask - bnMask2) + (whiteNoise + blockNoise + blockNoise2 - waveNoise);
        
    	float4 factor = mix(texColorX,__nv_out,1.0);

        float4 resultfinal;
        resultfinal = (max(factor, texColor) * 1.0) * texColor.a;
            
    	__nv_out = mix(texColor, resultfinal, u.alpha);
          }
    return __nv_out;
}
