// Haze/Flare (`haze`, linear), depois dos dois desfoques — `FXKernel_RectMaskAlpha`: o alfa vira o Matte Box, um
// retângulo arredondado (a matriz da elipse da Edge Softness, com outra pena): t = |(|u| − ix)₊·kx, (|v| − iy)₊·ky|,
// alfa = (1 − t)^(2t). A cor fica como veio. Host: ContasDoLooks.haze.
uniform vec3 uColunaU;   // u = x·a + y·b + c
uniform vec3 uColunaV;
uniform vec2 uInterno;   // ix, iy
uniform vec2 uEscala;    // 1/(1 − ix), 1/(1 − iy)
out vec4 fragColor;

void main() {
    vec2 p = vec2(pxAe());
    float u = p.x * uColunaU.x + p.y * uColunaU.y + uColunaU.z;
    float v = p.x * uColunaV.x + p.y * uColunaV.y + uColunaV.z;
    float du = max(abs(u) - uInterno.x, 0.0) * uEscala.x;
    float dv = max(abs(v) - uInterno.y, 0.0) * uEscala.y;
    float t = clamp(sqrt(dv * dv + du * du), 0.0, 1.0);
    float a = 1.0 - t > 0.0 ? exp2(log2(1.0 - t) * 2.0 * t) : 0.0;
    vec4 px = texelFetch(uEntrada, pxMemoria(), 0);
    fragColor = vec4(px.rgb, meia(a));
}
