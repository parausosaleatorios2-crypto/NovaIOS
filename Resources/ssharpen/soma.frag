// A soma do S_Sharpen (o passe 24 de effects/sapphire-sharpen.xml), de fragmento como lá — `render/PasseDoSSharpen`.
// A base (F3) mais cada nível de detalhe pela sua curva. O texto é o do XML, com os mesmos nomes, para sair o mesmo
// float: o `tanh` do compute (sharpen.comp) erra 1 nível em 4% dos pixels contra o de fragmento.
//
// Montagem (o Kotlin põe antes): `#version 300 es`.

precision highp float;
precision highp int;
precision mediump sampler2D;

uniform sampler2D inputImg;
uniform sampler2D f0;
uniform sampler2D f1;
uniform sampler2D f2;
uniform sampler2D f3;
uniform float sharpenAmp;
uniform float scaleTiny;
uniform float scaleSmall;
uniform float scaleMedium;
uniform float scaleLarge;
uniform float sharpenLuma;
uniform float sharpenChroma;
uniform float sharpenRed;
uniform float sharpenGreen;
uniform float sharpenBlue;

in vec2 vTexCoord;
layout(location = 0) out vec4 fragColor;

const vec3 BRILHO = vec3(5.0, 8.0, 3.0) / 16.0;
bool JUNTO;

vec3 trabalho(vec3 rgb) {
    if (JUNTO) return rgb;
    float l = dot(rgb, BRILHO);
    return vec3(l, rgb.r - l, rgb.b - l);
}

vec3 corInteira(vec3 t) { return vec3(t.y, -(5.0 * t.y + 3.0 * t.z) / 8.0, t.z); }

vec3 abrir(vec4 t, vec3 s) {
    ivec4 b = ivec4(t * 255.0 + 0.5);
    ivec3 q = (b.rgb << 2) | ivec3(b.a & 3, (b.a >> 2) & 3, (b.a >> 4) & 3);
    vec3 e = vec3(q) / 1023.0 * 2.0 - 1.0;
    return s + e * abs(e);
}

void main() {
    ivec2 TAM = textureSize(inputImg, 0);
    JUNTO = sharpenLuma == sharpenChroma;
    ivec2 p = ivec2(gl_FragCoord.xy);
    vec3 rgbC = texelFetch(inputImg, clamp(p, ivec2(0), TAM - 1), 0).rgb;
    vec3 sC = trabalho(rgbC);

    vec3 F0 = abrir(texelFetch(f0, p, 0), sC), F1 = abrir(texelFetch(f1, p, 0), sC);
    vec3 F2 = abrir(texelFetch(f2, p, 0), sC), F3 = abrir(texelFetch(f3, p, 0), sC);
    vec3 det[4] = vec3[4](sC - F0, F0 - F1, F1 - F2, F2 - F3);
    float escala[4] = float[4](scaleTiny, scaleSmall, scaleMedium, scaleLarge);
    vec3 saida;
    if (JUNTO) {
        saida = F3;
        for (int i = 0; i < 4; i++) {
            vec3 a = ((escala[i] - 1.0) * sharpenAmp * vec3(sharpenRed, sharpenGreen, sharpenBlue) + 1.0) * 2.125;
            saida += tanh(a * det[i] * 0.5);
        }
    } else {
        float brilho = F3.x;
        vec3 cor = corInteira(F3);
        for (int i = 0; i < 4; i++) {
            float g = (escala[i] - 1.0) * sharpenAmp;
            brilho += tanh((g * sharpenLuma + 1.0) * 2.125 * det[i].x * 0.5);
            cor += tanh((g * sharpenChroma + 1.0) * 2.125 * corInteira(det[i]) * 0.5);
        }
        saida = brilho + cor;
    }
    fragColor = vec4(clamp(saida, 0.0, 1.0), texelFetch(inputImg, p, 0).a);
}
