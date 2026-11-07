// Lens Vignette (`lenv`, vídeo) — `ColorKernel_LensVignette`. O kernel decodifica o sRGB por conta própria
// (`decodVinheta`), escurece pelo raio elíptico^expoente e codifica de volta. Constantes do host
// (`0x18041a130`): ContasDoLooks.lensVignette.
uniform vec2 uCentro;
uniform float uAspecto;
uniform float uInvRaio;
uniform float uExpoente;
uniform float uAltas;
uniform float uQuantidade;
out vec4 fragColor;

void main() {
    vec4 px = texelFetch(uEntrada, pxMemoria(), 0);
    vec3 v = px.rgb;
    vec3 lin = decodVinheta(v);
    vec2 p = vec2(pxAe());
    float a = uAspecto * (p.x - uCentro.x);
    float b = p.y - uCentro.y;
    float d = sqrt(a * a + b * b) * uInvRaio;
    float t = clamp(1.0 - d, 0.0, 1.0);
    t = max(t, 0.5) - 0.5 + min(t, 0.5);
    float m = exp2(log2(t) * uExpoente);
    if (uAltas > 0.0) {
        float mx = max(v.r, max(v.g, v.b));
        float mn = min(v.r, min(v.g, v.b));
        float q = min(max((mx + mn) * 0.5 - 0.75, 0.0) * 4.0, 1.0);
        m = (max(1.0 - (1.0 - q * q) * (1.0 - m), 0.0) - m) * uAltas + m;
    }
    vec3 o = uQuantidade < 0.0
        ? ((6.0 - m * 5.0) * lin - lin) * (-uQuantidade) + lin
        : (m * lin - lin) * uQuantidade + lin;
    fragColor = vec4(meia(codVinheta(o)), px.a);
}
