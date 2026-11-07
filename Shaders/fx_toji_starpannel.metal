// ---------------------------------------------------------------------------
// Starry Planes
// origem : assets/effects/toji-starpannel.xml
// id     : com.alightcreative.effects.starry_planes
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_starpannelParams {
    float speed;
    float intensity;
    float exposure;
    float opacity;
};

// --- funcoes auxiliares do efeito
// Alight Motion mapping
    // iResolution -> eng.acScreenSize
    // iTime -> eng.acTime

    const float PI = 3.14159265358979323846264;

    static float2x2 ROT(float a){
      float c = cos(a), s = sin(a);
      return float2x2(c, s, -s, c);
    }

    // Matt Taylor ACES approx (tonemapping)
    static float3 aces_approx(float3 v) {
      v = max(v, 0.0);
      v *= 0.6;
      float a = 2.51;
      float b = 0.03;
      float c = 2.43;
      float d = 0.59;
      float e = 0.14;
      return clamp((v*(a*v+b))/(v*(c*v+d)+e), 0.0, 1.0);
    }

    // Scene constants
    const float planeDist = 0.5;
    const float furthest  = 16.0;
    const float fadeFrom  = 8.0;

    const float2  pathA = float2(0.31, 0.41);
    const float2  pathB = float2(1.0, 0.7071067811865476); // sqrt(0.5)

    static float3 offsetf(float z) {
      return float3(pathB * sin(pathA*z), z);
    }

    static float3 doffsetf(float z) {
      return float3(pathA*pathB * cos(pathA*z), 1.0);
    }

    static float3 ddoffsetf(float z) {
      return float3(-pathA*pathA*pathB * sin(pathA*z), 0.0);
    }

    static float4 alphaBlend(float4 back, float4 front) {
      float w = front.w + back.w*(1.0-front.w);
      float3 xyz = (front.xyz*front.w + back.xyz*back.w*(1.0-front.w)) / max(w, 1e-6);
      return (w > 0.0) ? float4(xyz, w) : float4(0.0);
    }

    static float pmin(float a, float b, float k) {
      float h = clamp(0.5 + 0.5*(b-a)/k, 0.0, 1.0);
      return mix(b, a, h) - k*h*(1.0-h);
    }

    static float pabs(float a, float k) {
      return -pmin(a, -a, k);
    }

    // 5-pointed star SDF (tweaked inner rounding)
    static float star5(float2 p, float r, float rf, float sm) {
      p = -p;
      const float2 k1 = float2(0.809016994375, -0.587785252292);
      const float2 k2 = float2(-k1.x, k1.y);
      p.x = abs(p.x);
      p -= 2.0*max(dot(k1,p), 0.0)*k1;
      p -= 2.0*max(dot(k2,p), 0.0)*k2;
      p.x = pabs(p.x, sm);
      p.y -= r;
      float2 ba = rf*float2(-k1.y, k1.x) - float2(0,1);
      float h = clamp(dot(p,ba)/dot(ba,ba), 0.0, r);
      return length(p - ba*h) * sign(p.y*ba.x - p.x*ba.y);
    }

    static float3 palette(float n) {
      return 0.5 + 0.5 * sin(float3(0.0, 1.0, 2.0) + n);
    }

    static float4 plane(float3 ro, float3 rd, float3 pp, float3 npp, float pd, float3 cp, float3 off, float n) {
      float aa = 3.0 * pd * distance(pp.xy, npp.xy);
      float4 col = float4(0.0);
      float2 p2 = pp.xy;
      p2 -= offsetf(pp.z).xy;
      float2 doff   = ddoffsetf(pp.z).xz;
      float2 ddoff  = doffsetf(pp.z).xz;
      float dd = dot(doff, ddoff);
      p2 = ROT(dd*PI*5.0) * p2;

      float d0 = star5(p2, 0.45, 1.6, 0.2) - 0.02;
      float d1 = d0 - 0.01;
      float d2 = length(p2);
      const float colp = PI*100.0;
      float colaa = aa*200.0;

      col.xyz = palette(0.5*n + 2.0*d2)
              * mix(0.5/(d2*d2), 1.0, smoothstep(-0.5+colaa, 0.5+colaa, sin(d2*colp)))
              / max(3.0*d2*d2, 1e-1);
      col.xyz = mix(col.xyz, float3(2.0), smoothstep(aa, -aa, d1));
      col.w = smoothstep(aa, -aa, -d0);
      return col;
    }

    static float3 colorfn(float3 ww, float3 uu, float3 vv, float3 ro, float2 p, float2 iResolution) {
      float2 np = p + 1.0/iResolution.xy;
      float rdd = 1.75; // 2.0-0.25

      float3 rd  = normalize(p.x*uu + p.y*vv + rdd*ww);
      float3 nrd = normalize(np.x*uu + np.y*vv + rdd*ww);

      float nz = floor(ro.z / planeDist);
      float4 acol = float4(0.0);
      float3 aro = ro;
      float apd = 0.0;

      for (float i = 1.0; i <= furthest; i += 1.0) {
        if (acol.w > 0.95) break;
        float pz = planeDist*nz + planeDist*i;

        float lpd = (pz - aro.z)/rd.z;
        float npd = (pz - aro.z)/nrd.z;
        float cpd = (pz - aro.z)/ww.z;

        float3 pp  = aro + rd*lpd;
        float3 npp = aro + nrd*npd;
        float3 cp  = aro + ww*cpd;
        apd += lpd;

        float3 off = offsetf(pp.z);
        float dz = pp.z - ro.z;
        float fadeIn   = smoothstep(planeDist*furthest, planeDist*fadeFrom, dz);
        float fadeOut  = smoothstep(0.0, planeDist*0.1, dz);
        float fadeOutRI= smoothstep(0.0, planeDist*1.0, dz);
        float ri = mix(1.0, 0.9, fadeOutRI*fadeIn);

        float4 pcol = plane(ro, rd, pp, npp, apd, cp, off, nz + i);
        pcol.w *= fadeOut*fadeIn;
        acol = alphaBlend(pcol, acol);
        aro = pp;
      }

      return acol.xyz * acol.w;
    }

fragment float4 fx_toji_starpannel(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_starpannelParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 fragCoord = in.acScreenNorm * eng.acScreenSize;
      float2 iResolution = eng.acScreenSize;
      float iTime = eng.acTime * u.speed;

      float2 r = iResolution.xy;
      float2 q = fragCoord / r;
      float2 pp = -1.0 + 2.0*q;
      float2 p = pp;
      p.x *= r.x / max(r.y, 1.0);

      float tm = planeDist * iTime;
      float3 ro   = offsetf(tm);
      float3 dro  = doffsetf(tm);
      float3 ddro = ddoffsetf(tm);

      float3 ww = normalize(dro);
      float3 uu = normalize(cross(float3(0.0,1.0,0.0)+ddro, ww));
      float3 vv = cross(ww, uu);

      float3 col = colorfn(ww, uu, vv, ro, p, iResolution);
      col = aces_approx(col * u.exposure) * u.intensity;
      col = sqrt(max(col, 0.0));

      // Composite over input layer
      float4 base = inputImg.sample(__nv_smp, in.acScreenNorm);
      float4 outC = float4(col, 1.0) * u.opacity;
      outC = base * (1.0 - outC.a) + outC;
      __nv_out = outC;
    return __nv_out;
}
