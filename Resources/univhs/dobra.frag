// uni.VHS — Tape Wrinkle: a faixa (uY0..uY1, px a partir do topo) recebe a linha uRoll·H esticada — o fx.transform
// que estica uma linha por toda a imagem, desenhado num quad de Wrinkle Radius % da altura (gl.quads) —; fora dela,
// transparente. Depois vêm o blurV(1) da engine (a pirâmide vertical) e o bx.infront sobre a imagem (frente.frag).
uniform float uY0;
uniform float uY1;
uniform float uRoll;   // roll·H, px
out vec4 fragColor;

void main() {
    ivec2 p = pxAe();
    float yc = float(p.y) + 0.5;
    if (yc < uY0 || yc >= uY1) {
        fragColor = vec4(0.0);
        return;
    }
    float h = float(uTamanho.y);
    float v = (yc - uY0) / (uY1 - uY0);
    float ys = uRoll + (v * h - uRoll) / h;
    fragColor = meia(bilinear(uEntrada, vec2(float(p.x) + 0.5, ys)));
}
