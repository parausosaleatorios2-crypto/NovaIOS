// ---------------------------------------------------------------------------
// @am:string/effect_turbulentdisplace_name
// origem : assets/effects/toji-turbulentdisplace2.xml
// id     : com.alightcreative.effects.turbulentdisplace2
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_turbulentdisplace2Params {
    float2 parr;
    float2 position;
    float intensity;
    float evolution;
    int direction;
    float scale;
    float stretch;
    float seed;
    int singleAxis;
    int screenSpace;
    float octaves;
    float offs;
};

// --- funcoes auxiliares do efeito
float3 mod289(float3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
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

        float turbulence (in float2 st, in int OCTAVES, in float2 parallax, in float u.evolution) {
            // Initial values
            float value = 0.0;
            float amplitude = .5;
            float frequency = 0.;
            //
            // Loop of u.octaves
            for (int i = 0; i < OCTAVES; i++) {
                value += amplitude * abs(snoise(float3(st,u.evolution)));
                st *= 2.;
                st += parallax;
                amplitude *= .5;
            }
            return value;
        }

        float2 l2s( float2 v ) {
            return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
        }

fragment float4 fx_toji_turbulentdisplace2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_turbulentdisplace2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            float2 st;

            if( u.screenSpace ) {
                st = in.acScreenNorm;
                st.x *= eng.acScreenSize.x/eng.acScreenSize.y;
            } else {
                st = in.acLayerNorm;
                st.x *= eng.acLayerSize.x/eng.acLayerSize.y;
            }

            st += u.position*float2(-1.,1.)/500.; //float2(offsx,offsy);

            //st += mod(float2(4.365,7.701));

            float2 parallax = u.parr*float2(-1.,1.)/100.; //float2(parrx, parry);

            float2 scaleVec;
            if( u.stretch < 0.0 ) {
                scaleVec = float2(u.scale-u.stretch,u.scale);
            } else {
                scaleVec = float2(u.scale,u.scale+u.stretch);
            }

            float2 sampleCoord;

            if( u.singleAxis ) {
                if( u.direction==0 ) {
                    // X
                    sampleCoord = float2(0.,st.y - 0.5);
                } else if( u.direction == 1 ) {
                    // Y
                    sampleCoord = float2(st.x - 0.5,0.);
                } else if (u.direction == 2 ) {
                    // XY
                    sampleCoord = st - 0.5;
                } else if (u.direction == 4 ) {
                    // φr
                    sampleCoord = st - 0.5;
                } else if (u.direction == 5 ) {
                    // φ
                    sampleCoord = float2(0.,length(st-0.5));
                } else {
                    // R
                    float tt = abs(__nv_atan(st.x-0.5, st.y-0.5)/6.28318)*2.;
                    sampleCoord = float2(tt,0.);
                }
            } else {
                sampleCoord = st - 0.5;
            }

            float p = turbulence((sampleCoord-0.5)*scaleVec+0.5, int(u.octaves), parallax, u.evolution + 7391.935*u.seed);

            p += (u.offs-0.25);
            p *= u.intensity * 2.0;

            float2 uv = u.screenSpace ? in.acScreenNorm : in.acLayerNorm;

            if( u.direction==0 ) {
                // X
                uv.x += p;
            } else if( u.direction == 1 ) {
                // Y
                uv.y += p;
            } else if (u.direction == 2 ) {
                // XY
                float q = turbulence((sampleCoord)*scaleVec+0.5, int(u.octaves), parallax, u.evolution + 3937.7249*(u.seed+6.3379));
                //q -= 1.;
                q += (u.offs-0.25);
                q *= u.intensity * 2.0;
                uv.x += p;
                uv.y += q;
            } else if (u.direction == 4 ) {
                // φr
                float q = turbulence((sampleCoord)*scaleVec+0.5, int(u.octaves), parallax, u.evolution + 3937.7249*(u.seed+6.3379));
                q += (u.offs-0.25);
                q *= u.intensity * 2.0;
                float cq = cos(q);
                float sq = sin(q);
                uv += normalize(uv-0.5)*p;
                uv *= float2x2(cq,sq,-sq,cq);
            } else if (u.direction == 5 ) {
                // φ
                float cq = cos(p);
                float sq = sin(p);
                uv *= float2x2(cq,sq,-sq,cq);
            } else {
                // R
                uv += normalize(uv-0.5)*p;
            }

            if( !u.screenSpace ) {
                uv = l2s(uv);
            }

            __nv_out = inputImg.sample(__nv_smp, uv);
    return __nv_out;
}
