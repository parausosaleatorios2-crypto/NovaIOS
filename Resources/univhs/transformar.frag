// uni.VHS — o Gpu_TransformShader da engine (fx.tileMirror, fx.tileClamp, fx.transformScale):
// tuv = (uv − c)·uInv + c − uDesloc, amostrado com o bilinear da engine. uEspelho: perto da borda (≤ 0,5 ou
// ≥ W − 1,5 px), a coordenada vai e volta como espelho (o tileMirror); senão, a borda presa.
uniform vec2 uInv;
uniform vec2 uDesloc;
uniform bool uEspelho;
out vec4 fragColor;

void main() {
    vec2 tam = vec2(uTamanho);
    vec2 c = tam * 0.5;
    vec2 uv = vec2(pxAe()) + 0.5;
    vec2 t = (uv - c) * uInv + c - uDesloc;
    if (uEspelho && (t.x <= 0.5 || t.x >= tam.x - 1.5 || t.y <= 0.5 || t.y >= tam.y - 1.5)) {
        vec2 m = mod(t, tam);
        if (mod(floor(t.x / tam.x), 2.0) == 1.0) m.x = tam.x - m.x;
        if (mod(floor(t.y / tam.y), 2.0) == 1.0) m.y = tam.y - m.y;
        t = m;
    }
    fragColor = meia(bilinear(uEntrada, t));
}
