// Neg Bleach Bypass (`nbby`, linear) — `ColorKernel_BleachBypass` na ordem do DXIL (`tools/looks/dxil/040`), com a chave
// do negativo ligada; o host (`0x1803f9090` → `0x18041cdd0` → `0x180418160`) é o ContasDoLooks.negBleachBypass. O
// kernel roda sempre (não há caso de "nada roda").
uniform float uK;     // 1 − Silver Retention · 0,01
uniform bool uNeg;    // a chave do kernel: o Neg Bleach Bypass liga, o Bleach Bypass não
uniform float uE;     // 2^Exposure Compensation
out vec4 fragColor;

void main() {
    vec4 px = texelFetch(uEntrada, pxMemoria(), 0);
    vec3 c = px.rgb;
    float L = dot(c, vec3(0.2126, 0.7152, 0.0722));
    vec3 m = uNeg ? c + L : c * L;
    fragColor = vec4(meia(((c - m) * uK + m) * uE), px.a);
}
