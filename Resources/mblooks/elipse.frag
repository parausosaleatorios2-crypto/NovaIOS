// Edge Softness (`edgs`, linear), um passo — `FXKernel_EllipseMask`: out = u0 + (u1 − u0)·m, m = (1 − t)^(2t),
// t = a distância além do raio interno da elipse, normalizada (invertida nos passos do meio). A elipse vira uma
// matriz no host (`0x18043b0c0`): ContasDoLooks.edgeSoftness. A saída passa pelo float16 truncado do motor.
uniform highp sampler2D uU0;
uniform highp sampler2D uU1;
uniform vec3 uColunaU;   // u = x·a + y·b + c
uniform vec3 uColunaV;
uniform float uInternoX;
uniform float uInternoY;
uniform bool uInverte;
out vec4 fragColor;

void main() {
    vec2 p = vec2(pxAe());
    float u = p.x * uColunaU.x + p.y * uColunaU.y + uColunaU.z;
    float v = p.x * uColunaV.x + p.y * uColunaV.y + uColunaV.z;
    float u2 = u * u;
    float v2 = v * v;
    float r = sqrt(u2 + v2);
    float interno = uInternoX >= uInternoY
        ? clamp(u2, 0.0, 1.0) * (uInternoX - uInternoY) + uInternoY
        : clamp(v2, 0.0, 1.0) * (uInternoY - uInternoX) + uInternoX;
    float t = clamp(max(r - interno, 0.0) / (1.0 - min(interno, 0.999)), 0.0, 1.0);
    if (uInverte) t = 1.0 - t;
    float m = 1.0 - t > 0.0 ? exp2(log2(1.0 - t) * 2.0 * t) : 0.0;
    vec4 a = texelFetch(uU0, pxMemoria(), 0);
    vec4 b = texelFetch(uU1, pxMemoria(), 0);
    fragColor = meia(a + (b - a) * m);
}
