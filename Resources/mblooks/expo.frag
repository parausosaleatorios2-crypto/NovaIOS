// Exposure (`expo`, linear): ganho 2^stops pelo `MulAdd`.
uniform float uGanho;
out vec4 fragColor;

void main() {
    vec4 x = texelFetch(uEntrada, pxMemoria(), 0);
    fragColor = vec4(meia(x.rgb * uGanho), x.a);
}
