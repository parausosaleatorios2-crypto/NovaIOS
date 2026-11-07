// S_Glow — a luz e a mistura com a fonte (o passe 7 do effects/sapphire-glow.xml), lendo a luz das caixas em float
// (RGBA16F) no lugar da mantissa e expoente de 8 bits do XML (`render/PasseDoSGlow`). As contas são as de lá.
//
// Montagem (o Kotlin põe antes): `#version 300 es`.

precision highp float;
precision highp int;
precision mediump sampler2D;

uniform sampler2D inputImg;
uniform highp sampler2D uLuz;       // a última caixa (RGBA16F)
uniform float threshold;
uniform vec4 thresholdAddColor;
uniform float glowFromAlpha;
uniform int show;
uniform float brightness;
uniform vec4 color;
uniform float affectAlpha;
uniform float sourceOpacity;
uniform int combine;
uniform float glowUnderSource;

in vec2 vTexCoord;
layout(location = 0) out vec4 fragColor;

vec3 corDoLimiar(ivec2 p) {
    vec4 t = texelFetch(inputImg, p, 0);
    vec3 c = max(t.rgb * t.a, vec3(0.0));
    return mix(c, vec3(t.a), clamp(glowFromAlpha, 0.0, 1.0));
}
float fatorDoLimiar(vec3 c) {
    float soma = c.r + c.g + c.b;
    if (soma < 1e-6) return 0.0;
    vec3 passa = max(c - (threshold + floor(thresholdAddColor.rgb * 255.0 + 0.5) / 255.0), vec3(0.0));
    return (passa.r + passa.g + passa.b) / soma / max(1.0 - threshold, 1e-6);
}
vec3 limiar(ivec2 p) {
    vec3 c = corDoLimiar(p);
    return c * fatorDoLimiar(c);
}

void main() {
    ivec2 p = ivec2(gl_FragCoord.xy);
    if (show == 1) { fragColor = vec4(min(limiar(p), vec3(1.0)), 1.0); return; }

    vec3 luz = min(max(texelFetch(uLuz, p, 0).rgb, vec3(0.0)) * brightness * color.rgb, vec3(1.0));
    float aLuz = min(max(luz.r, max(luz.g, luz.b)) * affectAlpha, 1.0);
    vec4 fonte = texelFetch(inputImg, p, 0);
    float q = clamp(sourceOpacity, 0.0, 1.0);
    float aF = fonte.a * q;
    vec3 s = fonte.rgb * aF;

    vec3 cor;
    float alfa = 1.0 - (1.0 - aLuz) * (1.0 - aF);
    if (combine == 0) { cor = luz * s; alfa = aLuz * aF; }
    else if (combine == 1) { cor = luz + s; alfa = min(aLuz + aF, 1.0); }
    else if (combine == 2) cor = 1.0 - (1.0 - luz) * (1.0 - s);
    else if (combine == 3) cor = abs(luz - s);
    else cor = mix(2.0 * luz * s, 1.0 - 2.0 * (1.0 - luz) * (1.0 - s), vec3(greaterThanEqual(s, vec3(0.5))));

    float sob = clamp(glowUnderSource, 0.0, 1.0);
    cor = mix(cor, s + luz * (1.0 - aF), sob);
    alfa = mix(alfa, aF + aLuz * (1.0 - aF), sob);

    cor = clamp(cor, 0.0, 1.0);
    fragColor = alfa > 0.0 ? vec4(min(cor / alfa, vec3(1.0)), alfa) : vec4(0.0);
}
