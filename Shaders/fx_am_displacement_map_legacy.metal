// ---------------------------------------------------------------------------
// Mapa de deslocamento (versão 1)
// origem : assets/effects/am-displacement-map-legacy.xml
// id     : nova.effect.am-displacement-map-legacy
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_displacement_map_legacyParams {
    float2 offs;
    int type;
    int edges;
    int fromctr;
    int invert;
};

// --- funcoes auxiliares do efeito
// O mesmo `oitoBits`, `fundoPre` e `fundoNoPonto` da atual (ver `am-displacement-map.xml`).
float oitoBits(float k) {
    uint n = uint(k);
    if (n == 0u) return 0.0;
    if (n == 255u) return 1.0;
    int j = 0;
    for (int i = 1; i < 8; i++) if (n >= (1u << uint(i))) j = i;
    int e = 31 - j;
    uint q = ((n << uint(e)) + 127u) / 255u;
    return as_type<float>((uint(150 - e) << 23) + (q - 0x800000u));
}

float4 fundoPre(int2 px) {
    float4 c = comp.read(uint2(px), uint(0));
    if (c.a >= 1.0) return c;
    float3 k = floor(c.rgb * c.a * 255.0 + 0.5);
    return float4(oitoBits(k.r), oitoBits(k.g), oitoBits(k.b), c.a);
}

float4 fundoNoPonto(float2 uv) {
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

fragment float4 fx_am_displacement_map_legacy(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_displacement_map_legacyParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> comp [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 tela = __nv_acTela(in.acScreenNorm);

    float2 adjOffs = u.offs / 1000.0;
    adjOffs.x *= eng.acTamanhoDaCamada.x/eng.acTamanhoDaCamada.y * -1.0;

    float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
    if (texColor.a < 1.0) {
        float3 k = floor(texColor.rgb * texColor.a * 255.0 + 0.5);
        texColor.rgb = float3(oitoBits(k.r), oitoBits(k.g), oitoBits(k.b));
    }
    float p = 0.0;
    if( u.type==0 ) {
        p = texColor.r*0.2126 + texColor.g*0.7152 + texColor.b*0.0722;
    } else if( u.type == 1 ) {
        p = texColor.r;
    } else if( u.type == 2 ) {
        p = texColor.g;
    } else if( u.type == 3 ) {
        p = texColor.b;
    } else {
        adjOffs *= 0.0;
    }
    if( u.fromctr ) {
        p = (p-0.5)*2.0;
    }
    if( u.invert ) {
        adjOffs *= (1.0-p) * texColor.a;
    } else {
        adjOffs *= p * texColor.a;
    }

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

    __nv_out = saida.a > 0.0 ? float4(saida.rgb / saida.a, saida.a) : float4(0.0);
    return __nv_out;
}
