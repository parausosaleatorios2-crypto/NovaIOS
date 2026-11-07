// ---------------------------------------------------------------------------
// Desfoque de lente
// origem : assets/effects/lens-blur.xml
// id     : nova.effect.lensblur
// passes : 4
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct lens_blurParams {
    float radius;
    float useMap;
    float focusDistance;
    float boost;
    float cut;
    float energy;
    float rotation;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265;
const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

// 16 passos por direção. Mais que isso não muda o que se vê e custa linear; com
// muito menos, o hexágono vira uma fileira de fantasmas em vez de um borrão.
const int PASSOS = 16;

static float2 paraUv(float2 v) { return float2(v.x / max(eng.acAspect, 1e-4), v.y); }

static float2 direcao(float graus) {
    float a = (graus + u.rotation) * PI / 180.0;
    return float2(sin(a), cos(a));
}

// A separação de profundidade (0..1) que já conta como "totalmente fora de
// foco" — mesma constante e mesmo raciocínio de `depth-map.xml`: sem isto, só
// uma separação extrema entre assunto e fundo chegaria perto do raio cheio.
const float FAIXA_DE_QUEDA = 0.3;

/**
 * O raio naquele ponto, já considerando o mapa de profundidade.
 *
 * O mapa entra como MULTIPLICADOR e não como substituto: assim o slider de raio
 * continua sendo o controle mestre, e o mapa só decide onde ele vale.
 *
 * `profundidade - u.focusDistance` é o MESMO termo de `depth-map.xml`: o plano
 * escolhido em `u.focusDistance` fica nítido, e quem está mais longe dele (pra
 * qualquer lado) desfoca proporcionalmente — não é mais "claro borra, escuro
 * não", que ignorava qual profundidade a pessoa queria manter nítida.
 */
static float raioEm(float2 uv) {
    if (u.useMap <= 0.0) return u.radius;
    float profundidade = dot(focusMap.sample(__nv_smp, uv).rgb, LUMA);
    float queda = clamp(abs(profundidade - u.focusDistance) / FAIXA_DE_QUEDA, 0.0, 1.0);
    return u.radius * mix(1.0, queda, u.useMap);
}

/** A cor da fonte já preparada para somar: realçada e em energia. */
static float4 fonteEm(float2 uv) {
    float4 c = inputImg.sample(__nv_smp, uv);

    // Realce só do que já é claro. Espalhar tudo igualmente clarearia a imagem
    // inteira em vez de acender as luzes.
    float luz = dot(c.rgb, LUMA);

    // A borda de cima passa de 1,0 quando o corte está alto, e isso é proposital:
    // apertar as duas bordas no mesmo valor faria `smoothstep` dividir por zero, o
    // que a especificação não define. Com o corte no máximo, nada acende — que é
    // exatamente o que o controle promete.
    float acima = smoothstep(u.cut, u.cut + 0.25, luz);
    float3 realcada = c.rgb * (1.0 + u.boost * acima);

    return float4(pow(max(realcada, 0.0), float3(u.energy)), c.a);
}

/**
 * Borra em UMA direção, somando em energia.
 *
 * O alfa entra multiplicando a cor e sai dividindo: pixel transparente não tem
 * cor que signifique alguma coisa, e misturá-la puxaria a borda para preto.
 */
static float4 borrarDirecao(sampler2D tex, float2 uv, float2 dir, float raio, bool jaEmEnergia) {
    if (raio <= 0.0) {
        return jaEmEnergia ? tex.sample(__nv_smp, uv) : fonteEm(uv);
    }

    float2 passo = paraUv(dir) * (raio / float(PASSOS));
    float3 soma = float3(0.0);
    float peso = 0.0;

    for (int i = 0; i <= PASSOS; i++) {
        float2 p = uv + passo * float(i);
        float4 c = jaEmEnergia ? tex.sample(__nv_smp, p) : fonteEm(p);
        soma += c.rgb * c.a;
        peso += c.a;
    }

    return float4(soma / max(peso, 1e-4), peso / float(PASSOS + 1));
}

fragment float4 fx_lens_blur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant lens_blurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> focusMap [[texture(1)]],
    texture2d<float> bufV [[texture(2)]],
    texture2d<float> bufDL [[texture(3)]],
    texture2d<float> bufR1 [[texture(4)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float raio = raioEm(in.acScreenNorm);

    // As três direções do diafragma, a 120° uma da outra: é a menor quantidade
    // de direções que fecha um polígono convexo.
    float2 cima = direcao(0.0);
    float2 baixoEsq = direcao(120.0);
    float2 baixoDir = direcao(240.0);

    if (eng.acPass == 0) {
        __nv_out = borrarDirecao(inputImg, in.acScreenNorm, cima, raio, false);
        return __nv_out;
    }
    if (eng.acPass == 1) {
        __nv_out = borrarDirecao(inputImg, in.acScreenNorm, baixoEsq, raio, false);
        return __nv_out;
    }
    if (eng.acPass == 2) {
        __nv_out = borrarDirecao(bufV, in.acScreenNorm, baixoEsq, raio, true);
        return __nv_out;
    }

    // Último passe: o segundo losango sai de V+DL, e a média dos dois losangos
    // é o hexágono.
    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    float2 passo = paraUv(baixoDir) * (raio / float(PASSOS));
    float3 soma = float3(0.0);
    float peso = 0.0;
    for (int i = 0; i <= PASSOS; i++) {
        float2 p = in.acScreenNorm + passo * float(i);
        float4 v = bufV.sample(__nv_smp, p);
        float4 dl = bufDL.sample(__nv_smp, p);
        float3 juntos = (v.rgb * v.a + dl.rgb * dl.a) * 0.5;
        float a = (v.a + dl.a) * 0.5;
        soma += juntos;
        peso += a;
    }
    float4 losango2 = float4(soma / max(peso, 1e-4), peso / float(PASSOS + 1));
    float4 losango1 = bufR1.sample(__nv_smp, in.acScreenNorm);

    float3 energiaFinal = (losango1.rgb + losango2.rgb) * 0.5;
    float alfa = (losango1.a + losango2.a) * 0.5;

    // Volta da energia para a cor guardada. Sem esta raiz, tudo sairia lavado.
    float3 cor = pow(max(energiaFinal, 0.0), float3(1.0 / max(u.energy, 0.001)));

    // Raio zero tem que devolver a imagem intacta, e não uma versão que passou
    // por potência e raiz — as duas juntas não são exatamente a identidade.
    float quanto = smoothstep(0.0, 0.002, raio);
    __nv_out = mix(original, float4(cor, min(alfa, 1.0) * original.a + (1.0 - original.a) * alfa), quanto);
    return __nv_out;
}
