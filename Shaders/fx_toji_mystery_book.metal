// ---------------------------------------------------------------------------
// Mystery Book
// origem : assets/effects/toji-mystery_book.xml
// id     : com.creative.mystery_book
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_mystery_bookParams {
    float openProgress;
    float zoom;
    float camRot;
};

// --- funcoes auxiliares do efeito
precision float;

        // Shadertoy constants
        #define MAX_STEPS 100
        #define MAX_DIST 50.0
        #define SURF_DIST 0.001
        #define PI 3.14159265

        // Helpers
        static float hash21(float2 p) {
            float3 p3  = fract(float3(p.xyx) * .1031);
            p3 += dot(p3, p3.yzx + 33.33);
            return fract((p3.x + p3.y) * p3.z);
        }

        static float2x2 rot(float a) {
            float s = sin(a);
            float c = cos(a);
            return float2x2(c, -s, s, c);
        }

        static float sdBox(float3 p, float3 b) {
            float3 q = abs(p) - b;
            return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
        }

        static float sdRoundBox(float3 p, float3 b, float r) {
            float3 q = abs(p) - b;
            return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0) - r;
        }

        // Scene Logic
        static float2 map(float3 p) {
            float2 res = float2(100.0, 0.0);
            
            // 1. Wooden Table
            float dTable = p.y + 0.05;
            if (dTable < res.x) res = float2(dTable, 1.0);
            
            // Book Dimensions
            float3 dim = float3(1.2, 0.15, 1.6);
            float coverThick = 0.02;
            float3 pb = p - float3(0.0, 0.05, 0.0);
            
            // Spine
            float3 pSpine = pb;
            pSpine.y -= dim.y * 0.5;
            float dSpine = sdRoundBox(pSpine, float3(0.1, dim.y * 0.6, dim.z), 0.02);
            if (dSpine < res.x) res = float2(dSpine, 5.0);
            
            // Right Side
            float3 pR = pb;
            float3 localR = pR - float3(dim.x + 0.02, 0.0, 0.0);
            float dRCover = sdBox(localR - float3(0.0, -dim.y*0.5, 0.0), float3(dim.x, coverThick, dim.z));
            float dRPages = sdBox(localR - float3(0.0, coverThick, 0.0), float3(dim.x - 0.05, dim.y*0.5 - coverThick, dim.z - 0.05));
            if (dRCover < res.x) res = float2(dRCover, 2.0);
            if (dRPages < res.x) res = float2(dRPages, 4.0);
            
            // Left Side
            float rotAng = (1.0 - u.openProgress) * PI;
            float3 pL_rot = pb;
            pL_rot.xy *= rot(rotAng);
            float3 localL = pL_rot - float3(-dim.x - 0.02, 0.0, 0.0);
            float dLCover = sdBox(localL - float3(0.0, -dim.y*0.5, 0.0), float3(dim.x, coverThick, dim.z));
            float dLPages = sdBox(localL - float3(0.0, coverThick, 0.0), float3(dim.x - 0.05, dim.y*0.5 - coverThick, dim.z - 0.05));
            if (dLCover < res.x) res = float2(dLCover, 2.0);
            if (dLPages < res.x) res = float2(dLPages, 3.0);

            return res;
        }

        static float rayMarch(float3 ro, float3 rd, out float m) {
            float dO = 0.0;
            m = 0.0;
            for(int i=0; i<MAX_STEPS; i++) {
                float3 p = ro + rd * dO;
                float2 dS = map(p);
                dO += dS.x;
                m = dS.y;
                if(dO > MAX_DIST || abs(dS.x) < SURF_DIST) break;
            }
            return dO;
        }

        static float3 getNormal(float3 p) {
            float d = map(p).x;
            float2 e = float2(0.001, 0);
            float3 n = d - float3(
                map(p-e.xyy).x,
                map(p-e.yxy).x,
                map(p-e.yyx).x);
            return normalize(n);
        }

        static float3 getWood(float2 uv) {
            float n = sin(uv.x * 20.0 + sin(uv.y * 50.0) * 2.0);
            return float3(0.3, 0.15, 0.05) * (0.8 + 0.2 * n);
        }

fragment float4 fx_toji_mystery_book(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_mystery_bookParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> iChannel0 [[texture(0)]],
    constant NovaTexInfo& iChannel0_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 uv = in.acScreenNorm - 0.5;
            uv.x *= (eng.acLayerSize.x / eng.acLayerSize.y);

            // Camera
            float3 ro = float3(0.0, 3.5, -4.0) * u.zoom;
            ro.xz *= rot(u.camRot);
            
            float3 lookAt = float3(0.0, 0.0, 0.0);
            float3 f = normalize(lookAt - ro);
            float3 r = normalize(cross(float3(0,1,0), f));
            float3 u = cross(f, r);
            float3 rd = normalize(f + uv.x * r + uv.y * u);

            float m = 0.0;
            float d = rayMarch(ro, rd, m);
            
            float3 col = float3(0.01, 0.0, 0.02);
            
            if(d < MAX_DIST) {
                float3 p = ro + rd * d;
                float3 n = getNormal(p);
                float3 lightPos = float3(1.0, 3.0, -1.0);
                float3 l = normalize(lightPos - p);
                float dif = clamp(dot(n, l), 0.0, 1.0);
                float amb = 0.1;
                float3 albedo = float3(0.5);
                
                if (m == 1.0) { // Table
                     albedo = getWood(p.xz);
                     float spec = pow(max(dot(reflect(-l, n), -rd), 0.0), 16.0);
                     albedo += spec * 0.1;
                } 
                else if (m == 2.0 || m == 5.0) { // Cover & Spine
                     float grain = hash21(p.xz * 10.0);
                     albedo = float3(0.15, 0.02, 0.02) * (0.8 + 0.2 * grain);
                     float spec = pow(max(dot(reflect(-l, n), -rd), 0.0), 8.0);
                     albedo += spec * 0.2;
                }
                else if (m == 3.0 || m == 4.0) { // Pages
                     albedo = float3(0.9, 0.85, 0.75);
                     float3 dim = float3(1.2, 0.15, 1.6);
                     float2 pageUV = float2(0.0);
                     bool isTopFace = false;
                     
                     if (m == 4.0) { // Right
                         float3 local = p - float3(0.0, 0.05, 0.0) - float3(dim.x + 0.02, 0.0, 0.0);
                         if (n.y > 0.5) {
                             isTopFace = true;
                             pageUV.x = clamp((local.x + dim.x) / (2.0 * dim.x), 0.0, 1.0);
                             pageUV.y = clamp((local.z + dim.z) / (2.0 * dim.z), 0.0, 1.0);
                         }
                     } else { // Left
                         float3 pb = p - float3(0.0, 0.05, 0.0);
                         float rotAng = (1.0 - u.openProgress) * PI;
                         float3 pL_rot = pb;
                         pL_rot.xy *= rot(rotAng);
                         float3 local = pL_rot - float3(-dim.x - 0.02, 0.0, 0.0);
                         
                         if (n.y > -0.5) { 
                              isTopFace = true;
                              pageUV.x = clamp((local.x + dim.x) / (2.0 * dim.x), 0.0, 1.0);
                              pageUV.y = clamp((local.z + dim.z) / (2.0 * dim.z), 0.0, 1.0);
                              pageUV.x = 1.0 - pageUV.x; 
                         }
                     }
                     
                     if (isTopFace) {
                         float3 tex = iChannel0.sample(__nv_smp, pageUV).rgb;
                         tex *= 0.9 + 0.1 * hash21(p.xz * 50.0);
                         float vig = smoothstep(0.49, 0.45, abs(pageUV.x - 0.5)) * 
                                     smoothstep(0.49, 0.45, abs(pageUV.y - 0.5));
                         albedo = mix(albedo * 0.5, tex, vig);
                     } else {
                         float lines = sin(p.y * 200.0);
                         albedo *= 0.8 + 0.2 * lines;
                     }
                }
                
                float3 color = albedo * (amb + dif);
                
                // Shadows
                float sh = 1.0;
                float dS = 0.02;
                float shadowVal = 1.0;
                for(int i=0; i<20; i++) {
                    float h = map(p + l * dS).x;
                    if (h < 0.001) { shadowVal = 0.1; break; }
                    shadowVal = min(shadowVal, 10.0 * h / dS);
                    dS += h;
                    if (dS > 2.0) break;
                }
                color *= mix(0.2, 1.0, shadowVal);
                color = mix(color, float3(0.01, 0.0, 0.02), smoothstep(5.0, 15.0, d));
                col = color;
            }
            
            col = pow(col, float3(0.4545));
            col *= 1.0 - length(uv) * 0.5;

            __nv_out = float4(col, 1.0);
    return __nv_out;
}
