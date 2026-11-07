// S Curve (`logc`, vídeo) — `ColorKernel_LogCurve`; as constantes saem do host (`0x18041a6f0`), ver
// ContasDoLooks.sCurve. Curva em S em volta do pivô s: pé e ombro com expoente e, depois um gama g.
// Com "Log" ligado (`uLog`), a curva lê o pixel codificado em log (o sRGB do kernel → um log tipo Cineon); a
// mistura no fim continua com o pixel como chegou.
uniform float uE;
uniform float uS;
uniform float uLo;
uniform float uK;
uniform float uG;
uniform float uInvS;
uniform float uInvUmMenosS;
uniform float uMistura;
uniform bool uLog;
out vec4 fragColor;

float pw(float x, float e) { return exp2(log2(x) * e); }

float paraLog(float v) {
    return log2((decodVinheta(v) + 0.005208250135183334) * 0.9948187470436096) * 0.08819238096475601 + 0.6695992350578308;
}

float curva(float x) {
    float t = clamp(((uLog ? paraLog(x) : x) - uLo) * uK, 0.0, 1.0);
    float pe = pw(max(t * uInvS, 0.0), uE) * uS;
    float ombro = (1.0 - pw(max(1.0 - (t - uS) * uInvUmMenosS, 0.0), uE)) * (1.0 - uS) + uS;
    float y = pw(t < uS ? pe : ombro, uG);
    return (y - x) * uMistura + x;
}

void main() {
    vec4 x = texelFetch(uEntrada, pxMemoria(), 0);
    fragColor = vec4(meia(vec3(curva(x.r), curva(x.g), curva(x.b))), x.a);
}
