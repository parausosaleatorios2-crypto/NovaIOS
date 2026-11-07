// ---------------------------------------------------------------------------
// Monitor Scene
// origem : assets/effects/toji-monitor_on_table.xml
// id     : com.creative.monitor_on_table
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_monitor_on_tableParams {
    float zoom;
    float rotation;
};

// --- funcoes auxiliares do efeito
precision float;

        #define MAX_STEPS 100
        #define MAX_DIST 50.0
        #define SURF_DIST 0.001

        // Material IDs
        #define MAT_NONE 0.0
        #define MAT_FLOOR 1.0
        #define MAT_TABLE 2.0
        #define MAT_PLASTIC 3.0
        #define MAT_SCREEN 4.0
        #define MAT_WALL 5.0

        // Rotation matrix
        static float2x2 Rot(float a) {
            float s = sin(a), c = cos(a);
            return float2x2(c, -s, s, c);
        }

        // SDF Box
        static float sdBox(float3 p, float3 b) {
            float3 q = abs(p) - b;
            return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
        }

        // Scene Map
        static float2 map(float3 p) {
            float2 res = float2(MAX_DIST, MAT_NONE);
            
            // 1. Room Geometry
            float dFloor = p.y;
            float dWall = 2.5 - p.z; 
            
            if(dFloor < res.x) res = float2(dFloor, MAT_FLOOR);
            if(dWall < res.x) res = float2(dWall, MAT_WALL);
            
            // 2. Table Geometry
            float tH = 0.8; 
            float tW = 1.4; 
            float tD = 0.7; 
            float tThick = 0.05;
            
            // Table Top
            float3 pTop = p - float3(0.0, tH, 0.0);
            float dTop = sdBox(pTop, float3(tW*0.5, tThick*0.5, tD*0.5));
            
            // Table Legs
            float3 pLegs = p;
            pLegs.x = abs(pLegs.x);
            pLegs.z = abs(pLegs.z);
            pLegs -= float3(tW*0.4, tH*0.5, tD*0.4);
            float dLegs = sdBox(pLegs, float3(0.04, tH*0.5, 0.04));
            
            float dTable = min(dTop, dLegs);
            if(dTable < res.x) res = float2(dTable, MAT_TABLE);
            
            // 3. Monitor Geometry
            float3 pm = p - float3(0.0, tH + tThick*0.5, 0.0);
            
            // Stand Base
            float dBase = sdBox(pm - float3(0.0, 0.01, 0.0), float3(0.15, 0.01, 0.12));
            // Stand Neck
            float dNeck = sdBox(pm - float3(0.0, 0.15, 0.05), float3(0.04, 0.15, 0.02));
            
            // Screen Bezel
            float3 ph = pm - float3(0.0, 0.45, 0.0);
            float dBezel = sdBox(ph, float3(0.6, 0.35, 0.04));
            
            float dMonitorFrame = min(dBase, min(dNeck, dBezel));
            if(dMonitorFrame < res.x) res = float2(dMonitorFrame, MAT_PLASTIC);
            
            // Screen Surface
            float dScreen = sdBox(ph - float3(0.0, 0.0, -0.041), float3(0.57, 0.32, 0.001));
            if(dScreen < res.x) res = float2(dScreen, MAT_SCREEN);
            
            return res;
        }

        // Raymarch
        static float2 rayMarch(float3 ro, float3 rd) {
            float dO = 0.0;
            float m = MAT_NONE;
            
            for(int i=0; i<MAX_STEPS; i++) {
                float3 p = ro + rd * dO;
                float2 dS = map(p);
                dO += dS.x;
                m = dS.y;
                if(dO > MAX_DIST || abs(dS.x) < SURF_DIST) break;
            }
            return float2(dO, m);
        }

        // Normals
        static float3 getNormal(float3 p) {
            float d = map(p).x;
            float2 e = float2(0.001, 0);
            float3 n = d - float3(
                map(p-e.xyy).x,
                map(p-e.yxy).x,
                map(p-e.yyx).x);
            return normalize(n);
        }

        // Soft Shadows
        static float getShadow(float3 p, float3 l, float k) {
            float res = 1.0;
            float t = 0.02;
            for(int i=0; i<20; i++) { // Reduced steps for mobile
                float h = map(p + l * t).x;
                if(h < 0.001) return 0.0;
                res = min(res, k*h/t);
                t += h;
                if(t > 10.0) break;
            }
            return res;
        }

fragment float4 fx_toji_monitor_on_table(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_monitor_on_tableParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> iChannel0 [[texture(0)]],
    constant NovaTexInfo& iChannel0_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 uv = in.acScreenNorm - 0.5;
            uv.x *= (eng.acLayerSize.x / eng.acLayerSize.y);

            // Camera Setup
            float d = 4.0 / u.zoom;
            float3 pivot = float3(0.0, 1.25, 0.0);
            float3 camPos = float3(0.0, 0.5, -d);
            
            // Apply u.rotation
            camPos.xz *= Rot(u.rotation);
            camPos += pivot;
            
            float3 lookAt = pivot;
            float3 f = normalize(lookAt - camPos);
            float3 r = normalize(cross(float3(0,1,0), f));
            float3 u = cross(f, r);
            float3 rd = normalize(f + uv.x * r + uv.y * u);

            // Render
            float2 tr = rayMarch(camPos, rd);
            float dist = tr.x;
            float m = tr.y;
            
            float3 col = float3(0.05, 0.05, 0.08); // Background/Fog color
            
            if(dist < MAX_DIST) {
                float3 p = camPos + rd * dist;
                float3 n = getNormal(p);
                float3 lightPos = float3(2.0, 4.0, -2.0);
                float3 l = normalize(lightPos - p);
                
                float shadow = getShadow(p, l, 8.0);
                float diff = max(0.0, dot(n, l));
                float amb = 0.05;
                
                float3 albedo = float3(0.5);
                
                if(m == MAT_FLOOR) {
                    albedo = float3(0.15);
                    if((fract(p.x) > 0.5) != (fract(p.z) > 0.5)) albedo *= 0.8;
                } else if(m == MAT_TABLE) {
                    albedo = float3(0.95);
                } else if(m == MAT_PLASTIC) {
                    albedo = float3(0.1);
                } else if(m == MAT_WALL) {
                    albedo = float3(0.8, 0.8, 0.85);
                } else if(m == MAT_SCREEN) {
                    float3 screenCenter = float3(0.0, 1.275, -0.041);
                    float3 local = p - screenCenter;
                    float2 sUV = local.xy / float2(0.57, 0.32) * 0.5 + 0.5;
                    sUV = clamp(sUV, 0.0, 1.0);
                    albedo = iChannel0.sample(__nv_smp, sUV).rgb;
                    col = albedo * 1.5; 
                }
                
                if(m != MAT_SCREEN) {
                    col = albedo * (diff * shadow + amb);
                    float3 h = normalize(l - rd);
                    float spec = pow(max(0.0, dot(n, h)), 32.0);
                    float specStr = (m == MAT_TABLE) ? 0.5 : 0.3;
                    col += float3(spec * specStr * shadow);
                }
                
                // Fog
                col = mix(col, float3(0.05, 0.05, 0.08), 1.0 - exp(-dist * 0.02));
            }
            
            col = pow(col, float3(0.4545));
            __nv_out = float4(col, 1.0);
    return __nv_out;
}
