// A Lens Distortion do fim (lx.lensDistortion, a mesma op 0x20 dos canais) sobre a imagem inteira. meia().
uniform vec4 uLenteA;   // (normx, normy, k, flatten·0,99)
uniform vec3 uLenteB;   // (1/(1 − flatten), escala x, escala y)
out vec4 fragColor;

void main() {
    vec2 uv = vec2(pxAe()) + 0.5;
    vec2 centro = vec2(uTamanho) * 0.5;
    vec2 t1 = uv - centro;
    t1 *= uLenteA.xy;
    vec2 t2 = t1 * t1;
    float t3 = t2.x + t2.y;
    if (uLenteA.w > 0.0) {
        t3 = sqrt(t3);
        t3 = t3 - uLenteA.w;
        t3 = max(t3, 0.0);
        t3 *= uLenteB.x;
        t3 *= t3;
    }
    if (uLenteA.z >= 0.0) t3 = t3 * uLenteA.z + 1.0;
    else t3 = t3 * uLenteA.z + 1.0 - uLenteA.z;
    t1 *= vec2(t3);
    fragColor = meia(bilinear(uEntrada, t1 * uLenteB.yz + centro));
}
