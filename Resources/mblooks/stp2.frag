// 2-Strip Process (`2stp`, linear) — `CoreKernel_Mat3Mul` na ordem do DXIL (`tools/looks/dxil/020`); o host
// (`0x180400ad0` → `0x18042d4a0` → `0x180427d50`) é o ContasDoLooks.twoStrip: a matriz (e, 0, 0), (0, e·s, (1 − s)·e)
// duas vezes. O vermelho fica; o verde e o azul viram a mesma mistura dos dois. O kernel roda sempre.
uniform vec3 uR;      // a linha do vermelho: (float(e), 0, 0)
uniform vec3 uGB;     // a do verde e a do azul: (0, float(e·s), float((1 − s)·e))
out vec4 fragColor;

// o dot4 do kernel: ((x·a + y·b) + z·c) + w·0, em ordem
float soma(vec3 c, vec3 l) {
    return (c.r * l.x + c.g * l.y) + c.b * l.z;
}

void main() {
    vec4 px = texelFetch(uEntrada, pxMemoria(), 0);
    float gb = soma(px.rgb, uGB);
    fragColor = vec4(meia(vec3(soma(px.rgb, uR), gb, gb)), px.a);
}
