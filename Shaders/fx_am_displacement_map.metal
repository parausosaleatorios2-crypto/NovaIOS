// ---------------------------------------------------------------------------
// Mapa de deslocamento
// origem : assets/effects/am-displacement-map.xml
// id     : nova.effect.am-displacement-map
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_displacement_mapParams {
    float2 offs;
    int typex;
    int typey;
    int edges;
    int fromctr;
    int invert;
};

// --- funcoes auxiliares do efeito
// k/255 pelo mais perto, montado nos bits do float: o valor exato que a textura de 8 bits devolve ao AM (o
// `floor(..)/255.0` vai pelo recíproco e erra o último bit — ver `am-color-balance.xml`).
static float oitoBits(float k) {
    uint n = uint(k);
    if (n == 0u) return 0.0;
    if (n == 255u) return 1.0;
    int j = 0;                                                    // o bit mais alto de n
    for (int i = 1; i < 8; i++) if (n >= (1u << uint(i))) j = i;
    int e = 31 - j;
    uint q = ((n << uint(e)) + 127u) / 255u;                      // entre 2^23 e 2^24
    return as_type<float>((uint(150 - e) << 23) + (q - 0x800000u));
}

// Um pixel do fundo como a textura `comp` do AM o guarda: pré-multiplicado, em 8 bits.
static float4 fundoPre(int2 px) {
    float4 c = comp.read(uint2(px), uint(0));
    if (c.a >= 1.0) return c;
    float3 k = floor(c.rgb * c.a * 255.0 + 0.5);
    return float4(oitoBits(k.r), oitoBits(k.g), oitoBits(k.b), c.a);
}

// O `comp.sample(__nv_smp, uv)` do AM: o filtro linear da GPU no fundo pré-multiplicado, CLAMP_TO_EDGE. Com os
// 4 pixels opacos é o filtro da própria GPU; senão, à mão nos 4 pixels pré-multiplicados.
static float4 fundoNoPonto(float2 uv) {
    float4 g = comp.sample(__nv_smp, uv);
    if (g.a >= 1.0) return g;
    int2 T = int2(int(comp.get_width()), int(comp.get_height()));
    float2 p = uv * float2(T) - 0.5;
    float2 i = floor(p);
    float2 f = p - i;
    int2 a = int2(i);
    int2 m = T - 1;
    float4 c00 = fundoPre(clamp(a, int2(0), m));
    float4 c10 = fundoPre(clamp(a + int2(1, 0), int2(0), m));
    float4 c01 = fundoPre(clamp(a + int2(0, 1), int2(0), m));
    float4 c11 = fundoPre(clamp(a + int2(1, 1), int2(0), m));
    return mix(mix(c00, c10, f.x), mix(c01, c11, f.x), f.y);
}

const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);

fragment float4 fx_am_displacement_map(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_displacement_mapParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> comp [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& comp_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    // A UV da tela do fundo (t = 0 embaixo, a da tela do AM); na tela (`stage="screen"`) é o próprio in.acScreenNorm.
    float2 tela = __nv_acTela(in.acScreenNorm);

    // Daqui até a `amostra`, a conta do AM na mesma ordem (o `sample` dele é palavra reservada no GLSL ES 3.00).
    float2 adjOffs = u.offs / 1000.0;
    adjOffs.x *= eng.acTamanhoDaCamada.x/eng.acTamanhoDaCamada.y * -1.0;

    // A camada pré-multiplicada em 8 bits, como o AM a entrega (no opaco, a própria cor).
    float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
    if (texColor.a < 1.0) {
        float3 k = floor(texColor.rgb * texColor.a * 255.0 + 0.5);
        texColor.rgb = float3(oitoBits(k.r), oitoBits(k.g), oitoBits(k.b));
    }
    float luminance = dot(texColor.rgb, luminanceWeighting);
    float px = 0.0;
    float py = 0.0;

    if( u.typex==0 ) {
        px = luminance;
    } else if( u.typex == 1 ) {
        px = texColor.r;
    } else if( u.typex == 2 ) {
        px = texColor.g;
    } else if( u.typex == 3 ) {
        px = texColor.b;
    } else {
        adjOffs *= 0.0;
    }

    if( u.typey==0 ) {
        py = luminance;
    } else if( u.typey == 1 ) {
        py = texColor.r;
    } else if( u.typey == 2 ) {
        py = texColor.g;
    } else if( u.typey == 3 ) {
        py = texColor.b;
    } else {
        adjOffs *= 0.0;
    }

    if( u.fromctr ) {
        px = (px-0.5)*2.0;
        py = (py-0.5)*2.0;
    }
    if( u.invert ) {
        px = 1.0-px;
        py = 1.0-py;
    }

    float2 p = float2(px,py);

    adjOffs *= p * texColor.a;

    float2 amostra = tela + adjOffs;
    float4 saida;
    if(u.edges==0) {
        saida = fundoNoPonto(amostra);
    } else if(u.edges==1) {
        amostra = float2(1.0,1.0) - abs(__nv_mod(amostra, float2(2.0,2.0))-float2(1.0,1.0));
        saida = fundoNoPonto(amostra) * texColor.a;
    } else if(u.edges==2) {
        if( amostra.x < 0.0 || amostra.x > 1.0 || amostra.y < 0.0 || amostra.y > 1.0 ) {
            saida = float4(0.0,0.0,0.0,0.0);
        } else {
            saida = fundoNoPonto(amostra) * texColor.a;
        }
    } else if(u.edges==3) {
        amostra = __nv_mod(amostra, float2(1.0,1.0));
        saida = fundoNoPonto(amostra) * texColor.a;
    } else {
        saida = fundoNoPonto(amostra) * texColor.a;
    }

    // Pré-multiplicada, como o AM; o Nova guarda reta.
    __nv_out = saida.a > 0.0 ? float4(saida.rgb / saida.a, saida.a) : float4(0.0);
    return __nv_out;
}
