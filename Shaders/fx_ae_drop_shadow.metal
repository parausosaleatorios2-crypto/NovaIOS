// ---------------------------------------------------------------------------
// Drop Shadow (AE)
// origem : assets/effects/ae-drop-shadow.xml
// id     : nova.effect.aedropshadow
// passes : 7
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct ae_drop_shadowParams {
    float4 shadowColor;
    float opacity;
    float direction;
    float shadowDistance;
    float softness;
    int shadowOnly;
};

// --- funcoes auxiliares do efeito
// Calculados no Kotlin (model/DropShadowDoAe.kt), em double, como o host do plugin.
uniform int dsDx;           // o deslocamento inteiro, px do buffer, y para baixo (como no AE)
uniform int dsDy;
uniform float dsRaio;       // o raio da caixa: Softness · 0,5 / 2,71
uniform int dsN;            // ceil(dsRaio); 0 = sem desfoque
uniform float dsOpacidade;  // 0..1

const int MARGEM = 256;     // = margin dos buffers

// O deslocamento no buffer: com a cena de pé (a linha 0 é a base), o "para baixo" do AE é para cima aqui.
int2 deslocamento() { return int2(dsDx, eng.acEntradaDePe == 1 ? -dsDy : dsDy); }

// O alfa da camada (k / 255 exato); fora do quadro, transparente.
float alfaDaCamada(int2 c) {
    int2 t = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    if (any(lessThan(c, int2(0))) || any(greaterThanEqual(c, t))) return 0.0;
    return floor(inputImg.read(uint2(c), uint(0)).a * 255.0 + 0.5) / 255.0;
}

// 24 bits fixos no RGB de um RGBA8 (o alfa da passada fica em [0, 1]).
float4 guardar(float v) {
    uint q = min(uint(clamp(v, 0.0, 1.0) * 16777216.0), 16777215u);
    return float4(float(q >> 16u), float((q >> 8u) & 255u), float(q & 255u), 255.0) / 255.0;
}
float abrir(sampler2D b, int2 c) {
    int2 p = c + MARGEM;
    int2 n = int2(int(b.get_width()), int(b.get_height()));
    if (any(lessThan(p, int2(0))) || any(greaterThanEqual(p, n))) return 0.0;
    uint3 k = uint3(floor(b.read(uint2(p), uint(0)).rgb * 255.0 + 0.5));
    return float((k.x << 16u) | (k.y << 8u) | k.z) / 16777216.0;
}

// O valor que a passada lê: na 1ª, a máscara (o alfa da camada deslocado); nas outras, a passada anterior.
float anterior(int2 c) {
    if (eng.acPass == 0) return alfaDaCamada(c - deslocamento());
    return (eng.acPass % 2 == 1) ? abrir(dsA, c) : abrir(dsB, c);
}

fragment float4 fx_ae_drop_shadow(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant ae_drop_shadowParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> dsA [[texture(1)]],
    texture2d<float> dsB [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass < 6) {
        // uma passada da caixa: as três primeiras na horizontal, as outras na vertical
        int2 c = int2(__nv_fragCoord.xy) - MARGEM;
        int2 eixo = eng.acPass < 3 ? int2(1, 0) : int2(0, 1);
        int n = dsN;
        float inv = float(n) - dsRaio;
        float peso = float(2 * n + 1) - 2.0 * inv;
        float inteira = 0.0;
        for (int k = -n; k <= n; k++) inteira += anterior(c + eixo * k);
        float pontas = anterior(c - eixo * n) + anterior(c + eixo * n);
        __nv_out = guardar((inteira - pontas * inv) / peso);
        return __nv_out;
    }

    int2 c = int2(__nv_fragCoord.xy);
    float a = dsN == 0 ? alfaDaCamada(c - deslocamento()) : abrir(dsB, c);
    float sa = clamp(a * dsOpacidade, 0.0, 1.0);
    float3 cor = u.shadowColor.rgb;   // float, como o PF ColorParamSuite dá ao plugin
    float4 saida;
    if (u.shadowOnly) {
        saida = float4(cor, sa);
    } else {
        // NormalComposite do kernel: a camada (reta) por cima da sombra
        float4 l = floor(inputImg.read(uint2(c), uint(0)) * 255.0 + 0.5) / 255.0;
        float da = sa * (1.0 - l.a);
        float al = da + l.a;
        saida = al > 0.0 ? float4((l.rgb * l.a + cor * da) / al, al) : float4(0.0);
        // onde a camada é transparente o AE dá (c·a)·(1/a) = c: a própria cor (a divisão daqui erra o último bit
        // e, com 0,9 · 255 = 229,5, o empate caía para o outro lado)
        if (l.a == 0.0 && al > 0.0) saida.rgb = cor;
    }
    // 8 bits como o AE: v·255 arredondado em float, + 0,5, para baixo. O `um` impede o compilador de fundir o
    // produto e a soma num fma (que não arredonda o produto: 0,9 · 255 dava 229,49999 e não 229,5). E não deixar a
    // conversão para a GPU: a da AMD arredonda o x,5 para baixo.
    float um = float(min(eng.acIterationCount, 1));
    __nv_out = floor((clamp(saida, 0.0, 1.0) * 255.0) * um + 0.5) / 255.0;
    return __nv_out;
}
