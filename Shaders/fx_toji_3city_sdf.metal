// ---------------------------------------------------------------------------
// 3D City 
// origem : assets/effects/toji-3city_sdf.xml
// id     : com.alightcreative.effects.city_sdf
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_3city_sdfParams {
    float time;
    float camX;
    float camY;
    float camZ;
    float yawDeg;
    float pitchDeg;
    int autoRotate;
    float rotateSpeed;
    int placeLayer;
    float objPosX;
    float objPosY;
    float objPosZ;
    float objYaw;
    float objPitch;
    float objRoll;
    float objWidth;
    float objHeight;
    float objScale;
    float objOpacity;
};

// --- funcoes auxiliares do efeito
// Shadertoy port: bind eng.acTime as iTime and input size as iResolution

    // Helpers and bindings
    float2 getResolution() {
      float2 s = __nv_getTexSize(inputImg_info.size);
      // Fallback to 1920x1080 if size is zero (no content), to avoid div by zero
      if (s.x <= 0.0 || s.y <= 0.0) s = float2(1920.0, 1080.0);
      return s;
    }

    // Sample env texture with equirectangular mapping from direction 
    const float PI = 3.14159265358979323846; 
    // GLSL ES 1.00 helper (some runtimes lack radians())
    float deg2rad(float d){ return d * (PI / 180.0); }
    float2 dirToEquirect(float3 d) {
      d = normalize(d);
      float phi = __nv_atan(d.z, d.x);
      float theta = acos(clamp(d.y, -1.0, 1.0));
      return float2(phi / (2.0*PI) + 0.5, theta / PI);
    }

    // Shadertoy uniforms replacement
    #define iTime eng.acTime

    // ---------------- Copied/Adapted from source ----------------
    float localTime = 0.0;
    float seed = 1.0;

    float fade = 1.0;
    float3 sunDir;
    float3 sunCol;
    float exposure = 1.0;
    float3 skyCol, horizonCol;

    float marchCount = 0.0;

    float v31(float3 a){ return a.x + a.y * 37.0 + a.z * 521.0; }
    float v21(float2 a){ return a.x + a.y * 37.0; }
    float Hash11(float a){ return fract(sin(a)*10403.9); }
    float Hash21(float2 uv){ float f = uv.x + uv.y * 37.0; return fract(sin(f)*104003.9); }
    float2 Hash22(float2 uv){ float f = uv.x + uv.y * 37.0; return fract(cos(f)*float2(10003.579, 37049.7)); }
    float2 Hash12(float f){ return fract(cos(f)*float2(10003.579, 37049.7)); }
    float Hash1d(float u){ return fract(sin(u)*143.9); }
    float Hash2d(float2 uv){ float f = uv.x + uv.y * 37.0; return fract(sin(f)*104003.9); }
    float Hash3d(float3 uv){ float f = uv.x + uv.y * 37.0 + uv.z * 521.0; return fract(sin(f)*110003.9); }
    float mixP(float f0, float f1, float a){ return mix(f0, f1, a*a*(3.0-2.0*a)); }
    const float2 zeroOne = float2(0.0, 1.0);
    float noise2d(float2 uv){ float2 fr = fract(uv.xy); float2 fl = floor(uv.xy); float h00 = Hash2d(fl); float h10 = Hash2d(fl + zeroOne.yx); float h01 = Hash2d(fl + zeroOne); float h11 = Hash2d(fl + zeroOne.yy); return mixP(mixP(h00, h10, fr.x), mixP(h01, h11, fr.x), fr.y); }
    float noise(float3 uv){ float3 fr = fract(uv.xyz); float3 fl = floor(uv.xyz); float h000 = Hash3d(fl); float h100 = Hash3d(fl + zeroOne.yxx); float h010 = Hash3d(fl + zeroOne.xyx); float h110 = Hash3d(fl + zeroOne.yyx); float h001 = Hash3d(fl + zeroOne.xxy); float h101 = Hash3d(fl + zeroOne.yxy); float h011 = Hash3d(fl + zeroOne.xyy); float h111 = Hash3d(fl + zeroOne.yyy); return mixP( mixP(mixP(h000, h100, fr.x), mixP(h010, h110, fr.x), fr.y), mixP(mixP(h001, h101, fr.x), mixP(h011, h111, fr.x), fr.y), fr.z); }

    float3 saturate(float3 a) { return clamp(a, 0.0, 1.0); }
    float2 saturate(float2 a) { return clamp(a, 0.0, 1.0); }
    float saturate(float a) { return clamp(a, 0.0, 1.0); }

    float3 GetSunColorSmall(float3 rayDir, float3 sunDir){ float3 localRay = normalize(rayDir); float dist = 1.0 - (dot(localRay, sunDir) * 0.5 + 0.5); float sunIntensity = 0.05 / dist; sunIntensity += exp(-dist*150.0)*7000.0; sunIntensity = min(sunIntensity, 40000.0); return sunCol * sunIntensity*0.025; }

    float3 GetEnvMap(float3 rayDir, float3 sunDir){ float3 finalColor = mix(horizonCol, skyCol, pow(saturate(rayDir.y), 0.47))*0.95; float n = noise2d(rayDir.xz/max(0.0001,rayDir.y)*1.0); n += noise2d(rayDir.xz/max(0.0001,rayDir.y)*2.0)*0.5; n += noise2d(rayDir.xz/max(0.0001,rayDir.y)*4.0)*0.25; n += noise2d(rayDir.xz/max(0.0001,rayDir.y)*8.0)*0.125; n = pow(abs(n), 3.0); n = mix(n * 0.2, n, saturate(abs(rayDir.y * 8.0))); finalColor = mix(finalColor, (float3(1.0)+sunCol*10.0)*0.75*saturate((rayDir.y+0.2)*5.0), saturate(n*0.125)); finalColor += GetSunColorSmall(rayDir, sunDir); return finalColor; }

    float3 GetEnvMapSkyline(float3 rayDir, float3 sunDir, float height){ float3 finalColor = GetEnvMap(rayDir, sunDir); float radial = __nv_atan(rayDir.z, rayDir.x)*4.0; float skyline = floor((sin(5.3456*radial) + sin(1.234*radial)+ sin(2.177*radial))*0.6); radial *= 4.0; skyline += floor((sin(5.0*radial) + sin(1.234*radial)+ sin(2.177*radial))*0.6)*0.1; float mask = saturate((rayDir.y*8.0 - skyline-2.5+height)*24.0); float vert = sign(sin(radial*32.0))*0.5+0.5; float hor = sign(sin(rayDir.y*256.0))*0.5+0.5; mask = saturate(mask + (1.0-hor*vert)*0.05); finalColor = mix(finalColor * float3(0.1,0.07,0.05), finalColor, mask); return finalColor; }

    float2 matmin(float2 a, float2 b){ if (a.x < b.x) return a; else return b; }

    float sdBox(float3 p, float3 radius){ float3 dist = abs(p) - radius; return min(max(dist.x, max(dist.y, dist.z)), 0.0) + length(max(dist, 0.0)); }
    float cylCap(float3 p, float r, float lenRad){ float a = length(p.xy) - r; a = max(a, abs(p.z) - lenRad); return a; }
    float smin(float a, float b, float k){ return log2(exp2(k*a)+exp2(k*b))/k; }
    float Repeat(float a, float len){ return __nv_mod(a, len) - 0.5 * len; }

    float2 Car(float3 baseCenter, float unique){ float car = sdBox(baseCenter + float3(0.0, -0.008, 0.001), float3(0.01, 0.00225, 0.0275)); car = smin(car, sdBox(baseCenter + float3(0.0, -0.016, 0.008), float3(0.005, 0.0005, 0.01)), -160.0); float3 wMirror = baseCenter + float3(0.0, -0.005, 0.0); wMirror.z = abs(wMirror.z)-0.02; float wheels = cylCap((wMirror).zyx, 0.004, 0.0135); float2 distAndMat = float2(wheels, 3.0); distAndMat = matmin(distAndMat, float2(car, 100000.0 + unique)); return distAndMat; }

    float voxelPad = 0.2;
    float2 CityBlock(float3 p, float2 pint){ float4 rand; rand.xy = Hash22(pint); rand.zw = Hash22(rand.xy); float2 rand2 = Hash22(rand.zw); float baseRad = 0.2 + (rand.x) * 0.1; baseRad = floor(baseRad * 20.0+0.5)/20.0; float3 baseCenter = p - float3(0.5, 0.0, 0.5); float height = rand.w*rand.z + 0.1; float downtown = saturate(4.0 / length(pint.xy)); height *= downtown; height *= 1.5+(baseRad-0.15)*20.0; height += 0.1; height = floor(height*20.0)*0.05; float d = sdBox(baseCenter, float3(baseRad, height, baseRad)); d = min(d, p.y); float height2 = max(0.0, rand.y * 2.0 - 1.0) * downtown; height2 = floor(height2*20.0)*0.05; rand2 = floor(rand2*20.0)*0.05; d = min(d, sdBox(baseCenter - float3(0.0, height, 0.0), float3(baseRad, height2 - rand2.y, baseRad*0.4))); d = min(d, sdBox(baseCenter - float3(0.0, height, 0.0), float3(baseRad*0.4, height2 - rand2.x, baseRad))); if (rand2.y > 0.25){ d = min(d, sdBox(baseCenter - float3(0.0, height, 0.0), float3(baseRad*0.8, height2, baseRad*0.8))); float topWidth = baseRad; if (height2 > 0.0) topWidth = baseRad * 0.8; d = max(d, -sdBox(baseCenter - float3(0.0, height+height2, 0.0), float3(topWidth-0.0125, 0.015, topWidth-0.0125))); }
    else { if (height2 > 0.0) d = min(d, cylCap((baseCenter - float3(0.0, height, 0.0)).xzy, baseRad*0.8, height2)); }
    d = min(d, sdBox(baseCenter - float3((rand.x-0.5)*baseRad, height+height2, (rand.y-0.5)*baseRad), float3(baseRad*0.3*rand.z, 0.1*rand2.y, baseRad*0.3*rand2.x+0.025)));
    float3 boxPos = baseCenter - float3((rand2.x-0.5)*baseRad, height+height2, (rand2.y-0.5)*baseRad); float big = sign(boxPos.x); boxPos.x = abs(boxPos.x)-0.02 - baseRad*0.3*rand.w; d = min(d, sdBox(boxPos, float3(baseRad*0.3*rand.w, 0.07*rand.y, baseRad*0.2*rand.x + big*0.025)));
    if (rand.y < 0.04){ d = min(d, length(baseCenter - float3(0.0, height, 0.0)) - baseRad*0.8); }
    float2 distAndMat = float2(d, 0.0); distAndMat = matmin(distAndMat, float2(sdBox(baseCenter, float3(0.35, 0.005, 0.35)), 1.0)); return distAndMat; }

    float2 DistanceToObject(float3 p){ float3 rep = p; rep.xz = fract(p.xz); float2 distAndMat = CityBlock(rep, floor(p.xz)); float3 p2 = p; rep.xyz = p2; float carTime = localTime*0.2; float crossStreet = 1.0; float repeatDist = 0.25; if (abs(fract(rep.x)-0.5) < 0.35){ p2.x += 0.05; p2.xz = p2.zx * float2(-1.0,1.0); rep.xz = p2.xz; crossStreet = 0.0; repeatDist = 0.1; }
      rep.z += floor(p2.x); rep.x = Repeat(p2.x - 0.5, 1.0); rep.z = rep.z*sign(rep.x); rep.x = (rep.x*sign(rep.x))-0.09; rep.z -= carTime * crossStreet; float uniqueID = floor(rep.z/repeatDist); rep.z = Repeat(rep.z, repeatDist); rep.x += (Hash11(uniqueID)*0.075-0.01); float frontBack = Hash11(uniqueID*0.987)*0.18-0.09; frontBack *= sin(localTime*2.0 + uniqueID); rep.z += frontBack * crossStreet; float2 carDist = Car(rep, uniqueID); distAndMat = matmin(distAndMat, carDist); return distAndMat; }

    void CalcWindows(float2 block, float3 pos, inout float3 texColor, inout float windowRef, inout float3 normal){ float3 hue = float3(Hash21(block)*0.8, Hash21(block*7.89)*0.4, Hash21(block*37.89)*0.5); texColor += hue*0.4; texColor *= 0.75; float window = 0.0; window = max(window, mix(0.2, 1.0, floor(fract(pos.y*20.0-0.35)*2.0+0.1))); if (pos.y < 0.05) window = 1.0; float winWidth = Hash21(block*4.321)*2.0; if ((winWidth < 1.3) && (winWidth >= 1.0)) winWidth = 1.3; window = max(window, mix(0.2, 1.0, floor(fract(pos.x * 40.0+0.05)*winWidth))); window = max(window, mix(0.2, 1.0, floor(fract(pos.z * 40.0+0.05)*winWidth))); if (window < 0.5){ windowRef += 1.0; } window *= Hash21(block*1.123); texColor *= window; float wave = floor(sin((pos.y*40.0-0.1)*PI)*0.505-0.5)+1.0; normal.y -= max(-1.0, min(1.0, -wave*0.5)); float pits = min(1.0, abs(sin((pos.z*80.0)*PI))*4.0)-1.0; normal.z += pits*0.25; pits = min(1.0, abs(sin((pos.x*80.0)*PI))*4.0)-1.0; normal.x += pits*0.25; }

    // Rotation helpers
    float3x3 rotX(float a){ float c=cos(a), s=sin(a); return float3x3(1,0,0, 0,c,-s, 0,s,c); }
    float3x3 rotY(float a){ float c=cos(a), s=sin(a); return float3x3(c,0,s, 0,1,0, -s,0,c); }
    float3x3 rotZ(float a){ float c=cos(a), s=sin(a); return float3x3(c,-s,0, s,c,0, 0,0,1); }

    // Sample input content directly in [0,1] UV space (no screen mapping)
    float4 sampleLayer(float2 uv){ return inputImg.sample(__nv_smp, uv); }

    float3 RayTrace(in float2 fragCoord){
      marchCount = 0.0;
      sunCol = float3(258.0, 248.0, 200.0) / 3555.0;
      sunDir = normalize(float3(0.93, 1.0, 1.0));
      horizonCol = float3(1.0, 0.95, 0.85)*0.9;
      skyCol = float3(0.3,0.5,0.95);
      exposure = 1.0;
      fade = 1.0;

      float3 camPos, camUp, camLookat;
      float2 iResolution = getResolution();
      float2 uv = fragCoord.xy/iResolution.xy * 2.0 - 1.0;
      uv /= 2.0;

      // Param-driven camera (no automatic progression)
      camPos = float3(u.camX, u.camY, u.camZ);
      float yaw = radians(u.yawDeg + (u.autoRotate ? eng.acTime * u.rotateSpeed : 0.0));
      float pitch = radians(u.pitchDeg);
      float3 forward = float3(cos(pitch)*cos(yaw), sin(pitch), cos(pitch)*sin(yaw));
      camLookat = camPos + forward;
      camUp = float3(0.0, 1.0, 0.0);

      float3 camVec=normalize(camLookat - camPos);
      float3 sideNorm=normalize(cross(camUp, camVec));
      float3 upNorm=cross(camVec, sideNorm);
      float3 worldFacing=(camPos + camVec);
      float3 worldPix = worldFacing + uv.x * sideNorm * (iResolution.x/iResolution.y) + uv.y * upNorm;
      float3 rayVec = normalize(worldPix - camPos);

      float2 distAndMat; float t = 0.05; const float maxDepth = 45.0; float3 pos = float3(0.0); const float smallVal = 0.000625;
      for (int i = 0; i < 250; i++){
        marchCount+=1.0; pos = (camPos + rayVec * t); distAndMat = DistanceToObject(pos);
        float walk = distAndMat.x; float dx = -fract(pos.x); if (rayVec.x > 0.0) dx = fract(-pos.x); float dz = -fract(pos.z); if (rayVec.z > 0.0) dz = fract(-pos.z); float nearestVoxel = min(fract(dx/rayVec.x), fract(dz/rayVec.z))+voxelPad; nearestVoxel = max(voxelPad, nearestVoxel); walk = min(walk, nearestVoxel); t += walk; if ((t > maxDepth) || (abs(distAndMat.x) < smallVal)) break; }

      float alpha = -camPos.y / rayVec.y; if ((t > maxDepth) && (rayVec.y < -0.0)) { pos.xz = camPos.xz + rayVec.xz * alpha; pos.y = -0.0; t = alpha; distAndMat.y = 0.0; distAndMat.x = 0.0; }
      float3 finalColor = float3(0.0);

      if ((t <= maxDepth) || (t == alpha)){
        float dist = distAndMat.x; float3 smallVec = float3(smallVal, 0, 0); float3 normalU = float3(dist - DistanceToObject(pos - smallVec.xyy).x, dist - DistanceToObject(pos - smallVec.yxy).x, dist - DistanceToObject(pos - smallVec.yyx).x); float3 normal = normalize(normalU);
        float ambientS = 1.0; ambientS *= saturate(DistanceToObject(pos + normal * 0.0125).x*80.0); ambientS *= saturate(DistanceToObject(pos + normal * 0.025).x*40.0); ambientS *= saturate(DistanceToObject(pos + normal * 0.05).x*20.0); ambientS *= saturate(DistanceToObject(pos + normal * 0.1).x*10.0); ambientS *= saturate(DistanceToObject(pos + normal * 0.2).x*5.0); ambientS *= saturate(DistanceToObject(pos + normal * 0.4).x*2.5); float ambient = max(0.025, pow(ambientS, 0.5)); ambient = saturate(ambient);
        float3 ref = reflect(rayVec, normal);
        float sunShadow = 1.0; float iter = 0.01; float3 nudgePos = pos + normal*0.002; for (int i = 0; i < 40; i++){ float3 shadowPos = nudgePos + sunDir * iter; float tempDist = DistanceToObject(shadowPos).x; sunShadow *= saturate(tempDist*150.0); if (tempDist <= 0.0) break; float walk = tempDist; float dx = -fract(shadowPos.x); if (sunDir.x > 0.0) dx = fract(-shadowPos.x); float dz = -fract(shadowPos.z); if (sunDir.z > 0.0) dz = fract(-shadowPos.z); float nearestVoxel = min(fract(dx/sunDir.x), fract(dz/sunDir.z))+smallVal; nearestVoxel = max(0.2, nearestVoxel); walk = min(walk, nearestVoxel); iter += max(0.01, walk); if (iter > 4.5) break; }
        sunShadow = saturate(sunShadow);

        float n =0.0; n += noise(pos*32.0); n += noise(pos*64.0); n += noise(pos*128.0); n += noise(pos*256.0); n += noise(pos*512.0); n = mix(0.7, 0.95, n);

        float2 block = floor(pos.xz); float3 texColor = float3(0.95, 1.0, 1.0); texColor *= 0.8; float windowRef = 0.0;
        if ((normal.y < 0.1) && (distAndMat.y == 0.0)){
          float3 colTemp = texColor; float3 nTemp = float3(0.0);
          CalcWindows(block, pos, colTemp, windowRef, nTemp);
          texColor = colTemp; windowRef *= 0.2; normal = normalize(normal + nTemp * 0.2);
        } else {
          float xroad = abs(fract(pos.x+0.5)-0.5); float zroad = abs(fract(pos.z+0.5)-0.5); float road = saturate((min(xroad, zroad)-0.143)*480.0); texColor *= 1.0-normal.y*0.95*Hash21(block*9.87)*road; texColor *= mix(0.1, 1.0, road);
          float yellowLine = saturate(1.0-(min(xroad, zroad)-0.002)*480.0); yellowLine *= saturate((min(xroad, zroad)-0.0005)*480.0); yellowLine *= saturate((xroad*xroad+zroad*zroad-0.05)*880.0); texColor = mix(texColor, float3(1.0, 0.8, 0.3), yellowLine);
          float whiteLine = saturate(1.0-(min(xroad, zroad)-0.06)*480.0); whiteLine *= saturate((min(xroad, zroad)-0.056)*480.0); whiteLine *= saturate((xroad*xroad+zroad*zroad-0.05)*880.0); whiteLine *= saturate(1.0-(fract(zroad*8.0)-0.5)*280.0); whiteLine *= saturate(1.0-(fract(xroad*8.0)-0.5)*280.0); texColor = mix(texColor, float3(0.5), whiteLine);
          whiteLine = saturate(1.0-(min(xroad, zroad)-0.11)*480.0); whiteLine *= saturate((min(xroad, zroad)-0.106)*480.0); whiteLine *= saturate((xroad*xroad+zroad*zroad-0.06)*880.0); texColor = mix(texColor, float3(0.5), whiteLine);
          float crossWalk = saturate(1.0-(fract(xroad*40.0)-0.5)*280.0); crossWalk *= saturate((zroad-0.15)*880.0); crossWalk *= saturate((-zroad+0.21)*880.0)*(1.0-road); crossWalk *= n*n; texColor = mix(texColor, float3(0.25), crossWalk);
          crossWalk = saturate(1.0-(fract(zroad*40.0)-0.5)*280.0); crossWalk *= saturate((xroad-0.15)*880.0); crossWalk *= saturate((-xroad+0.21)*880.0)*(1.0-road); crossWalk *= n*n; texColor = mix(texColor, float3(0.25), crossWalk);
          float sidewalk = 1.0; float2 blockSize = float2(100.0); if (pos.y > 0.1) blockSize = float2(10.0, 50.0); sidewalk *= saturate(abs(sin(pos.z*blockSize.x)*800.0/blockSize.x)); sidewalk *= saturate(abs(sin(pos.x*blockSize.y)*800.0/blockSize.y)); sidewalk = saturate(mix(0.7, 1.0, sidewalk)); sidewalk = saturate((1.0-road) + sidewalk); texColor *= sidewalk;
        }
        if (distAndMat.y == 3.0){ texColor = float3(0.05); }
        texColor *= float3(1.0)*n*0.05; texColor *= 0.7; texColor = saturate(texColor);
        float windowMask = 0.0; if (distAndMat.y >= 100.0){ texColor = float3(Hash11(distAndMat.y)*1.0, Hash11(distAndMat.y*8.765), Hash11(distAndMat.y*17.731))*0.1; texColor = pow(abs(texColor), float3(0.2)); texColor = max(float3(0.25), texColor); texColor.z = min(texColor.y, texColor.z); texColor *= Hash11(distAndMat.y*0.789) * 0.15; windowMask = saturate( max(0.0, abs(pos.y - 0.0175)*3800.0)-10.0); float2 dirNorm = abs(normalize(normal.xz)); float pillars = saturate(1.0-max(dirNorm.x, dirNorm.y)); pillars = pow(max(0.0, pillars-0.15), 0.125); windowMask = max(windowMask, pillars); texColor *= windowMask; }

        float3 lightColor = float3(100.0)*sunCol * saturate(dot(sunDir, normal)) * sunShadow; float ambientAvg = (ambient*3.0 + ambientS) * 0.25; lightColor += (skyCol * saturate(normal.y *0.5+0.5))*pow(ambientAvg, 0.35)*2.5; lightColor *= 4.0;
        finalColor = texColor * lightColor;
        if (distAndMat.y >= 100.0){ float yfade = max(0.01, min(1.0, ref.y*100.0)); float2 envUV = dirToEquirect(ref); finalColor += GetEnvMapSkyline(ref, sunDir, pos.y-1.5)*0.3*yfade*max(0.4,sunShadow); finalColor += saturate(envTex.sample(__nv_smp, envUV).xyz-0.35)*0.15*max(0.2,sunShadow); }
        if (windowRef != 0.0){ finalColor *= mix(1.0, 0.6, windowRef); float yfade = max(0.01, min(1.0, ref.y*100.0)); float2 envUV = dirToEquirect(ref); finalColor += GetEnvMapSkyline(ref, sunDir, pos.y-0.5)*0.6*yfade*max(0.6,sunShadow)*windowRef; finalColor += saturate(envTex.sample(__nv_smp, envUV).xyz-0.35)*0.15*max(0.25,sunShadow)*windowRef; }
        finalColor *= 0.9; float3 rv2 = rayVec; rv2.y *= saturate(sign(rv2.y)); float3 fogColor = GetEnvMap(rv2, sunDir); fogColor = min(float3(9.0), fogColor); finalColor = mix(fogColor, finalColor, exp(-t*0.02));
      } else {
        finalColor = GetEnvMap(rayVec, sunDir);
      }

      // ------------------------------------------------------------
      // Place input layer as a textured quad in the scene
      // u.placeLayer is an int uniform; use non-zero check for GLSL ES 1.00
      if (u.placeLayer != 0){
        // Build object transform
        float yaw = deg2rad(u.objYaw);
        float pitch = deg2rad(u.objPitch);
        float roll = deg2rad(u.objRoll);
        float3x3 R = rotY(yaw) * rotX(pitch) * rotZ(roll);
        float3 objPos = float3(u.objPosX, u.objPosY, u.objPosZ);
        float3 n = normalize(R * float3(0.0, 1.0, 0.0)); // plane normal
        float3 u = normalize(R * float3(1.0, 0.0, 0.0)); // local X
        float3 v = normalize(R * float3(0.0, 0.0, 1.0)); // local Z

        float denom = dot(n, rayVec);
        if (abs(denom) > 1e-4){
          float tPlane = dot(n, (objPos - camPos)) / denom;
          if (tPlane > 0.0 && tPlane < maxDepth){
            // Is the plane hit closer than city geometry?
            float nearestT = t; if (nearestT > maxDepth) nearestT = maxDepth;
            if (tPlane < nearestT){
              float3 hit = camPos + rayVec * tPlane;
              float3 rel = hit - objPos;
              // Project into local axes
              float x = dot(rel, u);
              float z = dot(rel, v);
              float hw = 0.5 * u.objWidth * u.objScale;
              float hh = 0.5 * u.objHeight * u.objScale;
              if (abs(x) <= hw && abs(z) <= hh){
                float2 tuv = float2((x/hw)*0.5 + 0.5, (z/hh)*0.5 + 0.5);
                float4 lay = sampleLayer(tuv);
                float a = lay.a * u.objOpacity;
                // Simple lambert with sun to sit in scene
                float lam = saturate(dot(n, sunDir))*0.25 + 0.75;
                float3 layCol = lay.rgb * lam;
                // Composite over current finalColor
                finalColor = mix(finalColor, layCol, a);
              }
            }
          }
        }
      }

      finalColor *= float3(1.0) * saturate(1.0 - length((fragCoord.xy/getResolution())/2.5)); finalColor *= 1.3*exposure; return float3(clamp(finalColor, 0.0, 1.0)*saturate(fade+0.2));
    }

fragment float4 fx_toji_3city_sdf(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_3city_sdfParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> envTex [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& envTex_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 res = getResolution();
      float2 fragCoord = in.acScreenNorm * res;
      // Use user-controlled u.time so scene doesnt auto-progress
      localTime = u.time;
      float3 finalColor = RayTrace(fragCoord);
      __nv_out = float4(sqrt(clamp(finalColor, 0.0, 1.0)), 1.0);
    return __nv_out;
}
