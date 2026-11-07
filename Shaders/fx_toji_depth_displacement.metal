// ---------------------------------------------------------------------------
// Depth Displacement
// origem : assets/effects/toji-depth_displacement.xml
// id     : com.alightcreative.effects.depth_displacement
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_depth_displacementParams {
    float amp;
    int depthChannel;
    int invertDepth;
    float posX;
    float posY;
    float posZ;
    float rotX;
    float rotY;
    float rotZ;
    int edges;
};

// --- funcoes auxiliares do efeito
// Depth-based parallax displacement
    // Inputs: inputImg (depth map on the current layer), comp (underlying composition)

    const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

    static float getDepth(float2 uv){
      float4 d = inputImg.sample(__nv_smp, uv);
      float v;
      if(u.depthChannel==0){ v = dot(d.rgb, LUMA); }
      else if(u.depthChannel==1){ v = d.r; }
      else if(u.depthChannel==2){ v = d.g; }
      else if(u.depthChannel==3){ v = d.b; }
      else { v = dot(d.rgb, LUMA); }
      return u.invertDepth ? (1.0 - v) : v;
    }

    // Build a simple 3D-like view vector from position and Euler rotation
    // u.rotX=pitch, u.rotY=yaw, u.rotZ=roll (degrees)
    static float3 eulerToForward(float rx, float ry){
      float cx = cos(rx), sx = sin(rx);
      float cy = cos(ry), sy = sin(ry);
      // Start with forward along -Z, rotate by pitch (X) then yaw (Y)
      float3 f = float3(0.0, 0.0, -1.0);
      // pitch (X)
      f = float3(f.x, f.y*cx - f.z*sx, f.y*sx + f.z*cx);
      // yaw (Y)
      f = float3(f.x*cy + f.z*sy, f.y, -f.x*sy + f.z*cy);
      return normalize(f);
    }

fragment float4 fx_toji_depth_displacement(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_depth_displacementParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> comp [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& comp_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 uv = in.acScreenNorm;
      float4 depthSample = inputImg.sample(__nv_smp, uv);

      // Aspect-correct screen space for consistent displacement angles
      float2 aspect = float2(eng.acScreenSize.x/eng.acScreenSize.y, 1.0);

      // Convert degrees to radians
      float RX = u.rotX * 0.01745329252;
      float RY = u.rotY * 0.01745329252;
      float RZ = u.rotZ * 0.01745329252;

      // Forward/view direction from rotations
      float3 fwd = eulerToForward(RX, RY);
      // Roll rotates the screen-plane direction around Z
      float cr = cos(RZ), sr = sin(RZ);
      float2 rot2 = float2x2(cr, -sr, sr, cr) * normalize(float2(fwd.x, fwd.y) + 1e-6);

      // Compose 2D displacement direction from position controls and rotation-derived vector
      float2 dir = float2(u.posX, u.posY) + rot2 * u.posZ;
      // Aspect correction so a unit dir.x equals unit dir.y visually
      dir.x *= aspect.x;

      // Depth and displacement
      float depth = clamp(getDepth(uv), 0.0, 1.0);
      float strength = u.amp;
      float2 displacedUV = uv + dir * (1.0 - depth) * strength;

      // Edge handling
      float2 sampleUV = displacedUV;
      if(u.edges==0){
        // Repeat (clamped sampling handles repeat internally by mirroring logic below)
        sampleUV = displacedUV;
      } else if(u.edges==1){
        // Mirror
        sampleUV = float2(1.0,1.0) - abs(__nv_mod(displacedUV, float2(2.0)) - float2(1.0));
      } else if(u.edges==2){
        if(displacedUV.x < 0.0 || displacedUV.x > 1.0 || displacedUV.y < 0.0 || displacedUV.y > 1.0){
          __nv_out = float4(0.0);
          return __nv_out;
        }
      } else if(u.edges==3){
        // Tile
        sampleUV = fract(displacedUV);
      }

      float4 col = comp.sample(__nv_smp, sampleUV);
      // Multiply by depth layer alpha so masked areas remain transparent
      __nv_out = float4(col.rgb, col.a * depthSample.a);
    return __nv_out;
}
