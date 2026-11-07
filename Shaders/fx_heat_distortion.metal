// ---------------------------------------------------------------------------
// Heat Distortion
// origem : assets/effects/heat-distortion.xml
// id     : nova.effect.heatdistortion
// passes : 12
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct heat_distortionParams {
    int pattern;
    float distortion;
    float heat;
    float bias;
    float scale;
    float speed;
    float softness;
    float2 offset;
    float complexity;
    float gamma;
    float aspect;
    float windSpeed;
    float windDirection;
    int maskMode;
    int overrideAlpha;
    int clipBounds;
    int renderMode;
};

// --- funcoes auxiliares do efeito
// ------------------------------------------------------------------ 16 bits
float2 empacota(float v01) {
    float q = floor(clamp(v01, 0.0, 1.0) * 65535.0 + 0.5);
    return float2(floor(q / 256.0), __nv_mod(q, 256.0)) / 255.0;
}

float desempacota(float2 c) {
    return (floor(c.x * 255.0 + 0.5) * 256.0 + floor(c.y * 255.0 + 0.5)) / 65535.0;
}

// O maior h guardado (px do buffer): 512.
const float H_MAX = 512.0;

int2 tamanho() { return int2(eng.acResolution + 0.5); }

bool dentro(int2 p, int2 t) { return p.x >= 0 && p.y >= 0 && p.x < t.x && p.y < t.y; }

/** N ou v em −1..1, guardado em RG. */
float lerSinal(sampler2D b, int2 p) { return desempacota(b.read(uint2(p), uint(0)).rg) * 2.0 - 1.0; }

float esc() { return max(eng.acEscalaDePixel, 1e-4); }

// ------------------------------------------------------- Perlin (Ken Perlin)
const int PERM[256] = int[256](151,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,190,6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,88,237,149,56,87,174,20,125,136,171,168,68,175,74,165,71,134,139,48,27,166,77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,102,143,54,65,25,63,161,1,216,80,73,209,76,132,187,208,89,18,169,200,196,135,130,116,188,159,86,164,100,109,198,173,186,3,64,52,217,226,250,124,123,5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,223,183,170,213,119,248,152,2,44,154,163,70,221,153,101,155,167,43,172,9,129,22,39,253,19,98,108,110,79,113,224,232,178,185,112,104,218,246,97,228,251,34,242,193,238,210,144,12,191,179,162,241,81,51,145,235,249,14,239,107,49,192,214,31,181,199,106,157,184,84,204,176,115,121,50,45,127,4,150,254,138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180);

int perm(int i) { return PERM[i & 255]; }

float grad(int h, float x, float y, float z) {
    h = h & 15;
    float u = h < 8 ? x : y;
    float v = h < 4 ? y : ((h == 12 || h == 14) ? x : z);
    return ((h & 1) != 0 ? -u : u) + ((h & 2) != 0 ? -v : v);
}

float fade(float t) { return t * t * t * (t * (t * 6.0 - 15.0) + 10.0); }

float perlin(float3 p) {
    float3 f = floor(p);
    int X = int(f.x) & 255;
    int Y = int(f.y) & 255;
    int Z = int(f.z) & 255;
    p -= f;
    float u = fade(p.x), v = fade(p.y), w = fade(p.z);
    int A = perm(X) + Y, AA = perm(A) + Z, AB = perm(A + 1) + Z;
    int B = perm(X + 1) + Y, BA = perm(B) + Z, BB = perm(B + 1) + Z;
    float x = p.x, y = p.y, z = p.z;
    return mix(mix(mix(grad(perm(AA), x, y, z), grad(perm(BA), x - 1.0, y, z), u),
                   mix(grad(perm(AB), x, y - 1.0, z), grad(perm(BB), x - 1.0, y - 1.0, z), u), v),
               mix(mix(grad(perm(AA + 1), x, y, z - 1.0), grad(perm(BA + 1), x - 1.0, y, z - 1.0), u),
                   mix(grad(perm(AB + 1), x, y - 1.0, z - 1.0), grad(perm(BB + 1), x - 1.0, y - 1.0, z - 1.0), u), v), w);
}

float fbm(float3 p, int oitavas) {
    float s = 0.0;
    float a = 1.0;
    for (int i = 0; i < 10; i++) {
        if (i >= oitavas) break;
        s += a * perlin(p);
        p *= 2.0;
        a *= 0.5;
    }
    return s;
}

// ------------------------------------------------------------ as etapas
float escalaDoRuido() { return max(floor(u.scale), 1.0) * esc(); }

bool comDeslocamento() { return u.renderMode == 0 || u.renderMode == 1; }

bool comCalor() { return (u.renderMode == 0 || u.renderMode == 2) && u.heat > 0.0 && u.bias < 1.0; }

/** Passe 0: N em −1..1 no pixel p. */
float ruidoNo(int2 p) {
    float e = esc();
    float borda = u.clipBounds ? 0.0 : 1.5 * u.distortion * e;
    float2 xy = float2(p) + borda;
    float2 off = u.offset * eng.acResolution;
    float S = escalaDoRuido();
    float K = u.aspect < 0.0 ? 1.0 + 0.9 * u.aspect : 1.0 + 9.0 * u.aspect;
    float th = radians(u.windDirection) + 1.5707963;
    float w = eng.acTime * u.windSpeed * 2.5;
    float3 q = float3((xy.x - off.x) * K / S + cos(th) * w,
                  (xy.y - off.y) / S + sin(th) * w,
                  u.speed * eng.acTime);
    float n = clamp(fbm(q, int(u.complexity + 0.5)), -1.0, 1.0);
    float N = pow((n + 1.0) * 0.5, 1.5 * u.gamma) * 2.0 - 1.0;
    if (u.overrideAlpha) N *= inputImg.read(uint2(p), uint(0)).a;
    if (int2(int(layerMask.get_width()), int(layerMask.get_height())).x > 1) {
        float4 m = layerMask.sample(__nv_smp, in.acScreenNorm);
        float lum = dot(m.rgb, float3(0.2126, 0.7152, 0.0722));
        float f = u.maskMode == 0 ? m.a : (u.maskMode == 1 ? lum : (u.maskMode == 2 ? 1.0 - m.a : 1.0 - lum));
        N *= f;
    }
    return clamp(N, -1.0, 1.0);
}

/** N fora da imagem conta como 0 (a normal do plugin). */
float nOuZero(int2 p, int2 t) { return dentro(p, t) ? lerSinal(ruido, p) : 0.0; }

/** Bilinear do plugin no ruído (borda presa; o canto esquerdo/superior com o mesmo arredondamento dele). */
float ruidoBilinear(float2 s, int2 t) {
    float2 f = floor(s);
    float2 fr = s - f;
    // int(f + 0,5) trunca para zero: em f = −1 dá 0 e 1, como no plugin.
    int2 i0 = int2(int(f.x + 0.5), int(f.y + 0.5));
    int2 i1 = i0 + 1;
    int2 lo = int2(0), hi = t - 1;
    i0 = clamp(i0, lo, hi);
    i1 = clamp(i1, lo, hi);
    float a = lerSinal(ruido, int2(i0.x, i0.y)), b = lerSinal(ruido, int2(i1.x, i0.y));
    float c = lerSinal(ruido, int2(i0.x, i1.y)), d = lerSinal(ruido, int2(i1.x, i1.y));
    return mix(mix(a, b, fr.x), mix(c, d, fr.x), fr.y);
}

/** A imagem em (s), bilinear, com a borda presa ou transparente fora (Clip Bounds). */
float4 imagemBilinear(float2 s, int2 t) {
    float2 f = floor(s);
    float2 fr = s - f;
    int2 i0 = int2(f);
    float4 c[4];
    for (int k = 0; k < 4; k++) {
        int2 q = i0 + int2(k & 1, k >> 1);
        if (u.clipBounds) c[k] = inputImg.read(uint2(clamp(q, int2(0), t - 1)), uint(0));
        else c[k] = dentro(q, t) ? inputImg.read(uint2(q), uint(0)) : float4(0.0);
    }
    return mix(mix(c[0], c[1], fr.x), mix(c[2], c[3], fr.x), fr.y);
}

float calorDoPixel(int2 p) {
    if (!comCalor()) return 0.0;
    float v = lerSinal(ruido2, p);
    return max(abs(v) - u.bias, 0.0) / (1.0 - u.bias) * u.heat * esc();
}

float lerCalor(sampler2D b, int2 p) { return desempacota(b.read(uint2(p), uint(0)).rg) * H_MAX; }

float4 guardarCalor(float h) { return float4(empacota(h / H_MAX), 0.0, 1.0); }

/** Caixa do Softness: (x − r, x + r], zeros fora, ÷ 2r, num eixo. */
float caixaDoCalor(sampler2D b, int2 p, int2 t, int2 eixo, int r, bool doRuido) {
    float s = 0.0;
    for (int i = -r + 1; i <= r; i++) {
        int2 q = p + eixo * i;
        if (!dentro(q, t)) continue;
        s += doRuido ? calorDoPixel(q) : lerCalor(b, q);
    }
    return s / float(2 * r);
}

/** Média exata por área num eixo: [c + ½ − h/2, c + ½ + h/2] recortado na imagem. */
float4 caixaDaImagem(sampler2D b, int2 p, int2 t, int eixo, float h) {
    int n = eixo == 0 ? t.x : t.y;
    float c = float(eixo == 0 ? p.x : p.y) + 0.5;
    float a = max(c - 0.5 * h, 0.0);
    float z = min(c + 0.5 * h, float(n));
    float4 soma = float4(0.0);
    int i0 = int(floor(a));
    int i1 = int(ceil(z));
    for (int i = i0; i < i1; i++) {
        float peso = min(z, float(i + 1)) - max(a, float(i));
        int2 q = eixo == 0 ? int2(i, p.y) : int2(p.x, i);
        soma += b.read(uint2(q), uint(0)) * peso;
    }
    return soma / max(z - a, 1e-6);
}

fragment float4 fx_heat_distortion(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant heat_distortionParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> ruido [[texture(1)]],
    texture2d<float> normal [[texture(2)]],
    texture2d<float> ruido2 [[texture(3)]],
    texture2d<float> desl [[texture(4)]],
    texture2d<float> calorA [[texture(5)]],
    texture2d<float> calorB [[texture(6)]],
    texture2d<float> imgA [[texture(7)]],
    texture2d<float> imgB [[texture(8)]],
    texture2d<float> layerMask [[texture(9)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    int2 t = tamanho();
    int2 p = int2(floor(in.acScreenNorm * eng.acResolution));
    float e = esc();

    if (eng.acPass == 0) {
        __nv_out = float4(empacota((ruidoNo(p) + 1.0) * 0.5), 0.0, 1.0);
        return __nv_out;
    }
    if (eng.acPass == 1) {
        if (u.pattern == 0) { __nv_out = float4(0.0); return __nv_out; }
        float gx = nOuZero(p + int2(1, 0), t) - nOuZero(p - int2(1, 0), t);
        float gy = nOuZero(p + int2(0, 1), t) - nOuZero(p - int2(0, 1), t);
        float2 nrm = float2(gx, gy) / sqrt(gx * gx + gy * gy + 4.0);
        __nv_out = float4(empacota((nrm.x + 1.0) * 0.5), empacota((nrm.y + 1.0) * 0.5));
        return __nv_out;
    }
    if (eng.acPass == 2) {
        float N;
        if (u.pattern == 0) {
            N = lerSinal(ruido, p);
        } else {
            float4 c = normal.read(uint2(p), uint(0));
            float2 nrm = float2(desempacota(c.rg), desempacota(c.ba)) * 2.0 - 1.0;
            float k = (u.pattern == 2 ? -10.0 : -2.0) * escalaDoRuido();
            N = ruidoBilinear(float2(p) + k * nrm, t);
        }
        float v = clamp(u.pattern == 1 ? -N : N, -1.0, 1.0);
        __nv_out = float4(empacota((v + 1.0) * 0.5), 0.0, 1.0);
        return __nv_out;
    }
    if (eng.acPass == 3) {
        float v = lerSinal(ruido2, p);
        if (u.renderMode == 3) {
            __nv_out = float4(float3((v + 1.0) * 0.5), 1.0);
            return __nv_out;
        }
        float D = comDeslocamento() ? u.distortion * e : 0.0;
        float4 c = D > 0.0 ? imagemBilinear(float2(p) + v * D, t) : inputImg.read(uint2(p), uint(0));
        if (u.overrideAlpha) c.a = 1.0;
        __nv_out = c;
        return __nv_out;
    }

    // ---------------------------------------- o h: duas caixas do Softness
    float sof = u.softness * e;
    int r = int((sof + 1.0) * 0.5);
    bool caixa = sof >= 1.0 && r >= 1;
    if (eng.acPass == 4) {
        __nv_out = guardarCalor(caixa ? caixaDoCalor(ruido2, p, t, int2(1, 0), r, true) : calorDoPixel(p));
        return __nv_out;
    }
    if (eng.acPass == 5 || eng.acPass == 7) {
        __nv_out = guardarCalor(caixa ? caixaDoCalor(calorA, p, t, int2(0, 1), r, false) : lerCalor(calorA, p));
        return __nv_out;
    }
    if (eng.acPass == 6) {
        __nv_out = guardarCalor(caixa ? caixaDoCalor(calorB, p, t, int2(1, 0), r, false) : lerCalor(calorB, p));
        return __nv_out;
    }

    // ------------------------------- a imagem: duas caixas de lado h por pixel
    float h = lerCalor(calorB, p);
    bool borra = h > 1.0;
    if (eng.acPass == 8) {
        __nv_out = borra ? caixaDaImagem(desl, p, t, 0, h) : desl.read(uint2(p), uint(0));
        return __nv_out;
    }
    if (eng.acPass == 9) {
        // Onde h ≤ 1 o pixel fica como estava ANTES da passada horizontal.
        __nv_out = borra ? caixaDaImagem(imgA, p, t, 1, h) : desl.read(uint2(p), uint(0));
        return __nv_out;
    }
    if (eng.acPass == 10) {
        __nv_out = borra ? caixaDaImagem(imgB, p, t, 0, h) : imgB.read(uint2(p), uint(0));
        return __nv_out;
    }
    __nv_out = borra ? caixaDaImagem(imgA, p, t, 1, h) : imgB.read(uint2(p), uint(0));
    return __nv_out;
}
