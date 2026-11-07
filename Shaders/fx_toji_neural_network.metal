// ---------------------------------------------------------------------------
// Neural Network
// origem : assets/effects/toji-neural_network.xml
// id     : com.alightcreative.effects.neural_network
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_neural_networkParams {
    float2 center;
    float speed;
    float complexity;
    float4 lineColor;
    float intensity;
    float softness;
    int followLayer;
    float blend;
};

// --- funcoes auxiliares do efeito
static float dfLine(float2 start, float2 end, float2 uv) {
            float2 line = end - start;
            float frac = dot(uv - start, line) / dot(line, line);
            return distance(start + line * clamp(frac, 0.0, 1.0), uv);
        }

        static float hash(float2 p) {
            return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453123);
        }

        static float map(float2 uv, float2 mouse, float t, float time, float iterCount) {
            float col = 0.0;
            float2 end = float2(0.3, 0.3);
            float2 p = mouse;
            float2 p1 = end;
            
            float2 oldP = p;
            float2 oldP1 = p1;
            
            for(int i = 0; i < 500; i++) {
                if(float(i) >= iterCount) break;
                
                float fi = float(i);
                float p1Angle = __nv_atan(p.y - p1.y, p.x - p1.x);
                float pAngle = __nv_atan(p1.y - p.y, p1.x - p.x);
                
                p1Angle += (hash(p1 + fi + time * t) - 0.5) * 2.0;
                pAngle += (hash(p + fi + time * t) - 0.5) * 2.0;
                
                p += float2(cos(pAngle), sin(pAngle)) / max(hash(p * p1 * time * fi + t) * 100.0, 60.0);
                p1 += float2(cos(p1Angle), sin(p1Angle)) / max(hash(p * p1 * time * fi * 43.324 * t) * 100.0, 60.0);
                
                col += (1.0 - smoothstep(dfLine(p, oldP, uv), -u.softness * 0.5, u.softness)) * max(hash(p * fi * time + t * t) * 2.0, 0.3) / t;
                col += (1.0 - smoothstep(dfLine(p1, oldP1, uv), -u.softness * 0.5, u.softness)) * max(hash(p1 * fi * time / t) * 2.0, 0.3) / t;
                
                if (distance(p, p1) < 0.05) {
                    col += 1.0 - smoothstep(dfLine(p, p1, uv), -u.softness * 0.5, u.softness);
                    break;
                }
                oldP = p;
                oldP1 = p1;
            }
            return col;
        }

        static float4 tanh_approx(float4 x) {
            float4 e = exp(2.0 * x);
            return (e - 1.0) / (e + 1.0);
        }

fragment float4 fx_toji_neural_network(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_neural_networkParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 luv = in.acLayerNorm.xy;
            float2 suv = in.acScreenNorm.xy;
            
            float2 uv;
            float2 aspect;
            if(u.followLayer) {
                uv = luv;
                aspect = float2(eng.acLayerSize.x / eng.acLayerSize.y, 1.0);
            } else {
                uv = suv;
                aspect = float2(eng.acScreenSize.x / eng.acScreenSize.y, 1.0);
            }
            
            uv = (uv * 2.0 - 1.0) * aspect;

            float2 mouse = (u.center * 2.0 - 1.0) * aspect;
            
            float time = eng.acTime * u.speed;
            
            float v = map(uv, mouse, 1.0, time, u.complexity) + map(uv, mouse, 3.0, time, u.complexity);

            float4 effectCol = tanh_approx(float4(v * u.intensity) * u.lineColor);
            effectCol.a = clamp(v * u.intensity, 0.0, 1.0);

            float4 base = inputImg.sample(__nv_smp, suv);
            
            // Apply effect alpha masking based on layer alpha
            effectCol.a *= base.a;
            
            // Standard mix for transparency
            __nv_out = mix(base, effectCol, u.blend * effectCol.a);
    return __nv_out;
}
