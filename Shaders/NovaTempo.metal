//
//  NovaTempo.metal
//  Efeitos que olham outros instantes da camada: CC Wide Time e S_TimeSlice.
//  O Compositor desenha a camada em cada instante e soma aqui, com peso.
//  Modo 0 (Wide Time): peso fixo, a media dos quadros.
//  Modo 1 (Time Slice, porte de FatiaDoTempo do APK): cada pixel pega o quadro
//  da sua faixa — quadro = (cos·x − sen·y)·k + base, x e y em meias larguras,
//  y para baixo; com Interp Frames, mistura os dois vizinhos.
//

#include <metal_stdlib>
#include "NovaEngineUniforms.h"
using namespace metal;

struct TempoUniforms {
    float peso;
    int   modo;
    float cosseno;
    float seno;
    float k;
    float base;
    float inicio;
    float passo;
    float indice;
    float ultimo;
    float aspecto;
    int   interpolar;
    int   opacidade;     // 0 All Opaque, 1 Normal, 2 As Premult
};

fragment float4 nova_tempo_fragment(NovaVertexOut in [[stage_in]],
                                    constant TempoUniforms& u [[buffer(0)]],
                                    texture2d<float> quadro [[texture(0)]])
{
    constexpr sampler s(filter::linear, address::clamp_to_edge);
    float4 c = quadro.sample(s, in.uv);
    float w = u.peso;
    if (u.modo == 1) {
        float x = in.uv.x * 2.0 - 1.0;
        float y = (in.uv.y * 2.0 - 1.0) * u.aspecto;
        float f = (u.cosseno * x - u.seno * y) * u.k + u.base;      // quadro deste pixel
        float g = clamp((f - u.inicio) / u.passo, 0.0, u.ultimo);   // na grade das amostras
        if (u.interpolar != 0) {
            w = max(0.0, 1.0 - abs(g - u.indice));
        } else {
            w = (floor(g) == u.indice) ? 1.0 : 0.0;
        }
        if (u.opacidade == 0) c = float4(c.rgb, 1.0);
    }
    return c * w;
}
