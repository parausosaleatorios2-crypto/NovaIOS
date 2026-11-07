// ---------------------------------------------------------------------------
// Bokeh
// origem : assets/effects/bokeh.xml
// id     : nova.effect.bokeh
// passes : 7
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct bokehParams {
    float radius;
    float blades;
    float roundness;
    float rotation;
    float rim;
    float cateye;
    float chroma;
    float boost;
    float cut;
    float useMap;
    float focusDistance;
    float nearFar;
    int quality;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265;
const float ANGULO_AUREO = 2.39996323;   // espiral de girassol: cobertura uniforme com qualquer contagem
const float3  LUMA = float3(0.2126, 0.7152, 0.0722);
const int   MAX_AMOSTRAS = 72;

// A separação de profundidade (0..1) que já conta como "totalmente fora de foco"
// — a mesma constante e o mesmo raciocínio do depth-map.xml e do lens-blur.
const float FAIXA_DE_QUEDA = 0.3;

const float2 CANTOS[4] = float2[4](
    float2(-1.0, -1.0), float2(1.0, -1.0), float2(-1.0, 1.0), float2(1.0, 1.0)
);

float2 paraUv(float2 v) { return float2(v.x / max(eng.acAspect, 1e-4), v.y); }

float3 srgbParaLinear(float3 c) {
    return mix(c / 12.92, pow((c + 0.055) / 1.055, float3(2.4)), step(float3(0.04045), c));
}
float3 linearParaSrgb(float3 c) {
    c = max(c, float3(0.0));
    return mix(c * 12.92, 1.055 * pow(c, float3(1.0 / 2.4)) - 0.055, step(float3(0.0031308), c));
}

/**
 * O raio (círculo de confusão) naquele ponto, já contando o mapa de profundidade.
 *
 * O mapa entra como MULTIPLICADOR: o slider de raio segue sendo o mestre e o mapa
 * só decide onde ele vale. `profundidade - u.focusDistance` é o mesmo termo do
 * depth-map.xml: o plano escolhido fica nítido e quem se afasta dele (para
 * qualquer lado) desfoca. `u.nearFar` dá mais desfoque de um lado (frente) que do
 * outro (fundo) — 1,0 é simétrico.
 */
float raioEm(float2 uv) {
    if (u.useMap <= 0.0) return u.radius;
    float profundidade = dot(focusMap.sample(__nv_smp, uv).rgb, LUMA);
    float dir = profundidade - u.focusDistance;                 // >0 = mais perto (branco = perto)
    float queda = clamp(abs(dir) / FAIXA_DE_QUEDA, 0.0, 1.0);
    float lado = dir >= 0.0 ? u.nearFar : (2.0 - u.nearFar);
    return u.radius * mix(1.0, queda * lado, u.useMap);
}

/** O raio da abertura no ângulo `a`, para `n` lâminas retas (1 no vértice). */
float poligono(float a, float n) {
    float seg = (2.0 * PI) / n;
    float x = __nv_mod(a, seg) - seg * 0.5;
    return cos(seg * 0.5) / max(cos(x), 1e-3);
}

/**
 * Cat-eye (vinheta óptica): perto da borda do quadro, espreme a abertura na
 * direção RADIAL (a que aponta para o centro), o que deixa o disco em forma de
 * amêndoa com o eixo longo tangencial — o recorte que uma lente de verdade faz.
 */
float2 catEye(float2 off, float2 uv) {
    if (u.cateye <= 0.0) return off;
    float2 fc = uv - 0.5; fc.x *= eng.acAspect;
    float dcentro = length(fc);
    if (dcentro < 1e-4) return off;
    float rc = clamp(dcentro / 0.72, 0.0, 1.0);               // 0 no centro, ~1 no canto
    float2 rad = fc / dcentro;
    float compR = dot(off, rad);
    float2 offR = compR * rad;
    return (off - offR) + offR * mix(1.0, 1.0 - 0.7 * rc, u.cateye);
}

/** O peso de uma amostra pelo raio normalizado no disco (0 centro, 1 borda). */
float pesoRim(float r) {
    float borda = smoothstep(0.55, 1.0, r);
    if (u.rim >= 0.0) return mix(1.0, 0.15 + 3.0 * borda, u.rim);     // bolha: borda forte
    return mix(1.0, 0.5 + 1.2 * (1.0 - r), -u.rim);                 // creme: centro forte
}

int amostrasQ() { return u.quality == 0 ? 24 : (u.quality == 1 ? 48 : MAX_AMOSTRAS); }

/**
 * Baixa `tex` 2× por um filtro de caixa de 4 amostras em grade rotacionada — o
 * mesmo do passe 0 (ver o comentário lá), só que a fonte já está em energia
 * linear pré-multiplicada, então não há sRGB nem realce para refazer aqui.
 */
float4 caixaDaPiramide(sampler2D tex, float2 uv) {
    float2 d = eng.acTexelSize * 0.25;
    float4 acc = float4(0.0);
    for (int i = 0; i < 4; i++) acc += tex.sample(__nv_smp, uv + CANTOS[i] * d);
    return acc * 0.25;
}

/**
 * Os quatro pesos da pirâmide para ESTE pixel de saída — ver "A PIRÂMIDE" no
 * cabeçalho. `espacamento` é quanto uma amostra do gather precisa cobrir para
 * não deixar buraco até a vizinha (cresce com o raio, encolhe com a
 * quantidade de amostras); `nivel` converte isso em "quantos níveis de
 * pirâmide (cada um o dobro do texel do anterior) cobrem essa distância".
 * `w0..w3` somam sempre 1 e interpolam entre os dois níveis vizinhos — o
 * mesmo formato de um mip trilinear, montado à mão porque este pool de
 * buffers não gera mipmap.
 */
void pesosDaPiramide(float centroR, int taps, out float w0, out float w1, out float w2, out float w3) {
    float espacamento = centroR * sqrt(PI / float(taps));
    float texelBase = max(eng.acTexelSize.y, 1e-6);
    float nivel = clamp(log2(max(espacamento / texelBase, 1.0)), 0.0, 3.0);
    // Quatro "tendas" de largura 1 centradas em 0, 1, 2 e 3 — a mesma B-spline
    // linear por trechos de um mip trilinear. Somam exatamente 1 para
    // qualquer `nivel` no intervalo (dá pra provar por caso: em 0, 1, 2, 3 e
    // em qualquer ponto entre dois deles).
    w0 = clamp(1.0 - nivel, 0.0, 1.0);
    w1 = clamp(1.0 - abs(nivel - 1.0), 0.0, 1.0);
    w2 = clamp(1.0 - abs(nivel - 2.0), 0.0, 1.0);
    w3 = clamp(nivel - 2.0, 0.0, 1.0);
}

/** Rola o topo mantendo a COR (divide pela maior componente amaciada). */
float suave(float x) {
    const float k = 0.8;
    return x <= k ? x : k + (1.0 - k) * (1.0 - exp(-(x - k) / (1.0 - k)));
}
float3 ombroCor(float3 c) {
    float m = max(max(c.r, c.g), c.b);
    if (m <= 1e-4) return c;
    return c * (suave(m) / m);
}

float3 amostraLin(float2 uv) {
    float4 b = bokeh.sample(__nv_smp, uv);
    return b.rgb / max(b.a, 1e-4);
}

fragment float4 fx_bokeh(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant bokehParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> focusMap [[texture(1)]],
    texture2d<float> prep [[texture(2)]],
    texture2d<float> prep2 [[texture(3)]],
    texture2d<float> prep3 [[texture(4)]],
    texture2d<float> prep4 [[texture(5)]],
    texture2d<float> coc [[texture(6)]],
    texture2d<float> bokeh [[texture(7)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;

    // ---- Passe 0: prep (1/2). Baixa 2×, vai para linear, realça as luzes. ----
    if (eng.acPass == 0) {
        float2 d = eng.acTexelSize * 0.25;                          // meio texel do full-res
        float4 acc = float4(0.0);
        for (int i = 0; i < 4; i++) {
            float4 c = inputImg.sample(__nv_smp, uv + CANTOS[i] * d);
            float3 lin = srgbParaLinear(c.rgb);
            float luz = dot(c.rgb, LUMA);                     // brilho percebido (sRGB)
            float alto = smoothstep(u.cut, min(u.cut + 0.2, 1.0), luz);
            lin *= 1.0 + u.boost * alto;
            acc += float4(lin * c.a, c.a);                      // pré-multiplicado
        }
        __nv_out = acc * 0.25;
        return __nv_out;
    }

    // ---- Passes 1 a 3: a pirâmide de pré-borrão (1/4, 1/8, 1/16). ----
    if (eng.acPass == 1) { __nv_out = caixaDaPiramide(prep, uv); return __nv_out; }
    if (eng.acPass == 2) { __nv_out = caixaDaPiramide(prep2, uv); return __nv_out; }
    if (eng.acPass == 3) { __nv_out = caixaDaPiramide(prep3, uv); return __nv_out; }

    // ---- Passe 4: coc (1/2). O raio por pixel. ----
    if (eng.acPass == 4) {
        __nv_out = float4(raioEm(uv), 0.0, 0.0, 1.0);
        return __nv_out;
    }

    // ---- Passe 5: bokeh (1/2). Junta a abertura, em energia, lendo a pirâmide. ----
    if (eng.acPass == 5) {
        float centroR = coc.sample(__nv_smp, uv).r;
        if (centroR <= 0.00025) { __nv_out = prep.sample(__nv_smp, uv); return __nv_out; }

        int taps = amostrasQ();
        float rotR = radians(u.rotation);
        float3 somaRGB = float3(0.0);
        float somaA = 0.0;
        float wSum = 0.0;

        // Um peso por pixel de SAÍDA, não por amostra: o espaçamento entre
        // amostras vizinhas é quase constante numa espiral uniforme em área,
        // então recalcular por amostra não mudaria o nível escolhido — só
        // custaria mais. Ver `pesosDaPiramide`.
        float pw0, pw1, pw2, pw3;
        pesosDaPiramide(centroR, taps, pw0, pw1, pw2, pw3);

        for (int k = 0; k < MAX_AMOSTRAS; k++) {
            if (k >= taps) break;
            float t = (float(k) + 0.5) / float(taps);
            float rBase = sqrt(t);                            // uniforme em ÁREA
            float ang = float(k) * ANGULO_AUREO + rotR;
            float2 dir = float2(cos(ang), sin(ang));

            float forma = mix(poligono(ang, u.blades), 1.0, u.roundness);
            float2 off = catEye(dir * (rBase * forma), uv);
            float2 uvT = uv + paraUv(off) * centroR;

            /*
             * A LEITURA MULTI-NÍVEL. `uvT` é a MESMA coordenada normalizada
             * (0..1) em qualquer nível — é a textura por trás que muda de
             * resolução, não a UV — então não há conta de escala aqui, só
             * quatro leituras (uma por nível) pesadas por `pesosDaPiramide`.
             * Quatro samplers fixos, e não um array indexado por variável,
             * de propósito: indexação dinâmica de sampler em GLSL ES é
             * insegura entre GPUs, e quatro `if` custariam o mesmo em troca
             * de mais chance de erro.
             */
            float4 s = prep.sample(__nv_smp, uvT) * pw0
                   + prep2.sample(__nv_smp, uvT) * pw1
                   + prep3.sample(__nv_smp, uvT) * pw2
                   + prep4.sample(__nv_smp, uvT) * pw3;

            // Rejeição por profundidade: uma amostra NÍTIDA (raio pequeno) não pode
            // vazar para cá; só entra quem é borrado o bastante para chegar. Com
            // desfoque uniforme, tapR = centroR e nada é rejeitado. Lida sempre do
            // nível 0 (`coc` não tem pirâmide) — borrar um RAIO não faz sentido do
            // jeito que borrar uma cor faz.
            float aceita = 1.0;
            if (u.useMap > 0.0) {
                float tapR = coc.sample(__nv_smp, uvT).r;
                float dist = rBase * forma * centroR;
                aceita = clamp((tapR - dist) / (centroR * 0.15) + 1.0, 0.0, 1.0);
            }
            float w = pesoRim(rBase) * aceita;
            somaRGB += s.rgb * w;
            somaA   += s.a * w;
            wSum    += w;
        }

        wSum = max(wSum, 1e-4);
        __nv_out = float4(somaRGB / wSum, somaA / wSum);
        return __nv_out;
    }

    // ---- Passe 6: tela (cheia). Energia→cor, franja, composição pelo foco. ----
    float4 original = inputImg.sample(__nv_smp, uv);
    float r = coc.sample(__nv_smp, uv).r;
    float mistura = smoothstep(0.0, 0.0015, r);
    if (mistura <= 0.0) { __nv_out = original; return __nv_out; }

    // Franja cromática: separa os canais radialmente, só onde há desfoque.
    float amt = u.chroma * 0.006 * mistura;
    float2 dc = uv - 0.5;
    float3 lin;
    lin.r = amostraLin(uv + dc * amt).r;
    lin.g = amostraLin(uv).g;
    lin.b = amostraLin(uv - dc * amt).b;

    lin = ombroCor(lin);
    float3 cor = linearParaSrgb(lin);
    float cobertura = bokeh.sample(__nv_smp, uv).a;

    __nv_out = mix(original, float4(cor, cobertura), mistura);
    return __nv_out;
}
