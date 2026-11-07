// ---------------------------------------------------------------------------
// Luz profunda
// origem : assets/effects/deep-glow.xml
// id     : nova.effect.deepglow
// passes : 9
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct deep_glowParams {
    float limiar;
    float raio;
    float intensidade;
    float cauda;
    float joelho;
    float4 cor;
    float dispersao;
    int comprimir;
    int soLuz;
};

// --- funcoes auxiliares do efeito
// ===========================================================================
//  Luz e pixel
// ===========================================================================
//
// `paraLuz` desfaz a curva do sRGB; `paraTela` refaz. Entre as duas, tudo que
// acontece é luz — somar, borrar e tirar média valem as regras da física.
//
// A fórmula é a do padrão, com o trecho reto perto do zero. A aproximação
// `pow(c, 2.2)` erraria justamente nas sombras, que é onde a u.cauda do halo mora.

static float3 paraLuz(float3 c) {
    float3 alto = pow(max(c + 0.055, 0.0) / 1.055, float3(2.4));
    float3 baixo = c / 12.92;
    return mix(baixo, alto, step(float3(0.04045), c));
}

static float3 paraTela(float3 l) {
    float3 seguro = max(l, 0.0);
    float3 alto = 1.055 * pow(seguro, float3(1.0 / 2.4)) - 0.055;
    float3 baixo = seguro * 12.92;
    return mix(baixo, alto, step(float3(0.0031308), seguro));
}

// ===========================================================================
//  Guardar luz em 8 bits sem perder a u.cauda
// ===========================================================================
//
// Os buffers são RGBA de 8 bits. Guardar luz linear neles desperdiça quase toda
// a precisão nas sombras — e a u.cauda do halo é toda sombra. A raiz quadrada
// devolve precisão ao escuro, e quem lê desfaz a raiz antes de somar: a conta
// acontece em luz linear do mesmo jeito.
//
// Por isso a DESCIDA lê texel a texel (`texelFetch`) e abre cada um antes de
// somar — a média da GPU entre dois texels seria a média das raízes, e numa
// borda dura isso come metade da luz. Na SUBIDA os níveis já são lisos na
// escala deles, e a média das raízes vizinhas é praticamente a raiz da média.

// Ruído de um pixel ("interleaved gradient noise"): somado ANTES de gravar em 8
// bits, troca os degraus da u.cauda por um grão invisível — era a "qualidade
// péssima" do print do snow (28/09/2026): o halo em faixas.
static float ruidoDoPixel() {
    return fract(52.9829189 * fract(dot(__nv_fragCoord.xy, float2(0.06711056, 0.00583715)))) - 0.5;
}

static float4 guardar(float4 luz) {
    return float4(sqrt(max(luz.rgb, 0.0)) + ruidoDoPixel() / 255.0, max(luz.a, 0.0));
}

static float4 abrir(float4 guardado) {
    return float4(guardado.rgb * guardado.rgb, guardado.a);
}

// ===========================================================================
//  A descida
// ===========================================================================
//
// Cada texel do nível novo é a média com peso de TENDA dos 4×4 texels da
// origem em volta dele (1, 3, 3, 1 de cada lado quando a razão é 2). Tenda,
// e não caixa 2×2: a caixa deixa o nível com cantos, e os cantos viram
// quadrados no halo. Os pesos saem da distância, então a conta vale também
// onde o buffer travou no mínimo de 8 px e a razão não é 2.

/** O que passa do u.limiar num texel da imagem, em luz linear. */
static float4 brilhoDoTexel(int2 t) {
    int2 tam = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    float4 c = inputImg.read(uint2(clamp(t, int2(0), tam - 1)), uint(0));

    // A luminância do CORTE é medida em sRGB, de propósito: o u.limiar tem que
    // responder ao que se vê na tela. Corte suave, nunca duro: um degrau
    // serrilha a borda do halo e ela PISCA quando a cena se move.
    float visto = dot(c.rgb, float3(0.2126, 0.7152, 0.0722));
    float quanto = smoothstep(u.limiar, min(u.limiar + u.joelho, 1.0), visto) * c.a;
    // Abaixo do u.limiar não há luz: pula a conversão (três `pow`) — o mesmo zero,
    // mais barato. São 16 texels por pixel da descida (otimização de 01/10/2026).
    if (quanto <= 0.0) return float4(0.0);

    // A u.cor do motor é RETA: um pixel transparente ainda guarda uma u.cor (num PNG recortado, a do fundo que foi
    // apagado). Sem pesar pelo alfa, essa u.cor invisível acendia o halo — e o fundo apagado voltava em volta da
    // silhueta, em degraus (relato do snow, 23/10/2026, export em PNG). Pesada, a luz é pré-multiplicada.
    // O alfa vai junto: sem isso o brilho não vaza para fora da silhueta da
    // camada, que é metade da graça.
    return float4(paraLuz(c.rgb) * quanto, quanto);
}

static float4 descerDaImagem() {
    float2 tam = float2(int2(int(inputImg.get_width()), int(inputImg.get_height())));
    float2 p = in.acScreenNorm * tam;
    float2 t0 = floor(p) - 2.0;
    float4 soma = float4(0.0);
    float pesos = 0.0;
    for (int j = 0; j < 4; j++) {
        for (int i = 0; i < 4; i++) {
            float2 t = t0 + float2(float(i), float(j));
            float2 w = max(2.0 - abs(t + 0.5 - p), 0.0);
            float peso = w.x * w.y;
            soma += brilhoDoTexel(int2(t)) * peso;
            pesos += peso;
        }
    }
    return guardar(soma / max(pesos, 0.0001));
}

static float4 descer(sampler2D origem) {
    int2 tamI = int2(int(origem.get_width()), int(origem.get_height()));
    float2 p = in.acScreenNorm * float2(tamI);
    float2 t0 = floor(p) - 2.0;
    float4 soma = float4(0.0);
    float pesos = 0.0;
    for (int j = 0; j < 4; j++) {
        for (int i = 0; i < 4; i++) {
            float2 t = t0 + float2(float(i), float(j));
            float2 w = max(2.0 - abs(t + 0.5 - p), 0.0);
            float peso = w.x * w.y;
            int2 ti = clamp(int2(t), int2(0), tamI - 1);
            soma += abrir(origem.read(uint2(ti), uint(0))) * peso;
            pesos += peso;
        }
    }
    return guardar(soma / max(pesos, 0.0001));
}

// ===========================================================================
//  A subida: B-spline cúbica com quatro leituras
// ===========================================================================
//
// Ler um nível de 1/64 com a bilinear da GPU mostra o losango de cada texel.
// A B-spline cúbica é lisa até a segunda derivada — não há canto nenhum para o
// olho achar — e sai em quatro leituras bilineares: cada par de texels
// vizinhos vira uma leitura só, no ponto em que a bilinear dá a proporção
// certa entre os dois.

static float4 lerLiso(sampler2D t, float2 uv) {
    float2 tam = float2(int2(int(t.get_width()), int(t.get_height())));
    float2 p = uv * tam - 0.5;
    float2 i = floor(p);
    float2 f = p - i;
    float2 f2 = f * f;
    float2 f3 = f2 * f;
    float2 w0 = (1.0 - 3.0 * f + 3.0 * f2 - f3) / 6.0;
    float2 w1 = (4.0 - 6.0 * f2 + 3.0 * f3) / 6.0;
    float2 w2 = (1.0 + 3.0 * f + 3.0 * f2 - 3.0 * f3) / 6.0;
    float2 w3 = f3 / 6.0;
    float2 g0 = w0 + w1;
    float2 g1 = w2 + w3;
    float2 a = (i - 1.0 + w1 / max(g0, 0.0001) + 0.5) / tam;
    float2 b = (i + 1.0 + w3 / max(g1, 0.0001) + 0.5) / tam;
    return abrir(t.sample(__nv_smp, float2(a.x, a.y))) * g0.x * g0.y
         + abrir(t.sample(__nv_smp, float2(b.x, a.y))) * g1.x * g0.y
         + abrir(t.sample(__nv_smp, float2(a.x, b.y))) * g0.x * g1.y
         + abrir(t.sample(__nv_smp, float2(b.x, b.y))) * g1.x * g1.y;
}

// ===========================================================================
//  O peso de cada nível
// ===========================================================================
//
// As quatro escalas de antes (desvios de uns 0,5r, 1,1r, 2,3r e 4,6r, com
// r = Raio) continuam sendo a forma da luz: "Cauda" é a razão da queda entre
// elas, e a soma dos pesos é 1 — mudar a forma não muda o brilho total, e um
// projeto antigo continua com o mesmo tamanho de halo, só que liso.
//
// Cada escala cai entre dois níveis da pirâmide (em escala logarítmica) e se
// divide entre eles. Por isso o Raio anda contínuo, sem saltar de nível em nível.

static void pesosDosNiveis(out float w[8]) {
    for (int k = 0; k < 8; k++) w[k] = 0.0;
    float queda = mix(0.25, 0.9, u.cauda);
    float4 p = float4(1.0, queda, queda * queda, queda * queda * queda);
    p /= max(p.x + p.y + p.z + p.w, 0.001);
    // O Raio é em pixels da COMPOSIÇÃO: na prévia reduzida (arrastando) o buffer
    // tem menos pixels, e sem esta conta o halo ficava maior e mais forte ao
    // mexer e encolhia ao soltar (relato do snow, 28/09/2026).
    float4 s = u.raio * max(eng.acEscalaDePixel, 0.05) * float4(0.5, 1.1, 2.3, 4.6);
    for (int j = 0; j < 4; j++) {
        float nivel = clamp(log2(max(s[j], 0.01) / 0.76), 1.0, 8.0) - 1.0;
        float baixo = floor(nivel);
        float f = nivel - baixo;
        int k = int(baixo);
        w[k] += p[j] * (1.0 - f);
        if (k < 7) w[k + 1] += p[j] * f;
    }
}

/** A luz somada dos níveis, num ponto. */
static float4 luzEm(float2 uv, float w[8]) {
    float4 l = float4(0.0);
    if (w[0] > 0.0) l += lerLiso(p1, uv) * w[0];
    if (w[1] > 0.0) l += lerLiso(p2, uv) * w[1];
    if (w[2] > 0.0) l += lerLiso(p3, uv) * w[2];
    if (w[3] > 0.0) l += lerLiso(p4, uv) * w[3];
    if (w[4] > 0.0) l += lerLiso(p5, uv) * w[4];
    if (w[5] > 0.0) l += lerLiso(p6, uv) * w[5];
    if (w[6] > 0.0) l += lerLiso(p7, uv) * w[6];
    if (w[7] > 0.0) l += lerLiso(p8, uv) * w[7];
    return l;
}

// ===========================================================================
//  A compressão dos estouros
// ===========================================================================
//
// Não é um tonemap global (que escureceria o que não tem brilho nenhum). O
// halo gasta, exponencialmente, só o ESPAÇO QUE FALTA até o branco:
//
//     saída = base + espaço · (1 − e^(−luz / espaço))
//
// Para luz pequena isso é a própria soma; só o exagero é que curva.
//
// A conta ACIMA descreve a IDEIA; a de baixo já não é mais por canal. Até a
// 0.276 era `float3 espaco = 1-base; base + espaco*(1-exp(-luz/espaco))`, canal
// a canal — bom para o uso comum daqui (um toque de luz sobre uma foto que já
// tem u.cor própria, raramente forte o bastante para saturar). Mas o snow passou
// a empilhar este efeito SOBRE o Cósmico (`cosmico.xml`), cuja saída já é
// bem clara e saturada por si só — e aí cada canal convergindo para 1.0
// sozinho lava a PROPORÇÃO entre eles, que é o que carrega o matiz: um
// magenta forte (0.85, 0.10, 0.55) recebendo um halo branco virava (1.00,
// 0.67, 0.94) — quase branco. Mesma causa, mesmo remédio já aplicado no
// Cósmico (25/09/2026): u.comprimir só a LUMINÂNCIA e escalar a u.cor BRUTA
// inteira por ela — a proporção r:g:b nunca muda. O mesmo magenta, no mesmo
// teste, fica (1.18, 0.67, 0.98) antes do clamp final — ainda reconhecível
// como magenta, não uma mancha branca. Verificado num teste numérico (Node)
// antes de mexer aqui.
const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

static float3 comprimirNoEspaco(float3 base, float3 luz) {
    float lumaBase = dot(base, LUMA);
    float luzLuma = dot(luz, LUMA);
    float espaco = max(1.0 - lumaBase, 0.001);
    float lumaComprimida = lumaBase + espaco * (1.0 - exp(-luzLuma / espaco));
    float3 corBruta = base + luz;
    float lumaBruta = max(dot(corBruta, LUMA), 0.0001);
    return corBruta * (lumaComprimida / lumaBruta);
}

fragment float4 fx_deep_glow(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant deep_glowParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> p1 [[texture(1)]],
    texture2d<float> p2 [[texture(2)]],
    texture2d<float> p3 [[texture(3)]],
    texture2d<float> p4 [[texture(4)]],
    texture2d<float> p5 [[texture(5)]],
    texture2d<float> p6 [[texture(6)]],
    texture2d<float> p7 [[texture(7)]],
    texture2d<float> p8 [[texture(8)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 0) { __nv_out = descerDaImagem(); return __nv_out; }
    if (eng.acPass == 1) { __nv_out = descer(p1); return __nv_out; }
    if (eng.acPass == 2) { __nv_out = descer(p2); return __nv_out; }
    if (eng.acPass == 3) { __nv_out = descer(p3); return __nv_out; }
    if (eng.acPass == 4) { __nv_out = descer(p4); return __nv_out; }
    if (eng.acPass == 5) { __nv_out = descer(p5); return __nv_out; }
    if (eng.acPass == 6) { __nv_out = descer(p6); return __nv_out; }
    if (eng.acPass == 7) { __nv_out = descer(p7); return __nv_out; }

    // ------------------------------------------------------- 8: a soma final
    float4 base = inputImg.sample(__nv_smp, in.acScreenNorm);
    float w[8];
    pesosDosNiveis(w);
    float4 luz = luzEm(in.acScreenNorm, w);

    // Dispersão: o halo se separa em u.cor conforme se afasta do centro, como uma
    // lente barata faz com luz forte. Vermelho para fora, azul para dentro.
    if (u.dispersao > 0.001) {
        float2 desvio = (in.acScreenNorm - float2(0.5)) * u.dispersao * 0.04;
        float4 quente = luzEm(in.acScreenNorm + desvio, w);
        float4 fria = luzEm(in.acScreenNorm - desvio, w);
        luz = float4(quente.r, luz.g, fria.b, luz.a);
    }

    float3 halo = luz.rgb * u.cor.rgb * u.intensidade;

    // Onde a camada é opaca, a luz soma sobre ela (como sempre foi); onde é transparente, só a luz — sobre o
    // vazio, não sobre a u.cor escondida do pixel. As duas se juntam pelo alfa da camada, em u.cor pré-multiplicada,
    // e o alfa de saída é o do Unmult do Deep Glow do AE (`deep-glow-ae.xml`): screen(alfa da camada, maior canal
    // da luz). Sem halo, a camada sai idêntica — borda semitransparente inclusive. No PNG, a luz sobre o
    // transparente vira u.cor com alfa, e não um bloco opaco.
    float ab = u.soLuz ? 0.0 : base.a;
    float ruido = ruidoDoPixel() / 255.0;
    float3 sobreACamada = paraTela(u.comprimir ? comprimirNoEspaco(paraLuz(base.rgb), halo) : (paraLuz(base.rgb) + halo));
    float3 soALuz = clamp(paraTela(u.comprimir ? comprimirNoEspaco(float3(0.0), halo) : halo) + ruido, 0.0, 1.0);
    float3 pre = clamp(sobreACamada + ruido, 0.0, 1.0) * ab + soALuz * (1.0 - ab);
    float alfa = 1.0 - (1.0 - ab) * (1.0 - max(soALuz.r, max(soALuz.g, soALuz.b)));

    __nv_out = alfa > 0.0 ? float4(min(pre / alfa, float3(1.0)), alfa) : float4(0.0);
    return __nv_out;
}
