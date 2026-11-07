//
//  NovaFullscreen.metal
//  Vertex compartilhado por todos os 1.438 efeitos.
//
//  Um triangulo que cobre a tela inteira, sem vertex buffer: as posicoes saem
//  do vertex_id. E mais barato que dois triangulos e evita a costura na diagonal.
//

#include <metal_stdlib>
#include "NovaEngineUniforms.h"
using namespace metal;

vertex NovaVertexOut nova_fullscreen_vertex(uint vid [[vertex_id]])
{
    // (-1,-1) (3,-1) (-1,3) cobre o viewport inteiro com um triangulo so.
    const float2 pos[3] = { float2(-1.0, -1.0), float2(3.0, -1.0), float2(-1.0, 3.0) };
    const float2 uv [3] = { float2( 0.0,  1.0), float2(2.0,  1.0), float2( 0.0, -1.0) };

    NovaVertexOut out;
    out.position     = float4(pos[vid], 0.0, 1.0);
    out.uv           = uv[vid];
    out.acScreenNorm = uv[vid];
    out.acLayerNorm  = uv[vid];
    out.vs_TEXCOORD0 = uv[vid];
    out.vs_TEXCOORD1 = float4(uv[vid], 0.0, 1.0);
    out.vs_TEXCOORD2 = float4(uv[vid], 0.0, 1.0);
    out.vs_TEXCOORD3 = float4(uv[vid], 0.0, 1.0);
    out.vs_TEXCOORD4 = float4(uv[vid], 0.0, 1.0);
    out.vs_TEXCOORD5 = float4(uv[vid], 0.0, 1.0);
    out.vs_COLOR0    = float4(1.0);
    return out;
}
