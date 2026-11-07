// ---------------------------------------------------------------------------
// gaussian splatting
// origem : assets/effects/toji-3d_point_cloud.xml
// id     : com.alightcreative.effects.3d_point_cloud
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_3d_point_cloudParams {
    float strength;
    float density;
    float partSize;
    float depthFreq;
    float intensity;
    float posX;
    float posY;
    float posZ;
    float rotX;
    float rotY;
    float rotZ;
};

// --- funcoes auxiliares do efeito
// Math Helpers
        const float PI = 3.14159265358;
        float deg2rad(float d){ return d * (PI / 180.0); }
        
        float3x3 getRotX(float a){ float c=cos(a), s=sin(a); return float3x3(1,0,0, 0,c,-s, 0,s,c); }
        float3x3 getRotY(float a){ float c=cos(a), s=sin(a); return float3x3(c,0,s, 0,1,0, -s,0,c); }
        float3x3 getRotZ(float a){ float c=cos(a), s=sin(a); return float3x3(c,-s,0, s,c,0, 0,0,1); }

fragment float4 fx_toji_3d_point_cloud(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_3d_point_cloudParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            // Normalize layer coordinates (so it moves with the object)
            float2 uv = in.acLayerNorm * 2.0 - 1.0;
            float aspectRatio = eng.acLayerSize.x / eng.acLayerSize.y;
            uv.x *= aspectRatio;
            
            float3 finalColor = float3(0.0);
            
            // 1. Camera Setup
            // Move the camera backward on the Z-axis
            float3 ro = float3(0.0, 0.0, -2.5 + u.posZ); 
            
            // 2. Prep Transformations
            float rotRX = deg2rad(u.rotX);
            float rotRY = deg2rad(u.rotY);
            float rotRZ = deg2rad(u.rotZ);
            float3x3 combinedRot = getRotY(rotRY) * getRotX(rotRX) * getRotZ(rotRZ);
            
            float3 objPos = float3(u.posX * aspectRatio, u.posY, 0.0);
            
            // 3. Loop through a grid of particles
            float steps = floor(u.density);
            for(float y = 0.0; y < 80.0; y++) {
                if(y >= steps) break;
                for(float x = 0.0; x < 80.0; x++) {
                    if(x >= steps) break;
                    
                    // Get the UV coordinate of this specific particle (Layer relative)
                    float2 puv = float2(x, y) / (steps - 1.0);
                    
                    // Sample the texture for color
                    float4 texColor = inputImg.sample(__nv_smp, puv);
                    if(texColor.a < 0.01) continue; // More aggressive transparency skip
                    
                    // Calculate brightness (luminance) to use as the Z-depth
                    float luminance = dot(texColor.rgb, float3(0.299, 0.587, 0.114));
                    
                    // 4. Construct the 3D Position (X, Y, Z)
                    float3 p3d = float3(
                        (puv.x - 0.5) * 2.0 * aspectRatio, 
                        (puv.y - 0.5) * 2.0, 
                        (luminance - 0.5) * u.depthFreq
                    );
                    
                    // 5. Apply Position and Rotation
                    p3d = combinedRot * p3d;
                    p3d += objPos;
                    
                    // 6. 3D to 2D Projection (Perspective)
                    float3 viewPos = p3d - ro;
                    
                    if(viewPos.z < 0.1) continue; 
                    
                    float2 projPos = viewPos.xy / viewPos.z;
                    
                    // 7. Draw the point
                    float dist = length(uv - projPos);
                    float size = u.partSize / viewPos.z; 
                    float weight = exp(-(dist * dist) / (size * size));
                    
                    finalColor += texColor.rgb * weight * u.intensity * texColor.a;
                }
            }
            
            // Tone mapping and Gamma correction
            finalColor = finalColor / (1.0 + finalColor);
            finalColor = pow(finalColor, float3(1.0/2.2));
            
            // Sample original for blending
            float4 original = inputImg.sample(__nv_smp, in.acLayerNorm);
            float3 result = mix(original.rgb, finalColor, u.strength);
            
            __nv_out = float4(result, mix(original.a, 1.0, u.strength));
    return __nv_out;
}
