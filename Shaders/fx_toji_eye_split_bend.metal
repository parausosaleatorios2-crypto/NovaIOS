// ---------------------------------------------------------------------------
// Split
// origem : assets/effects/toji-eye_split_bend.xml
// id     : com.alightcreative.effects.eye_split_bend
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_eye_split_bendParams {
    float2 pointA;
    float2 pointB;
    float split;
    float sharpness;
    float bendFactor;
    float tipSharpness;
    float lobePower;
    float upperScale;
    float lowerScale;
    int invertInside;
    float alpha;
};

// --- funcoes auxiliares do efeito
// Eye Split Bend
    // Port of the provided ShaderToy with AM coordinate + param mapping
    // - Uses Point A/B to define the u.split axis
    // - Split (px) sets the height manually (keyframe as needed)

    // Helper: perpendicular
    float2 perp(float2 v){ return float2(-v.y, v.x); }

fragment float4 fx_toji_eye_split_bend(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_eye_split_bendParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 uv = in.acScreenNorm;
      float4 src = inputImg.sample(__nv_smp, uv);

      // Points in pixels -> normalize to UV
      float2 Auv = u.pointA / eng.acScreenSize;
      float2 Buv = u.pointB / eng.acScreenSize;
      float2 Muv = (Auv + Buv) * 0.5;              // midpoint in UV
      float2 dir = normalize(Buv - Auv);           // axis unit in UV
      float2 nrm = perp(dir);                      // normal unit in UV
      float halfLen = max(length(Buv - Auv) * 0.5, 1e-6); // half-length in UV units

      // Local coordinates relative to the AB frame
      float2 p = uv - Muv;
      float x = dot(p, dir);                     // along AB
      float y = dot(p, nrm);                     // across AB
      float xN = x / halfLen;                    // normalize so A/B map to -1..+1 along 2*range

      // Split height in UV units (based on screen height to be pixel-consistent)
      // Manual control: keyframe 'u.split' as needed; no time-based animation here.
      float splitUV = (u.split / max(eng.acScreenSize.y, 1.0));
      // Superellipse-like longitudinal profile with sharper tips
      // base runs 0..1 across x, with tip shaping and global u.sharpness
      float xAbs = abs(xN);
      float base = pow(max(0.0, 1.0 - pow(xAbs, u.tipSharpness)), u.sharpness);
      base = pow(base, u.lobePower);

      // Asymmetric upper / lower lobe scales
      float topBoundary    = splitUV * u.upperScale * base;
      float bottomBoundary = splitUV * u.lowerScale * base;

      // Vertical bend profile along x
      float vertical_bend = u.bendFactor * (0.25 - (xN * xN));

      // Inside if within the piecewise top/bottom boundaries around the bent centerline
      float yRel = y - vertical_bend;
      bool inside = (yRel <= topBoundary) && (yRel >= -bottomBoundary);

      float4 transparent = float4(0.0,0.0,0.0,0.0);
      float4 outCol = (u.invertInside ? (inside ? src : transparent)
                                  : (inside ? transparent : src));

      float aSrc = src.a * u.alpha;
      __nv_out = outCol * aSrc;
    return __nv_out;
}
