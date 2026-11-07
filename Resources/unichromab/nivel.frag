// Um passo da pirâmide do desfoque da engine (Gpu_BlurResizeRGB_Shader, render em 0x18027a810): desenha o
// retângulo centrado da fonte (largura uFonte.z × altura uFonte.w) como o retângulo do destino, com 5 px de
// borda esticada (8 tiras + o quad do meio, em 0x18027aef0: a tira da direita começa em dR − 1). Na descida,
// depois do desenho vêm os passes de 3 amostras (Gpu_Blur3x3Shader: soma de +1, 0, −1 × 0,333333333333), só
// dentro do scissor. Na subida, opcionalmente, as misturas (0x18027a200: atual·peso + outra·(1 − peso)).
// Tudo em float16 (meia), alvos RGBA16F do tamanho da camada.
uniform vec4 uS;        // (sL, sB, sR, sT): a fonte, em px
uniform vec4 uD;        // (dL, dB, dR, dT): o destino, em px
uniform float uDR1;     // dR − 1 (calculado em double, como no código)
uniform float uPad;     // 5
uniform ivec4 uTesoura; // (x0, y0, x1, y1), x1/y1 exclusivos
uniform bool uH;        // 3 amostras na horizontal
uniform bool uV;        // 3 amostras na vertical
uniform float uPeso1;   // < 0: sem mistura
uniform highp sampler2D uOutra1;
uniform float uPeso2;
uniform highp sampler2D uOutra2;
out vec4 fragColor;

bool dentro(vec2 c, float x0, float x1, float y0, float y1) {
    return c.x >= min(x0, x1) && c.x < max(x0, x1) && c.y >= min(y0, y1) && c.y < max(y0, y1);
}

float lin(float c, float x0, float x1, float t0, float t1) { return t0 + (c - x0) * ((t1 - t0) / (x1 - x0)); }

/** O desenho no px `p`: o último quad que o cobre (o do meio por cima de tudo). */
vec4 desenho(ivec2 p) {
    vec2 c = vec2(p) + 0.5;
    float sL = uS.x, sB = uS.y, sR = uS.z, sT = uS.w;
    float dL = uD.x, dB = uD.y, dR = uD.z, dT = uD.w;
    float pd = uPad;
    vec2 tc;
    if (dentro(c, dL, dR, dB, dT)) tc = vec2(lin(c.x, dL, dR, sL, sR), lin(c.y, dB, dT, sB, sT));
    else if (dentro(c, dR, dR + pd, dB - pd, dB)) tc = vec2(sR, sB);
    else if (dentro(c, dL - pd, dL, dT, dT + pd)) tc = vec2(sL, sT);
    else if (dentro(c, dR, dR + pd, dT, dT + pd)) tc = vec2(sR, sT);
    else if (dentro(c, dL - pd, dL, dB - pd, dB)) tc = vec2(sL, sB);
    else if (dentro(c, uDR1, uDR1 + pd, dB, dT)) tc = vec2(sR, lin(c.y, dB, dT, sB, sT));
    else if (dentro(c, dL - pd, dL, dB, dT)) tc = vec2(sL, lin(c.y, dB, dT, sB, sT));
    else if (dentro(c, dL, dR, dT, dT + pd)) tc = vec2(lin(c.x, dL, dR, sL, sR), sT);
    else if (dentro(c, dL, dR, dB - pd, dB)) tc = vec2(lin(c.x, dL, dR, sL, sR), sB);
    else return vec4(0.0);
    return meia(bilinear(uEntrada, tc));
}

bool naTesoura(ivec2 p) { return p.x >= uTesoura.x && p.x < uTesoura.z && p.y >= uTesoura.y && p.y < uTesoura.w; }

vec4 horizontal(ivec2 p) {
    if (!uH || !naTesoura(p)) return desenho(p);
    vec4 s = desenho(clamp(p + ivec2(1, 0), ivec2(0), uTamanho - 1)) + desenho(p);
    s += desenho(clamp(p - ivec2(1, 0), ivec2(0), uTamanho - 1));
    return meia(s * 0.333333333333);
}

void main() {
    ivec2 p = pxAe();
    vec4 v;
    if (uV && naTesoura(p)) {
        vec4 s = horizontal(clamp(p + ivec2(0, 1), ivec2(0), uTamanho - 1)) + horizontal(p);
        s += horizontal(clamp(p - ivec2(0, 1), ivec2(0), uTamanho - 1));
        v = meia(s * 0.333333333333);
    } else {
        v = horizontal(p);
    }
    if (uPeso1 >= 0.0) {
        vec4 m = v * uPeso1 + lerAe(uOutra1, p) * (1.0 - uPeso1);
        m.a = clamp(m.a, 0.0, 1.0);
        v = meia(m);
    }
    if (uPeso2 >= 0.0) {
        vec4 m = v * uPeso2 + lerAe(uOutra2, p) * (1.0 - uPeso2);
        m.a = clamp(m.a, 0.0, 1.0);
        v = meia(m);
    }
    fragColor = v;
}
