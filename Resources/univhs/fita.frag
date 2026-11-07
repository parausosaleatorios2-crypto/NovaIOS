// uni.VHS — o ruído da fita (Tape Noise Type), GERADO aqui. No plugin ele é uma sequência de JPGs de fita filmada
// (30 ou 60 quadros por tipo, 720 × 486, esticados até a camada) que é da Red Giant e não vem com o app; este shader
// refaz o que elas têm, medido nelas (tools/univhs/benchmark/ruido_medir.py, LEIAME.md):
//   - o campo médio de cada tipo (cinza-azulado com vinheta; a estática escura que clareia para cima), um polinômio
//     de grau 3 em x, y por canal;
//   - a faixa preta de ~6 px na esquerda com o brilho de ringing logo depois, as linhas escuras do topo (Bad
//     Tracking, Vertical Slip) e as do pé;
//   - o grão: uma parte fixa (a mesma em todos os quadros, como na filmagem) e uma que muda a cada quadro do laço,
//     com o desvio e o comprimento horizontal medidos; nas estáticas (Very Bad Tracking, Blank Tape), riscos longos
//     na horizontal e o corte em 0..1.
// O quadro do laço (uIndice) é o do script: (Random Seed + Offset + quadro) % 30 ou 60.
// As Pop Lines: uma faixa de 1,1% da altura em uPopY com riscos claros, por cima em "screen" a 50% (como o popLine
// do plugin, também gerado).
// Versão nova do plugin: Adjust Noise Scale (uEscala) amplia o ruído no centro; Frame Style 4x3 aperta na
// horizontal (uAperto, o fx.transformScale do script).
uniform int uTipo;        // 0 VHS Noise, 1 Bad Tracking, 2 Very Bad Tracking, 3 Blank Tape, 4 Vertical Slip
uniform float uCromaExtra;
uniform int uIndice;
uniform int uSemente;
uniform float uEscala;
uniform float uAperto;
uniform bool uPop;
uniform float uPopY;      // o centro da faixa, em fração da altura (a partir do topo)
uniform int uPopEstilo;
out vec4 fragColor;

// <<constantes>> (geradas por tools/univhs/benchmark/fita_constantes.py — não editar à mão)
const vec3 COEF[50] = vec3[50](
    vec3(0.396369, 0.404330, 0.441032),
    vec3(0.018704, 0.037607, 0.015075),
    vec3(0.092794, 0.094681, 0.096360),
    vec3(-0.110060, -0.102122, -0.085491),
    vec3(0.035546, -0.012452, -0.070444),
    vec3(0.075573, 0.016278, 0.019392),
    vec3(0.025596, 0.025216, 0.018832),
    vec3(0.170318, 0.261894, 0.397946),
    vec3(-0.093741, -0.037668, -0.036219),
    vec3(-0.238372, -0.277723, -0.368105),
    vec3(0.390650, 0.399599, 0.436536),
    vec3(0.023457, 0.007946, 0.014240),
    vec3(0.069334, 0.155219, 0.090592),
    vec3(-0.090871, -0.137599, -0.082204),
    vec3(0.044374, 0.005532, -0.069173),
    vec3(0.075146, 0.019191, 0.024874),
    vec3(0.023994, 0.022305, 0.021110),
    vec3(0.141359, 0.218375, 0.381250),
    vec3(-0.091723, -0.037371, -0.042912),
    vec3(-0.215538, -0.249818, -0.350784),
    vec3(0.411940, 0.415959, 0.423496),
    vec3(-1.136608, -1.146884, -1.052424),
    vec3(1.808330, 1.847930, 1.657717),
    vec3(-1.028861, -1.057573, -0.939692),
    vec3(0.175090, 0.160383, 0.131097),
    vec3(-0.277760, -0.274701, -0.302117),
    vec3(0.101330, 0.088617, 0.088837),
    vec3(-0.083623, -0.070420, 0.031241),
    vec3(0.173445, 0.184120, 0.208875),
    vec3(-0.083166, -0.081658, -0.161823),
    vec3(0.294600, 0.294600, 0.294600),
    vec3(-0.079906, -0.079906, -0.079906),
    vec3(0.122991, 0.122991, 0.122991),
    vec3(-0.057448, -0.057448, -0.057448),
    vec3(-0.071423, -0.071423, -0.071423),
    vec3(0.057271, 0.057271, 0.057271),
    vec3(-0.040871, -0.040871, -0.040871),
    vec3(0.132461, 0.132461, 0.132461),
    vec3(-0.021317, -0.021317, -0.021317),
    vec3(-0.070888, -0.070888, -0.070888),
    vec3(0.183704, 0.195602, 0.230326),
    vec3(1.468037, 1.425274, 1.467889),
    vec3(-2.437603, -2.303813, -2.435725),
    vec3(1.237674, 1.165268, 1.264542),
    vec3(0.052193, 0.009047, -0.095278),
    vec3(0.038148, -0.006758, -0.002593),
    vec3(0.097104, 0.089489, 0.064582),
    vec3(0.154880, 0.239982, 0.470891),
    vec3(-0.145566, -0.096801, -0.075786),
    vec3(-0.213971, -0.253229, -0.401073));
const float BORDA[80] = float[80](0.027975, 0.027197, 0.025488, 0.027644, 0.028929, 0.062928, 0.354994, 0.784707, 1.173770, 1.361754, 1.349181, 1.241118, 1.154433, 1.145682, 1.119882, 1.099520, 0.006901, 0.005495, 0.005923, 0.006621, 0.011910, 0.052278, 0.329927, 0.776872, 1.189847, 1.404858, 1.398953, 1.278646, 1.181855, 1.145336, 1.124606, 1.096157, 0.623668, 0.649727, 0.679914, 0.711518, 0.747734, 0.790286, 0.835098, 0.871457, 0.911420, 0.948041, 0.973157, 0.980072, 0.976158, 0.968044, 0.955421, 0.946349, 1.002923, 1.001366, 0.998526, 0.993521, 0.992155, 0.994683, 1.001982, 1.004716, 1.002439, 0.995553, 0.993434, 0.994365, 0.996518, 0.996912, 0.993145, 0.987119, 0.009006, 0.007901, 0.009605, 0.016637, 0.033190, 0.083998, 0.321548, 0.724170, 1.126258, 1.367832, 1.403562, 1.307561, 1.206398, 1.156531, 1.130291, 1.100262);
const float TOPO[60] = float[60](1.059671, 1.063092, 1.053687, 1.054198, 1.047992, 1.049062, 1.042971, 1.043734, 1.038238, 1.037090, 1.034048, 1.032912, 0.316625, 0.230396, 0.592201, 0.999643, 1.066390, 1.053912, 1.048778, 1.039185, 1.037606, 1.035018, 1.032547, 1.030594, 0.883636, 0.888144, 0.928012, 0.974860, 0.996683, 1.012570, 1.034274, 1.050492, 1.073147, 1.087501, 1.042211, 0.996349, 0.941000, 0.941331, 0.946952, 0.982248, 0.974103, 0.995132, 0.969487, 0.977010, 0.958669, 0.973659, 0.952010, 0.962529, 0.446733, 0.439824, 0.257588, 0.119198, 0.256467, 0.459297, 0.507718, 0.570869, 0.592787, 0.613001, 0.632867, 0.653407);
const float PE[20] = float[20](1.020812, 1.004419, 1.031957, 1.004958, 1.015459, 1.028950, 1.039646, 1.044010, 0.529811, 0.555587, 0.306628, 0.235452, 1.025114, 1.038624, 1.026575, 1.049318, 0.969560, 0.970105, 0.979618, 0.990304);
const vec4 GRAO[5] = vec4[5](vec4(0.027247, 0.024286, 0.005947, 0.0), vec4(0.031096, 0.023527, 0.014452, 0.0), vec4(0.216181, 0.036719, 0.029674, 1.0), vec4(0.319816, 0.037703, 0.000000, 1.0), vec4(0.043924, 0.028585, 0.014225, 0.0));
// <</constantes>>

uint mistura32(uint x) {
    x ^= x >> 16; x *= 0x7feb352du;
    x ^= x >> 15; x *= 0x846ca68bu;
    x ^= x >> 16;
    return x;
}

/** Um valor em [0, 1) para a célula (x, y) e a semente s. */
float acaso(int x, int y, int s) {
    uint h = mistura32(uint(x) * 0x9E3779B1u ^ mistura32(uint(y) * 0x85EBCA77u ^ mistura32(uint(s) + 0x27D4EB2Fu)));
    return float(h >> 8) * (1.0 / 16777216.0);
}

/** Ruído de média 0 e desvio ~1 (triangular), interpolado na horizontal entre células de largura w e altura hh. */
float grao(vec2 q, float w, float hh, int s) {
    vec2 c = q / vec2(w, hh);
    int cy = int(floor(c.y));
    float fx = c.x - floor(c.x);
    int cx = int(floor(c.x));
    float a = acaso(cx, cy, s) + acaso(cx, cy, s + 911) - 1.0;
    float b = acaso(cx + 1, cy, s) + acaso(cx + 1, cy, s + 911) - 1.0;
    // a interpolação linear tira variância: (f² + (1 − f)²) em média 2/3
    float n = mix(a, b, fx) / sqrt(fx * fx + (1.0 - fx) * (1.0 - fx));
    return n * 2.449489743;
}

vec3 campo(int k, float x, float y) {
    float t[10] = float[10](1.0, y, y * y, y * y * y, x, x * y, x * y * y, x * x, x * x * y, x * x * x);
    vec3 r = vec3(0.0);
    for (int i = 0; i < 10; i++) r += COEF[k * 10 + i] * t[i];
    return r;
}

void main() {
    ivec2 p = pxAe();
    vec2 tam = vec2(uTamanho);
    vec2 uv = vec2(p) + 0.5;
    uv.x = clamp((uv.x - tam.x * 0.5) / uAperto + tam.x * 0.5, 0.5, tam.x - 0.5);
    vec2 q = uv / tam * vec2(720.0, 486.0);
    q = (q - vec2(360.0, 243.0)) / uEscala + vec2(360.0, 243.0);
    int k = clamp(uTipo, 0, 4);
    vec3 c = campo(k, q.x / 720.0, q.y / 486.0);
    int col = int(floor(q.x));
    int lin = int(floor(q.y));
    float ganho = 1.0;
    if (col >= 0 && col < 16) ganho *= BORDA[k * 16 + col];
    if (lin >= 0 && lin < 12) ganho *= TOPO[k * 12 + lin];
    if (lin >= 482 && lin < 486) ganho *= PE[k * 4 + lin - 482];
    c *= ganho;
    vec4 g = GRAO[k];   // (luma, luma fixa, croma, estática)
    int sq = uSemente * 131 + uIndice * 7919 + 17;
    if (g.w > 0.5) {
        // a estática: riscos longos na horizontal, o desvio medido, cortada em 0..1
        float n = grao(q, 9.0, 1.6, sq);
        c += vec3(n * g.x * 1.2);
        c += vec3(grao(q, 14.0, 2.0, sq + 3), grao(q, 14.0, 2.0, sq + 5), grao(q, 14.0, 2.0, sq + 7)) * (g.z + uCromaExtra);
    } else {
        float dyn = sqrt(max(g.x * g.x - g.y * g.y, 0.0));
        float l = grao(q, 2.5, 1.0, 7) * g.y + grao(q, 2.5, 1.0, sq) * dyn;
        c += vec3(l) * ganho;
        vec3 cr = vec3(grao(q, 6.0, 2.0, sq + 1), grao(q, 6.0, 2.0, sq + 2), grao(q, 6.0, 2.0, sq + 4)) * (g.z + uCromaExtra);
        c += cr - dot(cr, vec3(0.299, 0.587, 0.114));
        // o "head switching" das últimas linhas: traços claros curtos
        if (lin >= 484 && acaso(int(floor(q.x / 18.0)), lin, sq + 9) > 0.86) c += vec3(0.35);
    }
    c = clamp(c, 0.0, 1.0);
    if (uPop) {
        float meio = uPopY * tam.y;
        float alt = 0.011 * tam.y;
        float yy = (uv.y - (meio - alt * 0.5)) / alt;
        if (yy >= 0.0 && yy < 1.0) {
            int fileira = int(floor(yy * 8.0));
            float largura = 4.0 + float(uPopEstilo) * 3.0;
            float x = q.x / largura;
            float a = acaso(int(floor(x)), fileira / 2, uPopEstilo * 97 + uIndice);
            float b = acaso(int(floor(x)) + 1, fileira / 2, uPopEstilo * 97 + uIndice);
            float v = mix(a, b, smoothstep(0.0, 1.0, fract(x)));
            v = smoothstep(0.45, 0.95, v) * (0.55 + 0.45 * sin(3.14159265 * (yy * 0.9 + 0.05)));
            vec3 pop = vec3(v) * 0.5;   // bx.screen(50, 100)
            c = 1.0 - (1.0 - pop) * (1.0 - c);
        }
    }
    fragColor = meia(vec4(c, 1.0));
}
