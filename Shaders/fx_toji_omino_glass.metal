// ---------------------------------------------------------------------------
// @am:string/effect_omino_glass_name
// origem : assets/effects/toji-omino-glass.xml
// id     : com.alightcreative.effects.ominoglass
// passes : 3
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_omino_glassParams {
    float strength;
    float refraction;
    float aberration;
    float featureSize;
    float samples;
    float4 tintcolor;
    float blend;
    int shadingType;
    float lightIntensity;
    float lightShine;
    float lightSpec;
    float lightAmbient;
    float4 lightColor;
    float2 lightDir;
    float lightDepth;
    int useLumaHeight;
    float roughness;
    float roughnessScale;
    float evolution;
    float seed;
};

// --- funcoes auxiliares do efeito
static float3 mod289(float3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
        float2 mod289(float2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
        float4 mod289(float4 x) {
          return x - floor(x * (1.0 / 289.0)) * 289.0;
        }
        float3 permute(float3 x) { return mod289(((x*34.0)+1.0)*x); }
        float4 permute(float4 x) {
             return mod289(((x*34.0)+1.0)*x);
        }

        float4 taylorInvSqrt(float4 r)
        {
          return 1.79284291400159 - 0.85373472095314 * r;
        }

        float snoise(float3 v)
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

          //   x0 = x0 - 0.0 + 0.0 * C.xxx;
          //   x1 = x0 - i1  + 1.0 * C.xxx;
          //   x2 = x0 - i2  + 2.0 * C.xxx;
          //   x3 = x0 - 1.0 + 3.0 * C.xxx;
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
          float4 y_ = floor(j - 7.0 * x_ );    // __nv_mod(j, N)

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

        float snoise(float2 v) {

            // Precompute values for skewed triangular grid
            const float4 C = float4(0.211324865405187,
                                // (3.0-sqrt(3.0))/6.0
                                0.366025403784439,
                                // 0.5*(sqrt(3.0)-1.0)
                                -0.577350269189626,
                                // -1.0 + 2.0 * C.x
                                0.024390243902439);
                                // 1.0 / 41.0

            // First corner (x0)
            float2 i  = floor(v + dot(v, C.yy));
            float2 x0 = v - i + dot(i, C.xx);

            // Other two corners (x1, x2)
            float2 i1 = float2(0.0);
            i1 = (x0.x > x0.y)? float2(1.0, 0.0):float2(0.0, 1.0);
            float2 x1 = x0.xy + C.xx - i1;
            float2 x2 = x0.xy + C.zz;

            // Do some permutations to avoid
            // truncation effects in permutation
            i = mod289(i);
            float3 p = permute(
                    permute( i.y + float3(0.0, i1.y, 1.0))
                        + i.x + float3(0.0, i1.x, 1.0 ));

            float3 m = max(0.5 - float3(
                                dot(x0,x0),
                                dot(x1,x1),
                                dot(x2,x2)
                                ), 0.0);

            m = m*m ;
            m = m*m ;

            // Gradients:
            //  41 pts uniformly over a line, mapped onto a diamond
            //  The ring size 17*17 = 289 is close to a multiple
            //      of 41 (41*7 = 287)

            float3 x = 2.0 * fract(p * C.www) - 1.0;
            float3 h = abs(x) - 0.5;
            float3 ox = floor(x + 0.5);
            float3 a0 = x - ox;

            // Normalise gradients implicitly by scaling m
            // Approximation of: m *= rsqrt(a0*a0 + h*h);
            m *= 1.79284291400159 - 0.85373472095314 * (a0*a0+h*h);

            // Compute final noise value at P
            float3 g = float3(0.0);
            g.x  = a0.x  * x0.x  + h.x  * x0.y;
            g.yz = a0.yz * float2(x1.x,x2.x) + h.yz * float2(x1.y,x2.y);
            return 130.0 * dot(m, g);
        }

        float2x2 rot2(float a) {
            float s = sin(a);
            float c = cos(a);
            return float2x2(c,-s,s,c);
        }

        float turbulence (float2 st, int OCTAVES, float2 parallax, float u.evolution) {
            // Initial values
            float value = 0.0;
            float amplitude = .5;
            float frequency = 0.;
            float2x2 rr = rot2(0.3);
            //
            // Loop of octaves
            for (int i = 0; i < OCTAVES; i++) {
                value += amplitude * abs(snoise(float3(st,u.evolution)));
                st *= 2.;
                st = st * rr;
                st += parallax;
                amplitude *= .5;
            }
            return value;
        }

        const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);
        
        float4 sampleNearestDistort(float2 p) {
            return surfBuf.sample(__nv_smp, p/eng.acScreenSize);
        }
        
        float sampleDistortLuma(float2 p) {
            float4 samp = surfBuf.sample(__nv_smp, p/eng.acScreenSize);
            float luma = dot( samp.rgb, luminanceWeighting );
            if( u.strength>0.0 ) {
                float4 blurSamp = blurBuf.sample(__nv_smp, p/eng.acScreenSize);
                float p = min(blurSamp.a,samp.a);
                //p = 1.-pow((1.-p),edgeexp);
                luma += p;
                luma *= smoothstep( 0.5, 1.0, blurSamp.a);
            }
            return luma;
        }
        
        float4 sampleLinearSrc(float2 p, float4 texColor) {
            float4 tc = texColor * (1.-u.tintcolor.a) + float4(u.tintcolor.rgb,1.)*u.tintcolor.a;
            float4 c = comp.sample(__nv_smp, p/eng.acScreenSize);
            c = mix(c,tc/max(0.0001,tc.a)*c,u.blend*tc.a);
            return c;
        }
        
        float4 pluckColor(float4 texColor, float2 xy,float4 rgb)
        {
            //if(wrap > 0)
            //    xy = __nv_mod(xy, eng.acScreenSize);
            float4 c = sampleLinearSrc(xy,texColor);
            c *= rgb;
            return c;
        }

        float4 chromatizePixel(float2 xy,float2 offset,float4 texColor)
        {
            float4 result = float4(0,0,0,0);
            result += pluckColor(texColor, xy - offset * 1.5,float4(.2,0,0,0.2));
            result += pluckColor(texColor, xy - offset,float4(.3,0,0,0.2));
            result += pluckColor(texColor, xy - offset / 2.0,float4(.5,.3333,0,0.2));
            result += pluckColor(texColor, xy,float4(0,.33333,0,0.2));
            result += pluckColor(texColor, xy + offset / 2.0,float4(0,.33333,.5,0.2));
            result += pluckColor(texColor, xy + offset,float4(0,0,.3,.2));
            result += pluckColor(texColor, xy + offset * 1.5,float4(0,0,.2,.2));
            return result;
        }
        
        float lighting(float3 p, float3 n) {
            float3 lightPos = float3(u.lightDir.x/2.0, -u.lightDir.y/2.0, -u.lightDepth*2.0);
            float3 l = normalize(lightPos-p);
            return dot(n,l);
        }

        float directionalLighting(float3 p, float3 n) {
            float3 lightPos = float3(u.lightDir.x/2.0, -u.lightDir.y/2.0, -u.lightDepth*2.0);
            float3 l = normalize(lightPos);
            return dot(n,l);
        }

        float4 applyShading(float4 texColor, float3 p, float3 n ) {
            float shine = u.lightShine;
            float ambient = u.lightAmbient;
            float spec = u.lightSpec;
            float4 result = float4(0.);
            if( u.shadingType == 0 ) {                // Flat
                result = texColor;
            } else if( u.shadingType == 1 ) {         // Point Light
                float l = lighting(p,n);
                float3 tc = texColor.rgb / max(texColor.a,0.0001);
                float3 surface = tc * ambient + tc * u.lightColor.rgb * l * (1.-ambient);
                surface *= u.lightIntensity;
                float s = pow(l,spec);
                surface = mix(surface*(1.-shine*0.1),float3(1.),shine*s);
                result = clamp(float4(surface, 1.),0.,1.) * texColor.a;
            } else if( u.shadingType == 2 ) {         // Directonal Light
                float l = directionalLighting(p,n);
                float3 tc = texColor.rgb / max(texColor.a,0.0001);
                float3 surface = tc * ambient + tc * u.lightColor.rgb * l * (1.-ambient);
                surface *= u.lightIntensity;
                float s = pow(l,spec);
                surface = mix(surface*(1.-shine*0.1),float3(1.),shine*s);
                result = clamp(float4(surface, 1.),0.,1.) * texColor.a;
            }

            return result;
        }


        float4 evaluatePixelXy(float2 srcXy, float4 texColor) {
            float2 imageSize = eng.acScreenSize;
            
            float2 slope = float2(0.);
            float2 dx = float2(2.0,0.0);
            float2 dy = float2(0.0,2.0);
            float floatSamples = float(u.samples);
            int intSamples = int(u.samples);
            
            for(int i = -intSamples; i < intSamples; i++) {
                float n = float(i);
                slope.x += sampleDistortLuma(srcXy+dx*(n-0.5)) - sampleDistortLuma(srcXy+dx*n+(0.5));
                slope.y += sampleDistortLuma(srcXy+dy*(n-0.5)) - sampleDistortLuma(srcXy+dy*n+(0.5));
            }
            slope /= floatSamples;
            
            float3 p = float3(slope,-0.5);
            float3 n = normalize(p);
            
            float2 sourceXy = srcXy + slope * u.featureSize * u.refraction;
            float2 aberrXy = slope * u.featureSize * u.aberration;

            float4 result = chromatizePixel(sourceXy,aberrXy,texColor);
            
            result.a = 1.0;
            result = clamp(result,0.,1.);
            //result = float4(slopeX,slopeY,0.5,1.0);
            return applyShading(result,p,n);
        }

fragment float4 fx_toji_omino_glass(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_omino_glassParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> comp [[texture(1)]],
    texture2d<float> blurBuf [[texture(2)]],
    texture2d<float> surfBuf [[texture(3)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& comp_info [[buffer(3)]],
    constant NovaTexInfo& blurBuf_info [[buffer(4)]],
    constant NovaTexInfo& surfBuf_info [[buffer(5)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            if( eng.acPass==1 ) {
                float4 result = texColor;
                if( !u.useLumaHeight ) {
                    result.rgb = float3(result.a);
                }
                if( abs(u.roughness) > 0.0001 ) {
                    float2 st = in.acLayerNorm;
                    st.x *= eng.acLayerSize.x/eng.acLayerSize.y;
                    float scale = 0.15 * u.roughnessScale;
                    int OCTAVES = 2;
                    float2 parallax = float2(0.,0.);
                    float p;
                    if( u.roughness < 0.0 ) {
                        p = (turbulence((st-0.5)/scale+0.5, OCTAVES, parallax, u.evolution + 7391.935*u.seed)) * (-u.roughness/3.);
                    } else {
                        p = (1.-turbulence((st-0.5)/scale+0.5, OCTAVES, parallax, u.evolution + 7391.935*u.seed)) * (u.roughness/3.);
                    }
                    result.rgb *= (1.-p);
                }
                __nv_out = result;
            } else {
                __nv_out = evaluatePixelXy(in.acScreenNorm*eng.acScreenSize,texColor) * texColor.a;
            }
    return __nv_out;
}
