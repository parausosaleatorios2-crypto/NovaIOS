// ---------------------------------------------------------------------------
// Campo de estrelas
// origem : assets/effects/starfield.xml
// id     : nova.effect.starfield
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct starfieldParams {
    float density;
    float speed;
    int mode;
    float starSize;
    float twinkle;
    float colorVariety;
    float depthLayers;
    float4 starColor;
    float heroDensity;
    float heroSize;
    float heroGlow;
    float heroSpikes;
    float nebula;
    float nebulaScale;
    float4 nebulaWarm;
    float4 nebulaCool;
    float clusters;
    float4 skyColor;
    float angle;
    float starCount3D;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265;

static float3 hash3(float2 c) {
    // Três números de uma célula: onde a estrela fica (x, y) e o quanto ela
    // brilha (z). Um hash só, três usos.
    float3 p = fract(float3(c.xyx) * float3(443.897, 441.423, 437.195));
    p += dot(p, p.yzx + 19.19);
    return fract((p.xxy + p.yzz) * p.zyx);
}

/**
 * A cor de UMA estrela, por temperatura — sorteada à parte do brilho, com o
 * mesmo peso de uma população estelar de verdade: a maioria branca/amarela,
 * poucas azuis, algumas laranja e vermelhas. Antes, a cor vinha só do
 * brilho (fraca = vermelha, forte = azul) e todo céu saía com a MESMA
 * variação — bonito uma vez, monótono na segunda.
 */
static float3 corDaEstrela(float t) {
    float3 azul     = float3(0.66, 0.78, 1.00);
    float3 branca   = float3(1.00, 1.00, 1.00);
    float3 amarela  = float3(1.00, 0.92, 0.70);
    float3 laranja  = float3(1.00, 0.68, 0.40);
    float3 vermelha = float3(1.00, 0.42, 0.32);

    if (t < 0.10) return azul;
    if (t < 0.65) return branca;
    if (t < 0.85) return amarela;
    if (t < 0.95) return laranja;
    return vermelha;
}

/**
 * Uma camada de estrelas, na escala pedida.
 *
 * Olha a célula do pixel e as oito ao redor porque uma estrela perto da borda da
 * célula precisa acender também no vizinho — senão aparece uma grade invisível
 * cortando as estrelas ao meio.
 *
 * `corAcc` recebe a cor de cada estrela já ponderada pelo próprio brilho —
 * quem chama soma as camadas todas e divide pelo brilho total no final, o
 * que dá a média certa nas bordas onde duas estrelas se tocam.
 */
static float camadaDeEstrelas(
    float2 p, float escala, float brilhoMin, float tempo, float peso, inout float3 corAcc,
    // "3D DE VERDADE, NÃO SÓ PARALAXE" (pedido do snow, 26/09/2026, com
    // referência do Alight Motion): as duas contas abaixo são o que faz uma
    // estrela parecer estar se APROXIMANDO, e não só deslizando na mesma
    // distância pra sempre.
    //
    // `perspectiva` cresce a estrela (tamanho E brilho) conforme ela se
    // afasta do centro no modo Atravessar — no esquema log-polar deste
    // efeito, afastar do centro JÁ SIGNIFICA "mais perto da câmera, prestes
    // a sair da tela": sem multiplicar por isso, toda estrela nascia e
    // morria do MESMO tamanho, e a viagem parecia um zoom parado, não um
    // vôo de verdade.
    float perspectiva,
    // `esticar` alonga a estrela num eixo só — o eixo RADIAL, que no
    // esquema log-polar é o eixo Y da própria célula (afastar-se no tempo é
    // andar em Y). Uma estrela rápida vira um RISCO curto na direção de
    // onde ela veio, do jeito que "velocidade de dobra" sempre foi
    // desenhada em qualquer viagem espacial.
    float esticar
) {
    float2 posicao = p * escala;
    float2 celula = floor(posicao);
    float2 dentro = fract(posicao);

    float soma = 0.0;

    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            float2 vizinha = float2(float(x), float(y));
            float3 sorte = hash3(celula + vizinha);

            // A densidade decide se a célula tem estrela. Com 1.0 todas têm.
            if (sorte.z > u.density) continue;

            float2 centro = vizinha + sorte.xy;
            float2 diferenca = float2(dentro.x - centro.x, (dentro.y - centro.y) / esticar);
            float d = length(diferenca);

            // Raio pequeno e queda exponencial: estrela é um ponto com halo, e
            // não um disco. Disco parece bolha de sabão.
            float raio = (0.02 + 0.05 * sorte.z) * u.starSize * perspectiva;
            float ponto = exp(-pow(d / max(raio, 1e-4), 1.6));

            // Cintilação: cada estrela pisca no próprio ritmo e na própria fase,
            // senão o céu inteiro pulsa junto como um pisca-pisca de Natal.
            float ritmo = 2.0 + sorte.x * 6.0;
            float pisca = 1.0 - u.twinkle * 0.5 * (0.5 + 0.5 * sin(tempo * ritmo + sorte.y * 6.28));

            float intensidade = ponto * pisca * mix(brilhoMin, 1.0, sorte.z) * peso
                * clamp(perspectiva, 0.5, 2.0);
            soma += intensidade;

            float semente = hash3(celula + vizinha + float2(7.0, 3.0)).x;
            corAcc += corDaEstrela(semente) * intensidade;
        }
    }

    return soma;
}

/**
 * As estrelas GRANDES e BRILHANTES — uma camada bem mais rala, com um halo
 * largo além do núcleo apertado. É o halo que faz a diferença entre "um
 * ponto maior" e "uma estrela que brilha de verdade", como a alaranjada da
 * foto de referência do snow. `u.heroDensity` em 0 desliga a camada inteira
 * (o `if` sai antes de tocar em `corAcc`) — o padrão de fábrica, para quem
 * já tinha o efeito aplicado não ganhar estrelas novas sem pedir.
 */
static float estrelasBrilhantes(
    float2 p, float escala, float tempo, inout float3 corAcc, float perspectiva, float esticar
) {
    if (u.heroDensity <= 0.0) return 0.0;

    float2 posicao = p * escala;
    float2 celula = floor(posicao);
    float2 dentro = fract(posicao);

    float soma = 0.0;

    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            float2 vizinha = float2(float(x), float(y));
            float3 sorte = hash3(celula + vizinha + float2(31.0, 17.0));

            // ×0,1: no Atravessar a escala é outra — o padrão do Deslizar (0,5) dá aqui
            // as ~0,05 que este modo sempre usou.
            if (sorte.z > u.heroDensity * 0.1) continue;

            float2 centro = vizinha + sorte.xy;
            float2 diferenca = float2(dentro.x - centro.x, (dentro.y - centro.y) / esticar);
            float d = length(diferenca);
            float tamanho = u.heroSize * perspectiva;

            float nucleo = exp(-pow(d / max(0.012 * tamanho, 1e-4), 1.6));
            float halo = exp(-d / max(0.25 * tamanho, 1e-4));

            /*
             * AS ESPIGAS DE DIFRAÇÃO — o "brilho de verdade" pedido com a
             * referência do Alight Motion: um halo redondo lê como "bolha
             * de luz"; o que faz ler como ESTRELA BRILHANDO é o risco fino
             * cruzando o núcleo, como toda foto de estrela tirada com uma
             * lente de verdade (difração na abertura). Quatro raios (duas
             * retas, duas diagonais), cada um decaindo rápido só NAQUELE
             * eixo — e multiplicado por um decaimento radial normal, pra
             * não virar uma cruz atravessando o céu inteiro.
             */
            float ex = abs(diferenca.x);
            float ey = abs(diferenca.y) * esticar; // volta ao eixo real pra não alongar a espiga vertical demais
            float diag1 = abs(diferenca.x - diferenca.y) * 0.70710678;
            float diag2 = abs(diferenca.x + diferenca.y) * 0.70710678;
            float larguraDaEspiga = max(0.0035 * tamanho, 1e-4);
            float espigasRetas = exp(-ex / larguraDaEspiga) + exp(-ey / larguraDaEspiga);
            float espigasDiagonais = exp(-diag1 / larguraDaEspiga) + exp(-diag2 / larguraDaEspiga);
            float alcanceDaEspiga = exp(-d / max(0.9 * tamanho, 1e-4));
            float espigas = (espigasRetas + espigasDiagonais * 0.6) * alcanceDaEspiga * u.heroSpikes;

            float ritmo = 1.0 + sorte.x * 2.0;
            float pisca = 1.0 - u.twinkle * 0.3 * (0.5 + 0.5 * sin(tempo * ritmo + sorte.y * 6.28));

            float intensidade = (nucleo + halo * 0.6 + espigas * 0.5) * u.heroGlow
                * mix(0.6, 1.0, sorte.z) * pisca * clamp(perspectiva, 0.5, 2.2);
            soma += intensidade;

            float semente = hash3(celula + vizinha + float2(53.0, 29.0)).x;
            corAcc += corDaEstrela(semente) * intensidade;
        }
    }

    return soma;
}


// ============================================================================
//  O CÉU PROFUNDO — o "Deslizar" no estilo do vídeo de referência (06/10/2026)
// ============================================================================

static float ruidoDeValor(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    float a = hash3(i).x;
    float b = hash3(i + float2(1.0, 0.0)).x;
    float c = hash3(i + float2(0.0, 1.0)).x;
    float d = hash3(i + float2(1.0, 1.0)).x;
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

/** Ruído fractal: a poeira tem detalhe em toda escala, como fumaça. */
static float fbm(float2 p) {
    float soma = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 5; i++) {
        soma += amp * ruidoDeValor(p);
        p = float2x2(1.6, 1.2, -1.2, 1.6) * p + float2(5.3, 1.7);
        amp *= 0.5;
    }
    return soma;
}

/**
 * A nebulosa: duas manchas de poeira (quente e fria) que quase não aparecem —
 * medido na referência, ela só sobe o fundo de ~1 a ~12 níveis. É o que tira o
 * "preto chapado" e dá o fundo de foto de céu de verdade.
 */
static float3 nebulosa(float2 p) {
    if (u.nebula <= 0.0) return float3(0.0);
    float2 q = p * 5.0 / u.nebulaScale;
    // Onde há poeira: manchas de várias escalas, com vãos escuros entre elas.
    float base = fbm(q);
    float grao = fbm(q * 2.5 + float2(3.0, 9.0));
    float poeira = smoothstep(0.32, 0.78, base * 0.55 + grao * 0.55);
    // De que cor: regiões grandes quentes OU frias — separadas, como na referência,
    // e não misturadas num marrom só.
    float regiao = smoothstep(0.38, 0.62, fbm(q * 0.35 + float2(13.1, 7.7)));
    float3 cor = mix(u.nebulaCool.rgb, u.nebulaWarm.rgb, regiao);
    return cor * poeira * 0.125 * u.nebula;
}

/** A cor de um pontinho comum: quase sempre neutro, de vez em quando com tom. */
static float3 corDoPontinho(float t, float forca) {
    float3 tom = corDaEstrela(t);
    return mix(float3(1.0), tom, (0.25 + 0.75 * u.colorVariety) * forca);
}

/**
 * Uma camada de pontinhos. Uma estrela no máximo por célula e longe da borda dela,
 * então basta olhar a PRÓPRIA célula — barato o bastante para cinco camadas finas.
 * O raio é em unidades de altura, com um piso de ~0,55 px: menor que isso a estrela
 * cairia entre os pixels e piscaria ao andar; com o piso, a energia é conservada
 * (o brilho cai na mesma proporção que a área cresce).
 */
static float3 camadaDePontinhos(float2 p, float celulas, float prob, float brilho, float tam, float px, float semente) {
    float2 q = p * celulas;
    float2 c = floor(q);
    float3 s = hash3(c + semente);
    if (s.z > prob) return float3(0.0);
    float3 s2 = hash3(c + semente + float2(17.0, 41.0));
    float2 centro = 0.18 + 0.64 * s.xy;
    float2 d = (fract(q) - centro) / celulas;
    float b = pow(s2.x, 5.0);
    float r = (0.0006 + 0.0012 * b) * u.starSize * tam;
    float sigma = max(r, 0.55 * px);
    float energia = (r * r) / (sigma * sigma);
    float ponto = exp(-dot(d, d) / (2.0 * sigma * sigma)) * energia;
    float pisca = 1.0 - u.twinkle * 0.7 * (0.5 + 0.5 * sin(eng.acTime * (1.5 + s2.y * 5.0) + s2.z * 6.2831));
    float forca = s2.z < 0.12 ? 1.0 : 0.15;
    return corDoPontinho(s2.y, forca) * ponto * mix(0.13, 1.9, b) * brilho * pisca;
}

/** As estrelas fortes: miolo pequeno de cor saturada e um brilho suave em volta. */
static float3 estrelasFortes(float2 p, float px) {
    if (u.heroDensity <= 0.0) return float3(0.0);
    float celulas = 5.0;
    float2 q = p * celulas;
    float2 c = floor(q);
    float3 soma = float3(0.0);
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            float2 v = c + float2(float(x), float(y));
            float3 s = hash3(v + float2(31.0, 17.0));
            if (s.z > u.heroDensity) continue;
            float3 s2 = hash3(v + float2(53.0, 29.0));
            float2 d = (q - v - s.xy) / celulas;
            float l2 = dot(d, d);
            float r = (0.0019 + 0.0018 * s2.x) * u.heroSize;
            float sigma = max(r, 0.6 * px);
            float miolo = exp(-l2 / (2.0 * sigma * sigma)) * (r * r) / (sigma * sigma);
            float rh = 0.008 * u.heroSize;
            float halo = exp(-l2 / (2.0 * rh * rh)) * 0.28 * u.heroGlow;
            float espigas = 0.0;
            if (u.heroSpikes > 0.0) {
                float l = sqrt(l2);
                float w = max(0.0007 * u.heroSize, 0.5 * px);
                espigas = (exp(-abs(d.x) / w) + exp(-abs(d.y) / w)) * exp(-l / (0.02 * u.heroSize)) * u.heroSpikes * 0.6;
            }
            // Cor: as fortes são as COLORIDAS da referência (laranja, vermelha, azul, branca).
            float t = s2.y;
            float3 cor = t < 0.35 ? float3(1.0, 0.72, 0.36)
                     : t < 0.55 ? float3(1.0, 0.36, 0.28)
                     : t < 0.75 ? float3(0.72, 0.82, 1.0)
                     : float3(1.0, 0.95, 0.88);
            cor = mix(float3(1.0), cor, 0.3 + 0.7 * u.colorVariety);
            float pisca = 1.0 - u.twinkle * 0.3 * (0.5 + 0.5 * sin(eng.acTime * (1.0 + s2.z * 2.0) + s.y * 6.28));
            soma += (cor * miolo * 2.6 + cor * halo + cor * espigas) * mix(0.6, 1.0, s2.z) * pisca;
        }
    }
    return soma;
}

/** Manchinhas difusas: aglomerados e galáxias distantes, cinza-amarronzadas. */
static float3 aglomerados(float2 p) {
    if (u.clusters <= 0.0) return float3(0.0);
    float celulas = 9.0;
    float2 q = p * celulas;
    float2 c = floor(q);
    float3 soma = float3(0.0);
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            float2 v = c + float2(float(x), float(y));
            float3 s = hash3(v + float2(71.0, 3.0));
            if (s.z > 0.10) continue;
            float3 s2 = hash3(v + float2(5.0, 93.0));
            float2 d = (q - v - s.xy) / celulas;
            float r = 0.006 + 0.008 * s2.x;
            float m = exp(-dot(d, d) / (2.0 * r * r));
            float3 cor = mix(float3(0.75, 0.75, 0.78), float3(0.9, 0.7, 0.45), step(0.6, s2.y));
            soma += cor * m * (0.035 + 0.04 * s2.z);
        }
    }
    return soma * u.clusters;
}

/**
 * O céu inteiro do modo Deslizar. `deriva` é o quanto o céu já andou (em alturas);
 * cada camada anda uma fração dela — perto 1, longe ~0,25 —, que é a paralaxe.
 */
static float3 ceuProfundo(float2 centrado, float2 deriva, float px) {
    int camadas = clamp(int(u.depthLayers + 0.5), 2, 5);
    float prob = clamp(u.density * 0.95, 0.0, 1.0);
    float3 cor = float3(0.0);
    for (int i = 0; i < 5; i++) {
        if (i >= camadas) break;
        float fi = float(i);
        float vel = pow(0.62, fi);
        float2 p = centrado + deriva * vel;
        float celulas = 26.0 * pow(1.32, fi);
        float brilho = mix(1.0, 0.55, fi / 4.0);
        float tam = mix(1.35, 0.8, fi / 4.0);
        cor += camadaDePontinhos(p, celulas, prob, brilho, tam, px, fi * 11.0);
        // Uma segunda grade deslocada na mesma camada: tira a regularidade da grade.
        cor += camadaDePontinhos(p + float2(0.37, 0.71) / celulas, celulas * 1.17, prob * 0.6, brilho * 0.8, tam * 0.85, px, fi * 11.0 + 5.0);
    }
    cor += estrelasFortes(centrado + deriva * 0.8, px);
    float2 longe = centrado + deriva * 0.22;
    cor += aglomerados(longe);
    return cor;
}

fragment float4 fx_starfield(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant starfieldParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> particulas3d [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    float3 cor;
    float alfa;

    if (u.mode == 2) {
        /*
         * ATRAVESSAR 3D: as partículas já foram desenhadas, DE VERDADE, num
         * passe à parte (instanciado, com posição própria por vértice) — ver
         * <passes> acima. Aqui só se lê o resultado (já vem com o alfa
         * pré-multiplicado, mesclagem aditiva) e soma sobre o céu, exatamente
         * como o resto deste efeito já compõe camadas de cor.
         */
        float4 estrelas = particulas3d.sample(__nv_smp, in.acScreenNorm);
        float3 neb = nebulosa((in.acScreenNorm - 0.5) * float2(eng.acAspect, 1.0));
        cor = u.skyColor.rgb + neb + estrelas.rgb;
        alfa = clamp(u.skyColor.a + estrelas.a + dot(neb, float3(6.0)), 0.0, 1.0);
    } else if (u.mode == 0) {
        float2 centrado = (in.acScreenNorm - 0.5) * float2(eng.acAspect, 1.0);
        float a = u.angle * PI / 180.0;
        // A velocidade é a da camada de perto, em alturas por segundo.
        float2 deriva = float2(cos(a), sin(a)) * eng.acTime * u.speed * 0.9;
        float px = 1.0 / max(eng.acResolution.y, 1.0);
        float3 neb = nebulosa(centrado + deriva * 0.18);
        float3 estrelas = ceuProfundo(centrado, deriva, px) * u.starColor.rgb * u.starColor.a;
        cor = u.skyColor.rgb + neb + estrelas;
        alfa = clamp(u.skyColor.a + dot(neb, float3(6.0)) + max(estrelas.r, max(estrelas.g, estrelas.b)), 0.0, 1.0);
    } else {
        float2 centrado = (in.acScreenNorm - 0.5) * float2(eng.acAspect, 1.0);
        int camadas = clamp(int(u.depthLayers + 0.5), 2, 5);

        float total = 0.0;
        float3 corAcc = float3(0.0);
        float escala = 8.0;
        float peso = 1.0;

        for (int i = 0; i < 5; i++) {
            if (i >= camadas) break;

            // A camada mais distante anda mais devagar: é disso que a profundidade
            // é feita.
            float distancia = 1.0 / (1.0 + float(i) * 0.9);
            float2 p;
            float perspectiva = 1.0;
            float esticar = 1.0;

            if (u.mode == 1) {
                // Atravessar: a posição é radial, e o tempo EMPURRA para fora com
                // velocidade proporcional à distância do centro.
                float raio = length(centrado) + 1e-4;
                float ang = __nv_atan(centrado.y, centrado.x);
                float avanco = eng.acTime * u.speed * distancia;
                p = float2(ang * 1.2, log(raio) * 1.5 - avanco);

                /*
                 * ================================================================
                 *  "3D DE VERDADE" — A ILUSÃO 2D QUE VEIO ANTES DO "Atravessar 3D"
                 * ================================================================
                 *
                 * No esquema log-polar acima, afastar do centro da tela JÁ
                 * significa "mais perto da câmera, quase saindo do quadro" — é
                 * a mesma matemática que faz o avanço acelerar. Só que o
                 * TAMANHO e o BRILHO de cada estrela nunca liam essa distância:
                 * toda estrela nascia e morria do mesmo jeito, e a viagem
                 * parecia um zoom de imagem parada, não um vôo pelo espaço.
                 *
                 * `perspectiva` cresce a estrela conforme ela se afasta do
                 * centro — perto do centro (recém-nascida, longe) ela é
                 * pequena; perto da borda (prestes a cruzar a tela) ela é
                 * grande, como estrela de verdade passando perto da câmera.
                 *
                 * `esticar` alonga a MESMA estrela no eixo radial conforme ela
                 * anda mais rápido (raio grande × velocidade alta) — o risco de
                 * "velocidade de dobra" de qualquer viagem espacial, sem
                 * simular rastro nenhum: é só a MESMA estrela, esticada num
                 * eixo só, no mesmo quadro.
                 */
                perspectiva = clamp(0.35 + raio * 1.4, 0.35, 3.0);
                esticar = clamp(1.0 + u.speed * distancia * raio * 2.2, 1.0, 7.0);
            } else {
                float a = u.angle * PI / 180.0;
                p = centrado + float2(cos(a), sin(a)) * eng.acTime * u.speed * distancia * 0.35;
            }

            total += camadaDeEstrelas(p, escala, 0.35, eng.acTime, peso, corAcc, perspectiva, esticar);

            // As brilhantes só na camada mais próxima: elas já nascem grandes,
            // e repetir nas outras escalas dobraria/triplicaria o brilho no
            // mesmo ponto da tela.
            if (i == 0) {
                total += estrelasBrilhantes(p, escala * 0.35, eng.acTime, corAcc, perspectiva, esticar);
            }

            escala *= 1.9;
            peso *= 0.75;
        }

        // A cor de cada estrela já foi somada em `corAcc`, ponderada pelo
        // próprio brilho — dividir pelo total dá a média certa nas bordas onde
        // duas estrelas se tocam. `u.colorVariety` mistura com o tom antigo
        // (brilho vira quente/frio) para quem já usava o efeito poder manter o
        // visual de antes em 0, ou pedir a paleta rica em 1.
        float3 quente = float3(1.0, 0.78, 0.62);
        float3 fria = float3(0.72, 0.84, 1.0);
        float3 tomAntigo = mix(quente, fria, clamp(total * 0.8, 0.0, 1.0));
        float3 tomRico = corAcc / max(total, 1e-4);
        float3 tom = mix(tomAntigo, tomRico, u.colorVariety);
        float3 corEstrela = u.starColor.rgb * mix(float3(1.0), tom, 0.35 + 0.5 * u.colorVariety);

        float brilho = clamp(total, 0.0, 1.0) * u.starColor.a;
        float3 neb = nebulosa(centrado);
        cor = mix(u.skyColor.rgb + neb, corEstrela, brilho);
        alfa = max(brilho, clamp(u.skyColor.a + dot(neb, float3(6.0)), 0.0, 1.0));
    }

    float4 desenhado = float4(cor, alfa);
    float saidaAlfa = desenhado.a + original.a * (1.0 - desenhado.a);
    float3 saidaCor = saidaAlfa > 0.0
        ? (desenhado.rgb * desenhado.a + original.rgb * original.a * (1.0 - desenhado.a)) / saidaAlfa
        : float3(0.0);

    __nv_out = float4(saidaCor, saidaAlfa);
    return __nv_out;
}
