// ---------------------------------------------------------------------------
// Vox Pattern
// origem : assets/effects/voxpattern.xml
// id     : nova.effect.voxpattern
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct voxpatternParams {
    int patternType;
    float spacing;
    float elementScale;
    float depth;
    float4 color;
    float opacity;
    float depthFade;
    float crossWidth;
    float rotationX;
    float rotationY;
    float rotationZ;
    int uniformScale;
    float scaleX;
    float scaleY;
    float scaleZ;
    float2 offsetXY;
    float offsetZ;
    float seed;
    float randomPosition;
    float randomScale;
    float randomRotation;
    float randomVisibility;
    float randomColor;
    float randomOpacity;
    float phase;
    int cameraView;
    int cropXn;
    float xn;
    int cropXp;
    float xp;
    int cropYn;
    float yn;
    int cropYp;
    float yp;
    int cropZn;
    float zn;
    int cropZp;
    float zp;
    float cropFade;
    int compositeOnOriginal;
};

// --- funcoes auxiliares do efeito
// Medidos no plugin (tools/vox/benchmark):
const float FOCO = 0.8660254;          // sem câmera na composição: o foco, em alturas do quadro (60° de campo vertical)
const int PASSOS = 64;        // quantas células da grade o raio atravessa, no máximo

float2 tamanho() { return float2(int2(int(inputImg.get_width()), int(inputImg.get_height()))); }

float3x3 giro() {
    float3 a = radians(float3(u.rotationX, u.rotationY, u.rotationZ));
    float3 s = sin(a), c = cos(a);
    float3x3 rx = float3x3(1.0, 0.0, 0.0, 0.0, c.x, s.x, 0.0, -s.x, c.x);
    float3x3 ry = float3x3(c.y, 0.0, -s.y, 0.0, 1.0, 0.0, s.y, 0.0, c.y);
    float3x3 rz = float3x3(c.z, s.z, 0.0, -s.z, c.z, 0.0, 0.0, 0.0, 1.0);
    return rz * ry * rx;
}

/**
 * Quanto do pixel o segmento (centro c, eixo e, meio-comprimento L, raio r + `folga` px) cobre; t = a
 * distância no raio. As pontas são retas.
 */
float segmento(float3 ro, float3 rd, float3 c, float3 e, float L, float r, float ang, float folga, out float t) {
    float3 w = ro - c;
    float b = dot(rd, e), dd = dot(rd, w), ee = dot(e, w);
    float den = max(1.0 - b * b, 1e-6);
    float s = (ee - b * dd) / den;                     // onde, na reta do segmento, o raio passa mais perto
    float3 q = c + e * s;
    t = dot(q - ro, rd);
    if (t <= 0.0) return 0.0;
    float px = t * ang;
    float dist = length(ro + rd * t - q);
    // (medido: a linha fina nunca some — tem pelo menos 1.17 px de largura)
    float lado = clamp((max(r, 0.5 * 1.17 * px) + folga * px - dist) / px + 0.5, 0.0, 1.0);
    float ponta = clamp((L - abs(s)) / (px / max(sqrt(den), 0.05)) + 0.5, 0.0, 1.0);
    return lado * ponta;
}

float esfera(float3 ro, float3 rd, float3 c, float r, float ang, out float t) {
    float3 oc = c - ro;
    t = dot(oc, rd);
    if (t <= 0.0) return 0.0;
    float px = t * ang;
    return clamp((r - sqrt(max(dot(oc, oc) - t * t, 0.0))) / px + 0.5, 0.0, 1.0);
}

float caixa(float3 ro, float3 rd, float3 c, float3 h, out float t) {
    float3 inv = 1.0 / (abs(rd) + 1e-9) * sign(rd + 1e-12);
    float3 a = (c - h - ro) * inv, b = (c + h - ro) * inv;
    float3 mn = min(a, b), mx = max(a, b);
    float t0 = max(mn.x, max(mn.y, mn.z)), t1 = min(mx.x, min(mx.y, mx.z));
    t = t0;
    return t1 >= max(t0, 0.0) ? 1.0 : 0.0;
}

/** Um sorteio 0..1 por elemento e por canal; a Phase faz ele andar devagar, sem pular. */
float sorteio(float3 cel, float canal) {
    float3 p = fract((cel + float3(u.seed * 0.731, u.seed * 1.377, canal * 7.13)) * float3(0.1031, 0.1030, 0.0973));
    p += dot(p, p.yxz + 33.33);
    float h = fract((p.x + p.y) * p.z), h2 = fract((p.x + p.z) * p.y);
    return abs(fract(h + u.phase / 360.0 * (0.3 + 0.7 * h2)) * 2.0 - 1.0);
}

float3x3 giroDe(float3 graus) {
    float3 a = radians(graus), s = sin(a), c = cos(a);
    return float3x3(c.z, s.z, 0.0, -s.z, c.z, 0.0, 0.0, 0.0, 1.0) * float3x3(c.y, 0.0, -s.y, 0.0, 1.0, 0.0, s.y, 0.0, c.y) * float3x3(1.0, 0.0, 0.0, 0.0, c.x, s.x, 0.0, -s.x, c.x);
}

/** Um plano do Crop: 1 dentro, caindo a 0 ao longo de `u.cropFade` para fora. `d` = quanto o ponto está para dentro. */
float corte(bool ligado, float d) {
    if (!ligado) return 1.0;
    return u.cropFade > 0.5 ? clamp(d / u.cropFade + 1.0, 0.0, 1.0) : step(0.0, d);
}

fragment float4 fx_voxpattern(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant voxpatternParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;
    float4 orig = inputImg.sample(__nv_smp, uv);
    float2 R = tamanho() / eng.acEscalaDePixel;               // o quadro em px da composição: a unidade do mundo
    float2 p = uv * R;

    // O RAIO. Medido: sem câmera na composição, o olho do plugin fica na ORIGEM do mundo (o canto do
    // quadro, z = 0) olhando para +z, com 60° de campo vertical, e o centro da imagem é o eixo dele.
    // Com câmera, ele usa a posição e o giro dela, mas com o foco = zoom × altura / 1920 (não é o
    // campo de visão da câmera do AE — repetido aqui para dar a mesma imagem).
    float3 ro, rd, frente, direita, baixo;
    if (eng.acCamera3D == 1) {
        float2 tela = __nv_acTela(uv);
        float3 dc = (eng.acCameraInvVP * float4(0.0, 0.0, 1.0, 1.0)).xyz;
        float3 dx = (eng.acCameraInvVP * float4(1.0, 0.0, 1.0, 1.0)).xyz - dc, dy = (eng.acCameraInvVP * float4(0.0, -1.0, 1.0, 1.0)).xyz - dc;
        dc -= eng.acCameraOlhoNova;
        frente = normalize(dc); direita = normalize(dx); baixo = normalize(dy);
        rd = dc + (dx * (tela.x * 2.0 - 1.0) + dy * (tela.y * 2.0 - 1.0)) * (1920.0 / R.y);
        ro = eng.acCameraOlho;
    } else {
        ro = float3(0.0);
        frente = float3(0.0, 0.0, 1.0); direita = float3(1.0, 0.0, 0.0); baixo = float3(0.0, 1.0, 0.0);
        rd = float3(p - 0.5 * R, FOCO * R.y);
    }
    rd = normalize(rd);
    float ang = max(length(dfdx(rd)), length(dfdy(rd)));        // o tamanho angular de um pixel

    // A GRADE, no espaço dela: gira e estica em volta do canto da grade (medido: 50 − Offset em X e Y, −Offset Z).
    float S = max(u.spacing, 1.0);
    float3 esc = (u.uniformScale ? float3(u.scaleX) : float3(u.scaleX, u.scaleY, u.scaleZ)) / 100.0;
    float3x3 M = giro();
    // (medido com a câmera girada: o plugin aplica esse canto nos eixos da CÂMERA, não nos do mundo)
    float3 canto = float3(50.0 - u.offsetXY * R, -u.offsetZ);
    float3 pivo = direita * canto.x + baixo * canto.y + frente * canto.z;
    float3 o = transpose(M) * (ro - pivo) / esc + pivo;
    float3 d = transpose(M) * rd / esc;
    float estica = length(d);                                  // (unidades da grade por unidade do mundo, ao longo do raio)
    d /= estica;
    float angG = ang * estica;
    float3 base = pivo + 0.5 * S;                                // os pontos da grade: de S em S a partir daqui

    float3 cel = floor((o - base) / S + 0.5);
    float3 passo = sign(d + 1e-12);
    float3 inv = 1.0 / (abs(d) + 1e-9) * passo;
    float3 tProx = ((cel + 0.5 * passo) * S + base - o) * inv;
    float3 tDelta = abs(S * inv);
    float3 acum = float3(0.0); float alfa = 0.0;
    float tCel = 0.0;
    bool aleatorio = u.randomPosition + u.randomScale + u.randomRotation + u.randomVisibility + u.randomColor + u.randomOpacity > 0.0;
    for (int n = 0; n < PASSOS; n++) {
        if (tCel / estica > u.depth * 1.8 + 2.0 * S || alfa > 0.995) break;
        float3 c = cel * S + base;
        float raio = 0.5 * u.elementScale, a0 = u.opacity / 100.0;
        float3 cor = u.color.rgb;
        float3x3 G = float3x3(1.0);
        bool some = false;
        if (aleatorio) {
            // Random (as faixas foram medidas com pontos; o sorteio em si é outro)
            some = sorteio(cel, 1.0) < u.randomVisibility / 100.0;
            raio *= max(0.1, 1.0 + (2.0 * sorteio(cel, 2.0) - 1.0) * 0.6 * u.randomScale / 100.0);
            a0 *= 1.0 - sorteio(cel, 3.0) * u.randomOpacity / 100.0;
            cor = mix(cor, float3(sorteio(cel, 4.0), sorteio(cel, 5.0), sorteio(cel, 6.0)), u.randomColor / 100.0);
            // (a posição sorteada fica dentro da própria célula — é o que o raio consegue achar)
            float3 desvio = float3(sorteio(cel, 7.0), sorteio(cel, 8.0), sorteio(cel, 9.0)) * 2.0 - 1.0;
            c += desvio * min(u.randomPosition / 100.0, 1.0) * max(0.5 * S - raio, 0.0);
            if (u.randomRotation > 0.0) G = giroDe((float3(sorteio(cel, 10.0), sorteio(cel, 11.0), sorteio(cel, 12.0)) * 2.0 - 1.0) * u.randomRotation * 2.0);
        }
        float3 doOlho = M * ((c - pivo) * esc) + pivo - ro;       // o elemento, visto do olho, no mundo
        float longe = length(doOlho), z = dot(doOlho, frente);
        // Crop (medido): planos a partir do canto da grade, no espaço da câmera (Camera View) ou no do mundo
        float3 pc = u.cameraView ? float3(dot(doOlho, direita), dot(doOlho, baixo), z) : doOlho + ro;
        float recorte = corte(u.cropXn, pc.x - (canto.x - u.xn)) * corte(u.cropXp, (canto.x + u.xp) - pc.x)
                      * corte(u.cropYn, pc.y - (canto.y - u.yn)) * corte(u.cropYp, (canto.y + u.yp) - pc.y)
                      * corte(u.cropZn, pc.z - (canto.z - u.zn)) * corte(u.cropZp, (canto.z + u.zp) - pc.z);
        // Depth Fade (medido): linear nos últimos `fade` antes do Depth, contado no eixo da câmera
        float some2 = clamp((u.depth - z) / max(u.depthFade, 1e-3), 0.0, 1.0) * a0 * recorte;
        if (!some && z > 0.0 && z < u.depth && some2 > 0.0) {
            float t;
            float3 ol = transpose(G) * (o - c) + c, dl = transpose(G) * d;       // o raio no espaço do elemento
            if (u.patternType == 2) {
                float a = esfera(o, d, c, raio * 1.05, angG, t) * some2;
                acum += (1.0 - alfa) * a * cor; alfa += (1.0 - alfa) * a;
            } else if (u.patternType == 4) {
                float a = caixa(ol, dl, c, float3(raio), t) * some2;
                acum += (1.0 - alfa) * a * cor; alfa += (1.0 - alfa) * a;
            } else if (u.patternType == 3 && longe < u.depth) {
                // CRUZ: três braços nos eixos, cada um pintado por cima do outro (medido: no cruzamento a
                // opacidade é 1 − (1 − a)³). Com Cross Width são caixas de ponta reta; sem, um fio de
                // largura fixa na tela. Medido: a cruz some além do Depth em RAIO, não em plano.
                float h = 0.5 * u.crossWidth;
                bool grosso = h > 0.75 * max(dot(c - o, d), 0.0) * angG;
                for (int e = 0; e < 3; e++) {
                    float3 eixo = e == 0 ? float3(1.0, 0.0, 0.0) : e == 1 ? float3(0.0, 1.0, 0.0) : float3(0.0, 0.0, 1.0);
                    float a = (grosso ? caixa(ol, dl, c, eixo * (raio - h) + h, t) : segmento(ol, dl, c, eixo, raio, h, angG, 0.0, t)) * some2;
                    acum += (1.0 - alfa) * a * cor; alfa += (1.0 - alfa) * a;
                }
            }
        }
        if (u.patternType < 2) {
            // LINHAS (só em X) e GRADE (nos três eixos): retas inteiras pelos pontos da grade, de largura
            // = Scale, com 0.6 px a mais de cada lado (medido).
            for (int e = 0; e < 3; e++) {
                if (u.patternType == 0 && e != 0) break;
                float3 eixo = e == 0 ? float3(1.0, 0.0, 0.0) : e == 1 ? float3(0.0, 1.0, 0.0) : float3(0.0, 0.0, 1.0);
                float t;
                float a = segmento(o, d, c, eixo, 0.5 * S, 0.5 * u.elementScale, angG, 0.6, t);
                if (a <= 0.0) continue;
                float3 q = M * ((o + d * t - pivo) * esc) + pivo - ro;
                float zq = dot(q, frente);
                if (zq <= 0.0 || length(q) > u.depth) continue;
                a *= clamp((u.depth - zq) / max(u.depthFade, 1e-3), 0.0, 1.0) * u.opacity / 100.0;
                acum += (1.0 - alfa) * a * u.color.rgb; alfa += (1.0 - alfa) * a;
            }
        }
        // anda para a próxima célula
        if (tProx.x < tProx.y && tProx.x < tProx.z) { tCel = tProx.x; tProx.x += tDelta.x; cel.x += passo.x; }
        else if (tProx.y < tProx.z) { tCel = tProx.y; tProx.y += tDelta.y; cel.y += passo.y; }
        else { tCel = tProx.z; tProx.z += tDelta.z; cel.z += passo.z; }
    }
    float4 saida = float4(alfa > 0.0 ? acum / alfa : float3(0.0), alfa);
    if (u.compositeOnOriginal) {
        float a = saida.a + orig.a * (1.0 - saida.a);
        saida = float4(a > 0.0 ? (saida.rgb * saida.a + orig.rgb * orig.a * (1.0 - saida.a)) / a : float3(0.0), a);
    }
    __nv_out = saida;
    return __nv_out;
}
