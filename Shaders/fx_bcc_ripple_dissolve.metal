// ---------------------------------------------------------------------------
// BCC Ripple Dissolve
// origem : assets/effects/bcc-ripple-dissolve.xml
// id     : nova.effect.bccrippledissolve
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct bcc_ripple_dissolveParams {
    int animation;
    float percentDone;
    float2 center;
    float radiusPeak;
    float height;
    float perpHeight;
    float waveWidth;
    float widthIncrease;
    float speed;
    float speedDecel;
    float phase;
    float insideRadius;
    float fallOff;
    float pinWidth;
    float lightLevel;
    float4 lightColor;
    float lightWidth;
    float lightFocus;
    float lightAngle;
    float lightElevation;
    int applyMode;
    float dissolveDuration;
    float heightScale;
    float widthScale;
    float speedScale;
};

// --- funcoes auxiliares do efeito
// Do Kotlin (RippleDissolveDoBcc): o struct do plugin neste quadro. Os comprimentos vêm em "px de 720 linhas" (o
// shader multiplica pela altura da camada / 720), a fase já com a Speed integrada no tempo, reduzida a [0, 360).
uniform float rdAltura, rdMeia, rdPerp, rdInterno, rdRaio, rdQueda, rdFase;
uniform int rdNivel;                       // Light Level·2,56·s, inteiro (0 = sem luz)
uniform int rdK8;                          // o alfa da dissolução em 1/255 (255 = nada)
uniform bool rdLuzAtiva;                   // Elevation < 100: L0 pela direção
uniform float rdElev, rdEf, rdEt, rdM;     // 90·smoothstep(e), e/10, o expoente e o fator de trás
uniform float4 rdLobo;                       // l2c, l30, rampa de baixo, rampa de cima (graus)
uniform float2 rdFoco;                       // k, 1 − k

const float GRAU = 0.017453292519943295;

int W, H;
int2 gBuf, gInicio;
bool dePe;

void preparar() {
    gBuf = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    int2 tam = clamp(int2(floor(eng.acCamada * float2(gBuf) + 0.5)), int2(1), gBuf);
    gInicio = (gBuf - tam) / 2;
    W = tam.x; H = tam.y;
    dePe = eng.acEntradaDePe == 1;
}
int2 noBuffer(int x, int y) { return gInicio + int2(x, dePe ? H - 1 - y : y); }

// O pixel (x, y) da camada (linha 0 = topo, como no AE). Fora do quadro: a cor do vizinho de dentro, alfa 0.
float4 pixel(int x, int y) {
    int cx = clamp(x, 0, W - 1), cy = clamp(y, 0, H - 1);
    float4 c = inputImg.read(uint2(noBuffer(cx, cy)), uint(0));
    if (cx != x || cy != y) c.a = 0.0;
    return c;
}
float4 bilinear(float2 p) {
    float2 b = floor(p), f = p - b;
    int x = int(b.x), y = int(b.y);
    if (x < -1 || y < -1 || x >= W || y >= H) return float4(0.0);
    return mix(mix(pixel(x, y), pixel(x + 1, y), f.x), mix(pixel(x, y + 1), pixel(x + 1, y + 1), f.x), f.y);
}

float mod360(float a) { return a - 360.0 * floor(a / 360.0); }

// O Pin Width (0x18052d100, medido no AE): o deslocamento × peso(x)·peso(y), d = distância do CENTRO do pixel à
// borda; rampa d·2/(2k + L − k) até k = 0,8·L, depois 1 − (L − d)²/(2(L − k)k + (L − k)²) até 1 em L = n·pino/2.
float pesoDoPino(float d, float L) {
    if (d >= max(L, 1.0)) return 1.0;
    float k = 0.8 * L, a = L - k;
    float f = d < k ? d * 2.0 / (2.0 * k + a) : 1.0 - (L - d) * (L - d) / (2.0 * a * k + a * a);
    return clamp(f, 0.0, 1.0);
}

// O envelope radial: a rampa de dentro, 1, a cauda; 0 antes de r0 e depois do alcance.
float envelope(float r, float Ir, float R, out float alcance) {
    alcance = (rdQueda * 0.9 + 2.0) * R;
    float r0 = (0.5 - rdQueda * 0.45) * Ir;
    if (r < r0 || r0 > alcance) return 0.0;
    if (r < Ir) return max((r - r0) / max(Ir - r0, 1e-6), 0.0);
    if (r > R) return max((alcance - r) / max(alcance - R, 1e-6), 0.0);
    return 1.0;
}

// O lobo da luz (0x180e300b0): 0 fora de (l2c, l30), a curva u·(k·u + 1 − k) nas rampas, inteiro como no plugin.
float lobo(float y) {
    y = mod360(y);
    if (y >= rdLobo.y || y <= rdLobo.x) return 0.0;
    float u;
    if (y < 180.0) u = (y - rdLobo.x) / rdLobo.z;
    else if (y > 180.0) u = (rdLobo.y - y) / rdLobo.w;
    else return float(rdNivel);
    float c = clamp(u * (u * rdFoco.x + rdFoco.y), 0.0, 1.0);
    return floor(float(rdNivel) * c);
}
// A (frente) e B (trás) crus no grau inteiro i da fase da onda (o laço de 360 do WaveLight).
float2 loboCru(float i) {
    float x = i + rdFase;
    float sv = sin(x * GRAU), sv2 = sin((x - 0.1) * GRAU);
    float ac = acos(clamp(sv, -1.0, 1.0)) / GRAU;
    if (sv > sv2) ac = -ac;
    return float2(lobo(ac + rdElev), lobo(ac - rdElev));
}
// Suavizado como o 0x18036b250 (s = 1,5): 0,1·(i ± 2) + 0,26667·(i − 1, i, i + 1), truncado.
float2 loboSuave(float i) {
    float2 s3 = loboCru(i - 1.0) + loboCru(i) + loboCru(i + 1.0);
    float2 s2 = loboCru(i - 2.0) + loboCru(i + 2.0);
    return floor(s2 * 0.1 + s3 * 0.26666668);
}
// L0 e o lado (frente/trás) pela direção j (graus inteiros) do pixel.
float2 direcao(float j) {
    float a = j + u.lightAngle;
    a = a - 360.0 * floor((a + 180.0) / 360.0);
    a *= GRAU;
    float v = 0.48780487804878 * cos(2.0 * a) + 0.51219512195122;
    if (cos(a) > 0.0) return float2(pow(v, rdEf), 1.0);
    return float2(pow(abs(v), rdEt) * rdM, 0.0);
}

fragment float4 fx_bcc_ripple_dissolve(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant bcc_ripple_dissolveParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    preparar();
    int2 t = min(int2(floor(in.acScreenNorm * float2(gBuf))), gBuf - int2(1));
    int2 q = t - gInicio;
    float4 src = inputImg.read(uint2(t), uint(0));
    if (any(lessThan(q, int2(0))) || any(greaterThanEqual(q, int2(W, H)))) { __nv_out = src; return __nv_out; }
    int x = q.x, y = dePe ? H - 1 - q.y : q.y;

    float esc = float(H) / 720.0;
    float meia = max(rdMeia * esc, 1.0), altura = rdAltura * esc, perp = rdPerp * esc;
    float Ir = rdInterno * esc, R = rdRaio * esc;
    float2 c = __nv_acPontoNoBuffer(u.center) * float2(gBuf) - float2(gInicio);
    if (dePe) c.y = float(H) - c.y;
    c = float2(clamp(c.x, 0.0, float(W)), clamp(c.y, 0.0, float(H)));

    float dx = float(x) - c.x, dy = c.y - float(y);            // y para cima, como o plugin
    float r = length(float2(dx, dy));
    float alcance;
    float env = envelope(r, Ir, R, alcance);
    float4 cor = src;
    if (r < alcance) {
        float gp = 180.0 / meia;
        float s = sin((r * gp + rdFase) * GRAU);
        float D = s * altura * env;
        float P = r > 0.1 ? -s * perp * env / r : 0.0;
        float a = __nv_atan(dy, dx) + P;
        float2 org = c + (r + D) * float2(cos(a), -sin(a));
        // o pino (0x18097a058: 0,01·max(Perp/4, Pin Width, Height/4), com Height e Perp crus; o modo é Pin Edges)
        if (u.height != 0.0 || u.perpHeight != 0.0) {
            float pino = 0.01 * max(u.perpHeight * 0.25, max(u.pinWidth, u.height * 0.25));
            float px = float(x) + 0.5, py = float(y) + 0.5;
            float w = pesoDoPino(min(px, float(W) - px), float(W) * pino * 0.5)
                    * pesoDoPino(min(py, float(H) - py), float(H) * pino * 0.5);
            org = float2(float(x), float(y)) + (org - float2(float(x), float(y))) * w;
        }
        cor = bilinear(org);

        // a luz pelo r e o θ ORIGINAIS do pixel
        if (rdNivel != 0) {
            float ang = mod360(r * gp);
            float i = floor(ang), f = ang - i;
            float2 lab = mix(loboSuave(i), loboSuave(i + 1.0), f) * env;
            float L = lab.x;
            if (rdLuzAtiva) {
                float th = mod360(degrees(__nv_atan(dy, dx)));
                float j = floor(th), g = th - j;
                float2 d0 = direcao(j), d1 = direcao(j + 1.0);
                float l0 = mix(floor(d0.x * 65536.0 + 0.5), floor(d1.x * 65536.0 + 0.5), g) / 65536.0;
                L = l0 * (d0.y > 0.5 ? lab.x : lab.y);
            }
            float w = min(L, 255.0) / 256.0;
            float3 novo = u.applyMode == 1 ? min(cor.rgb + u.lightColor.rgb, 1.0) : u.lightColor.rgb;
            cor.rgb += (novo - cor.rgb) * w;
        }
    }
    // a dissolução: alfa·k8 >> 8 em 8 bits
    if (rdK8 < 255) {
        int a8 = int(floor(cor.a * 255.0 + 0.5));
        cor.a = float((a8 * rdK8) >> 8) / 255.0;
    }
    __nv_out = clamp(cor, 0.0, 1.0);
    return __nv_out;
}
