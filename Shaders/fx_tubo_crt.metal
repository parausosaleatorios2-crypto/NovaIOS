// ---------------------------------------------------------------------------
// Tubo de imagem
// origem : assets/effects/tubo-crt.xml
// id     : nova.effect.tubocrt
// passes : 6
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct tubo_crtParams {
    int formatoDaTela;
    float forcaDaMascara;
    float pontoDeTela;
    float linhas;
    float curvatura;
    float tremida;
    float instabilidade;
    float forcaDoBrilho;
    float raioDoBrilho;
    float corte;
    float deslocamento;
    float brilhoDoVidro;
    float forcaDoReflexo;
    float escalaDoReflexo;
    float4 corDaTela;
    float saturacao;
    float vinheta;
    float2 centro;
    float varredura;
    float posterizar;
    float suavidadeDoCorte;
    float4 corDoBrilho;
    float4 corDoHaloLargo;
    float foco;
    float anguloDaAberracao;
    int espelharReflexo;
    float gama;
    float tonemap;
};

// --- funcoes auxiliares do efeito
// ============================================================================
//  FERRAMENTAS
// ============================================================================

const float TAU = 6.28318530718;

/** Disco de Vogel: pontos espalhados por ângulo dourado, sem aglomerar. */
float2 vogel(int i, int total, float giro) {
    float dourado = 2.39996323;
    float r = sqrt(float(i) + 0.5) / sqrt(float(total));
    float a = float(i) * dourado + giro;
    return r * float2(cos(a), sin(a));
}

/** Ruído barato e determinístico, de 0 a 1. */
float ruido(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

/** Dois ruídos de uma vez, para deslocar em X e Y. */
float2 ruido2(float2 p) {
    return float2(ruido(p), ruido(p + 37.19));
}

/**
 * A OSCILAÇÃO DA ALTA TENSÃO.
 *
 * Três senos de frequências bem diferentes somados — o truque clássico para ter
 * algo que parece aleatório sem textura de ruído e sem estado. Some rápido, mas
 * nunca repete de um jeito que o olho perceba, porque as três frequências não
 * são múltiplas entre si.
 */
float tremorDaFonte(float t) {
    return sin(t * 99.542) * 0.5 + sin(t * 26.523) * 0.3 + sin(t * 9.802) * 0.2;
}

/**
 * O VIDRO É CURVO.
 *
 * A UV é empurrada para fora proporcionalmente ao quadrado da distância ao
 * u.centro — é o estufamento de uma superfície esférica vista de frente. O eixo X
 * é corrigido pela proporção antes da conta, senão um vídeo deitado estufaria
 * mais na largura que na altura.
 */
float2 curvar(float2 uv) {
    float2 p = uv - u.centro;
    p.x *= eng.acAspect;
    float d = dot(p, p);
    p *= 1.0 + u.curvatura * d * 0.75;
    p.x /= eng.acAspect;
    return u.centro + p;
}

/**
 * ============================================================================
 *  A MÁSCARA DE SOMBRA
 * ============================================================================
 *
 * A tela é dividida em células do tamanho de um fósforo. Cada célula acende UM
 * canal (R, G ou B) — quem decide é a posição dela na grade, e o arranjo muda
 * com o formato escolhido.
 *
 * Duas coisas fazem isto parecer tubo em vez de grade desenhada por cima:
 *
 *  - **a cor vem do CENTRO da célula**, e não do pixel. É o que faz a imagem
 *    virar fósforo de verdade: dentro de um fósforo não há detalhe, ele é uma
 *    coisa só acesa;
 *  - **o fósforo tem forma**, e o `preenchimento` decide o quanto ele enche a
 *    célula. Baixo, sobra preto em volta e a grade aparece; alto, os fósforos
 *    se encostam e a máscara quase some.
 *
 * O `* 3.0` compensa a energia: como cada célula acende só um dos três canais,
 * sem ele a tela sairia com um terço do brilho.
 */
float4 fosforos(float2 uv) {
    float lado = max(1.0, u.pontoDeTela);
    float2 celulas = eng.acResolution / lado;
    float2 gradeUV = uv * celulas;
    float2 indice = floor(gradeUV);

    /*
     * A INSTABILIDADE, PARTE 1: O FÓSFORO SAI DO LUGAR.
     *
     * Cada célula sorteia um u.deslocamento próprio, refeito algumas vezes por
     * segundo (o `floor(eng.acTime * 18)` é o que segura o sorteio por um tempo —
     * sem ele o ruído troca a cada quadro e vira chiado de TV sem sinal).
     *
     * E a FILEIRA inteira escorrega junto, com um ruído só dela: é o
     * "tracking" tremendo, que é o que mais lembra fita e tubo velho.
     */
    float2 desvio = float2(0.0);
    if (u.instabilidade > 0.001) {
        float quadro = floor(eng.acTime * 18.0);
        float2 sorteio = ruido2(indice + quadro) - 0.5;
        float fileira = ruido(float2(indice.y, quadro)) - 0.5;
        desvio = (sorteio * 0.6 + float2(fileira, 0.0)) * u.instabilidade / celulas;
    }

    // A cor do fósforo inteiro: uma amostra no u.centro da célula. É o que faz a
    // imagem virar fósforo em vez de ganhar uma grade por cima — dentro de um
    // fósforo não há detalhe, ele é uma coisa só acesa.
    float2 centroDaCelula = (indice + 0.5) / celulas + desvio;
    float4 fonte = inputImg.sample(__nv_smp, clamp(centroDaCelula, 0.0, 1.0));

    if (u.formatoDaTela == 0 || u.forcaDaMascara <= 0.001) return fonte;

    int canal;
    if (u.formatoDaTela == 1) {
        canal = int(__nv_mod(indice.x, 3.0));                       // tiras verticais
    } else if (u.formatoDaTela == 2) {
        canal = int(__nv_mod(indice.y, 3.0));                       // tiras horizontais
    } else if (u.formatoDaTela == 3) {
        canal = int(__nv_mod(indice.x + indice.y, 3.0));            // pontos em diagonal
    } else {
        // Alvenaria: cada fileira anda meia célula, como tijolo.
        canal = int(__nv_mod(indice.x + floor(indice.y * 0.5), 3.0));
    }

    /*
     * ========================================================================
     *  A MÁSCARA ESCURECE OS VIZINHOS — ELA NÃO APAGA A IMAGEM
     * ========================================================================
     *
     * A primeira versão multiplicava a cor por uma máscara que nascia em ZERO:
     * cada célula acendia um canal e matava os outros dois. Simulei antes de
     * mandar, e o resultado foi este — a imagem vira confete de RGB, o branco
     * some e a tela perde metade do brilho.
     *
     * O certo é a máscara ser uma MODULAÇÃO: o canal da célula fica cheio, os
     * outros caem até `1 - força`. Com força 0 não há máscara; com 1 é o tubo
     * cru visto de perto.
     *
     * O ganho recompõe o brilho: com força 1, a média de energia cai para um
     * terço, então multiplica-se por três. A conta é `3/(1+2(1-força))`, que
     * vale 1 sem máscara e 3 na máscara cheia — a tela não muda de brilho quando
     * se mexe no controle, que é o mínimo que um controle deve prometer.
     */
    float fundo = 1.0 - clamp(u.forcaDaMascara, 0.0, 1.0);
    float3 mascara = float3(fundo);
    if (canal == 0) mascara.r = 1.0;
    else if (canal == 1) mascara.g = 1.0;
    else mascara.b = 1.0;

    float ganho = 3.0 / (1.0 + 2.0 * fundo);

    // A forma do fósforo dentro da célula: mais aceso no meio, apagando para a
    // borda. Sem isso a máscara vira listra de cor chapada, que lê como filtro,
    // não como fósforo.
    float2 local = fract(gradeUV) * 2.0 - 1.0;

    /*
     * A FORMA DO FÓSFORO — e ela muda com o tipo de máscara.
     *
     * Grade de abertura (as tiras) tem fósforo COMPRIDO: ele só apaga para os
     * lados, e por isso a queda olha só o eixo X. Máscara de sombra (os pontos)
     * tem fósforo REDONDO, que apaga em todas as direções — é a diferença
     * visível entre um Trinitron e uma TV comum, e vale reproduzir.
     */
    float distancia;
    if (u.formatoDaTela == 1) {
        distancia = local.x * local.x;                 // tiras verticais
    } else if (u.formatoDaTela == 2) {
        distancia = local.y * local.y;                 // tiras horizontais
    } else {
        distancia = clamp(dot(local, local), 0.0, 1.0); // pontos e alvenaria
    }
    float queda = (u.formatoDaTela >= 3) ? 0.75 : 0.45;
    float forma = 1.0 - queda * distancia * u.forcaDaMascara;

    /*
     * AS LINHAS DE VARREDURA, que são outra coisa.
     *
     * A máscara é vertical (os trios); a linha é horizontal (as passadas do
     * feixe). Num tubo de verdade as duas coexistem, e é a soma delas que dá a
     * textura característica. A linha anda a cada DOIS fósforos: uma acesa, uma
     * apagada.
     */
    float linha = 1.0;
    if (u.linhas > 0.001) {
        float faixaY = __nv_mod(floor(gradeUV.y), 2.0);
        linha = mix(1.0, 1.0 - u.linhas, faixaY);
        // Compensa o escurecimento médio das u.linhas, pelo mesmo motivo do ganho:
        // metade das fileiras cai para (1-u.linhas), então a média é 1 - u.linhas/2.
        linha *= 2.0 / (2.0 - u.linhas);
    }

    // O ALFA NÃO ENTRA NA MÁSCARA, de propósito. Furar o alfa de acordo com a
    // grade transformaria a camada numa tela de mosquiteiro — a imagem
    // apareceria recortada sobre o que estiver embaixo. O fósforo modula LUZ,
    // e luz é cor.
    return float4(fonte.rgb * mascara * ganho * forma * linha, fonte.a);
}

/**
 * A FAIXA DE VARREDURA.
 *
 * Dente de serra com rampa trapezoidal — sobe rápido, segura, desce rápido —, e
 * não um seno: o feixe de um tubo não oscila suave, ele varre e volta. Com um
 * seno a faixa fica com cara de "brilho pulsando", que é outra coisa.
 */
float varrer(float2 uv) {
    if (u.tremida <= 0.001) return 1.0;
    float faixa = fract(uv.x * 0.2 - eng.acTime * u.varredura + uv.y * 1.2);
    float trapezio = min(faixa * 2.0, 1.0) - max(0.0, (faixa - 0.95) * 20.0);
    return mix(1.0, trapezio, clamp(u.tremida, 0.0, 1.0));
}

/**
 * ============================================================================
 *  ABERRAÇÃO CROMÁTICA
 * ============================================================================
 *
 * Os três canais são lidos em posições diferentes ao longo da MESMA reta. É o
 * que o vidro grosso de um tubo faz: ele não separa as cores em anel (isso é
 * lente de câmera), separa numa direção.
 *
 * O verde fica parado e vermelho e azul andam para lados opostos — é o arranjo
 * que mantém a imagem no lugar. Separar os três para o mesmo lado deslocaria a
 * cena inteira, e aí seria mais fácil mover a camada.
 */
float4 comAberracao(float2 uv) {
    float4 base = tela.sample(__nv_smp, clamp(uv, 0.0, 1.0));
    if (u.deslocamento <= 0.001) return base;

    float rad = radians(u.anguloDaAberracao);
    float2 direcao = float2(cos(rad), sin(rad) * eng.acAspect) * eng.acTexelSize * u.deslocamento * eng.acEscalaDePixel * 4.0;

    base.r = tela.sample(__nv_smp, clamp(uv + direcao, 0.0, 1.0)).r;
    base.b = tela.sample(__nv_smp, clamp(uv - direcao, 0.0, 1.0)).b;
    return base;
}

/**
 * ============================================================================
 *  O QUE O VIDRO DEVOLVE
 * ============================================================================
 *
 * Duas coisas somadas, e as duas são LUZ que chega à lente sem passar pelos
 * fósforos — por isso entram no fim, depois da máscara e do halo, e não são
 * moduladas por eles.
 *
 * ## O reflexo é um espelho CONVEXO
 *
 * A imagem do tubo estufa para fora (`1 + k·d²`); o reflexo faz o contrário,
 * ele **encolhe** para as bordas (`1 / (1 + k·d²)`). É o que todo espelho
 * convexo faz — o mesmo motivo de o retrovisor de carro caber o mundo inteiro e
 * avisar que os objetos estão mais perto do que parecem.
 *
 * Inverter o sinal aqui não é detalhe estético: com o reflexo estufando junto
 * com a imagem, os dois andam juntos e o cérebro lê tudo como uma coisa só —
 * some a sensação de que existe uma superfície na frente.
 *
 * ## E ele acende de raspão
 *
 * Fresnel: vidro reflete pouco de frente e muito de lado. Numa tela curva, "de
 * lado" é a borda — daí o reflexo ser fraco no meio e forte na moldura. É a
 * pista que o olho usa para saber que a superfície é curva.
 */
float3 reflexoDoVidro(float2 uv, float distanciaRadial) {
    float3 total = float3(0.0);

    // ---------------------------------------------------- o lustro do ambiente
    if (u.brilhoDoVidro > 0.001) {
        // Uma mancha larga vinda de cima à esquerda, que é de onde vem a luz em
        // quase todo lugar filmado (janela ou luminária de teto).
        float2 g = uv - float2(0.28, 0.22);
        g.x *= eng.acAspect;
        float mancha = exp(-dot(g, g) * 3.2);

        // Mais a borda acendendo: é o mesmo Fresnel, e é o que desenha o
        // CONTORNO do vidro.
        float borda = distanciaRadial * distanciaRadial;

        total += float3(mancha * 0.7 + borda * 0.5) * u.brilhoDoVidro;
    }

    // ------------------------------------------------------ a camada refletida
    if (u.forcaDoReflexo > 0.001) {
        float2 p = uv - u.centro;
        p.x *= eng.acAspect;

        // Espelho convexo: encolhe para as bordas, ao contrário da imagem.
        p /= 1.0 + u.curvatura * dot(p, p) * 1.5;
        p /= max(u.escalaDoReflexo, 0.05);
        p.x /= eng.acAspect;

        float2 uvReflexo = u.centro + p;
        if (u.espelharReflexo) uvReflexo.x = 1.0 - uvReflexo.x;

        /*
         * A BORDA DA CAMADA REFLETIDA SAI SUAVE.
         *
         * Repetir a borda esticaria um pixel pela tela toda; cortar seco deixa
         * uma LINHA RETA no meio do vidro, que denuncia o truque na hora — foi
         * o que a simulação mostrou, atravessando o canto superior direito.
         *
         * Quatro por cento de esmaecimento resolvem: o reflexo termina como
         * reflexo termina, apagando.
         */
        float2 suave = smoothstep(float2(0.0), float2(0.04), uvReflexo) *
            smoothstep(float2(0.0), float2(0.04), 1.0 - uvReflexo);
        float dentro = suave.x * suave.y;

        if (dentro > 0.001) {
            float4 amostraDoReflexo = reflexo.sample(__nv_smp, clamp(uvReflexo, 0.0, 1.0));
            float fresnel = mix(0.25, 1.0, distanciaRadial);
            // O alfa da camada refletida conta: um reflexo com fundo
            // transparente reflete só o que tem lá.
            total += amostraDoReflexo.rgb * amostraDoReflexo.a *
                u.forcaDoReflexo * fresnel * dentro;
        }
    }

    return total;
}

/** Desfoque em disco no buffer anterior. Poucas amostras, porque ele é pequeno. */
float3 desfocar(sampler2D fonte, float2 uv, float raio) {
    float3 soma = float3(0.0);
    float giro = ruido(uv * eng.acResolution) * TAU;
    for (int i = 0; i < 12; i++) {
        float2 desvio = vogel(i, 12, giro) * eng.acTexelSize * raio * eng.acEscalaDePixel;
        soma += fonte.sample(__nv_smp, clamp(uv + desvio, 0.0, 1.0)).rgb;
    }
    return soma / 12.0;
}

// ============================================================================
//  OS SEIS PASSES
// ============================================================================

fragment float4 fx_tubo_crt(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant tubo_crtParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> tela [[texture(1)]],
    texture2d<float> brilhoA [[texture(2)]],
    texture2d<float> brilhoB [[texture(3)]],
    texture2d<float> brilhoC [[texture(4)]],
    texture2d<float> brilhoD [[texture(5)]],
    texture2d<float> reflexo [[texture(6)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;

    // ---------------------------------------------- passe 0: a tela do tubo
    if (eng.acPass == 0) {
        float2 curvo = curvar(uv);

        // Fora do vidro não há imagem. Transparente, e não preto: a camada
        // continua sendo uma camada, e o que está embaixo aparece.
        if (curvo.x < 0.0 || curvo.x > 1.0 || curvo.y < 0.0 || curvo.y > 1.0) {
            __nv_out = float4(0.0);
            return __nv_out;
        }

        float4 cor = fosforos(curvo);
        cor.rgb *= varrer(uv);
        cor.rgb *= u.corDaTela.rgb;

        // A INSTABILIDADE, PARTE 2: o brilho respira. A fonte oscila, e a tela
        // inteira acompanha — de leve, senão vira estroboscópio.
        if (u.instabilidade > 0.001) {
            cor.rgb *= 1.0 + tremorDaFonte(eng.acTime) * u.instabilidade * 0.06;
        }

        if (u.posterizar > 0.001) {
            float niveis = mix(16.0, 2.0, min(u.posterizar, 0.98));
            cor.rgb = floor(cor.rgb * niveis) / niveis;
        }

        __nv_out = cor;
        return __nv_out;
    }

    // ------------------------------- passe 1: o que é brilhante o bastante
    //
    // O u.corte é o que separa "luz" de "imagem": só o que passa dele vira halo.
    // Sem ele, o brilho seria a imagem borrada por cima da imagem — o que
    // deixa tudo leitoso em vez de aceso.
    if (eng.acPass == 1) {
        float3 cor = desfocar(tela, uv, 1.4);
        float luz = dot(cor, float3(0.299, 0.587, 0.114));
        float peso = smoothstep(u.corte - u.suavidadeDoCorte, u.corte + u.suavidadeDoCorte, luz);
        __nv_out = float4(cor * peso, 1.0);
        return __nv_out;
    }

    // ------------------------- passes 2 a 4: a escada de desfoque, descendo
    //
    // Cada nível tem metade da resolução do anterior, então o MESMO raio em
    // texels cobre o dobro da tela. É daí que sai o halo contínuo: quatro
    // alcances somados, sem degrau entre eles.
    if (eng.acPass == 2) { __nv_out = float4(desfocar(brilhoA, uv, 2.2 * u.raioDoBrilho), 1.0); return __nv_out; }
    if (eng.acPass == 3) { __nv_out = float4(desfocar(brilhoB, uv, 2.2 * u.raioDoBrilho), 1.0); return __nv_out; }
    if (eng.acPass == 4) { __nv_out = float4(desfocar(brilhoC, uv, 2.2 * u.raioDoBrilho), 1.0); return __nv_out; }

    // ----------------------------------------------- passe 5: juntar tudo
    float4 cor = comAberracao(uv);

    /*
     * ========================================================================
     *  O FOCO CAI PARA AS BORDAS — O MESMO SISTEMA RADIAL DO VIDRO
     * ========================================================================
     *
     * Bulge, u.foco e halo saem todos da MESMA distância ao u.centro. Não são três
     * efeitos: é uma geometria só, e é isso que faz a imagem parecer uma
     * superfície, e não filtros empilhados.
     *
     * O desfoque cresce com o QUADRADO da distância, como a aberração de uma
     * lente simples: o meio fica cravado e as quinas abrem.
     */
    float2 doCentro = uv - u.centro;
    doCentro.x *= eng.acAspect;
    float distanciaRadial = clamp(dot(doCentro, doCentro) * 2.0, 0.0, 1.0);

    if (u.foco > 0.001) {
        float raioDoFoco = u.foco * distanciaRadial * 5.0;
        float3 borrado = float3(0.0);
        float giro = ruido(uv * eng.acResolution) * TAU;
        for (int i = 0; i < 6; i++) {
            float2 desvioFoco = vogel(i, 6, giro) * eng.acTexelSize * raioDoFoco * eng.acEscalaDePixel;
            borrado += tela.sample(__nv_smp, clamp(uv + desvioFoco, 0.0, 1.0)).rgb;
        }
        cor.rgb = mix(cor.rgb, borrado / 6.0, clamp(distanciaRadial * u.foco * 1.6, 0.0, 1.0));
    }

    /*
     * A SOMA DOS QUATRO NÍVEIS, EM DUAS CORES.
     *
     * O peso cai com o alcance: o halo apertado é o que se vê, o largo é o que
     * se sente. E os dois largos levam a segunda cor — perto do fósforo o halo
     * tem a cor dele, espalhado pelo vidro ele esfria, porque o azul espalha
     * mais. Ver `u.corDoHaloLargo`.
     */
    float3 haloPerto =
        brilhoA.sample(__nv_smp, uv).rgb * 0.40 +
        brilhoB.sample(__nv_smp, uv).rgb * 0.30;
    float3 haloLargo =
        brilhoC.sample(__nv_smp, uv).rgb * 0.20 +
        brilhoD.sample(__nv_smp, uv).rgb * 0.10;

    // O halo cresce para as bordas junto com o u.foco: onde o ponto abre, a luz
    // espalha mais. É de graça — a distância radial já está calculada.
    float ganhoDeBorda = 1.0 + distanciaRadial * u.foco * 0.8;

    float3 luz = (haloPerto * u.corDoBrilho.rgb + haloLargo * u.corDoHaloLargo.rgb) *
        u.forcaDoBrilho * ganhoDeBorda;
    cor.rgb += luz;

    /*
     * O HALO CRIA A PRÓPRIA COBERTURA.
     *
     * Fora do vidro a tela é transparente, e o alfa lá é zero. Sem esta linha o
     * brilho existiria em RGB e **não apareceria**: com alfa reto, `float4(cor, 0)`
     * compõe como nada.
     *
     * Só que luz de tubo vaza para fora do vidro — é metade do charme de filmar
     * um CRT no escuro. Então o brilho traz alfa junto, proporcional à própria
     * força. Onde a tela já é opaca isto não muda coisa alguma (o `max` segura).
     */
    cor.a = max(cor.a, clamp(dot(luz, float3(0.299, 0.587, 0.114)), 0.0, 1.0));

    /*
     * ========================================================================
     *  O VIDRO, POR ÚLTIMO — PORQUE ELE ESTÁ NA FRENTE
     * ========================================================================
     *
     * Reflexo e lustro são luz que bate na superfície e volta SEM passar pelos
     * fósforos. Por isso entram aqui: depois da máscara, depois do halo, sem
     * serem modulados por nenhum dos dois.
     *
     * Só dentro do vidro, porém. Fora da moldura não há superfície — e é a
     * mesma conta do passe 0 que decide, refeita aqui em três u.linhas em vez de
     * carregada num canal.
     *
     * Antes do u.tonemap, de propósito: reflexo estourado tem que rolar junto com
     * o resto da luz, senão ele vira uma mancha branca chapada sobre uma imagem
     * que foi comprimida.
     */
    float2 dobra = curvar(uv);
    bool noVidro = dobra.x >= 0.0 && dobra.x <= 1.0 && dobra.y >= 0.0 && dobra.y <= 1.0;

    if (noVidro) {
        float3 vidro = reflexoDoVidro(uv, distanciaRadial);
        cor.rgb += vidro;
        // O vidro também cobre: um reflexo forte sobre a parte transparente da
        // tela precisa aparecer. Mesma regra do halo, logo acima.
        cor.a = max(cor.a, clamp(dot(vidro, float3(0.299, 0.587, 0.114)), 0.0, 1.0));
    }

    // Segurar as altas: sem isto, o halo estoura em branco chapado e some o
    // desenho da luz. Reinhard, que é o mais barato que funciona.
    if (u.tonemap > 0.001) {
        float3 comprimido = cor.rgb / (1.0 + cor.rgb);
        cor.rgb = mix(cor.rgb, comprimido * 1.35, u.tonemap);
    }

    float cinza = dot(cor.rgb, float3(0.299, 0.587, 0.114));
    cor.rgb = mix(float3(cinza), cor.rgb, u.saturacao);

    cor.rgb = pow(max(cor.rgb, 0.0), float3(1.0 / max(u.gama, 0.05)));

    if (u.vinheta > 0.001) {
        float2 v = (uv - 0.5) * 2.0;
        v.x *= eng.acAspect;
        float escuro = 1.0 - u.vinheta * dot(v, v) * 0.5;
        cor.rgb *= clamp(escuro, 0.0, 1.0);
    }

    __nv_out = float4(clamp(cor.rgb, 0.0, 1.0), cor.a);
    return __nv_out;
}
