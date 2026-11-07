// ---------------------------------------------------------------------------
// Edge Colorize
// origem : assets/effects/toji-edgecolorize.xml
// id     : com.alightcreative.effects.edge_colorize_directional
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_edgecolorizeParams {
    float edgeSmooth;
    int subpixelSmooth;
    float edgeThreshold;
    float brightness;
    float rotateColors;
    float4 bgColor;
    float4 colTop;
    float4 colRight;
    float4 colBottom;
    float4 colLeft;
    float opacity;
};

// --- funcoes auxiliares do efeito
// Edge Colorize (Directional)
        // Port of a Shadertoy-style pre-blur + Sobel edge detector with directional colorization.
        // Controls: u.edgeSmooth (pre-blur radius), u.subpixelSmooth, u.edgeThreshold, u.brightness, u.rotateColors, 4 directional colors, u.bgColor, u.opacity.

        float luminance(float3 c){
            return dot(c, float3(0.2126, 0.7152, 0.0722));
        }

        // Sample source at a given UV
        float3 sampleSrc(float2 uv){
            return inputImg.sample(__nv_smp, uv).rgb;
        }

        // 3x3 Gaussian blur luminance with adjustable radius (in UV space scaled by pixel size)
        float getBlurredLuminance(float2 uv, float2 texel, float radius){
            // Gaussian-like kernel (1 2 1; 2 4 2; 1 2 1), weight 16
            // We keep a slight normalization factor to mimic the Shadertoy reference
            const float3x3 k = float3x3(
                1.0, 2.0, 1.0,
                2.0, 4.0, 2.0,
                1.0, 2.0, 1.0
            );
            const float w = 16.0;

            float acc = 0.0;
            for(int j=-1; j<=1; ++j){
                for(int i=-1; i<=1; ++i){
                    float2 off = float2(float(i), float(j)) * texel * radius;
                    float3 c = sampleSrc(uv + off);
                    acc += luminance(c) * k[j+1][i+1];
                }
            }
            return acc / w;
        }

        void sobelOnBlur(float2 uv, float2 texel, float radius, out float gx, out float gy){
            // Precompute blurred luminance over 3x3 neighborhood
            float lum[9];
            int idx = 0;
            for(int j=-1; j<=1; ++j){
                for(int i=-1; i<=1; ++i){
                    float2 off = float2(float(i), float(j)) * texel;
                    lum[idx++] = getBlurredLuminance(uv + off, texel, radius);
                }
            }
            // Sobel kernels
            const float3x3 sx = float3x3(-1.0, 0.0, 1.0,
                                 -2.0, 0.0, 2.0,
                                 -1.0, 0.0, 1.0);
            const float3x3 sy = float3x3(-1.0, -2.0, -1.0,
                                  0.0,  0.0,  0.0,
                                  1.0,  2.0,  1.0);
            gx = 0.0; gy = 0.0;
            // Map 1D array back into 3x3 indexing [x][y]
            for(int j2=0; j2<3; ++j2){
                for(int i2=0; i2<3; ++i2){
                    float L = lum[j2*3 + i2];
                    gx += L * sx[i2][j2];
                    gy += L * sy[i2][j2];
                }
            }
        }

        // Rotate a 2D vector by angle (radians)
        float2 rotate(float2 v, float a){
            float s = sin(a), c = cos(a);
            return float2x2(c, -s, s, c) * v;
        }

        float3 directionalColor(float2 grad, float mag, float th, float angle){
            if(mag <= th) return u.bgColor.rgb; // below threshold -> background

            // Normalize gradient
            float2 g = grad / max(1e-6, mag);

            // Cardinal directions (Up, Right, Down, Left), rotated by angle
            float2 up    = rotate(float2(0.0, -1.0), angle);
            float2 right = rotate(float2(1.0,  0.0), angle);
            float2 down  = rotate(float2(0.0,  1.0), angle);
            float2 left  = rotate(float2(-1.0, 0.0), angle);

            // Weights by directional agreement; exponent sharpens selection
            float e = 3.0;
            float wUp    = pow(max(0.0, dot(g, up)),    e);
            float wRight = pow(max(0.0, dot(g, right)), e);
            float wDown  = pow(max(0.0, dot(g, down)),  e);
            float wLeft  = pow(max(0.0, dot(g, left)),  e);

            float wSum = max(1e-6, wUp + wRight + wDown + wLeft);
            float3 mixCol = (u.colTop.rgb    * wUp +
                           u.colRight.rgb  * wRight +
                           u.colBottom.rgb * wDown +
                           u.colLeft.rgb   * wLeft) / wSum;

            return mixCol * mag * u.brightness;
        }

        float3 evalEdgeColor(float2 uv, float2 texel){
            float4 src4 = inputImg.sample(__nv_smp, uv);
            float3 baseCol = u.bgColor.rgb;
            float gx, gy;
            sobelOnBlur(uv, texel, u.edgeSmooth, gx, gy);
            float mag = length(float2(gx, gy));

            float th = u.edgeThreshold;
            if(u.subpixelSmooth){
                float soft = smoothstep(th - 0.02, th + 0.02, mag);
                float ang = radians(u.rotateColors);
                float3 col = directionalColor(float2(gx, gy), max(th, mag*soft), th, ang);
                return mix(baseCol, col, soft);
            } else {
                float ang = radians(u.rotateColors);
                float3 col = directionalColor(float2(gx, gy), mag, th, ang);
                float mask = step(th, mag);
                return mix(baseCol, col, mask);
            }
        }

fragment float4 fx_toji_edgecolorize(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_edgecolorizeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            // Aspect-correct UVs
            float2 res = eng.acScreenSize;
            float2 uv = in.acScreenNorm;
            float2 texel = 1.0 / res;

            float3 color;
            if(u.subpixelSmooth){
                // 4-tap supersample around pixel center for extra anti-aliasing
                float2 o = 0.5 * texel;
                float3 c0 = evalEdgeColor(uv + float2(-o.x, -o.y), texel);
                float3 c1 = evalEdgeColor(uv + float2( o.x, -o.y), texel);
                float3 c2 = evalEdgeColor(uv + float2(-o.x,  o.y), texel);
                float3 c3 = evalEdgeColor(uv + float2( o.x,  o.y), texel);
                color = (c0 + c1 + c2 + c3) * 0.25;
            } else {
                color = evalEdgeColor(uv, texel);
            }

            float4 src4m = inputImg.sample(__nv_smp, uv);
            float aOut = src4m.a * u.opacity;
            __nv_out = float4(color, 1.0) * aOut;
    return __nv_out;
}
