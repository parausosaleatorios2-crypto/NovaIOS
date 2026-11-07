// Mojo II (`mjo2`, vídeo) — `MojoKernel_MojoPlug`, reescrito à mão a partir do kernel do Looks (a ordem das contas
// é a dele: cada `+`, `*` e cada constante saem como lá, porque o resultado tem de bater bit a bit).
// O host (`0x1803f6620`, ver ContasDoLooks.mojo2) transforma os 12 valores da ferramenta nos uniforms abaixo e em 5
// curvas de 1024 pontos (`uCurvas`, uma por linha): 0 = exposição, 1 = contraste, 3 = "skin bend", 4 = "blue bend"
// (a 2 é a do caminho com conversão para log, que o AE não usa: o host só liga esse caminho quando a camada
// trabalha em log — `0x1803cdc60` —, e aí o kernel troca vários estágios; não implementado).
//
// Os estágios, em ordem: curva de exposição → vinheta → curvas de filme (P8 e P9) → split toning → saturação
// → dobra do azul → dobra da pele → curva de contraste → cor (saturação pela luminosidade) → mistura final.
uniform highp sampler2D uCurvas;
uniform vec3 uExpoFim;      // a curva continua além de `fim` em reta, com a inclinação `incl`
uniform vec3 uExpoIncl;
uniform vec3 uVinheta;      // expoente (0 = sem vinheta), quantidade, 1/raio
uniform float uP8;
uniform float uP9;
uniform vec3 uTomSombra;    // split toning: as cores V1 e V2 do host
uniform vec3 uTomLuz;
uniform float uSaturacao;   // %
uniform vec3 uAzul;         // força (> 0 liga), largura, centro do matiz
uniform vec4 uPele;         // força (> 0 liga), P10 (≠ 0 liga), largura, centro do matiz
uniform vec3 uContFim;
uniform vec3 uContIncl;
uniform float uCor;
uniform vec2 uSaida;        // nível do preto, nível do branco
uniform float uForca;
out vec4 fragColor;

float pot(float x, float e) { return exp2(log2(x) * e); }
vec3 pot(vec3 x, float e) { return exp2(log2(x) * e); }

/** A curva de filme com o pé suave: (v^a + 1 − (1 − v)^b) / 2 abaixo de 1; acima, a reta de inclinação a. */
float curvaPe(float v, float a, float b) {
    float pw = pot(v, a);
    return v < 1.0 ? ((pw + 1.0) - pot(max(1.0 - v, 0.0), b)) * 0.5 : (pw + -1.0) * a + 1.0;
}

/**
 * A curva de filme com o ombro: entre d e 1 sai do pé suave para v^a. c1 = 1/(d − 1), c2 = 1/(1 − d) — o kernel
 * as traz prontas (constantes) ou as calcula (split toning); as duas formas entram aqui como vierem.
 */
float curvaOmbro(float v, float a, float b, float c1, float d, float c2) {
    float pw = pot(v, a);
    float pe = ((pw + 1.0) - pot(1.0 - v, b)) * 0.5;
    float t1 = clamp((v + -1.0) * c1, 0.0, 1.0);
    float t2 = clamp((v - d) * c2, 0.0, 1.0);
    return v >= 1.0 ? pw : t2 * pw + pe * t1;
}

/** Uma curva do host (linha `linha` de uCurvas) por canal; além de `fim`, a reta. */
vec3 curva(int linha, vec3 v, vec3 fim, vec3 incl) {
    return vec3(
        v.r < fim.r ? amostra1d(uCurvas, linha, v.r).r : (v.r - fim.r) * incl.r + fim.r,
        v.g < fim.g ? amostra1d(uCurvas, linha, v.g).g : (v.g - fim.g) * incl.g + fim.g,
        v.b < fim.b ? amostra1d(uCurvas, linha, v.b).b : (v.b - fim.b) * incl.b + fim.b);
}

/** A vinheta do Mojo (a mesma conta da Lens Vignette, centrada, sem proteção parcial das altas). */
vec3 vinheta(vec3 y) {
    vec3 lin = decodVinheta(y);
    vec2 d = vec2(pxAe()) - vec2(uTamanho) * 0.5;
    float t = clamp(1.0 - sqrt(d.x * d.x + d.y * d.y) * uVinheta.z, 0.0, 1.0);
    t = (max(t, 0.5) + -0.5) + min(t, 0.5);
    float m = exp2(log2(t) * uVinheta.x);
    float mx = max(y.r, max(y.g, y.b));
    float mn = min(y.r, min(y.g, y.b));
    float q = min(max((mx + mn) * 0.5 + -0.75, 0.0) * 4.0, 1.0);
    m = max(1.0 - (1.0 - q * q) * (1.0 - m), 0.0);
    vec3 o = uVinheta.y < 0.0
        ? ((6.0 - m * 5.0) * lin - lin) * (-0.0 - uVinheta.y) + lin
        : (m * lin - lin) * uVinheta.y + lin;
    return codVinheta(o);
}

/** As curvas de filme do P8 (negativo e positivo têm formas próprias por canal). */
vec3 filmeP8(vec3 y) {
    vec3 g = pot(max(y, 1e-6), 0.45454543828964233);
    vec3 f;
    float mistura;
    if (uP8 < 0.0) {
        f.r = curvaPe(max(g.r * 1.1549999713897705 + -0.38499999046325684, 1e-6), 0.5263158082962036, 1.899999976158142);
        f.g = curvaPe(max(g.g * 1.092000126838684 + -0.18199999630451202, 1e-6), 0.6211180090904236, 1.6100000143051147);
        f.b = curvaOmbro(max(g.b * 0.7350000143051147 + 0.31499993801116943, 1e-6), 1.3333333730697632, 0.75,
                         -1.2903226613998413, 0.22499999403953552, 1.2903226613998413);
        mistura = uP8 * -0.004999999888241291;
    } else {
        f.r = curvaPe(max(g.r * 1.3224999904632568 + -0.17249996960163116, 1e-6), 0.7662835121154785, 1.3050000667572021);
        f.g = curvaOmbro(max(g.g * 1.123499870300293 + -0.07349999248981476, 1e-6), 1.0946907997131348, 0.9134999513626099,
                         -1.0844223499298096, 0.07785004377365112, 1.0844223499298096);
        f.b = curvaOmbro(max(g.b * 0.949999988079071, 1e-6), 1.6420361995697021, 0.6089999675750732,
                         -1.5429717302322388, 0.35190001130104065, 1.5429717302322388);
        mistura = uP8 * 0.004999999888241291;
    }
    f = pot(max(f, 1e-6), 2.200000047683716);
    return (f - y) * mistura + y;
}

/** As curvas de filme do P9 (vermelho e azul iguais). */
vec3 filmeP9(vec3 y) {
    vec3 g = pot(max(y, 1e-6), 0.45454543828964233);
    vec3 f;
    float mistura;
    if (uP9 < 0.0) {
        f.r = curvaOmbro(max(g.r * 0.7999999523162842 + 0.20000004768371582, 1e-6), 1.6666666269302368, 0.6000000238418579,
                         -1.5624998807907104, 0.35999995470046997, 1.5624998807907104);
        f.g = curvaPe(max(g.g * 1.5 + -0.5, 1e-6), 0.5263158082962036, 1.899999976158142);
        f.b = curvaOmbro(max(g.b * 0.7999999523162842 + 0.20000004768371582, 1e-6), 1.6666666269302368, 0.6000000238418579,
                         -1.5624998807907104, 0.35999995470046997, 1.5624998807907104);
        mistura = 1.0 - (uP9 + 200.0) * 0.004999999888241291;
    } else {
        f.r = curvaPe(max(g.r * 1.2000000476837158 + -0.19999998807907104, 1e-6), 0.7142857313156128, 1.399999976158142);
        f.g = curvaOmbro(max(g.g * 0.7000000476837158 + 0.2999999523162842, 1e-6), 1.6666666269302368, 0.6000000238418579,
                         -1.5624998807907104, 0.35999995470046997, 1.5624998807907104);
        f.b = curvaPe(max(g.b * 1.2000000476837158 + -0.19999998807907104, 1e-6), 0.7142857313156128, 1.399999976158142);
        mistura = uP9 * 0.004999999888241291;
    }
    f = pot(max(f, 1e-6), 2.200000047683716);
    return (f - y) * mistura + y;
}

/** Split toning de um canal: a cor da sombra (v1) desloca, a da luz (v2) vira o expoente de uma curva de filme. */
float tom(float g, float v1, float v2) {
    float a = (v1 + -1.0) + g * (2.0 - v1);
    float inv = 1.0 / v2;
    float d = max(1.0 - v2, 0.0) * 0.8999999761581421;
    float v = max(a, 1e-6);
    if (v2 > 1.0) return curvaPe(v, inv, v2);
    if (v2 < 1.0) return curvaOmbro(v, inv, v2, 1.0 / (d + -1.0), d, 1.0 / (1.0 - d));
    return v;
}

vec3 splitToning(vec3 y) {
    vec3 g = pot(max(y, 1e-6), 0.45454543828964233);
    vec3 t = vec3(tom(g.r, uTomSombra.r, uTomLuz.r), tom(g.g, uTomSombra.g, uTomLuz.g), tom(g.b, uTomSombra.b, uTomLuz.b));
    return pot(max(t, 1e-6), 2.200000047683716);
}

/** RGB (já em 0..1) → HSL, com as comparações e o matiz do kernel. */
vec3 paraHsl(vec3 c) {
    float mn = min(c.r, min(c.g, c.b));
    float mx = max(c.r, max(c.g, c.b));
    if (mx == 0.0) return vec3(0.0);
    if (mn == mx) return vec3(0.0, 0.0, mx);
    float soma = mx + mn;
    float l = soma * 0.5;
    float d = mx - mn;
    float s = d / (l <= 0.5 ? soma : (2.0 - mn) - mx);
    float k = 0.1666666716337204 / d;
    float h;
    if (c.r < c.g) {
        if (c.r < c.b) h = c.b < c.g ? 0.5 - k * (mx - c.b) : k * (mx - c.g) + 0.5;
        else h = k * (mx - c.r) + 0.1666666716337204;
    } else {
        if (c.g < c.b) h = c.b < c.r ? k * (mx - c.b) + 0.8333333134651184 : 0.8333333134651184 - k * (mx - c.r);
        else h = 0.1666666716337204 - k * (mx - c.g);
    }
    return vec3(h, s, l);
}

vec3 deHsl(vec3 hsl) {
    float h = clamp(hsl.x, 0.0, 1.0);
    float s = clamp(hsl.y, 0.0, 1.0);
    float l = clamp(hsl.z, 0.0, 1.0);
    if (l == 0.0) return vec3(0.0);
    if (s == 0.0) return vec3(l);
    float q = l <= 0.5 ? l * s + l : (l + s) - l * s;
    float p = l * 2.0 - q;
    float h6 = h * 6.0;
    float dq = q - p;
    if (h6 <= 1.0) return vec3(q, dq * h6 + p, p);
    if (h6 <= 3.0) return h6 <= 2.0 ? vec3(dq * (2.0 - h6) + p, q, p) : vec3(p, q, dq * (h6 + -2.0) + p);
    if (h6 <= 5.0) return h6 <= 4.0 ? vec3(p, dq * (4.0 - h6) + p, q) : vec3(dq * (h6 + -4.0) + p, p, q);
    return vec3(q, p, dq * (6.0 - h6) + p);
}

/**
 * Dobra de matiz (blue bend / skin bend): o matiz, medido a partir de `centro` (−0,5..0,5), passa pela curva
 * `linha` numa janela de `largura`; fora da janela fica como está.
 */
vec3 dobraMatiz(vec3 c, int linha, float largura, float centro) {
    vec3 hsl = paraHsl(clamp(c, 0.0, 1.0));
    float d = hsl.x - centro;
    if (d > 0.5) d = d + -1.0;
    else if (d < -0.5) d = d + 1.0;
    float u = (1.0 / largura) * d + 0.5;
    float v = (u < 0.0 || u >= 1.0) ? u : amostra1d(uCurvas, linha, u).r;
    float h = (v + -0.5) * largura + centro;
    for (int i = 0; i < 64 && !(h < 1.0); i++) h = h + -1.0;
    for (int i = 0; i < 64 && h < 0.0; i++) h = h + 1.0;
    return deHsl(vec3(h, hsl.y, hsl.z));
}

void main() {
    vec4 px = texelFetch(uEntrada, pxMemoria(), 0);
    vec3 x = px.rgb;
    vec3 y = curva(0, max(x, 0.0), uExpoFim, uExpoIncl);
    if (uVinheta.x != 0.0) y = vinheta(y);
    y = filmeP8(y);
    y = filmeP9(y);
    y = splitToning(y);
    float L = dot(y, vec3(0.3098039925098419, 0.6078429818153381, 0.08235300332307816));
    y = max((uSaturacao * 0.01) * (y - L) + L, 0.0);
    if (uAzul.x > 0.0) y = dobraMatiz(y, 4, uAzul.y, uAzul.z);
    if (uPele.x > 0.0 || uPele.y != 0.0) y = dobraMatiz(y, 3, uPele.z, uPele.w);
    y = curva(1, max(y, 0.0), uContFim, uContIncl);
    if (uCor > 0.0) {
        vec3 hsl = paraHsl(clamp(y, 0.0, 1.0));
        hsl.y = exp2(log2(hsl.z) * 0.4) * hsl.y;
        y = uCor * (deHsl(hsl) - y) + y;
    }
    vec3 z = (uSaida.x - x) + (uSaida.y - uSaida.x) * y;
    fragColor = vec4(meia(z * uForca + x), px.a);
}
