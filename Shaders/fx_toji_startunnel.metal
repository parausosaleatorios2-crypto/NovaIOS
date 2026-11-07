// ---------------------------------------------------------------------------
// Star Tunnel 
// origem : assets/effects/toji-startunnel.xml
// id     : com.alightcreative.effects.star_tunnel_camera
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_startunnelParams {
    float camX;
    float camY;
    float camZ;
    float3 rotDeg;
    float zSpeed;
    int autoBlur;
    float blurFactor;
    float rotBlurSpeed;
    float manualTrail;
    float brightness;
    float particleSize;
    float particleCount;
    float4 colorA;
    float4 colorB;
    float alpha;
    float3 sysRotDeg;
    float sysRotSpeedX;
    float sysRotSpeedY;
    float sysRotSpeedZ;
};

// --- funcoes auxiliares do efeito
// Star Tunnel - camera pose + auto motion blur (based on @P_Malin)
    // AM official style: fixed loops, only builtins

    static float Random(float x){
      return fract(sin(x * 123.456) * 23.4567 + sin(x * 345.678) * 45.6789 + sin(x * 456.789) * 56.789);
    }

    static float3 RotateX(float3 v, float a){ float s=sin(a), c=cos(a); return float3(v.x, c*v.y + s*v.z, -s*v.y + c*v.z); }
    static float3 RotateY(float3 v, float a){ float s=sin(a), c=cos(a); return float3(c*v.x + s*v.z, v.y, -s*v.x + c*v.z); }
    static float3 RotateZ(float3 v, float a){ float s=sin(a), c=cos(a); return float3(c*v.x + s*v.y, -s*v.x + c*v.y, v.z); }

    // Tunables (kept as constants for stability)
    const float fSteps = 121.0;
    const float fMinDist = 0.8;
    const float fMaxDist = 5.0;
    const float fRepeatMin = 1.0;
    const float fRepeatMax = 2.0;
    const float fDepthFade = 0.8;

    static float3 GetParticlePos(float3 vRayDir, float fZPos, float fSeed){
      float fAngle = __nv_atan(vRayDir.x, vRayDir.y);
      float fAngleFraction = fract(fAngle / (6.28318530718));
      float fSegment = floor(fAngleFraction * fSteps + fSeed) + 0.5 - fSeed;
      float fParticleAngle = fSegment / fSteps * (6.28318530718);
      float fSegmentPos = fSegment / fSteps;
      float fRadius = fMinDist + Random(fSegmentPos + fSeed) * (fMaxDist - fMinDist);
      float tunnelZ = vRayDir.z / length(vRayDir.xy / fRadius);
      tunnelZ += fZPos;
      float fRepeat = fRepeatMin + Random(fSegmentPos + 0.1 + fSeed) * (fRepeatMax - fRepeatMin);
      float fParticleZ = (ceil(tunnelZ / fRepeat) - 0.5) * fRepeat - fZPos;
      return float3( sin(fParticleAngle) * fRadius, cos(fParticleAngle) * fRadius, fParticleZ );
    }

    static float3 GetParticleColour(float3 vParticlePos, float fParticleSize, float3 vRayDir, float particleLength, float u.brightness){
      float2 vNormDir = normalize(vRayDir.xy);
      float d1 = dot(vParticlePos.xy, vNormDir.xy) / max(length(vRayDir.xy), 1e-5);
      float3 vClosest2d = vRayDir * d1;
      float3 vClampedPos = vParticlePos;
      vClampedPos.z = clamp(vClosest2d.z, vParticlePos.z - particleLength, vParticlePos.z + particleLength);
      float d = dot(vClampedPos, vRayDir);
      float3 vClosestPos = vRayDir * d;
      float3 vDeltaPos = vClampedPos - vClosestPos;
      float fClosestDist = length(vDeltaPos) / max(fParticleSize, 1e-5);
      float fShade = clamp(1.0 - fClosestDist, 0.0, 1.0);
      fShade = fShade * exp2(-d * fDepthFade) * u.brightness;
      return float3(fShade);
    }

    static float4 GetParticleEx(float3 vRayDir, float fZPos, float fSeed){
      float fAngle = __nv_atan(vRayDir.x, vRayDir.y);
      float fAngleFraction = fract(fAngle / (6.28318530718));
      float fSegment = floor(fAngleFraction * fSteps + fSeed) + 0.5 - fSeed;
      float fParticleAngle = fSegment / fSteps * (6.28318530718);
      float fSegmentPos = fSegment / fSteps;
      float fRadius = fMinDist + Random(fSegmentPos + fSeed) * (fMaxDist - fMinDist);
      float tunnelZ = vRayDir.z / length(vRayDir.xy / fRadius);
      tunnelZ += fZPos;
      float fRepeat = fRepeatMin + Random(fSegmentPos + 0.1 + fSeed) * (fRepeatMax - fRepeatMin);
      float fRing = (ceil(tunnelZ / fRepeat) - 0.5);
      float fParticleZ = fRing * fRepeat - fZPos;
      float id = floor(fSegment) + 4096.0 * floor(fRing);
      float3 pos = float3( sin(fParticleAngle) * fRadius, cos(fParticleAngle) * fRadius, fParticleZ );
      return float4(pos, id);
    }

    static float3 Starfield(float3 vRayDir, float fZPos, float fSeed, float fParticleSize, float particleLength, float u.brightness){
      float3 sysRad = radians(u.sysRotDeg);
      float ax = sysRad.x + radians(u.sysRotSpeedX) * eng.acTime;
      float ay = sysRad.y + radians(u.sysRotSpeedY) * eng.acTime;
      float az = sysRad.z + radians(u.sysRotSpeedZ) * eng.acTime;
      float3 vRayObj = vRayDir;
      vRayObj = RotateX(vRayObj, -ax);
      vRayObj = RotateY(vRayObj, -ay);
      vRayObj = RotateZ(vRayObj, -az);
      float4 P = GetParticleEx(vRayObj, fZPos, fSeed);
      float3 vParticlePos = P.xyz;
      float pid = P.w;
      float3 shade = GetParticleColour(vParticlePos, fParticleSize, vRayObj, particleLength, u.brightness);
      float h = fract(sin(pid*123.456 + fSeed*7.123) * 43758.5453);
      float3 c = (h < 0.5) ? u.colorA.rgb : u.colorB.rgb;
      return shade * c;
    }

fragment float4 fx_toji_startunnel(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_startunnelParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      // Screen ray
      float2 vScreenUV = in.acScreenNorm;
      float2 vScreenPos = vScreenUV * 2.0 - 1.0;
      vScreenPos.x *= eng.acScreenSize.x / max(eng.acScreenSize.y, 1.0);
      // Camera XY offsets: shift screen pos (parallax-like)
      vScreenPos += float2(u.camX, u.camY) * 0.2;

      float3 vRayDir = normalize(float3(vScreenPos, 1.0));

      // Apply rotations
      float3 rotRad = radians(u.rotDeg);
      float rx = rotRad.x;
      float ry = rotRad.y;
      float rz = rotRad.z;
      vRayDir = RotateX(vRayDir, rx);
      vRayDir = RotateY(vRayDir, ry);
      vRayDir = RotateZ(vRayDir, rz);

      // Forward motion controlled by u.zSpeed and u.camZ offset
      float t = eng.acTime;
      float fZPos = u.camZ + t * u.zSpeed;
      float fSpeed = abs(u.zSpeed);

      // Auto motion-blur -> particle trail length (includes rotation-driven blur)
      float rotComponent = u.rotBlurSpeed * 0.002; // deg/s to trail scalar
      float particleLength = u.autoBlur ? (u.blurFactor * (fSpeed + rotComponent + 0.001)) : u.manualTrail; // in Z units

      // No background: start from black for transparent background
      float3 vResult = float3(0.0);

      // Pass count (1..3 capped)
      int passes = int(clamp(float(u.particleCount), 1.0, 3.0));
      float fSeed = 0.0;
      for(int i=0;i<3;i++){
        if(i>=passes) break;
        vResult += Starfield(vRayDir, fZPos, fSeed, u.particleSize, particleLength, u.brightness);
        fSeed += 1.234;
      }

      float3 col = sqrt(vResult);
      // Alpha derived from star intensity (transparent background)
      float starIntensity = max(max(col.r, col.g), col.b);
      float aOut = clamp(starIntensity, 0.0, 1.0) * u.alpha;
      __nv_out = float4(col, aOut);
    return __nv_out;
}
