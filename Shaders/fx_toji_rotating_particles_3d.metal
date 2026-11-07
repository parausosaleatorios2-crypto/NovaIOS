// ---------------------------------------------------------------------------
// 3D Particles
// origem : assets/effects/toji-rotating_particles_3d.xml
// id     : com.alightcreative.effects.rotating_particles_3d
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_rotating_particles_3dParams {
    float angle_x;
    float angle_y;
    float angle_z;
    float posX;
    float posY;
    float posZ;
    float spread;
    float count;
    float pSize;
    int shapeType;
    float4 colorNear;
    float4 colorFar;
    float depthMix;
    float hueFreq;
};

// --- funcoes auxiliares do efeito
// HSV to RGB helper
    static float3 hsv2rgb(float3 c) {
        float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
        float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
        return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
    }

    // RGB to HSV helper
    static float3 rgb2hsv(float3 c) {
        float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
        float4 p = mix(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
        float4 q = mix(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
        float d = q.x - min(q.w, q.y);
        float e = 1.0e-10;
        return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
    }

fragment float4 fx_toji_rotating_particles_3d(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_rotating_particles_3dParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputTexture [[texture(0)]],
    constant NovaTexInfo& inputTexture_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

        // Normalize coordinates (0 in center), matching Shadertoys logic
        float2 uv = (in.acLayerNorm * eng.acLayerSize - 0.5 * eng.acLayerSize) / eng.acLayerSize.y;
        
        float4 accumulated = float4(0.0);
        
        // 1. Setup Rotation Matrices
        float cx = cos(u.angle_x), sx = sin(u.angle_x);
        float cy = cos(u.angle_y), sy = sin(u.angle_y);
        float cz = cos(u.angle_z), sz = sin(u.angle_z);
        float3x3 rx = float3x3(1,0,0, 0,cx,-sx, 0,sx,cx);
        float3x3 ry = float3x3(cy,0,sy, 0,1,0, -sy,0,cy);
        float3x3 rz = float3x3(cz,-sz,0, sz,cz,0, 0,0,1);
        float3x3 rot = rz * ry * rx;
        
        // 2. Loop through particles
        for(float i=0.0; i<200.0; i++) {
            if (i >= u.count) break;
            
            // Generate pseudo-random 3D position
            float3 p = float3(
                fract(sin(i*123.45)*456.78),
                fract(sin(i*234.56)*567.89),
                fract(sin(i*345.67)*678.90)
            );
            p = (p - 0.5) * u.spread;
            
            // Add animation
            p += float3(
                sin(eng.acTime + p.y * 2.0) * 0.1,
                cos(eng.acTime * 0.8 + p.x * 1.5) * 0.1,
                sin(eng.acTime * 1.2 + p.z * 3.0) * 0.1
            );
            
            // 3. Apply 3D Rotation and Position Offset
            float3 pos = (rot * p) + float3(u.posX, u.posY, u.posZ);
            
            // 4. Perspective Projection
            float cameraDist = 3.5;
            float z = pos.z + cameraDist;
            
            if(z > 0.1) {
                float2 projPos = pos.xy / z;
                float2 rel = uv - projPos;
                
                // Particle Color
                float normZ = clamp((z - 0.1) / 5.0, 0.0, 1.0);
                float3 pCol = mix(u.colorNear.rgb, u.colorFar.rgb, normZ * u.depthMix);
                if (u.hueFreq > 0.0) {
                    float3 hsv = rgb2hsv(pCol);
                    hsv.x = fract(hsv.x + eng.acTime * u.hueFreq + i * 0.02);
                    pCol = hsv2rgb(hsv);
                }
                
                // Shape/Texture Logic
                float brightness = 0.0;
                float4 texCol = float4(1.0);
                
                if (u.shapeType == 0) { // Glow
                    brightness = (0.0015 * u.pSize) / (dot(rel, rel) + 0.00005);
                } else if (u.shapeType == 1) { // Circle
                    float s = 0.01 * u.pSize / z;
                    brightness = smoothstep(s, s * 0.8, length(rel)) * 5.0;
                } else if (u.shapeType == 2) { // Square
                    float s = 0.01 * u.pSize / z;
                    brightness = smoothstep(s, s * 0.8, max(abs(rel.x), abs(rel.y))) * 5.0;
                } else if (u.shapeType == 3) { // Star
                    float s = 0.015 * u.pSize / z;
                    float dStar = min(abs(rel.x), abs(rel.y)) + length(rel) * 0.6;
                    brightness = smoothstep(s, s * 0.5, dStar) * 10.0;
                } else if (u.shapeType == 4) { // Streak
                    brightness = (0.0015 * u.pSize) / (rel.x*rel.x * 20.0 + rel.y*rel.y + 0.00005);
                } else { // Custom Texture
                    float s = 0.05 * u.pSize / z;
                    float2 texUV = rel / (s * 2.0) + 0.5;
                    if (texUV.x >= 0.0 && texUV.x <= 1.0 && texUV.y >= 0.0 && texUV.y <= 1.0) {
                        texCol = inputTexture.sample(__nv_smp, texUV);
                        brightness = texCol.a * 1.5;
                    }
                }
                
                accumulated += float4(pCol * brightness * texCol.rgb, brightness) * (1.0 / (z*z));
            }
        }
        
        // Final color assembly
        float3 finalCol = pow(accumulated.rgb, float3(0.4545)); 
        __nv_out = float4(finalCol, clamp(accumulated.a, 0.0, 1.0));
    return __nv_out;
}
