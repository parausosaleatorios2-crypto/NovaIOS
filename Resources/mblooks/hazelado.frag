// Haze/Flare (`haze`, linear), 1º passe — `FXKernel_HazeSideMatte`: a imagem × duas faixas nas laterais, cada uma
// subindo nos primeiros b px da borda e caindo até c (b = s·0,1·W, c = s·0,5·W, s = Spillage/100 com mínimo 0,01).
// Host: ContasDoLooks.haze.
uniform float uFim;     // W − 1
uniform float uInvB;    // 1/b
uniform float uB;
uniform float uK;       // −1/(c − b)
out vec4 fragColor;

void main() {
    float x = float(pxAe().x);
    float d = uFim - x;
    float t1 = clamp(uInvB * x, 0.0, 1.0);
    float t2 = clamp(d * uInvB, 0.0, 1.0);
    float u1 = clamp((x - uB) * uK + 1.0, 0.0, 1.0);
    float u2 = clamp((d - uB) * uK + 1.0, 0.0, 1.0);
    float m = max(min(t1, u1), min(t2, u2));
    fragColor = meia(texelFetch(uEntrada, pxMemoria(), 0) * m);
}
