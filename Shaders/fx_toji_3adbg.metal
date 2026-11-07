// ---------------------------------------------------------------------------
//  3D Background
// origem : assets/effects/toji-3adbg.xml
// id     : com.alightcreative.effects.shadertoy_bg3d
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_3adbgParams {
    float time;
    float camX;
    float camY;
    float camZ;
    float3 camRotate;
    float yawDeg;
    float pitchDeg;
    float fovDeg;
    int autoRotate;
    float rotateSpeed;
    float cam2X;
    float cam2Y;
    float cam2Z;
    float3 cam2Rotate;
    float yaw2Deg;
    float pitch2Deg;
    float fov2Deg;
    int autoRotate2;
    float rotateSpeed2;
    float3 skyRotate;
    int linkCamSky;
    int bgFeatherEnabled;
    float bgFeather;
    float bgFeatherPower;
    int roomEnabled;
    float roomWidth;
    float roomHeight;
    float roomDepth;
    float roomScale;
    int floorEnabled;
    float floorPosY;
    float floorYaw;
    float floorPitch;
    float floorRoll;
    float floorScaleX;
    float floorScaleY;
    float floorOpacity;
    int placeLayer;
    int planeSource;
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
    int objDepthTest;
};

// --- funcoes auxiliares do efeito
// Utility: get layer size, fallback to 1920x1080 when empty
    float2 getResolution() {
      float2 s = __nv_getTexSize(inputImg_info.size);
      if (s.x <= 0.0 || s.y <= 0.0) s = float2(1920.0, 1080.0);
      return s;
    }

    const float PI = 3.14159265358979323846;
    float radiansf(float d){ return d * (PI / 180.0); }

    // Rotation helpers
    float3x3 rotX(float a){ float c=cos(a), s=sin(a); return float3x3(1,0,0, 0,c,-s, 0,s,c); }
    float3x3 rotY(float a){ float c=cos(a), s=sin(a); return float3x3(c,0,s, 0,1,0, -s,0,c); }
    float3x3 rotZ(float a){ float c=cos(a), s=sin(a); return float3x3(c,-s,0, s,c,0, 0,0,1); }

    // Equirect mapping from direction
    float2 dirToEquirectUV(float3 d) {
      d = normalize(d);
      float u = __nv_atan(d.x, d.z) / (2.0*PI) + 0.5;
      float v = asin(clamp(d.y,-1.0,1.0)) / PI + 0.5;
      return float2(u,v);
    }

    // Ray-plane intersection for oriented rectangle plane
    struct Hit {
      float t;
      float2 uv;
      bool hit;
    };

    Hit intersectPlane(float3 ro, float3 rd, float3 center, float3x3 R, float2 halfSize) {
      float3 n = R * float3(0.0, 0.0, 1.0); // Plane faces +Z in local space
      float denom = dot(rd, n);
      Hit h; h.t = -1.0; h.uv = float2(0.0); h.hit = false;
      if (abs(denom) < 1e-6) return h;

      float t = dot(center - ro, n) / denom;
      if (t <= 0.0) return h;

      float3 p = ro + rd * t;
      // GLSL ES 1.00 has no transpose(float3x3). For orthonormal R, R^T * v equals dot with columns.
      float3 v = p - center;
      float3 lp = float3(dot(v, R[0]), dot(v, R[1]), dot(v, R[2])); // to local plane space
      // local plane spans X,Y with Z=0
      if (abs(lp.x) <= halfSize.x && abs(lp.y) <= halfSize.y) {
        float2 uv = (lp.xy / (halfSize*2.0)) + 0.5;
        h.t = t;
        h.uv = uv;
        h.hit = true;
      }
      return h;
    }

    // Ray-box intersection for axis-aligned room centered at origin
    struct BoxHit {
      float t;
      float3 p;
      int  face; // 0:+X, 1:-X, 2:+Y, 3:-Y, 4:+Z, 5:-Z
      bool hit;
    };

    bool within(float3 p, float3 c, float3 hw, int axis){
      if(axis==0 || axis==1) return abs(p.y - c.y) <= hw.y && abs(p.z - c.z) <= hw.z;
      if(axis==2 || axis==3) return abs(p.x - c.x) <= hw.x && abs(p.z - c.z) <= hw.z;
      return abs(p.x - c.x) <= hw.x && abs(p.y - c.y) <= hw.y;
    }

    BoxHit intersectRoom(float3 ro, float3 rd, float3 c, float3 hw){
      BoxHit h; h.t = 1e20; h.p = float3(0.0); h.face = -1; h.hit = false;
      // +X and -X planes
      if (abs(rd.x) > 1e-6) {
        float tpos = (c.x + hw.x - ro.x) / rd.x;
        if (tpos > 0.0) {
          float3 ppos = ro + rd*tpos;
          if (within(ppos,c,hw,0) && tpos < h.t) { h.t = tpos; h.p = ppos; h.face = 0; h.hit = true; }
        }
        float tneg = (c.x - hw.x - ro.x) / rd.x;
        if (tneg > 0.0) {
          float3 pneg = ro + rd*tneg;
          if (within(pneg,c,hw,1) && tneg < h.t) { h.t = tneg; h.p = pneg; h.face = 1; h.hit = true; }
        }
      }
      // +Y and -Y planes
      if (abs(rd.y) > 1e-6) {
        float tpos = (c.y + hw.y - ro.y) / rd.y;
        if (tpos > 0.0) {
          float3 ppos = ro + rd*tpos;
          if (within(ppos,c,hw,2) && tpos < h.t) { h.t = tpos; h.p = ppos; h.face = 2; h.hit = true; }
        }
        float tneg = (c.y - hw.y - ro.y) / rd.y;
        if (tneg > 0.0) {
          float3 pneg = ro + rd*tneg;
          if (within(pneg,c,hw,3) && tneg < h.t) { h.t = tneg; h.p = pneg; h.face = 3; h.hit = true; }
        }
      }
      // +Z and -Z planes
      if (abs(rd.z) > 1e-6) {
        float tpos = (c.z + hw.z - ro.z) / rd.z;
        if (tpos > 0.0) {
          float3 ppos = ro + rd*tpos;
          if (within(ppos,c,hw,4) && tpos < h.t) { h.t = tpos; h.p = ppos; h.face = 4; h.hit = true; }
        }
        float tneg = (c.z - hw.z - ro.z) / rd.z;
        if (tneg > 0.0) {
          float3 pneg = ro + rd*tneg;
          if (within(pneg,c,hw,5) && tneg < h.t) { h.t = tneg; h.p = pneg; h.face = 5; h.hit = true; }
        }
      }
      return h;
    }

    // Sample plane content: either current layer (mapped via eng.acLayerToScreen) or composition behind
    float4 samplePlane(float2 uv01){
      if (u.planeSource == 1) {
        // Sample composition behind this layer directly in [0,1] UV space
        return comp.sample(__nv_smp, uv01);
      }
      // Default: sample current layer with screen mapping
      float4 scr = float4(uv01, 0.0, 1.0) * eng.acLayerToScreen;
      return inputImg.sample(__nv_smp, scr.xy);
    }

fragment float4 fx_toji_3adbg(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_3adbgParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> comp [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& comp_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      // Shadertoy bindings
      float iTime = eng.acTime + u.time;

      // Screen ray setup with aspect correction (use screen coords, not layer coords)
      float2 iResolution = getResolution();
      float2 uv = in.acScreenNorm * 2.0 - 1.0;
      uv.x *= iResolution.x / iResolution.y;

      float3 camPos = float3(u.camX, u.camY, u.camZ) / 100.0;
      camPos += float3(u.cam2X, u.cam2Y, u.cam2Z) / 100.0;
      float3 camEuler1 = u.camRotate * 0.017453292519943295;
      float3 camEuler2 = u.cam2Rotate * 0.017453292519943295;
      float yawAll = radiansf(u.yawDeg) + radiansf(u.yaw2Deg) + camEuler1.y + camEuler2.y
                     + (u.autoRotate ? radiansf(u.rotateSpeed) * eng.acTime : 0.0)
                     + (u.autoRotate2 ? radiansf(u.rotateSpeed2) * eng.acTime : 0.0);
      float pitchAll = radiansf(u.pitchDeg) + radiansf(u.pitch2Deg) + camEuler1.x + camEuler2.x;
      float rollAll = camEuler1.z + camEuler2.z;
      float3 forward = float3(0.0, 0.0, 1.0);
      float3 right = float3(1.0, 0.0, 0.0);
      float3 up = float3(0.0, 1.0, 0.0);
      float tanHalfFov = tan(radiansf(u.fovDeg + u.fov2Deg) * 0.5);
      float3 rd = normalize(forward + (uv.x * tanHalfFov) * right + (uv.y * tanHalfFov) * up);
      float3x3 sceneRInv = rotY(-yawAll) * rotX(-pitchAll) * rotZ(-rollAll);
      float3 camPosScene = sceneRInv * camPos;
      float3 rdScene = sceneRInv * rd;

      float3 skyEuler = u.skyRotate * 0.017453292519943295;
      if (u.linkCamSky) skyEuler.xy += float2(pitchAll, yawAll);
      float3x3 skyR = rotZ(skyEuler.z) * rotX(skyEuler.x) * rotY(skyEuler.y);
      float3 skyDir = normalize(skyR * rdScene);
      float2 suv = dirToEquirectUV(skyDir);
      float4 sky = comp.sample(__nv_smp, suv);

      // Room intersection and texturing
      float4 outColor = sky;
      // Declare room hit for optional depth test with plane
      BoxHit rh; rh.t = 1e20; rh.p = float3(0.0); rh.face = -1; rh.hit = false;
      if (u.roomEnabled) {
        float3 roomCenter = float3(0.0);
        float3 hw = float3(u.roomWidth, u.roomHeight, u.roomDepth) * 0.5 * u.roomScale;
        rh = intersectRoom(camPosScene, rdScene, roomCenter, hw);
        if (rh.hit) {
          float2 texCoord;
          if (rh.face == 0) { // +X : use Z,Y
            texCoord = float2( (rh.p.z - roomCenter.z)/(hw.z*2.0)+0.5, (rh.p.y - roomCenter.y)/(hw.y*2.0)+0.5 );
          } else if (rh.face == 1) { // -X
            texCoord = float2( 1.0 - ((rh.p.z - roomCenter.z)/(hw.z*2.0)+0.5), (rh.p.y - roomCenter.y)/(hw.y*2.0)+0.5 );
          } else if (rh.face == 2) { // +Y : use X,Z
            texCoord = float2( (rh.p.x - roomCenter.x)/(hw.x*2.0)+0.5, (rh.p.z - roomCenter.z)/(hw.z*2.0)+0.5 );
          } else if (rh.face == 3) { // -Y
            texCoord = float2( 1.0 - ((rh.p.x - roomCenter.x)/(hw.x*2.0)+0.5), 1.0 - ((rh.p.z - roomCenter.z)/(hw.z*2.0)+0.5) );
          } else if (rh.face == 4) { // +Z : use X,Y
            texCoord = float2( 1.0 - ((rh.p.x - roomCenter.x)/(hw.x*2.0)+0.5), (rh.p.y - roomCenter.y)/(hw.y*2.0)+0.5 );
          } else { // -Z
            texCoord = float2( (rh.p.x - roomCenter.x)/(hw.x*2.0)+0.5, (rh.p.y - roomCenter.y)/(hw.y*2.0)+0.5 );
          }
          float4 wall = comp.sample(__nv_smp, texCoord);
          outColor = wall;
        }
      }

      // Floor plane: oriented rectangle that samples the composition
      if (u.floorEnabled) {
        float3 floorCenter = float3(0.0, u.floorPosY/100.0, 0.0);
        float sx = u.floorScaleX * 0.5; // half-extents in scene units
        float sy = u.floorScaleY * 0.5;
        float3x3 RF = rotZ(radiansf(u.floorRoll)) * rotX(radiansf(u.floorPitch)) * rotY(radiansf(u.floorYaw));
        Hit fh = intersectPlane(camPosScene, rdScene, floorCenter, RF, float2(sx, sy));
        if (fh.hit) {
          bool occluded = (u.roomEnabled && rh.hit && (fh.t > rh.t + 1e-4));
          if (!occluded) {
            float4 floorPix = comp.sample(__nv_smp, fh.uv);
            outColor = mix(outColor, floorPix, u.floorOpacity);
          }
        }
      }

      // Optional: place layer as 3D plane in scene
      
      
      if (u.placeLayer == 1) {
        float3 objCenter = float3(u.objPosX, u.objPosY, u.objPosZ) / 100.0;
        float sx = u.objWidth * u.objScale;
        float sy = u.objHeight * u.objScale;
        float objYawRad = radiansf(u.objYaw);
        float objPitchRad = radiansf(u.objPitch);
        float objRollRad = radiansf(u.objRoll);
        float3x3 R = rotZ(objRollRad) * rotX(objPitchRad) * rotY(objYawRad);
        Hit h = intersectPlane(camPosScene, rdScene, objCenter, R, float2(sx, sy));
        if (h.hit) {
          // Optional depth test against room: skip blending if plane is behind wall
          bool occluded = (u.objDepthTest && u.roomEnabled && rh.hit && (h.t > rh.t + 1e-4));
          if (!occluded) {
            float4 planePix = samplePlane(h.uv);
            float a = u.objOpacity * planePix.a;
            outColor = mix(outColor, float4(planePix.rgb, 1.0), a);
          }
        }
      }

      // Shadertoy port hook:
      // If your Shadertoy draws its own background or needs raymarching,
      // we can inject it here and then composite the layer plane above or below.
      // Example (to be replaced once you share the code):
      // float4 shadertoyColor = float4(0.0);
      // outColor = mix(outColor, shadertoyColor, 1.0);

      // Background feathering: smoothly blend edges to screen-sampled comp
      if (u.bgFeatherEnabled) {
        float2 uv01 = in.acScreenNorm; // 0..1 screen UV
        float edge = min(min(uv01.x, 1.0 - uv01.x), min(uv01.y, 1.0 - uv01.y));
        float mask = pow(smoothstep(0.0, u.bgFeather, edge), u.bgFeatherPower);
        float4 compPix = comp.sample(__nv_smp, uv01);
        outColor = mix(compPix, outColor, mask);
      }

      __nv_out = outColor;
    return __nv_out;
}
