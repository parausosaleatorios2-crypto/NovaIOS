// ---------------------------------------------------------------------------
// Dissolver em poeira
// origem : assets/effects/dust-dissolve.xml
// id     : nova.effect.dustdissolve
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct dust_dissolveParams {
    float completion;
    float angle;
    int invert;
    float dustScale;
    float turbulence;
    float grainSpread;
    float grainDensity;
    float driftAngle;
    float driftStrength;
    float gravityStrength;
    float distortionSpeed;
    float4 glowColor;
    float4 colorFar;
    float glowAmount;
    float shineAmount;
    float shineDensity;
    int showMask;
};

// --- funcoes auxiliares do efeito
// hash/ruído — mesma técnica de `fractal-noise.xml`.
static float hash21(float2 p) {
    p = fract(p * float2(127.1, 311.7));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

static float valueNoise(float2 p) {
    float2 cell = floor(p);
    float2 f = fract(p);
    float2 w = f * f * (3.0 - 2.0 * f);
    float a = hash21(cell);
    float b = hash21(cell + float2(1.0, 0.0));
    float c = hash21(cell + float2(0.0, 1.0));
    float d = hash21(cell + float2(1.0, 1.0));
    return mix(mix(a, b, w.x), mix(c, d, w.x), w.y);
}

const int OITAVAS = 3;
const float ALCANCE_DO_VOO = 0.06;

// A soma da série de amplitude do fbm (0,5 + 0,25 + 0,125, três oitavas
// caindo pela metade) — o TETO exato que `fbm()` consegue alcançar, nunca
// 1,0. Usado pra renormalizar o ruído de volta pra 0..1 de verdade — ver o
// comentário grande perto de `distanciaDaBorda`.
const float TETO_DO_FBM = 0.875;

// Quantas células de dither cabem na largura da tela — fixo, não depende de
// `u.dustScale` nem da resolução de saída. Achado comparando com a referência:
// fino o bastante pra ler como grão de poeira, grosso o bastante pra não
// precisar de resolução de export pra aparecer na prévia.
const float GRAO_POR_TELA = 340.0;

static float fbm(float2 p) {
    float soma = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < OITAVAS; i++) {
        soma += amplitude * valueNoise(p);
        p *= 2.03;
        amplitude *= 0.5;
    }
    return soma;
}

/**
 * "Domain warping": desloca a ENTRADA de um fbm pelo RESULTADO de outros
 * dois — a técnica clássica (Inigo Quilez) para transformar ruído liso em
 * veios ramificados, tipo rachadura, fumaça ou mármore. `forca` controla o
 * quanto o deslocamento distorce; perto de zero o resultado quase não
 * ramifica, alto e vira uma rede de veios cruzados.
 */
static float ruidoOrganico(float2 p, float forca) {
    float2 q = float2(fbm(p), fbm(p + float2(5.2, 1.3)));
    float2 r = float2(
        fbm(p + forca * q + float2(1.7, 9.2)),
        fbm(p + forca * q + float2(8.3, 2.8))
    );
    return fbm(p + forca * r);
}

fragment float4 fx_dust_dissolve(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant dust_dissolveParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 cor = inputImg.sample(__nv_smp, in.acScreenNorm);

    // Direção base — mesma projeção normalizada de `linear-wipe.xml`.
    float rad = radians(u.angle);
    float2 eixo = float2(cos(rad), sin(rad));
    float2 centrado = (in.acScreenNorm - 0.5) * float2(eng.acAspect, 1.0);
    float alcance = max(0.5 * (eng.acAspect * abs(eixo.x) + abs(eixo.y)), 0.0001);
    float posicaoBase = (dot(centrado, eixo) + alcance) / (2.0 * alcance);

    float progresso = clamp(u.completion * 0.01, 0.0, 1.0);

    // Vento (qualquer direção) e gravidade (sempre pra BAIXO, Y+ neste
    // motor) somam no deslocamento da amostragem do ruído — dois campos de
    // força de verdade, não um "deriva" só fazendo as duas coisas.
    float radVento = radians(u.driftAngle);
    float2 eixoVento = float2(cos(radVento), sin(radVento));
    float2 deslocVento = eixoVento * u.driftStrength * progresso * 0.6;
    float2 deslocGravidade = float2(0.0, u.gravityStrength) * progresso * 0.6;
    float2 deslocMovimento = deslocVento + deslocGravidade;

    // Ondulação viva: a amostragem desliza sozinha no tempo, então o veio
    // respira mesmo com o progresso parado — sem isto, a forma é uma
    // fotografia congelada do ruído, só reagindo quando `u.completion` muda.
    float2 deslocTempo = float2(1.0, 0.7) * eng.acTime * u.distortionSpeed * 0.05;

    float2 uvRuido = in.acScreenNorm * u.dustScale + deslocMovimento + deslocTempo;
    float forcaWarp = mix(0.4, 3.5, u.turbulence);
    // Renormalizado pelo TETO_DO_FBM: sem isso, `ruido` nunca passa de 0,875
    // (a soma da série de amplitude), e "campo" abaixo nunca alcança 1,0 nem
    // no canto mais favorável da tela — ver o comentário grande adiante.
    float ruido = ruidoOrganico(uvRuido, forcaWarp) / TETO_DO_FBM;

    // Puro ruído pareceria aleatório demais; pura direção pareceria uma
    // cortina lisa atrás de textura. A mistura dá "segue essa direção, mas
    // rasgando de um jeito orgânico" — o veio, não a mancha.
    float campo = mix(posicaoBase, ruido, 0.7);

    /*
     * ========================================================================
     *  SEXTA RODADA: POEIRA DE VERDADE — REFERÊNCIA REAL, NÃO SÓ NOMES
     * ========================================================================
     *
     * Desta vez o snow mandou uma referência de VERDADE: uma sequência de
     * frames de um logo se desintegrando. Ampliando pixel a pixel (várias
     * regiões, vários instantes), a granulação NÃO é feita de motas com
     * forma/tamanho variável (o que a rodada anterior fazia) — é um DITHER
     * ESTOCÁSTICO por pixel: cada pixel individual sobrevive ou não, na
     * resolução nativa da imagem, SEM nenhum contorno suave de "grão" e SEM
     * antialiasing nenhum — é exatamente esse aspecto "serrilhado, granulado"
     * que faz ler como areia/poeira de verdade, e não como uma mancha lisa
     * com uma borda tremida.
     *
     * A troca: em vez de uma faixa ESTREITA com motas redondas por célula (a
     * rodada anterior), uma zona bem mais LARGA onde a PROBABILIDADE de cada
     * pixel sobreviver cai suavemente com a distância além da frente
     * (`distanciaDaBorda`) — testada contra um hash de ALTA frequência, na
     * resolução da TELA (não da célula grossa do veio). Sem partícula
     * geométrica nenhuma, sem buffer novo: é a mesma ideia de sempre
     * (`hash21`, já existe no arquivo), só decidindo pixel a pixel em vez de
     * célula a célula. Verificado por simulação em Python contra os frames
     * de referência antes de escrever este shader.
     */
    /*
     * ========================================================================
     *  "MESMO EM 100% AINDA FICA COM RESTOS" (relato do snow, 26/09/2026)
     * ========================================================================
     *
     * Bati na conta antes de mexer: mesmo com `ruido` renormalizado acima,
     * `campo` só chega a EXATAMENTE 1,0 no pixel mais favorável da tela — e
     * "distanciaDaBorda == 0" ali é o MEIO da zona de dither (50% de chance
     * de sobreviver), não o fim dela. Faltava empurrar o progresso um pouco
     * ALÉM de 1,0 — o tanto exato é METADE da largura da zona
     * (`larguraDaZona`), que é a distância que falta pra `posicaoNaZona`
     * zerar de vez. Por isso a folga é proporcional a `u.grainSpread` (o
     * controle já existente, "Largura da poeira") e não um número fixo — se
     * a pessoa aumentar a zona, a folga cresce junto, sozinha.
     */
    float larguraDaZona = max(u.grainSpread, 0.0001);
    float progressoEfetivo = progresso * (1.0 + larguraDaZona * 0.5);
    float distanciaDaBorda = campo - progressoEfetivo;
    // 0 = já bem depois de ter sumido; 1 = ainda bem antes de começar a
    // sumir. A ZONA de dither em si é a faixa intermediária, onde isto vai
    // suavemente de 0 a 1.
    float posicaoNaZona = clamp(distanciaDaBorda / larguraDaZona + 0.5, 0.0, 1.0);

    // `u.grainDensity` dobra de função: mais densidade achata a curva (mais
    // pixel aguenta por mais tempo, a nuvem fica "cheia"); menos densidade
    // deixa a curva mais em pé (poucos pixels aguentam, dissolve rápido e
    // ralo). 2,2 e 0,5 achados comparando lado a lado com a referência.
    float curvaDaZona = mix(2.2, 0.5, clamp(u.grainDensity, 0.0, 1.0));
    float probabilidade = pow(posicaoNaZona, curvaDaZona);

    // Hash por PIXEL DE TELA — frequência FIXA, independente da resolução de
    // saída, pra o grão parecer do mesmo tamanho na prévia (720p) e no
    // export (4K), do mesmo jeito que qualquer outro parâmetro deste efeito
    // já é resolução-independente.
    float2 idPixel = floor(in.acScreenNorm * float2(eng.acAspect, 1.0) * GRAO_POR_TELA);
    float ruidoDoPixel = hash21(idPixel);

    float mascara = step(ruidoDoPixel, probabilidade);

    /*
     * POEIRA VOANDO — a aproximação de "partícula de verdade" que dá pra
     * fazer NUM fragment shader por pixel, sem estado entre quadros.
     *
     * O plugin original tem compute shader escrevendo num buffer de
     * partícula (`DustTextured`) e desenhando cada floco como um quad
     * (`DrawDustQuadIndexes`) — só nomes de recurso GPU, não o algoritmo
     * (o próprio material é explícito: "sem os dispatches, qualquer
     * fórmula seria especulação"). Esse desenho não existe neste motor —
     * é um efeito por vez, um pixel de saída por vez, sem buffer que
     * sobrevive de um quadro pro outro. E mesmo que existisse, simulação
     * de física ITERATIVA (posição = velocidade acumulada quadro a quadro)
     * não combina com um editor onde o cursor pula pra qualquer instante
     * — não dá pra "simular só até ali" sem calcular tudo antes.
     *
     * O que dá pra fazer sem nenhuma das duas coisas: pra cada pixel bem
     * perto de trás da fronteira (já devia estar 100% sumido), pergunta
     * "o que tinha um pouco ATRÁS na direção do vento/gravidade?" e mostra
     * aquilo aqui, esmaecendo com a distância — como se aquele pedaço
     * tivesse literalmente voado pra cá. Sem simular nada: pra qualquer
     * instante, a pergunta "o que voou até aqui?" tem resposta direta,
     * então funciona igual parado, tocando ou com o cursor pulando.
     */
    float3 corDaPoeiraVoando = float3(0.0);
    float alfaDaPoeiraVoando = 0.0;
    float idadeVoando = clamp(-distanciaDaBorda, 0.0, ALCANCE_DO_VOO);
    // Direção real do movimento em espaço de TELA — não a versão já
    // multiplicada pela escala do ruído (`deslocMovimento`), que não tem
    // relação direta com distância na tela.
    float2 direcaoDoVoo = eixoVento * u.driftStrength + float2(0.0, u.gravityStrength);
    float forcaDoVoo = length(direcaoDoVoo);
    if (idadeVoando > 0.0 && forcaDoVoo > 0.0001) {
        float2 uvVoo = in.acScreenNorm - (direcaoDoVoo / forcaDoVoo) * idadeVoando * 3.0;
        float4 amostraVoo = inputImg.sample(__nv_smp, clamp(uvVoo, 0.0, 1.0));
        corDaPoeiraVoando = amostraVoo.rgb;
        alfaDaPoeiraVoando = amostraVoo.a * (1.0 - idadeVoando / ALCANCE_DO_VOO) * 0.6;
    }
    mascara = max(mascara, alfaDaPoeiraVoando);

    if (u.invert) mascara = 1.0 - mascara;

    if (u.showMask) {
        __nv_out = float4(float3(mascara), 1.0);
        return __nv_out;
    }

    float3 corSaida = cor.rgb;
    if (alfaDaPoeiraVoando > 0.0) {
        // Nesta faixa quem aparece é a poeira que voou pra cá — não a cor
        // ORIGINAL deste pixel (que já devia estar sumida). Mostrar a cor
        // original ali pareceria um bug ressurgindo, não uma partícula.
        corSaida = corDaPoeiraVoando;
    }

    // Brilho: só bem perto da fronteira visível/sumido — `pow` estreita a
    // faixa que acende, senão vira uma faixa larga em vez de uma linha de
    // borda incandescente.
    float proximidadeDaBorda = pow(clamp(1.0 - abs(mascara * 2.0 - 1.0), 0.0, 1.0), 3.0);
    if (u.glowAmount > 0.0) {
        // Gradiente, não cor única: bem na linha da fronteira usa
        // `u.glowColor` (a mais quente); um pouco ALÉM dela (já no lado que
        // sumiu) esfria pra `u.colorFar`. `distanciaDaBorda` já é negativa
        // desse lado, então `-distanciaDaBorda` cresce indo pra dentro da
        // área dissolvida.
        float t = smoothstep(0.0, max(u.grainSpread, 0.0001) * 2.0, -distanciaDaBorda);
        float3 corDaBorda = mix(u.glowColor.rgb, u.colorFar.rgb, clamp(t, 0.0, 1.0));
        corSaida = mix(corSaida, corDaBorda, proximidadeDaBorda * u.glowAmount);
    }

    // Faíscas: pontos esparsos e brilhantes, só perto da borda, piscando —
    // malha mais grossa que o grão fino, sorteada a cada fração de segundo
    // com o mesmo "quadro quantizado" de `film-grain.xml`.
    if (u.shineAmount > 0.0) {
        float quadroDaFaisca = floor(eng.acTime * 6.0);
        float2 celulaDaFaisca = floor(in.acScreenNorm * eng.acResolution / eng.acEscalaDePixel * 0.12);
        float sorteio = hash21(celulaDaFaisca + quadroDaFaisca * 17.0);
        float achou = step(1.0 - u.shineDensity * 0.06, sorteio);
        corSaida += achou * proximidadeDaBorda * u.shineAmount;
    }

    __nv_out = float4(corSaida, cor.a * mascara);
    return __nv_out;
}
