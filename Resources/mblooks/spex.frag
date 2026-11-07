// Spot Exposure (`spex`, linear) — `ColorKernel_SpotMul` na ordem do DXIL (`tools/looks/dxil/043`); o host
// (`0x1803fdb40` → `0x180420340` → `0x18041b260`) é o ContasDoLooks.spotExposure. A exposição (2^Stops × a cor)
// entra só dentro do spot: uma elipse com borda pela curva S de meio em Falloff. O kernel roda sempre.
uniform vec2 uCentro;
uniform float uAspecto;
uniform float uInvRaio;
uniform float uInvSpread;
uniform vec4 uCurva;   // s, 1/s, s − 1, 1/(s − 1)
uniform float uK;      // |s − 0,5|·5 + 2,5
uniform vec3 uTint;    // Red/Green/Blue · 2^Stops
uniform bool uInverte;
out vec4 fragColor;

// x^k da GPU (exp2(log2 x)·k), com 0 no zero: o log₂(0) = −∞ do kernel dá 0, e nem toda GPU de celular garante isso
float potS(float x, float k) {
    return x > 0.0 ? exp2(log2(x) * k) : 0.0;
}

void main() {
    vec4 px = texelFetch(uEntrada, pxMemoria(), 0);
    vec3 c = px.rgb;
    vec2 p = vec2(pxAe());
    float a = (p.x - uCentro.x) * uAspecto;
    float b = p.y - uCentro.y;
    float d = sqrt(a * a + b * b) * uInvRaio;
    float t = clamp((1.0 - clamp(d, 0.0, 1.0)) * uInvSpread, 0.0, 1.0);
    float u = uInverte ? 1.0 - t : t;
    float s = uCurva.x;
    float lo = min(potS(u * uCurva.y, uK) * s, s);
    float hi = max(potS((u - 1.0) * uCurva.w, uK) * uCurva.z + 1.0, s);
    float m = lo - s + hi;
    vec3 g = (c * uTint - c) * m;
    fragColor = vec4(meia(g + c), px.a);
}
