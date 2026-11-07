// O fim do fnoise em x: a grade × (0,5 · Amplitude), mais uma subdivisão e a leitura linear na posição de cada
// coluna de pixel (a cadeia em float32 calculada na CPU, `uPos`): i = trunc(p); fma(p − i, b[i+1] − b[i], b[i]).
// Alvo RG32UI de W × (linhas da grade).
uniform highp usampler2D uGrade;
uniform highp sampler2D uPos;      // R32F, W × 1
uniform float uEscala;             // f32(0,5) · f32(Amplitude)
layout(location = 0) out uvec4 saida;

vec2 g(int x, int y) { return lerGrade(uGrade, ivec2(x, y)) * uEscala; }

vec2 b(int p, int y) {
    int k = p >> 1;
    return subdivide(p, g(k, y), g(k + 1, y), (p & 1) == 1 ? g(k + 2, y) : vec2(0.0));
}

void main() {
    ivec2 q = ivec2(gl_FragCoord.xy);
    float pos = texelFetch(uPos, ivec2(q.x, 0), 0).r;
    int i = int(pos);
    float t = pos - float(i);
    vec2 b0 = b(i, q.y);
    vec2 b1 = b(i + 1, q.y);
    saida = uvec4(floatBitsToUint(t * (b1 - b0) + b0), 0u, 0u);
}
