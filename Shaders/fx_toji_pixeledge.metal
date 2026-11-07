// ---------------------------------------------------------------------------
// Pixelate Edge
// origem : assets/effects/toji-pixeledge.xml
// id     : alightcreative.effects.pixelate_edge_gradient
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_pixeledgeParams {
    float pixelSize;
    float4 color1;
    float4 color2;
    float4 color3;
    float edgeThresh;
    float gradientBias;
};

// --- funcoes auxiliares do efeito
// Pixelate Edge Detection with 3-Color Gradient
        static float3 rgb2gray(float3 c) { return float3(dot(c, float3(0.299, 0.587, 0.114))); }

fragment float4 fx_toji_pixeledge(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_pixeledgeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 uv = in.acScreenNorm;
            float p = u.pixelSize;
            float2 pixUV = floor(uv / p) * p + 0.5 * p;
            // Pixelate sample
            float4 pixCol = inputImg.sample(__nv_smp, pixUV);

            // Sobel edge detection (on pixelated image)
            float s = p * 1.0;
            float gx = 0.0;
            float gy = 0.0;
            float k[9];
            k[0] = -1.0; k[1] = 0.0; k[2] = 1.0;
            k[3] = -2.0; k[4] = 0.0; k[5] = 2.0;
            k[6] = -1.0; k[7] = 0.0; k[8] = 1.0;
            float l[9];
            l[0] = -1.0; l[1] = -2.0; l[2] = -1.0;
            l[3] = 0.0;  l[4] = 0.0;  l[5] = 0.0;
            l[6] = 1.0;  l[7] = 2.0;  l[8] = 1.0;
            int idx = 0;
            for (int y = -1; y <= 1; ++y) {
                for (int x = -1; x <= 1; ++x) {
                    float2 o = float2(float(x), float(y)) * s;
                    float gray = rgb2gray(inputImg.sample(__nv_smp, pixUV + o).rgb).r;
                    gx += gray * k[idx];
                    gy += gray * l[idx];
                    idx++;
                }
            }
            float edge = sqrt(gx * gx + gy * gy);
            edge = smoothstep(u.edgeThresh, 1.0, edge);

            // 3-color gradient mapping
            float gradBias = u.gradientBias;
            float3 gradCol = mix(u.color1.rgb, u.color2.rgb, smoothstep(0.0, gradBias, edge));
            gradCol = mix(gradCol, u.color3.rgb, smoothstep(gradBias, 1.0, edge));

            __nv_out = float4(gradCol, 1.0);
    return __nv_out;
}
