// Channel Mixer (`cmix`, vídeo) — `ExpKernel_ChannelMixer` / `ExpKernel_ChannelMixerMono` na ordem do DXIL
// (`tools/looks/dxil/079` e `080`); o host (`0x1803ebcc0` → `0x180434020` / `0x180434380`) é o
// ContasDoLooks.channelMixer. Cada canal sai do produto escalar da cor com a linha dele (já normalizada), preso em 0;
// no monocromático, os três com a mesma linha. O kernel roda sempre.
uniform vec3 uR;      // Red R/G/B (no monocromático: RGB R/G/B)
uniform vec3 uG;      // Green R/G/B
uniform vec3 uB;      // Blue R/G/B
uniform bool uMono;
uniform float uK;     // Strength · 0,01
out vec4 fragColor;

// o dot4 do kernel: ((x·a + y·b) + z·c) + w·0, em ordem
float soma(vec3 c, vec3 l) {
    return (c.r * l.x + c.g * l.y) + c.b * l.z;
}

void main() {
    vec4 px = texelFetch(uEntrada, pxMemoria(), 0);
    vec3 c = px.rgb;
    float r = max(soma(c, uR), 0.0);
    vec3 o = uMono ? vec3(r) : vec3(r, max(soma(c, uG), 0.0), max(soma(c, uB), 0.0));
    // o alfa do kernel é (máx(a, 0) − a)·k + a: o da entrada (nunca negativo aqui)
    fragColor = vec4(meia((o - c) * uK + c), px.a);
}
