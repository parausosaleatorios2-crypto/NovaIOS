// O fim do Edge Blur (fx.compoundBlur, 0x18032eba0): os 5 níveis (cumulativos, raio (i/5)·Edge Blur/2) já
// estão prontos; a máscara da borda (alfa) escolhe o intervalo [i/4, (i+1)/4) e mistura os dois vizinhos;
// depois a cor é despré-multiplicada. Cada passe grava meia().
uniform highp sampler2D uN1;
uniform highp sampler2D uN2;
uniform highp sampler2D uN3;
uniform highp sampler2D uN4;
uniform vec4 uMascA;
uniform vec4 uMascB;
uniform vec4 uMascC;
out vec4 fragColor;

vec4 nivel(int i, ivec2 p) {
    if (i == 0) return lerAe(uEntrada, p);
    if (i == 1) return lerAe(uN1, p);
    if (i == 2) return lerAe(uN2, p);
    if (i == 3) return lerAe(uN3, p);
    return lerAe(uN4, p);
}

void main() {
    ivec2 p = pxAe();
    float m = mascara(vec2(p) + 0.5, uMascA, uMascB, uMascC);
    vec4 v = vec4(0.0);
    for (int i = 0; i < 4; i++) {
        float lo = float(i) / 4.0;
        float hi = float(i + 1) / 4.0;
        if (i == 3) hi = hi + 0.01;
        if (m >= lo && m < hi) v = meia(mistura(nivel(i, p), nivel(i + 1, p), (m - lo) / (hi - lo)));
    }
    fragColor = meia(despre(v));
}
