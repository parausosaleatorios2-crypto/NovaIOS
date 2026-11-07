// ---------------------------------------------------------------------------
// Saber
// origem : assets/effects/toji-1saber.xml
// id     : com.alightcreative.effects.electricedges_saber
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_1saberParams {
    float distance;
    float thickness;
    float complexity;
    float disort;
    float4 color1;
    float4 color2;
    float alpha;
    float glowAlpha;
    float seed;
    float evolution;
    float fill;
    float4 maskColor;
    float maskStrength;
    float maskEvolution;
    float maskScale;
    float maskSeed;
    int saberType;
    float pulseSpeed;
    float coreScale;
    float glowSize;
    float glowBrightness;
    float brightness;
    float flickerAmount;
    float coreSoftness;
    float glowFalloff;
    float glowSpread;
    float colorBoost;
    float gammaExp;
    int renderContours;
    float contourCount;
    float contourOffset;
    float contourAngle;
};

// --- funcoes auxiliares do efeito
static float2 random2( float2 p ) { return fract(sin(float2(dot(p,float2(127.1,311.7)),dot(p,float2(269.5,183.3))))*43758.5453); }
        static float2 noise (in float2 st) {
            float2 i = floor(st);
            float2 f = fract(st);
            float2 a = random2(i);
            float2 b = random2(i + float2(1.0, 0.0));
            float2 c = random2(i + float2(0.0, 1.0));
            float2 d = random2(i + float2(1.0, 1.0));
            float2 u = f;
            return mix(a, b, u.x) + (c - a)* u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
        }
        static float3 mod289(float3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
        static float2 mod289(float2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
        static float4 mod289(float4 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
        static float3 permute(float3 x) { return mod289(((x*34.0)+1.0)*x); }
        static float4 permute(float4 x) { return mod289(((x*34.0)+1.0)*x); }
        static float4 taylorInvSqrt(float4 r) { return 1.79284291400159 - 0.85373472095314 * r; }
        static float rand(float2 co){ return fract(sin(dot(co.xy, float2(12.9898,78.233))) * 43758.5453); }
        static float snoise(float3 v){
          const float2  C = float2(1.0/6.0, 1.0/3.0);
          const float4  D = float4(0.0, 0.5, 1.0, 2.0);
          float3 i  = floor(v + dot(v, C.yyy));
          float3 x0 = v - i + dot(i, C.xxx);
          float3 g = step(x0.yzx, x0.xyz);
          float3 l = 1.0 - g;
          float3 i1 = min( g.xyz, l.zxy );
          float3 i2 = max( g.xyz, l.zxy );
          float3 x1 = x0 - i1 + C.xxx;
          float3 x2 = x0 - i2 + C.yyy;
          float3 x3 = x0 - D.yyy;
          i = mod289(i);
          float4 p = permute( permute( permute( i.z + float4(0.0, i1.z, i2.z, 1.0 )) + i.y + float4(0.0, i1.y, i2.y, 1.0 )) + i.x + float4(0.0, i1.x, i2.x, 1.0 ));
          float n_ = 0.142857142857;
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
          float4 a0 = b0.xzyw + s0.xzyw*sh.xxyy;
          float4 a1 = b1.xzyw + s1.xzyw*sh.zzww;
          float3 p0 = float3(a0.xy,h.x);
          float3 p1 = float3(a0.zw,h.y);
          float3 p2 = float3(a1.xy,h.z);
          float3 p3 = float3(a1.zw,h.w);
          float4 norm = taylorInvSqrt(float4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
          p0 *= norm.x; p1 *= norm.y; p2 *= norm.z; p3 *= norm.w;
          float4 m = max(0.6 - float4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
          m = m * m;
          return 42.0 * dot( m*m, float4( dot(p0,x0), dot(p1,x1), dot(p2,x2), dot(p3,x3) ) );
        }
        static float turbulence (in float2 st, in int OCTAVES, in float2 parallax, in float u.evolution) {
            float value = 0.0; float amplitude = .5; for (int i = 0; i < OCTAVES; i++) { value += amplitude * abs(snoise(float3(st,u.evolution))); st *= 2.; st += parallax; amplitude *= .5; } return value;
        }
        static float2x2 rot2d(float a) { float s = sin(a); float c = cos(a); return float2x2(c,s,-s,c); }

fragment float4 fx_toji_1saber(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_1saberParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> blurBuf [[texture(1)]],
    texture2d<float> comp [[texture(2)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& blurBuf_info [[buffer(3)]],
    constant NovaTexInfo& comp_info [[buffer(4)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 st = in.acLayerNorm; st -= 0.5; st.x *= eng.acLayerSize.x/eng.acLayerSize.y;
            float2 evoseed = float2(3.)*(u.evolution + eng.acTime * u.pulseSpeed) + float2(62.5587,137.1935)*u.seed;
            float2 pixelSize = float2(1.) / eng.acScreenSize;

            float dMul = 1.0; float cMul = 1.0; float gMul = u.glowBrightness;
            int tp = int(u.saberType);
            if (tp==0){ dMul=1.2; cMul=1.5; gMul*=1.2; }
            else if (tp==1){ dMul=0.7; cMul=0.9; gMul*=1.5; }
            else if (tp==2){ dMul=1.0; cMul=1.2; gMul*=1.1; }
            else if (tp==3){ dMul=1.4; cMul=2.0; gMul*=1.3; }
            else if (tp==4){ dMul=1.1; cMul=1.3; gMul*=1.25; }
            else if (tp==5){ dMul=0.8; cMul=1.8; gMul*=1.4; }
            else if (tp==6){ dMul=1.3; cMul=1.6; gMul*=1.6; }
            else if (tp==7){ dMul=1.5; cMul=2.4; gMul*=0.9; }
            else if (tp==8){ dMul=0.9; cMul=1.0; gMul*=1.8; }
            else if (tp==9){ dMul=1.6; cMul=2.2; gMul*=1.5; }

            float2 l1 = noise(evoseed + st * rot2d(0.1) * 2. * u.complexity * cMul);
            float2 l2 = noise(evoseed + st * rot2d(0.3) * 4. * u.complexity * cMul);
            float2 l3 = noise(evoseed + st * rot2d(1.42) * 8. * u.complexity * cMul);
            float2 l4 = noise(evoseed + st * rot2d(2.534) * 16. * u.complexity * cMul);
            float2 offs = abs(abs(l1 - l2) - abs(l3 - l4));
            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float4 blurTexColorMid = blurBuf.sample(__nv_smp, in.acScreenNorm);
            float4 blurTexColorUp = blurBuf.sample(__nv_smp, in.acScreenNorm + pixelSize*float2(0.,-4.));
            float4 blurTexColorLeft = blurBuf.sample(__nv_smp, in.acScreenNorm + pixelSize*float2(-4.,0.));
            float4 compColor = comp.sample(__nv_smp, in.acScreenNorm.st);
            float dx = blurTexColorMid.a - blurTexColorLeft.a;
            float dy = blurTexColorMid.a - blurTexColorUp.a;
            float2 norm = normalize(float2(dx,dy));
            float4 blurTexColor = blurBuf.sample(__nv_smp, in.acScreenNorm + norm*length(offs)*(u.disort*dMul*0.055));

            float turbBase = turbulence((st-0.5)/u.maskScale+0.5, 3, float2(0.), u.maskEvolution + 91.935*u.maskSeed);
            float TINT_RANGE = 0.02;
            float turb = smoothstep( u.maskStrength - (TINT_RANGE+.2), u.maskStrength-(TINT_RANGE+.1), turbBase);
            float suppress = smoothstep( u.maskStrength - (TINT_RANGE+.1), u.maskStrength-TINT_RANGE, turbBase);
            float ttint = smoothstep( u.maskStrength - TINT_RANGE, u.maskStrength-0.001, turbBase);

            float p = blurTexColor.a;
            float dist = 1. - (u.distance * 0.4 + 0.5);
            float coreBase = 1. - abs(p - dist);
            float distGlow = dist - (u.glowSize-1.0)*0.1 - u.glowSpread*0.1;
            float glowBase = 1. - abs(p - distGlow);
            float sPulse = 0.5 + 0.5*sin(eng.acTime * u.pulseSpeed);
            float tBlock = floor(eng.acTime * u.pulseSpeed);
            float flick = 1.0 - u.flickerAmount + u.flickerAmount * rand(st*437.0 + float2(tBlock));
            float eCBase = (1.-(u.thickness*0.9*suppress))*30.;
            float eGBase = (1.-(u.thickness*0.9*suppress))*25.;
            float eCAdj = eCBase * u.coreSoftness;
            float eGAdj = eGBase * u.glowFalloff;

            float pp;
            float qq;
            if (tp==0){
                float n = 0.3 + 0.7*snoise(float3(st*u.complexity*cMul, u.evolution));
                pp = pow(coreBase, eCAdj) * u.coreScale * (0.7 + 0.3*n);
                qq = pow(glowBase, eGAdj) * (0.8 + 0.2*n);
            } else if (tp==1){
                pp = pow(coreBase, 8.0*u.coreSoftness) * u.coreScale * sPulse * flick;
                qq = pow(glowBase, 2.5*u.glowFalloff) * sPulse;
            } else if (tp==2){
                pp = smoothstep(0.0, 1.0, coreBase) * u.coreScale * flick;
                qq = smoothstep(0.0, 1.0, glowBase);
            } else if (tp==3){
                float tn = turbulence((st-0.5)/u.maskScale+0.5, 4, float2(0.), u.maskEvolution + 13.7*u.maskSeed);
                float eC = (12.0 + 18.0*tn) * u.coreSoftness;
                float eG = (10.0 + 14.0*tn) * u.glowFalloff;
                pp = pow(coreBase, eC) * u.coreScale * flick;
                qq = pow(glowBase, eG);
            } else if (tp==4){
                float arad = u.contourAngle * 0.0174533;
                float2 st2 = st * rot2d(arad);
                float lines = saturate(sin((st2.y + u.contourOffset) * u.contourCount));
                pp = pow(coreBase, 20.0*u.coreSoftness) * (0.7 + 0.3*lines) * u.coreScale * flick;
                qq = pow(glowBase, 18.0*u.glowFalloff) * (0.7 + 0.3*lines);
            } else {
                if (tp==5){
                    float neb = 0.5 + 0.5*snoise(float3(st*u.complexity, u.evolution));
                    pp = pow(coreBase, 12.0*u.coreSoftness) * u.coreScale * (0.8 + 0.4*neb);
                    qq = pow(glowBase, 9.0*u.glowFalloff) * (0.8 + 0.4*neb);
                } else if (tp==6){
                    float flame = 0.6 + 0.4*abs(sin(eng.acTime*u.pulseSpeed + st.y*10.0));
                    pp = pow(coreBase, 6.0*u.coreSoftness) * u.coreScale * flame * flick;
                    qq = pow(glowBase, 2.0*u.glowFalloff) * (1.0 + 0.5*flame);
                } else if (tp==7){
                    pp = pow(coreBase, 40.0*u.coreSoftness) * u.coreScale * (0.9 + 0.1*sPulse) * flick;
                    qq = pow(glowBase, 8.0*u.glowFalloff) * 0.6;
                } else if (tp==8){
                    pp = smoothstep(0.6, 1.0, coreBase) * u.coreScale * flick;
                    qq = pow(glowBase, 3.0*u.glowFalloff) * 1.8;
                } else { // Lightning
                    float jag = 0.5 + 0.5*abs(sin(st.x*35.0 + st.y*25.0 + eng.acTime*u.pulseSpeed));
                    pp = pow(coreBase, 28.0*u.coreSoftness) * u.coreScale * (0.7 + 0.3*jag) * flick;
                    qq = pow(glowBase, 14.0*u.glowFalloff) * (0.8 + 0.2*jag);
                }
            }

            pp = clamp(pp, 0.0, 1.0);
            qq = clamp(qq, 0.0, 1.0);
            pp *= smoothstep(0.01,0.12,p);
            pp *= smoothstep(1.0,0.999,p);
            qq *= smoothstep(0.01,0.12,p);
            qq *= smoothstep(1.0,0.999,p);

            if(u.renderContours) {
                float arad = u.contourAngle * 0.0174533;
                float2 st2 = st;
                st2.y += blurTexColorMid.a*0.1;
                st2 *= rot2d(length(offs*u.disort*dMul*1.1)*0.2+arad);
                st2.y += blurTexColorMid.a*0.1;
                float lines = saturate(sin((st2.y+u.contourOffset+(offs.y*u.disort*dMul*0.015)) * u.contourCount)) * smoothstep(0.1,0.2,blurTexColorMid.a);
                pp += pow(lines,(1.-(u.thickness*0.9*suppress))*30.);
                qq += pow(lines,(1.-(u.thickness*0.9*suppress))*25.);
            }

            float4 c0 = float4(pow( float3(pp), 1./u.color1.rgb),pp) * u.alpha;
            float4 c1 = float4(pow( float3(qq), 1./u.color2.rgb),qq) * (u.glowAlpha * gMul);
            float4 c = saturate(c0 + c1);
            c.rgb *= (u.brightness * u.colorBoost);
            c.rgb = pow(c.rgb, float3(u.gammaExp));
            c *= (mix(u.maskColor,float4(1.),ttint)*turb);
            __nv_out = texColor * u.fill * (1.-c.a) + c;
    return __nv_out;
}
