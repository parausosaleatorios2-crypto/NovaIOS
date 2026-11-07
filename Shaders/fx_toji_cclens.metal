// ---------------------------------------------------------------------------
// CC Lens
// origem : assets/effects/toji-cclens.xml
// id     : com.example.learning.cclens
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_cclensParams {
    float size;
    float convergence;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265359;

fragment float4 fx_toji_cclens(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_cclensParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      // 1. NORMALIZE COORDINATES
      // in.acScreenNorm is 0.0 to 1.0 (bottom-left to top-right).
      // We want (0,0) to be in the CENTER for easier circle math.
      // So we subtract 0.5. Range becomes -0.5 to 0.5.
      float2 uv = in.acScreenNorm - 0.5;

      // 2. ASPECT RATIO CORRECTION
      // Screens are usually rectangles, not squares.
      // If we draw a circle on a rectangle using raw 0-1 coords, it looks like an oval.
      // We fix this by multiplying the X coordinate by the aspect ratio.
      float aspect = eng.acScreenSize.x / eng.acScreenSize.y;
      uv.x *= aspect;

      // 3. CALCULATE DISTANCE & ANGLE
      // We convert Cartesian (x,y) to Polar (radius, angle) coordinates.
      float dist = length(uv);  // How far from center?
      float angle = __nv_atan(uv.y, uv.x); // What direction?

      // 4. CALCULATE SPHERICAL DISTORTION
      // This is the core "Lens" math.
      // We normalize the distance based on the 'u.size' parameter.
      // u.size is a percentage, so we divide by 100.0.
      float radius = u.size / 100.0;
      
      // If the pixel is outside the lens radius, we don't distort it (or we mask it).
      // For a true "Orb" effect, anything outside is transparent.
      if (dist > radius) {
          // You can choose to:
          // a) Discard (transparent)
          // b) Show original (return inputImg.sample(__nv_smp, in.acScreenNorm))
          // Let's make it transparent for a clean Orb look.
          __nv_out = float4(0.0);
          return __nv_out; 
      }

      // Map the 0->radius distance to 0->1 range for easier math
      float normalizedDist = dist / radius;

      // Apply the distortion curve.
      // A simple way to get a sphere look is using separate formulas for X and Y or 
      // just using a power function on the distance.
      // Here we simulate the surface of a sphere using cosine interpolation.
      // As 'u.convergence' changes, we modify the curve.
      
      float z = sqrt(1.0 - normalizedDist * normalizedDist); // Height of the sphere at this point
      float r = __nv_atan(normalizedDist, z * u.convergence) / PI; // New distance from center
      
      // Scale it back up
      r *= 2.0; // Adjustment factor

      // 5. CONVERT BACK TO UV
      // New UV position based on the new distance 'r' and original 'angle'.
      float2 newUV;
      newUV.x = r * cos(angle);
      newUV.y = r * sin(angle);

      // Undo Aspect Ratio Correction
      newUV.x /= aspect;

      // Shift back to 0.0->1.0 range
      newUV += 0.5;

      // 6. SAMPLE & OUTPUT
      // Read the texture at the distorted position.
      __nv_out = inputImg.sample(__nv_smp, newUV);
    return __nv_out;
}
