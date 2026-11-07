// ---------------------------------------------------------------------------
// Warped Noise Field
// origem : assets/effects/toji-warped_noise_field.xml
// id     : com.alightcreative.effects.warped_noise_field
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_warped_noise_fieldParams {
    float scale;
    float time;
    float speed;
    float warpAmount;
    float eps;
    float4 baseColor;
    int blendSource;
};

// --- funcoes auxiliares do efeito
// Warped noise field, approximating os2NoiseWithDerivatives_ImproveXY via
        // simplex noise + finite-difference derivatives.
        const float PI = 3.14159265358979323846264;

        /* 3D Simplex noise from IQ (public domain-ish) */
        static float3 mod289(float3 x){ return x - floor(x * (1.0 / 289.0)) * 289.0; }
        static float4 mod289(float4 x){ return x - floor(x * (1.0 / 289.0)) * 289.0; }
        static float4 permute(float4 x){ return mod289(((x*34.0)+1.0)*x); }
        static float4 taylorInvSqrt(float4 r){ return 1.79284291400159 - 0.85373472095314 * r; }
        static float snoise(float3 v){
            const float2  C = float2(1.0/6.0, 1.0/3.0) ;
            const float4  D = float4(0.0, 0.5, 1.0, 2.0);
            // First corner
            float3 i  = floor(v + dot(v, C.yyy) );
            float3 x0 = v - i + dot(i, C.xxx) ;
            // Other corners
            float3 g = step(x0.yzx, x0.xyz);
            float3 l = 1.0 - g;
            float3 i1 = min( g.xyz, l.zxy );
            float3 i2 = max( g.xyz, l.zxy );
            //  x0 = x0 - 0.0 + 0.0 * C.xxx;
            float3 x1 = x0 - i1 + 1.0 * C.xxx;
            float3 x2 = x0 - i2 + 2.0 * C.xxx;
            float3 x3 = x0 - 1.0 + 3.0 * C.xxx;
            // Permutations
            i = mod289(i);
            float4 p = permute( permute( permute(
                       i.z + float4(0.0, i1.z, i2.z, 1.0 ))
                     + i.y + float4(0.0, i1.y, i2.y, 1.0 ))
                     + i.x + float4(0.0, i1.x, i2.x, 1.0 ));
            // Gradients: 7x7 points over a square, mapped onto an octahedron.
            float n_ = 0.142857142857; // 1.0/7.0
            float3  ns = n_ * D.wyz - D.xzx;
            float4 j = p - 49.0 * floor(p * ns.z * ns.z);
            float4 x_ = floor(j * ns.z);
            float4 y_ = floor(j - 7.0 * x_ );
            float4 x = x_ *ns.x + ns.yyyy;
            float4 y = y_ *ns.x + ns.yyyy;
            float4 h = 1.0 - abs(x) - abs(y);
            float4 b0 = float4( x.xy, y.xy );
            float4 b1 = float4( x.zw, y.zw );
            float4 s0 = floor(b0)*2.0 + 1.0;
            float4 s1 = floor(b1)*2.0 + 1.0;
            float4 sh = -step(h, float4(0.0));
            float4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
            float4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;
            float3 p0 = float3(a0.xy,h.x);
            float3 p1 = float3(a0.zw,h.y);
            float3 p2 = float3(a1.xy,h.z);
            float3 p3 = float3(a1.zw,h.w);
            // Normalise gradients
            float4 norm = taylorInvSqrt(float4(dot(p0,p0), dot(p1,p1), dot(p2,p2), dot(p3,p3)));
            p0 *= norm.x;
            p1 *= norm.y;
            p2 *= norm.z;
            p3 *= norm.w;
            // Mix contributions from the four corners
            float4 m = max(0.6 - float4(dot(x0,x0), dot(x1,x1),
                                    dot(x2,x2), dot(x3,x3)), 0.0);
            m = m * m;
            return 42.0 * dot( m*m, float4( dot(p0,x0), dot(p1,x1),
                                          dot(p2,x2), dot(p3,x3) ) );
        }

        // Approximate derivatives by finite differences
        static float4 snoiseWithDerivatives(float3 p, float e){
            float n  = snoise(p);
            float3 ex = float3(e,0.0,0.0);
            float3 ey = float3(0.0,e,0.0);
            float3 ez = float3(0.0,0.0,e);
            float nx = snoise(p+ex) - snoise(p-ex);
            float ny = snoise(p+ey) - snoise(p-ey);
            float nz = snoise(p+ez) - snoise(p-ez);
            float3 d = float3(nx,ny,nz) / (2.0*e);
            return float4(d, n);
        }

fragment float4 fx_toji_warped_noise_field(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_warped_noise_fieldParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 res = eng.acScreenSize;
            float m = max(res.x, res.y);
            float2 frag = in.acScreenNorm * res; // convert back to pixel space
            float2 uv = frag / m * u.scale;

            float t = __nv_mod(u.time * u.speed, 578.0) * 0.8660254037844386; // tan(60)/? factor from source
            float3 X = float3(uv, t);

            // First evaluation
            float4 nr = snoiseWithDerivatives(X, u.eps);
            // Warped evaluation
            nr = snoiseWithDerivatives(X - nr.xyz * u.warpAmount, u.eps);
            float value = nr.w;

            float3 col = u.baseColor.rgb * (0.5 + 0.5 * value);
            float4 outC = float4(col, 1.0);

            if (u.blendSource) {
                float4 src = inputImg.sample(__nv_smp, in.acScreenNorm);
                outC.rgb *= src.rgb;
                outC.a = 1.0;
            }
            __nv_out = outC;
    return __nv_out;
}
