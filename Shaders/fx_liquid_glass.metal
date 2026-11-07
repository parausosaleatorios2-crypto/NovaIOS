// ---------------------------------------------------------------------------
// Vidro líquido
// origem : assets/effects/liquid-glass.xml
// id     : nova.effect.liquidglass
// passes : 5
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct liquid_glassParams {
    float depth;
    float thickness;
    int shape;
    int profile;
    float2 center;
    float2 size;
    float radius;
    float rotation;
    int keepLayer;
    float2 size2;
    float2 center2;
    float merge;
    int refractFrom;
    float magnify;
    float spectral;
    float blurAmount;
    float lightAngle;
    float specular;
    float rimLight;
    float4 tintColor;
    float absorb;
    float4 shadowColor;
    float shadowDist;
    float ior;
    float edgeBlur;
    float fresnel;
    float specularSharp;
    float oppositeLobe;
    float innerShadow;
    float shadowSoft;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265;

// Pesos de uma gaussiana de 9 amostras, somando 1.
const float PESOS[5] = float[5](
    0.2270270270, 0.1945945946, 0.1216216216, 0.0540540541, 0.0162162162
);

// Espaço "altura": X multiplicado pelo aspecto, então distância é fração da
// ALTURA e nada estica numa composição que não é quadrada.
static float2 paraAltura(float2 uv) { return float2(uv.x * eng.acAspect, uv.y); }
static float2 paraUv(float2 ph) { return float2(ph.x / max(eng.acAspect, 1e-4), ph.y); }

static float2 girar(float2 v, float graus) {
    float a = graus * PI / 180.0;
    float c = cos(a);
    float s = sin(a);
    return float2(v.x * c - v.y * s, v.x * s + v.y * c);
}

/**
 * SDF da caixa arredondada — a forma de Inigo Quilez. Ela é exata: o valor é a
 * distância de verdade, o que faz a banda da borda ter largura uniforme
 * inclusive nos cantos.
 */
static float sdCaixa(float2 p, float2 meia, float r) {
    float2 q = abs(p) - meia + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

/**
 * Mínimo SUAVE — a fusão das gotas.
 *
 * O mínimo comum de duas distâncias dá a união das formas, e a união tem bico na
 * junção. O mínimo suave arredonda essa junção num raio `k`, que é o que a
 * tensão superficial faz quando duas gotas encostam.
 */
static float sminSuave(float a, float b, float k) {
    if (k <= 1e-4) return min(a, b);
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

/**
 * O alfa da camada, com o DE FORA valendo ZERO.
 *
 * A amostragem presa na borda devolve o pixel da beirada quando se lê fora do
 * quadro, e para uma camada que preenche o quadro inteiro isso daria alfa 1 em
 * toda a volta: silhueta nenhuma, vidro sem beirada — e placa sem beirada não se
 * lê como vidro, porque é justamente ali que o Fresnel acende.
 *
 * Com o de fora valendo zero, a MOLDURA da camada vira a silhueta, que é o que
 * "o formato da camada" quer dizer quando o formato é o retângulo cheio.
 */
static float alfaEm(float2 uv) {
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) return 0.0;
    return inputImg.sample(__nv_smp, uv).a;
}

/** O menor "raio interno" da forma: até onde dá para afundar antes do meio. */
static float raioInterno() {
    float2 meia = max(u.size * float2(eng.acAspect, 1.0) * 0.5, float2(1e-4));
    float menor = min(meia.x, meia.y);
    if (u.size2.x > 0.0 && u.size2.y > 0.0) {
        float2 meia2 = max(u.size2 * float2(eng.acAspect, 1.0) * 0.5, float2(1e-4));
        menor = min(menor, min(meia2.x, meia2.y));
    }
    return menor;
}

/**
 * A largura da banda do chanfro, LIMITADA PELA FORMA.
 *
 * "Largura do chanfro" é uma distância absoluta, e a placa tem o tamanho que
 * tem. Numa composição 9:16, uma placa de 33% da largura tem meia-largura de
 * 0,09 — menos que os 0,07 do padrão. Sem limite, o chanfro cobria a placa
 * inteira: em vez de uma janela com a borda entortando, uma bola de vidro que ia
 * buscar pixel tão longe que repetia a borda da imagem.
 *
 * Com o teto de 45% do raio interno sempre sobra meio da placa plano — que é o
 * que faz o olho ler "janela".
 */
static float bandaLente() {
    float pedida = max(u.thickness, 1e-4);
    if (u.shape == 1) return pedida;
    return min(pedida, 0.45 * raioInterno());
}

/** Distância com sinal até a silhueta do vidro. Negativa dentro. */
static float silhueta(float2 ph) {
    if (u.shape == 1) {
        float banda = bandaLente();
        float a0 = alfaEm(paraUv(ph));
        if (a0 > 0.0) return (0.5 - a0) * banda * 2.0;

        /*
         * SEM ALFA NENHUM AQUI — MAS ISSO NÃO DIZ SE ESTÁ PERTO OU LONGE.
         *
         * Sem olhar em volta, todo ponto de fora (alfa 0) devolvia a MESMA
         * distância fixa — a própria banda —, não importa se era um pixel ao
         * lado da estrela ou o canto oposto da composição. A sombra ("Distância
         * da sombra") compara essa distância com uma maciez bem menor que a
         * banda, e com a mesma distância em toda parte, a comparação dava o
         * MESMO resultado em toda parte: a sombra pintava a composição inteira
         * por igual, sempre que a Largura do chanfro ficasse pequena — o
         * relato do snow, com print (uma estrela pequena escurecendo a cena
         * toda).
         *
         * Uma coroa de amostras, bem mais larga que a da normal ([formaEm]),
         * resolve: se alguma delas encontra alfa, este ponto está perto da
         * beirada de verdade (devolve a banda, como antes). Se nenhuma
         * encontra, está longe de qualquer jeito plausível de sombra — e "0,5"
         * é maior que qualquer maciez de sombra que o painel permite (até
         * 0,25), então a sombra nunca mais confunde "longe" com "na beirada".
         */
        float largo = max(banda * 3.0, 0.03);
        for (int i = 0; i < 8; i++) {
            float ang = float(i) * 0.78539816;
            float2 dir = float2(cos(ang), sin(ang));
            if (alfaEm(paraUv(ph + dir * largo)) > 0.0) return banda;
        }
        return 0.5;
    }

    float2 meia = max(u.size * float2(eng.acAspect, 1.0) * 0.5, float2(1e-4));
    float r = min(max(u.radius, 0.0), min(meia.x, meia.y));
    float2 rel = girar(ph - paraAltura(u.center), -u.rotation);
    float d = sdCaixa(rel, meia, r);

    if (u.size2.x > 0.0 && u.size2.y > 0.0) {
        float2 meia2 = max(u.size2 * float2(eng.acAspect, 1.0) * 0.5, float2(1e-4));
        float r2 = min(max(u.radius, 0.0), min(meia2.x, meia2.y));
        float2 rel2 = girar(ph - paraAltura(u.center2), -u.rotation);
        d = sminSuave(d, sdCaixa(rel2, meia2, r2), u.merge);
    }

    return d;
}

/**
 * A distância E a direção da borda no mesmo ponto: `float3(d, n.x, n.y)`.
 *
 * Para a caixa arredondada, a direção sai de diferenças finitas — aritmética
 * pura, de graça. Para a silhueta vinda do ALFA, cada avaliação é uma leitura de
 * textura, e o alfa é praticamente um degrau: medir assim daria inclinação zero
 * em quase toda parte e enorme em cima da borda.
 *
 * Uma COROA de oito amostras resolve as duas coisas de uma vez — a média dá uma
 * rampa suave, a soma vetorial dá para onde ela cresce. E de brinde, no meio da
 * forma as amostras dão todas 1: a rampa satura e o chanfro se apaga sozinho.
 */
static float3 formaEm(float2 ph) {
    float banda = bandaLente();

    if (u.shape == 1) {
        float raio = max(banda * 0.6, 0.002);
        float media = alfaEm(paraUv(ph)) * 0.2;
        float2 soma = float2(0.0);

        for (int i = 0; i < 8; i++) {
            float ang = float(i) * 0.78539816;
            float2 dir = float2(cos(ang), sin(ang));
            float a = alfaEm(paraUv(ph + dir * raio));
            media += a * 0.1;
            // O alfa cresce para DENTRO e a distância cresce para FORA: o sinal
            // menos é o que faz a normal apontar para fora da placa.
            soma -= dir * a;
        }

        float comp = length(soma);
        return float3(
            (0.5 - media) * banda * 2.0,
            comp > 1e-5 ? soma / comp : float2(0.0, -1.0)
        );
    }

    float passo = max(banda * 0.25, 0.002);
    float d = silhueta(ph);
    float dx = silhueta(ph + float2(passo, 0.0)) - silhueta(ph - float2(passo, 0.0));
    float dy = silhueta(ph + float2(0.0, passo)) - silhueta(ph - float2(0.0, passo));
    float2 g = float2(dx, dy);
    float comp = length(g);
    return float3(d, comp > 1e-6 ? g / comp : float2(0.0, -1.0));
}

/**
 * Borrão de nove amostras numa direção.
 *
 * As cores entram MULTIPLICADAS pelo alfa e saem divididas de volta: num pixel
 * transparente o RGB não quer dizer nada, e misturá-lo junto puxaria a borda do
 * vidro para preto.
 */
static float4 borrar(sampler2D tex, float2 uv, float2 passo) {
    float4 c = tex.sample(__nv_smp, uv);
    float3 soma = c.rgb * c.a * PESOS[0];
    float peso = c.a * PESOS[0];

    for (int i = 1; i < 5; i++) {
        float2 salto = passo * float(i);

        float4 a = tex.sample(__nv_smp, uv + salto);
        soma += a.rgb * a.a * PESOS[i];
        peso += a.a * PESOS[i];

        float4 b = tex.sample(__nv_smp, uv - salto);
        soma += b.rgb * b.a * PESOS[i];
        peso += b.a * PESOS[i];
    }

    return float4(soma / max(peso, 1e-4), clamp(peso, 0.0, 1.0));
}

static float4 sobre(float4 baixo, float4 cima) {
    float a = cima.a + baixo.a * (1.0 - cima.a);
    if (a <= 0.0) return float4(0.0);
    float3 rgb = (cima.rgb * cima.a + baixo.rgb * baixo.a * (1.0 - cima.a)) / a;
    return float4(rgb, a);
}

/**
 * O que está atrás do vidro, com queda automática.
 *
 * Fundo VAZIO naquele ponto — camada de baixo de tudo, projeto transparente —
 * refratado daria uma placa preta. Cair na própria camada mostra vidro em vez de
 * um buraco.
 */
static float4 fundoNitido(float2 uv) {
    if (u.refractFrom == 0) return inputImg.sample(__nv_smp, uv);

    /*
     * ========================================================================
     *  O FUNDO MORA NA TELA, A CAMADA NÃO
     * ========================================================================
     *
     * `in.acScreenNorm` é a coordenada do buffer DESTA camada, de antes de ela ser
     * movida, girada e escalada. `backdropImg` é a cena montada por baixo, já na
     * tela. Enquanto a camada está parada os dois coincidem — e foi por isso que
     * este defeito passou tanto tempo escondido.
     *
     * Movida a camada, o vidro passava a refratar um pedaço do fundo que não é o
     * que está atrás dele. O relato veio com print: a placa mostrando uma parte
     * da imagem que não tinha nada a ver com o lugar onde ela estava.
     *
     * `__nv_acTela()` é a ponte, montada por camada em `LayerGeometry`.
     */
    float2 naTela = __nv_acTela(uv);
    if (naTela.x < 0.0 || naTela.x > 1.0 || naTela.y < 0.0 || naTela.y > 1.0) {
        return inputImg.sample(__nv_smp, uv);
    }

    float4 b = backdropImg.sample(__nv_smp, naTela);
    return b.a < 0.01 ? inputImg.sample(__nv_smp, uv) : b;
}

/** Uma amostra do que o vidro atravessa, já misturando nítido com embaçado. */
static float3 atras(float2 uv, float fosco) {
    return mix(fundoNitido(uv).rgb, blurD.sample(__nv_smp, uv).rgb, clamp(fosco, 0.0, 1.0));
}

/**
 * O deslocamento da AMPLIAÇÃO.
 *
 * Puxa a amostra para o centro da placa: quanto mais perto do centro se lê, mais
 * o pedaço de fundo ocupa a tela — que é o que ampliar quer dizer.
 *
 * Multiplicado pela altura do perfil, então ele é máximo no meio (onde a lente é
 * grossa) e some na beirada, onde quem manda é a refração de Snell. As duas
 * contas se somam em vez de brigar.
 */
static float2 ampliar(float2 uv, float alturaRel) {
    if (u.magnify <= 0.001) return float2(0.0);
    return (uv - u.center) * (-u.magnify) * alturaRel;
}

/**
 * O perfil da superfície: altura relativa (0..1) e a inclinação dela.
 *
 * `x` é a altura, `y` é `d(altura)/d(distância)` — a inclinação, que é o que
 * vira normal. Os dois saem da mesma fórmula porque a derivada aqui é
 * analítica: medir a inclinação por diferenças finitas custaria mais avaliações
 * e daria ruído justamente na beirada, onde ela importa.
 */
static float2 perfilEm(float d, float banda) {
    // Plano: laje de faces paralelas. Só a parede lateral entorta, e ela é fina
    // demais para aparecer — serve para quem quer só o fosco e a cor.
    if (u.profile == 2) return float2(1.0, 0.0);

    // Domo mede pelo raio interno (curva a placa inteira); chanfro mede pela
    // banda (curva só a beirada).
    float alcance = u.profile == 1 ? max(raioInterno(), 1e-4) : banda;

    float u = clamp(-d / alcance, 0.0, 1.0);
    float um = 1.0 - u;
    float alt = sqrt(max(1.0 - um * um, 0.0));

    // d(alt)/du = (1-u)/alt, e du/dd = -1/alcance.
    float inclinacao = -(um / max(alt, 1e-3)) / alcance;
    return float2(alt, inclinacao);
}

/** Fresnel de Schlick: quanto reflete, dado o cosseno do ângulo de visão. */
static float schlick(float coseno, float indice) {
    float f0 = (1.0 - indice) / (1.0 + indice);
    f0 *= f0;
    return f0 + (1.0 - f0) * pow(clamp(1.0 - coseno, 0.0, 1.0), 5.0);
}

/**
 * Para onde o raio sai, depois de entortar na entrada e atravessar o vidro.
 *
 * `refract` devolve zero quando o ângulo passa do limite — reflexão interna
 * total. Aí não há travessia, e quem chama trata o ponto como reflexo puro.
 */
static float2 travessia(float3 normal, float indice, float espessuraLocal, out bool refletiu) {
    float3 entrada = float3(0.0, 0.0, -1.0);
    float3 raio = refract(entrada, normal, 1.0 / max(indice, 1.0001));

    refletiu = dot(raio, raio) < 1e-6 || raio.z > -1e-3;
    if (refletiu) return float2(0.0);

    // Anda até sair pela face de baixo. `-raio.z` é o avanço em profundidade por
    // unidade de caminho; o resto é regra de três.
    return raio.xy * (espessuraLocal / max(-raio.z, 0.02));
}

/**
 * O fosco da beirada. No painel há um "Fosco" só: abaixo do padrão dele (0,22)
 * ele apaga o da beirada junto, e em zero o vidro fica limpo de verdade.
 */
static float foscoDaBorda() {
    return u.edgeBlur * clamp(u.blurAmount / 0.22, 0.0, 1.0);
}

fragment float4 fx_liquid_glass(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant liquid_glassParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> backdropImg [[texture(1)]],
    texture2d<float> blurA [[texture(2)]],
    texture2d<float> blurB [[texture(3)]],
    texture2d<float> blurC [[texture(4)]],
    texture2d<float> blurD [[texture(5)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    // O quanto o borrão se espalha, em fração da altura.
    float espalha = 0.003 + 0.035 * u.blurAmount;
    float largo = espalha * 2.6;

    if (eng.acPass < 4) {
        // Fosco desligado: os quatro passes viram cópia. Sair aqui pula 36
        // leituras de textura que não mudariam nada.
        if (u.blurAmount <= 0.002 && foscoDaBorda() <= 0.002) {
            if (eng.acPass == 0) {
                __nv_out = fundoNitido(in.acScreenNorm);
            } else if (eng.acPass == 1) {
                __nv_out = blurA.sample(__nv_smp, in.acScreenNorm);
            } else if (eng.acPass == 2) {
                __nv_out = blurB.sample(__nv_smp, in.acScreenNorm);
            } else {
                __nv_out = blurC.sample(__nv_smp, in.acScreenNorm);
            }
            return __nv_out;
        }

        if (eng.acPass == 0) {
            float2 passo = float2(espalha / max(eng.acAspect, 1e-4), 0.0);
            // O fundo é lido pela UV da TELA (ver `fundoNitido`); o borrão
            // resultante fica guardado na UV da CAMADA, que é como os passes
            // seguintes e o vidro o leem.
            float2 naTela = __nv_acTela(in.acScreenNorm);
            float4 b = backdropImg.sample(__nv_smp, naTela);
            __nv_out = (u.refractFrom == 1 && b.a >= 0.01)
                ? borrar(backdropImg, naTela, passo)
                : borrar(inputImg, in.acScreenNorm, passo);
        } else if (eng.acPass == 1) {
            __nv_out = borrar(blurA, in.acScreenNorm, float2(0.0, espalha));
        } else if (eng.acPass == 2) {
            __nv_out = borrar(blurB, in.acScreenNorm, float2(largo / max(eng.acAspect, 1e-4), 0.0));
        } else {
            __nv_out = borrar(blurC, in.acScreenNorm, float2(0.0, largo));
        }
        return __nv_out;
    }

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);
    float2 ph = paraAltura(in.acScreenNorm);
    float aa = 1.5 / max(eng.acResolution.y, 1.0);

    float3 forma = formaEm(ph);
    float d = forma.x;
    float2 n2d = forma.yz;
    float dentro = 1.0 - smoothstep(-aa, aa, d);

    // ---------------------------------------------------- superfície e normal
    float banda = bandaLente();
    float2 perfil = perfilEm(d, banda);
    float alturaRel = perfil.x;
    float espessuraLocal = max(u.depth * alturaRel, 1e-4);

    // A inclinação vira o vetor normal em 3D. O teto de 8 existe porque, na
    // beirada exata, a superfície é vertical e a derivada vai ao infinito — e um
    // infinito aqui viraria NaN espalhado pela borda inteira.
    float inclina = clamp(-perfil.y * u.depth, -8.0, 8.0);
    float3 normal = normalize(float3(inclina * n2d, 1.0));

    float fosco = clamp(u.blurAmount + foscoDaBorda() * (1.0 - alturaRel), 0.0, 1.0);

    // ------------------------------------------------------------- travessia
    //
    // Um índice por canal: vidro entorta o azul mais que o vermelho, e é isso
    // que faz a franja colorida na beirada de qualquer lente.
    float leque = u.spectral * 0.06;
    bool tirR;
    bool tirG;
    bool tirB;
    float2 offR = travessia(normal, u.ior * (1.0 - leque), espessuraLocal, tirR);
    float2 offG = travessia(normal, u.ior, espessuraLocal, tirG);
    float2 offB = travessia(normal, u.ior * (1.0 + leque), espessuraLocal, tirB);

    float2 lente = ampliar(in.acScreenNorm, alturaRel);

    float3 atravessado = float3(
        atras(in.acScreenNorm + paraUv(offR) + lente, fosco).r,
        atras(in.acScreenNorm + paraUv(offG) + lente, fosco).g,
        atras(in.acScreenNorm + paraUv(offB) + lente, fosco).b
    );

    // ------------------------------------------------------------- absorção
    //
    // Lei de Beer: o que atravessa perde cor conforme o CAMINHO andado dentro do
    // vidro. É por isso que a beirada de um vidro grosso é mais verde que o meio
    // — e é o que dá impressão de material, e não de película.
    float caminho = length(float2(length(offG), espessuraLocal)) / max(u.depth, 1e-4);
    float3 perda = exp(-u.absorb * caminho * (1.0 - clamp(u.tintColor.rgb, 0.0, 1.0)));
    atravessado *= perda;

    // -------------------------------------------------------------- reflexo
    //
    // Sem mapa de ambiente, o próprio fundo faz as vezes: espelhado pela normal
    // e lido do borrão. Reflexo é quase sempre menos nítido que a travessia,
    // então a versão embaçada aproxima bem.
    float3 espelhado = reflect(float3(0.0, 0.0, -1.0), normal);
    float2 uvRefl = in.acScreenNorm - paraUv(espelhado.xy * u.depth * 2.0);
    float3 refletido = blurD.sample(__nv_smp, uvRefl).rgb;

    float f = clamp(schlick(clamp(normal.z, 0.0, 1.0), u.ior) * u.fresnel, 0.0, 1.0);

    // Reflexão interna total: o raio não atravessou, então o que se vê ali é
    // reflexo puro. É a beirada espelhada que todo vidro grosso tem.
    if (tirG) f = max(f, 0.9);

    float3 cor = mix(atravessado, refletido, f);

    // ------------------------------------------------------------- especular
    //
    // O ponto de luz, que nenhum reflexo de fundo dá: o brilho da fonte em si.
    // Dois lobos — o do lado da luz e o da parede oposta, que é o que sugere
    // espessura.
    //
    // A LUZ É RASANTE (z baixo), e isso não é gosto: é o que separa vidro de
    // plástico brilhante. Com a luz de frente, o meio-vetor fica quase colado no
    // eixo, e a parte PLANA da placa — que é a maior parte dela — acende
    // inteira. O resultado é uma pastilha leitosa. Rasante, o brilho só aparece
    // onde a superfície se inclina para a luz: a beirada.
    float2 luz2 = float2(cos(u.lightAngle * PI / 180.0), -sin(u.lightAngle * PI / 180.0));
    float3 luz = normalize(float3(luz2 * 1.6, 0.42));
    float3 meio = normalize(luz + float3(0.0, 0.0, 1.0));
    float brilho = pow(max(dot(normal, meio), 0.0), max(u.specularSharp, 1.0)) * u.specular;

    float3 luzOposta = normalize(float3(-luz2 * 1.6, 0.42));
    float3 meioOposto = normalize(luzOposta + float3(0.0, 0.0, 1.0));
    float oposto = pow(max(dot(normal, meioOposto), 0.0), max(u.specularSharp, 1.0)) *
                   u.specular * u.oppositeLobe;

    cor += brilho + oposto;

    /*
     * ========================================================================
     *  A BEIRADA ACESA E A SOMBRA INTERNA
     * ========================================================================
     *
     * As duas usam a mesma faixa exponencial medida a partir da borda para
     * dentro, e a mesma normal 2D para saber de que lado está a luz:
     *
     *  - a beirada acende em toda a volta, e mais forte onde ela encara a luz;
     *  - a sombra escurece o lado oposto, onde a parede lateral tapa a luz
     *    rasante.
     *
     * Exponencial e não `smoothstep` de propósito: ela cai rápido e nunca chega
     * a zero, que é como luz presa dentro de um material se comporta — dá o
     * gradiente macio que uma banda dura não dá.
     */
    float dentroDaBorda = max(-d, 0.0);

    if (u.rimLight > 0.001) {
        float faixa = exp(-dentroDaBorda / max(banda * 0.35, 1e-4));
        float encaraALuz = clamp(dot(n2d, luz2), 0.0, 1.0);
        cor += faixa * u.rimLight * (0.35 + 0.65 * encaraALuz) * u.tintColor.rgb;
    }

    if (u.innerShadow > 0.001) {
        float faixa = exp(-dentroDaBorda / max(banda * 0.8, 1e-4));
        float deCostas = clamp(-dot(n2d, luz2), 0.0, 1.0);
        cor *= 1.0 - faixa * deCostas * u.innerShadow;
    }

    // ---------------------------------------------------------------- sombra
    float dSombra = silhueta(ph + luz2 * u.shadowDist);
    float sombra = (1.0 - smoothstep(0.0, max(u.shadowSoft, 1e-3), dSombra)) *
                   u.shadowColor.a * (1.0 - dentro);

    float4 base = u.keepLayer ? original : float4(original.rgb, 0.0);
    float4 saida = sobre(base, float4(u.shadowColor.rgb, sombra));
    __nv_out = sobre(saida, float4(cor, dentro));
    return __nv_out;
}
