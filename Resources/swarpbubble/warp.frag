// O S_WarpBubble no buffer da cadeia: coords = rotate(noise2, Rotate Warp Dir) + xy · Z Dist; o nível do mipmap de
// cada pixel (pelas diferenças das coords com os vizinhos); as três amostras do rip-map; a saída reta em 8 bits.
// Fora do retângulo da camada, o buffer passa como estava.
//
// O rip-map do Sapphire não é guardado: o texel (i, j) do nível (a, b) é a média do bloco 2^a × 2^b da camada
// (a tabela de somas, `uSatL` + `uSatY`), menos a última coluna/linha de cada nível, que vem da folga (Wrap) — essa
// é uma soma de blocos (`uTermos`, feita na CPU por ContasDoWarpBubble.termosDaBorda).
uniform highp usampler2D uFinalX;   // W × (linhas da grade): o ruído já lido em x (finalx.frag)
uniform highp sampler2D uPosY;      // R32F, H × 1: as posições da leitura final em y
uniform vec2 uGiro;                 // (cos, sin) do Rotate Warp Dir
uniform float uZ;                   // Z Dist
uniform float uRazao;               // f32(H/W)
uniform ivec2 uModo;                // Wrap X, Y: 1 = No, 2 = Tile, 3 = Reflect
uniform bool uFiltro;
uniform vec2 uMaxNivel;             // f32(níveis − 1,01), x e y
uniform highp usampler2D uSatL;     // sat_local.frag
uniform highp usampler2D uSatY;     // sat_acumy.frag
uniform highp sampler2D uTermos;    // RGBA32F 33 × 32, linha eixo·16 + nível: (largura, nº de termos), (coef, início, comprimento)…
out vec4 fragColor;

const int MAX_TERMOS = 32;
const int MAX_PEDACOS = 64;

/** 2^k exato (o exp2 da GPU não garante). */
float pot2(int k) { return intBitsToFloat((127 + k) << 23); }

// ---- as coordenadas ------------------------------------------------------------------------------------------
vec2 emX(int k, int y) { return lerGrade(uFinalX, ivec2(k, y)); }

vec2 emY(int k, int p) {
    int j = p >> 1;
    return subdivide(p, emX(k, j), emX(k, j + 1), (p & 1) == 1 ? emX(k, j + 2) : vec2(0.0));
}

/** O noise2 do Sapphire (os dois canais) no pixel (k, r) da camada. */
vec2 ruido(int k, int r) {
    float pos = texelFetch(uPosY, ivec2(r, 0), 0).r;
    int i = int(pos);
    float t = pos - float(i);
    vec2 b0 = emY(k, i);
    vec2 b1 = emY(k, i + 1);
    return t * (b1 - b0) + b0;
}

/** coords (unidades do Sapphire: x de −1 a 1 na largura, y para cima) no pixel (k, r). */
vec2 coords(int k, int r) {
    vec2 n = ruido(k, r);
    vec2 g = vec2(n.x * uGiro.x - n.y * uGiro.y, n.x * uGiro.y + n.y * uGiro.x);
    float W = float(uTamanho.x);
    vec2 xy = vec2(-1.0 + float(2 * k + 1) / W, uRazao - float(2 * r + 1) / W);
    return g + xy * uZ;
}

// ---- o nível do mipmap (0x1811ffaf0, modo 0) ---------------------------------------------------------------
/** O log2 por partes do Sapphire: expoente − 127 + (mantissa − 1); 0 se v ≤ 0. */
float log2Partes(float v) {
    if (!(v > 0.0)) return 0.0;
    uint b = floatBitsToUint(v);
    int e = int((b >> 23) & 255u) - 128;
    float m = uintBitsToFloat((b & 0x807FFFFFu) + 0x3F800000u);
    return float(e) + m;
}

/**
 * Um canal: |Δ| dos dois lados na horizontal e na vertical (na borda, um lado × 2), vezes e = W/4 nos DOIS eixos;
 * v = maior + 0,5 · menor.
 */
float nivelDe(float c, float cE, float cD, float cC, float cB, bvec4 tem, float e) {
    float h = 0.0;
    if (tem.x && tem.y) h = abs((cD - c) * e) + abs((c - cE) * e);
    else if (tem.y) h = abs((cD - c) * (2.0 * e));
    else if (tem.x) h = abs((c - cE) * (2.0 * e));
    float v = 0.0;
    if (tem.z && tem.w) v = abs((cB - c) * e) + abs((c - cC) * e);
    else if (tem.w) v = abs((cB - c) * (2.0 * e));
    else if (tem.z) v = abs((c - cC) * (2.0 * e));
    float comb = h <= v ? v + 0.5 * h : v * 0.5 + h;
    return log2Partes(comb);
}

// ---- o Wrap das coordenadas (0x1811e28e0) --------------------------------------------------------------------
/** O fmod do C (exato; o sinal é o do dividendo). */
float fmodC(float f, float n) {
    float r = f - n * trunc(f / n);
    if (f >= 0.0) {
        if (r < 0.0) r += n;
        else if (r >= n) r -= n;
    } else {
        if (r > 0.0) r -= n;
        else if (r <= -n) r += n;
    }
    return r;
}

/** No = como está (a leitura prende); Tile = fmod; Reflect = o mesmo, espelhado nos períodos ímpares. */
float envolve(float f, int n, int modo) {
    if (modo == 1) return f;
    float nf = float(n);
    float m = fmodC(f, nf);
    if (f < 0.0) m += nf;
    if (modo == 2) return m;
    bool impar = ((abs(int(f)) / n) & 1) != 0;
    bool espelha = f < 0.0 ? !impar : impar;
    return espelha ? nf - m : m;
}

// ---- o rip-map pela tabela de somas -------------------------------------------------------------------------
int largura(int eixo, int l) { return int(texelFetch(uTermos, ivec2(0, eixo * 16 + l), 0).x); }
int nTermos(int eixo, int l) { return int(texelFetch(uTermos, ivec2(0, eixo * 16 + l), 0).y); }
vec3 termo(int eixo, int l, int u) { return texelFetch(uTermos, ivec2(1 + u, eixo * 16 + l), 0).xyz; }

/** A folga do rip-map (1 texel antes, 2 depois): Reflect repete a borda, Tile pega o outro lado, No = −1 (zero). */
int resolve(int i, int n, int modo) {
    if (i >= 0 && i < n) return i;
    if (modo == 1) return -1;
    if (modo == 2) return i < 0 ? n - 1 : 0;
    return i < 0 ? 0 : n - 1;
}

/** A soma da tabela até (x, y), inclusive; 0 fora (x ou y < 0). Módulo 2^32. */
uvec4 sat(int x, int y) {
    if (x < 0 || y < 0) return uvec4(0u);
    uvec4 v = texelFetch(uSatL, ivec2(x, y), 0);
    int t = y >> 3;
    if (t > 0) v += texelFetch(uSatY, ivec2(x, t - 1), 0);
    return v;
}

uvec4 caixa(int x0, int y0, int lx, int ly) {
    int x1 = x0 + lx - 1;
    int y1 = y0 + ly - 1;
    return sat(x1, y1) - sat(x0 - 1, y1) - sat(x1, y0 - 1) + sat(x0 - 1, y0 - 1);
}

/** A média pré-multiplicada (0..1) do bloco; acima de 65 536 px, em pedaços (cada um cabe em 32 bits). */
vec4 media(int x0, int y0, int lx, int ly) {
    float area = float(lx) * float(ly);
    if (lx * ly <= 65536) return vec4(caixa(x0, y0, lx, ly)) / (65025.0 * area);
    int pedacos = min((lx * ly) >> 16, MAX_PEDACOS);
    int py = min(ly, pedacos);
    int px = max(1, pedacos / py);
    int hy = ly / py;
    int hx = lx / px;
    vec4 s = vec4(0.0);
    for (int u = 0; u < MAX_PEDACOS; u++) {
        if (u >= px) break;
        for (int v = 0; v < MAX_PEDACOS; v++) {
            if (v >= py) break;
            s += vec4(caixa(x0 + u * hx, y0 + v * hy, hx, hy));
        }
    }
    return s / (65025.0 * area);
}

/** O nível (0, 0) é a própria camada (pré-multiplicada, em float). */
vec4 pixel(int i, int j) {
    int x = resolve(i, uTamanho.x, uModo.x);
    int y = resolve(j, uTamanho.y, uModo.y);
    if (x < 0 || y < 0) return vec4(0.0);
    vec4 c = camada(ivec2(x, y));
    return vec4(c.rgb * c.a, c.a);
}

/** O texel (i, j) — índice real, a folga incluída — do nível (a, b). */
vec4 texel(int a, int b, int i, int j) {
    if (a == 0 && b == 0) return pixel(i, j);
    int nA = largura(0, a);
    int nB = largura(1, b);
    int kx = resolve(i, nA, uModo.x);
    int ky = resolve(j, nB, uModo.y);
    if (kx < 0 || ky < 0) return vec4(0.0);
    int sa = 1 << a;
    int sb = 1 << b;
    bool bx = kx == nA - 1;
    bool by = ky == nB - 1;
    if (!bx && !by) return media(kx * sa, ky * sb, sa, sb);
    int tx = bx ? nTermos(0, a) : 1;
    int ty = by ? nTermos(1, b) : 1;
    vec4 s = vec4(0.0);
    for (int u = 0; u < MAX_TERMOS; u++) {
        if (u >= tx) break;
        vec3 ex = bx ? termo(0, a, u) : vec3(1.0, float(kx * sa), float(sa));
        for (int v = 0; v < MAX_TERMOS; v++) {
            if (v >= ty) break;
            vec3 ey = by ? termo(1, b, v) : vec3(1.0, float(ky * sb), float(sb));
            s += (ex.x * ey.x) * media(int(ex.y), int(ey.y), int(ex.z), int(ey.z));
        }
    }
    return s;
}

/** O bilinear do Sapphire num nível (posição em coordenadas de centro do nível): i = trunc(f + 1), taps i − 1 e i. */
vec4 bilinear(int a, int b, float x, float y) {
    float x1 = x + 1.0;
    float y1 = y + 1.0;
    int ix = int(x1);
    int iy = int(y1);
    float tx = x1 - float(ix);
    float ty = y1 - float(iy);
    float txy = tx * ty;
    float w00 = ((1.0 - tx) - ty) + txy;
    float w10 = tx - txy;
    float w01 = ty - txy;
    int i0 = ix - 1;
    int j0 = iy - 1;
    vec4 p00, p10, p01, p11;
    int sa = 1 << a;
    int sb = 1 << b;
    if ((a > 0 || b > 0) && sa * sb <= 65536 && i0 >= 0 && j0 >= 0 &&
        i0 + 1 <= largura(0, a) - 2 && j0 + 1 <= largura(1, b) - 2) {
        // os quatro texels no miolo: 9 cantos da tabela em vez de 16
        int X0 = i0 * sa - 1, X1 = X0 + sa, X2 = X1 + sa;
        int Y0 = j0 * sb - 1, Y1 = Y0 + sb, Y2 = Y1 + sb;
        uvec4 s00 = sat(X0, Y0), s10 = sat(X1, Y0), s20 = sat(X2, Y0);
        uvec4 s01 = sat(X0, Y1), s11 = sat(X1, Y1), s21 = sat(X2, Y1);
        uvec4 s02 = sat(X0, Y2), s12 = sat(X1, Y2), s22 = sat(X2, Y2);
        float k = 1.0 / (65025.0 * float(sa) * float(sb));
        p00 = vec4(s11 - s01 - s10 + s00) * k;
        p10 = vec4(s21 - s11 - s20 + s10) * k;
        p01 = vec4(s12 - s02 - s11 + s01) * k;
        p11 = vec4(s22 - s12 - s21 + s11) * k;
    } else {
        p00 = texel(a, b, i0, j0);
        p10 = texel(a, b, i0 + 1, j0);
        p01 = texel(a, b, i0, j0 + 1);
        p11 = texel(a, b, i0 + 1, j0 + 1);
    }
    return p00 * w00 + p10 * w10 + p11 * txy + p01 * w01;
}

/** Uma amostra do nível (a, b): a posição levada ao nível, presa em [−1, n] no Wrap No. */
vec4 leNivel(int a, int b, float fx, float fy) {
    float gx = (fx + 0.5) * pot2(-a) - 0.5;
    float gy = (fy + 0.5) * pot2(-b) - 0.5;
    if (uModo.x == 1) gx = clamp(gx, -1.0, float(largura(0, a)));
    if (uModo.y == 1) gy = clamp(gy, -1.0, float(largura(1, b)));
    return bilinear(a, b, gx, gy);
}

void main() {
    ivec2 m = ivec2(gl_FragCoord.xy);
    ivec2 q = m - uOrigem;
    if (any(lessThan(q, ivec2(0))) || any(greaterThanEqual(q, uTamanho))) {
        fragColor = texelFetch(uEntrada, m, 0);
        return;
    }
    int W = uTamanho.x;
    int H = uTamanho.y;
    int k = q.x;
    int r = uDePe ? H - 1 - q.y : q.y;
    vec2 c = coords(k, r);
    float Wf = float(W);
    float fx = (c.x + 1.0) * 0.5 * Wf - 0.5;
    float fy = (1.0 - c.y) * 0.5 * Wf + (float(H - W) * 0.5 - 0.5);
    fx = envolve(fx, W, uModo.x);
    fy = envolve(fy, H, uModo.y);

    bool usa = false;
    float nx = 0.0;
    float ny = 0.0;
    if (uFiltro) {
        bvec4 tem = bvec4(k > 0, k < W - 1, r > 0, r < H - 1);
        vec2 cE = tem.x ? coords(k - 1, r) : c;
        vec2 cD = tem.y ? coords(k + 1, r) : c;
        vec2 cC = tem.z ? coords(k, r - 1) : c;
        vec2 cB = tem.w ? coords(k, r + 1) : c;
        float e = Wf * 0.25;
        nx = nivelDe(c.x, cE.x, cD.x, cC.x, cB.x, tem, e);
        ny = nivelDe(c.y, cE.y, cD.y, cC.y, cB.y, tem, e);
        usa = nx > 0.0 || ny > 0.0;
    }
    vec4 v;
    if (!usa) {
        float x = uModo.x == 1 ? clamp(fx, -1.0, Wf) : fx;
        float y = uModo.y == 1 ? clamp(fy, -1.0, float(H)) : fy;
        v = bilinear(0, 0, x, y);
    } else {
        float dx = nx >= 0.0 ? min(nx, uMaxNivel.x) : 0.0;
        float dy = ny >= 0.0 ? min(ny, uMaxNivel.y) : 0.0;
        int lx = int(dx);
        int ly = int(dy);
        float tx = dx - float(lx);
        float ty = dy - float(ly);
        vec4 A = leNivel(lx, ly, fx, fy);
        vec4 B = leNivel(lx + 1, ly + 1, fx, fy);
        if (ty < tx) {
            vec4 C = leNivel(lx + 1, ly, fx, fy);
            v = (tx - ty) * C + (1.0 - tx) * A + ty * B;
        } else if (ty > tx) {
            vec4 C = leNivel(lx, ly + 1, fx, fy);
            v = (ty - tx) * C + (1.0 - ty) * A + tx * B;
        } else {
            v = tx * (B - A) + A;
        }
    }
    // a saída do Sapphire é pré-multiplicada; o buffer guarda a cor reta em 8 bits (como o AE de 8 bpc a recebe)
    vec4 o = v.a > 0.0 ? vec4(v.rgb / v.a, v.a) : vec4(0.0);
    fragColor = floor(clamp(o, 0.0, 1.0) * 255.0 + 0.5) / 255.0;
}
