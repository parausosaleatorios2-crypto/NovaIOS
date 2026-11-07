// ---------------------------------------------------------------------------
// @am:string/effect_palettemap_name
// origem : assets/effects/toji-palette-map.xml
// id     : com.alightcreative.effects.palettemap
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_palette_mapParams {
    int palette;
    float alpha;
    float4 color1;
    float4 color2;
    float4 color3;
    float4 color4;
    float4 color5;
    float4 color6;
    float4 color7;
    float4 color8;
    int shades;
};

fragment float4 fx_toji_palette_map(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_palette_mapParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            // 0xFF = 255 = 1.000
            // 0x55 =  85 = 0.333
            // 0xAA = 170 = 0.667

            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float a = texColor.a;
            float3 rgb = texColor.rgb / max(0.0001,a);

            float3 c[16];
            int ncolors;

            if( u.palette == 0 ) {
                c[0] = float3(0.000, 0.000, 0.000);
                c[1] = float3(0.333, 1.000, 0.333);
                c[2] = float3(1.000, 0.333, 0.333);
                c[3] = float3(1.000, 1.000, 0.333);
                ncolors = 4;
            } else if( u.palette == 1 ) {
                c[0] = float3(0.000, 0.000, 0.000);
                c[1] = float3(0.333, 1.000, 1.000);
                c[2] = float3(1.000, 0.333, 1.000);
                c[3] = float3(1.000, 1.000, 1.000);
                ncolors = 4;
            } else if( u.palette == 10 ) {
                c[0] = float3(0.333, 0.333, 1.000);
                c[1] = float3(0.333, 1.000, 1.000);
                c[2] = float3(1.000, 0.333, 1.000);
                c[3] = float3(1.000, 1.000, 1.000);
                ncolors = 4;
            } else if( u.palette == 2 ) {
                c[0] = float3(0.000, 0.000, 0.000);
                c[1] = float3(0.000, 0.000, 0.667);
                c[2] = float3(0.000, 0.667, 0.000);
                c[3] = float3(0.000, 0.667, 0.667);
                c[4] = float3(0.667, 0.000, 0.000);
                c[5] = float3(0.667, 0.000, 0.667);
                c[6] = float3(0.667, 0.333, 0.000);
                c[7] = float3(0.667, 0.667, 0.667);

                c[8]  = float3(0.333, 0.333, 0.333);
                c[9]  = float3(0.333, 0.333, 1.000);
                c[10] = float3(0.333, 1.000, 0.333);
                c[11] = float3(0.333, 1.000, 1.000);
                c[12] = float3(1.000, 0.333, 0.333);
                c[13] = float3(1.000, 0.333, 1.000);
                c[14] = float3(1.000, 1.000, 0.333);
                c[15] = float3(1.000, 1.000, 1.000);
                ncolors = 16;
            } else if( u.palette == 3 ) {
                c[0] = float3(0.000, 0.000, 0.000);
                c[1] = float3(0.000, 0.000, 0.667);
                c[2] = float3(0.000, 0.667, 0.000);
                c[3] = float3(0.333, 0.667, 1.000);
                c[4] = float3(0.667, 0.000, 0.000);
                c[5] = float3(0.667, 0.000, 0.667);
                c[6] = float3(0.333, 0.667, 0.000);
                c[7] = float3(0.667, 0.667, 0.667);

                c[8]  = float3(0.333, 0.333, 0.333);
                c[9]  = float3(0.333, 0.333, 1.000);
                c[10] = float3(0.333, 1.000, 0.333);
                c[11] = float3(0.333, 1.000, 1.000);
                c[12] = float3(1.000, 0.333, 0.333);
                c[13] = float3(1.000, 0.333, 1.000);
                c[14] = float3(1.000, 1.000, 0.333);
                c[15] = float3(1.000, 1.000, 1.000);
                ncolors = 16;
            } else if( u.palette == 4 ) {
                c[0] = float3(0.000, 0.000, 0.000);
                c[1] = float3(0.333, 0.333, 1.000);
                c[2] = float3(0.333, 1.000, 0.333);
                c[3] = float3(0.333, 1.000, 1.000);
                c[4] = float3(1.000, 0.333, 0.333);
                c[5] = float3(1.000, 0.333, 1.000);
                c[6] = float3(1.000, 1.000, 0.333);
                c[7] = float3(1.000, 1.000, 1.000);
                ncolors = 8;
            } else if( u.palette == 5 ) {
                c[0] = float3(0.000, 0.000, 0.000);
                c[1] = float3(0.333, 0.333, 0.333);
                c[2] = float3(0.667, 0.667, 0.667);
                c[3] = float3(1.000, 1.000, 1.000);
                ncolors = 4;
            } else if( u.palette == 6 && u.shades) {
                c[0] = u.color1.rgb;
                c[1] = u.color2.rgb;
                c[2] = u.color3.rgb;
                c[4] = u.color1.rgb * 0.667;
                c[5] = u.color2.rgb * 0.667;
                c[6] = u.color3.rgb * 0.667;
                ncolors = 6;
            } else if( u.palette == 6 ) {
                c[0] = u.color1.rgb;
                c[1] = u.color2.rgb;
                c[2] = u.color3.rgb;
                ncolors = 3;
            } else if( u.palette == 7 && u.shades ) {
                c[0] = u.color1.rgb;
                c[1] = u.color2.rgb;
                c[2] = u.color3.rgb;
                c[3] = u.color4.rgb;
                c[4] = u.color1.rgb * 0.667;
                c[5] = u.color2.rgb * 0.667;
                c[6] = u.color3.rgb * 0.667;
                c[7] = u.color4.rgb * 0.667;
                ncolors = 8;
            } else if( u.palette == 7 ) {
                c[0] = u.color1.rgb;
                c[1] = u.color2.rgb;
                c[2] = u.color3.rgb;
                c[3] = u.color4.rgb;
                ncolors = 4;
            } else if( u.palette == 8 && u.shades ) {
                c[0] = u.color1.rgb;
                c[1] = u.color2.rgb;
                c[2] = u.color3.rgb;
                c[3] = u.color4.rgb;
                c[4] = u.color5.rgb;
                c[5] = u.color6.rgb;
                c[6] = u.color1.rgb * 0.667;
                c[7] = u.color2.rgb * 0.667;
                c[8] = u.color3.rgb * 0.667;
                c[9] = u.color4.rgb * 0.667;
                c[10] = u.color5.rgb * 0.667;
                c[11] = u.color6.rgb * 0.667;
                ncolors = 12;
            } else if( u.palette == 8 ) {
                c[0] = u.color1.rgb;
                c[1] = u.color2.rgb;
                c[2] = u.color3.rgb;
                c[3] = u.color4.rgb;
                c[4] = u.color5.rgb;
                c[5] = u.color6.rgb;
                ncolors = 6;
            } else if( u.palette == 9 && u.shades ) {
                c[0] = u.color1.rgb;
                c[1] = u.color2.rgb;
                c[2] = u.color3.rgb;
                c[3] = u.color4.rgb;
                c[4] = u.color5.rgb;
                c[5] = u.color6.rgb;
                c[6] = u.color7.rgb;
                c[7] = u.color8.rgb;

                c[8]  = u.color1.rgb * 0.667;
                c[9]  = u.color2.rgb * 0.667;
                c[10] = u.color3.rgb * 0.667;
                c[11] = u.color4.rgb * 0.667;
                c[12] = u.color5.rgb * 0.667;
                c[13] = u.color6.rgb * 0.667;
                c[14] = u.color7.rgb * 0.667;
                c[15] = u.color8.rgb * 0.667;
                ncolors = 16;
            } else if( u.palette == 9 ) {
                c[0] = u.color1.rgb;
                c[1] = u.color2.rgb;
                c[2] = u.color3.rgb;
                c[3] = u.color4.rgb;
                c[4] = u.color5.rgb;
                c[5] = u.color6.rgb;
                c[6] = u.color7.rgb;
                c[7] = u.color8.rgb;
                ncolors = 8;
            }

            float3 bestColor = c[0];
            float bestDist = 100.0;

            for( int i=0; i<ncolors; i++ ) {
                float l = length(c[i] - rgb);
                if( l < bestDist ) {
                    bestDist = l;
                    bestColor = c[i];
                }
            }

            __nv_out = mix(texColor, float4(bestColor,1.0) * a, u.alpha);
    return __nv_out;
}
