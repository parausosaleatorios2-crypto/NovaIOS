// ---------------------------------------------------------------------------
// Metal Balls
// origem : assets/effects/toji-metalballs.xml
// id     : com.alightcreative.effects.glass_balls
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_metalballsParams {
    float ballCount;
    float ballRadius;
    float spread;
    float zSpread;
    float4 ballColor;
    float progress;
    int randomSize;
    float sizeVar;
    float randSeed;
    float posX;
    float posY;
    float posZ;
    float ior;
    float shininess;
    float reflectMix;
    float refractScale;
    float reflectScale;
    float fov;
    float lightX;
    float lightY;
    float lightZ;
};

// --- funcoes auxiliares do efeito
float2 getResolution(){
      float2 s = __nv_getTexSize(inputImg_info.size);
      if (s.x <= 0.0 || s.y <= 0.0) s = float2(1920.0, 1080.0);
      return s;
    }
    float2 hash2(float n){ return fract(sin(float2(n, n + 1.0)) * 43758.5453); }
    float intersectSphere(float3 ro, float3 rd, float3 center, float radius){
      float3 oc = ro - center;
      float b = dot(oc, rd);
      float c = dot(oc, oc) - radius * radius;
      float h = b*b - c;
      if (h < 0.0) return -1.0;
      return -b - sqrt(h);
    }

fragment float4 fx_toji_metalballs(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_metalballsParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 res = getResolution();
      float2 fragCoord = in.acScreenNorm * res;
      float2 uv = in.acScreenNorm;
      float2 p = (fragCoord - 0.5 * res) / res.y;
      float3 ro = float3(0.0, 0.0, -2.0);
      float3 rd = normalize(float3(p, u.fov));
      float3 lightPos = normalize(float3(u.lightX, u.lightY, u.lightZ));
      float3 col = inputImg.sample(__nv_smp, uv).rgb;
      float minT = 10000.0;
      float3 hitCenter = float3(0.0);
      int maxBalls = int(u.ballCount);
      float aspect = res.x / res.y;
      for(int i=0;i<400;i++){
        if (i >= maxBalls) break;
        float2 rnd = hash2(float(i) * 56.7 + u.randSeed);
        float t_anim = u.progress * 20.0 + (float(i) * 12.0);
        float3 center = float3(0.0);
        center.x = sin(t_anim + rnd.x * 6.2831853) * 0.8 * aspect * u.spread;
        center.y = cos(t_anim * 0.9 + rnd.y * 6.2831853) * 0.4 * u.spread;
        center.z = sin(t_anim * 0.5) * u.zSpread;
        center += float3(u.posX, u.posY, u.posZ);
        float rVar = 1.0;
        if (u.randomSize){ rVar = 1.0 + (rnd.x * 2.0 - 1.0) * u.sizeVar; }
        float rBall = clamp(u.ballRadius * rVar, 0.001, 10.0);
        float t = intersectSphere(ro, rd, center, rBall);
        if (t > 0.0 && t < minT){ minT = t; hitCenter = center; }
      }
      if (minT < 10000.0){
        float3 pos = ro + rd * minT;
        float3 normal = normalize(pos - hitCenter);
        float3 viewDir = -rd;
        float cosTheta = clamp(dot(normal, viewDir), 0.0, 1.0);
        float fresnel = pow(1.0 - cosTheta, 4.0);
        float reflStrength = (0.1 + 0.9 * fresnel) * u.reflectMix;
        float3 refrVec = refract(rd, normal, 1.0 / u.ior);
        float2 refrUV = uv + refrVec.xy * u.refractScale;
        float3 glassColor = inputImg.sample(__nv_smp, refrUV).rgb;
        float3 absorb = u.ballColor.rgb * (0.5 + 0.5 * cosTheta);
        glassColor *= absorb * 1.5;
        float3 reflVec = reflect(rd, normal);
        float2 reflUV = uv + reflVec.xy * u.reflectScale;
        float3 reflColor = inputImg.sample(__nv_smp, reflUV).rgb;
        float3 halfVec = normalize(lightPos + viewDir);
        float spec = pow(max(dot(normal, halfVec), 0.0), u.shininess);
        float3 sphereCol = mix(glassColor, reflColor, reflStrength);
        sphereCol += float3(1.0) * spec;
        sphereCol += float3(1.0, 0.2, 0.2) * fresnel * 0.3;
        col = sphereCol;
      }
      __nv_out = float4(col, 1.0);
    return __nv_out;
}
