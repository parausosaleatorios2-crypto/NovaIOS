// ---------------------------------------------------------------------------
// Grunge
// origem : assets/effects/am-grunge.xml
// id     : nova.effect.am-grunge
// passes : 7
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_grungeParams {
    float strength;
    int t1active;
    int t1region;
    float t1grain;
    float t1scale;
    float t1angle;
    float2 t1offset;
    float t1gamma;
    float t1contrast;
    float t1alpha;
    float4 t1color;
    float t1burn;
    float t1spread;
    float t1choke;
    int t1invert;
    int t1light;
    float t1lightAngle;
    int t1blendMode;
    int t2active;
    int t2region;
    float t2grain;
    float t2scale;
    float t2angle;
    float2 t2offset;
    float t2gamma;
    float t2contrast;
    float t2alpha;
    float4 t2color;
    float t2burn;
    float t2spread;
    float t2choke;
    int t2invert;
    int t2light;
    float t2lightAngle;
    int t2blendMode;
    int t3active;
    int t3region;
    float t3grain;
    float t3scale;
    float t3angle;
    float2 t3offset;
    float t3gamma;
    float t3contrast;
    float t3alpha;
    float4 t3color;
    float t3burn;
    float t3spread;
    float t3choke;
    int t3invert;
    int t3light;
    float t3lightAngle;
    int t3blendMode;
    int t4active;
    int t4region;
    float t4grain;
    float t4scale;
    float t4angle;
    float2 t4offset;
    float t4gamma;
    float t4contrast;
    float t4alpha;
    float4 t4color;
    float t4burn;
    float t4spread;
    float t4choke;
    int t4invert;
    int t4light;
    float t4lightAngle;
    int t4blendMode;
    int t5active;
    int t5region;
    float t5grain;
    float t5scale;
    float t5angle;
    float2 t5offset;
    float t5gamma;
    float t5contrast;
    float t5alpha;
    float4 t5color;
    float t5burn;
    float t5spread;
    float t5choke;
    int t5invert;
    int t5light;
    float t5lightAngle;
    int t5blendMode;
    int t6active;
    int t6region;
    float t6grain;
    float t6scale;
    float t6angle;
    float2 t6offset;
    float t6gamma;
    float t6contrast;
    float t6alpha;
    float4 t6color;
    float t6burn;
    float t6spread;
    float t6choke;
    int t6invert;
    int t6light;
    float t6lightAngle;
    int t6blendMode;
    int t7active;
    int t7region;
    float t7grain;
    float t7scale;
    float t7angle;
    float2 t7offset;
    float t7gamma;
    float t7contrast;
    float t7alpha;
    float4 t7color;
    float t7burn;
    float t7spread;
    float t7choke;
    int t7invert;
    int t7light;
    float t7lightAngle;
    int t7blendMode;
    int t8active;
    int t8region;
    float t8grain;
    float t8scale;
    float t8angle;
    float2 t8offset;
    float t8gamma;
    float t8contrast;
    float t8alpha;
    float4 t8color;
    float t8burn;
    float t8spread;
    float t8choke;
    int t8invert;
    int t8light;
    float t8lightAngle;
    int t8blendMode;
    int d1active;
    int d1region;
    float2 d1offset;
    int d1fromctr;
    float d1grain;
    float d1scale;
    float d1angle;
    float2 d1toffset;
    float d1gamma;
    float d1contrast;
    int d2active;
    int d2region;
    float2 d2offset;
    int d2fromctr;
    float d2grain;
    float d2scale;
    float d2angle;
    float2 d2toffset;
    float d2gamma;
    float d2contrast;
    int c1active;
    float4 fillColor;
    float fillColorBlend;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265;

// O float que a textura de 8 bits devolve para o nível k (k/255 arredondado como o hardware), montado pelos bits: gravado
// num alvo de 8 bits volta a ser k em qualquer GPU (o `oitoBits` do Equilíbrio de cor).
static float oitoBits(float k) {
    uint n = uint(k);
    if (n == 0u) return 0.0;
    if (n == 255u) return 1.0;
    int j = 0;                                                    // o bit mais alto de n
    for (int i = 1; i < 8; i++) if (n >= (1u << uint(i))) j = i;
    int e = 31 - j;
    uint q = ((n << uint(e)) + 127u) / 255u;                      // entre 2^23 e 2^24
    return as_type<float>((uint(150 - e) << 23) + (q - 0x800000u));
}

// A gaussiana de meio-lado `lado` (em pixels de `img`) no eixo `passo`, na mesma ordem de contas do Gaussian do AM (a
// do `am-gaussian-blur.xml` e do `am-unsharp-mask.xml`).
static float4 desfocar(sampler2D img, float2 passo, float2 st, float lado) {
    if (u.strength <= 0.0) return float4(0.0);
    float sigma = lado / 2.14596602;
    float3 g;
    g.x = 1.0 / (sqrt(2.0 * PI) * sigma);
    g.y = exp(-0.5 / (sigma * sigma));
    g.z = g.y * g.y;
    float4 soma = float4(0.0);
    float total = 0.0;
    soma += img.sample(__nv_smp, st) * g.x;
    total += g.x;
    for (float i = 1.0; i <= lado; i += 2.0) {
        float d0 = i;
        float d1 = i + 1.0;
        g.xy *= g.yz;
        total += 2.0 * g.x;
        float p0 = g.x;
        g.xy *= g.yz;
        total += 2.0 * g.x;
        float p1 = g.x;
        float par = p0 + p1;
        float d = (d0 * p0 + d1 * p1) / par;
        float2 stL = st - d * passo;
        float2 stR = st + d * passo;
        soma += img.sample(__nv_smp, stL) * par;
        soma += img.sample(__nv_smp, stR) * par;
    }
    return soma / total;
}

// O meio-lado: Tamanho da Borda ÷ 2 × 1,14 ÷ 4 ÷ 3 da diagonal da imagem CHEIA (o `eng.acPreviewSize` do AM).
static float ladoDoDesfoque() {
    return u.strength / 2.0 * 1.14 / 4.0 / 3.0 * length(float2(int2(int(pre.get_width()), int(pre.get_height()))));
}

// A volta da `eng.acCamadaParaTela`: UV da tela → UV do buffer da camada.
static float2 naCamada(float2 t) {
    float3 c = __nv_inverse(eng.acCamadaParaTela) * float3(t, 1.0);
    return c.xy / c.z;
}

// ---------------------------------------------------------------- daqui até o `main`, as funções do AM, linha por linha

static float saturate(float v) { return clamp(v, 0., 1.); }

static float2x2 rot2(float a) {
    float c = cos(a);
    float s = sin(a);
    return float2x2(c,s,-s,c);
}

static float4 composite( float4 a, float4 b) {
    return a * (1. - b.a) + b;
}

static float sampleGrain(float2 uv, int grainType, float gamma, float contrast, float scale, float angle, float2 offset, bool invert) {

    uv -= 0.5;
    uv *= rot2(angle*0.0174533);
    uv /= scale;
    uv += 0.5;
    uv -= offset * float2(1., -1.) / 500.;
    uv = fract(uv);

    float grainLuma;
    if( grainType == 1 ) {
        grainLuma = grunge_a.sample(__nv_smp, uv).r;
    } else if( grainType == 2 ) {
        grainLuma = grunge_a.sample(__nv_smp, uv).g;
    } else if( grainType == 3 ) {
        grainLuma = grunge_a.sample(__nv_smp, uv).b;
    } else if( grainType == 4 ) {
        grainLuma = grunge_b.sample(__nv_smp, uv).r;
    } else if( grainType == 5 ) {
        grainLuma = grunge_b.sample(__nv_smp, uv).g;
    } else if( grainType == 6 ) {
        grainLuma = grunge_b.sample(__nv_smp, uv).b;
    } else if( grainType == 7 ) {
        grainLuma = dot(grunge_a.sample(__nv_smp, uv).rgb, float3(1.)) / 3.;
    } else if( grainType == 8 ) {
        grainLuma = dot(grunge_b.sample(__nv_smp, uv).rgb, float3(1.)) / 3.;
    } else if( grainType == 9 ) {
        grainLuma = dot(grunge_b.sample(__nv_smp, uv).rb, float2(1.)) / 2.;
    } else if( grainType == 10 ) {
        uv *= 16.;
        float2 st = fract(uv);
        float2 id = floor(uv);
        if( __nv_mod(id.x + id.y, 2.) == 0. ) {
            st = st.yx;
        }
        float pp = 6.;
        float p = pow(sin(st.x*3.14159*1.),pp);
        st = st.yx;
        float q = clamp(pow(sin(st.x*3.14159*1.),pp),0.,1.);
        p += q * pow((1.-p),10.);
        grainLuma = p;
    } else if( grainType == 11 ) {
        float2 st = uv * 16.;
        float2 id = floor(st);
        st = fract(st);
        if( __nv_mod(id.x + id.y, 2.) == 0. ) {
            st = st.yx;
        }
        float pp = 6.;
        float p = pow(sin(st.x*3.14159*1.),pp);
        st = st.yx;
        float q = clamp(pow(sin(st.x*3.14159*1.),pp),0.,1.);
        p += q * pow((1.-p),10.);
        p = saturate(p);
        float tc = grunge_b.sample(__nv_smp, uv).b;
        grainLuma = p * abs(p-tc);
    } else if( grainType == 12 ) {
        grainLuma = sin(uv.y*30.*3.14159)*0.5+0.5;
    } else if( grainType == 13 ) {
        grainLuma = min(sin(uv.y*30.*3.14159)*0.5+0.5,sin(uv.x*30.*3.14159)*0.5+0.5);
    } else if( grainType == 14 ) {
        grainLuma = (sin(uv.y*30.*3.14159)*sin(uv.x*30.*3.14159))*0.5+0.5;
    } else if( grainType == 15 ) {
        grainLuma = uv.y;
    } else if( grainType == 16 ) {
        grainLuma = 1.0;
    } else {
        grainLuma = 0.5;
    }

    grainLuma = saturate(((grainLuma-0.5) * (1.+contrast)) + 0.5);
    grainLuma = pow(grainLuma,1.0/gamma);
    if( invert )
        grainLuma = 1.-grainLuma;

    return grainLuma;

}

static float2 applyDisplace(float2 displace, float4 blurColor, float2 offset, bool fromCtr, int region, float2 uv, int grainType, float gamma, float contrast, float scale, float angle, float2 texOffset) {

    float p;
    if( region == 1) {  // Edge
        p = 1. - saturate((blurColor.a-0.5) * 2.);
    } else if( region == 2 ) {  // Center
        p = saturate((blurColor.a-0.5) * 2.);
    } else if( region == 3 ) {  // Fill
        p = 1.;
    } else {
        p = 0.;
    }

    float g = sampleGrain( uv, grainType, gamma, contrast, scale, angle, texOffset, false);

    if( fromCtr ) {
        g = (g - 0.5) * 2.;
    }

    return displace + (offset * float2(1.,-1.) / 2000.) * g * p;
}

static float4 blendGrain(float4 baseColor, float4 originalColor, float4 blurColor, float4 color, float alpha, int blendMode, int region, float spread, float rawChoke, float burn, float2 uv, int grainType, float gamma, float contrast, float scale, float angle, float2 offset, bool invert, bool light, float lightAngle) {

    float choke = clamp(rawChoke,0.,0.999);

    float p;
    float m;
    if( region == 1) {  // Edge
        m = baseColor.a;
        p = 1. - saturate((blurColor.a-0.5) * 2.);
    } else if( region == 2 ) {  // Center
        m = baseColor.a;
        p = saturate((blurColor.a-0.5) * 2.);
    } else if( region == 3 ) {  // Fill
        m = baseColor.a;
        p = 1.;
    } else if( region == 4 ) {  // Glow
        m = 1.-baseColor.a;
        p = saturate(blurColor.a * 2. - baseColor.a);
    } else {
        m = 0.;
        p = 0.;
    }

    p = saturate((p-choke)/(max(1.-spread,choke+0.0001)-choke));
    float g;
    if( light ) {
        float2 lv = float2(.002, 0.) * rot2(lightAngle*0.0174533);
        float g1 = sampleGrain( uv+lv, grainType, gamma, contrast, scale, angle, offset, invert);
        float g2 = sampleGrain( uv-lv, grainType, gamma, contrast, scale, angle, offset, invert);
        g = saturate((g1-g2)*5.);
    } else {
        g = sampleGrain( uv, grainType, gamma, contrast, scale, angle, offset, invert);
    }

    float4 c = color;
    if( burn < 0.0 ) {
        c.rgb = mix(c.rgb, 1.-(1.-c.rgb) * (1.-(0.5+c.rgb*0.5)), -burn * g*g );
    } else {
        c.rgb = mix(c.rgb, c.rgb * c.rgb * 0.25, burn * g * g );
    }
    c *= alpha * p * g;

    if( region==4 ) {
        return composite(baseColor,c * m);
    } else if( blendMode==1 ) { // Multiply
        float3 baseRgb = baseColor.rgb / max(baseColor.a,0.00001);
        float3 rgb = c.rgb / max(c.a,0.00001);
        float3 adj = baseRgb * rgb;
        return composite(baseColor,float4(adj,1.) * c.a * baseColor.a);
    } else if( blendMode==2 ) { // Screen
        float3 baseRgb = baseColor.rgb / max(baseColor.a,0.00001);
        float3 rgb = c.rgb / max(c.a,0.00001);
        float3 adj = 1. - ((1.-baseRgb) * (1.-rgb));
        return composite(baseColor,float4(adj,1.) * c.a * baseColor.a);
    } else if( blendMode==3 ) { // Punch out
        return baseColor * (1.-c.a);
    } else if( blendMode==4 ) { // Copy original
        return composite(baseColor,originalColor * (c.a * m));
    } else { // Normal
        return composite(baseColor,c * m);
    }

}

fragment float4 fx_am_grunge(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_grungeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> pre [[texture(1)]],
    texture2d<float> downImg [[texture(2)]],
    texture2d<float> blurH [[texture(3)]],
    texture2d<float> blurV [[texture(4)]],
    texture2d<float> blurBuf [[texture(5)]],
    texture2d<float> grunge [[texture(6)]],
    texture2d<float> grunge_a [[texture(7)]],
    texture2d<float> grunge_b [[texture(8)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 0) {
        // A camada do AM chega pré-multiplicada EM 8 BITS, pelo mais perto (o premul do Android); no opaco a cor já é o
        // float da textura, bit a bit.
        float4 c = inputImg.sample(__nv_smp, in.acScreenNorm);
        float3 p = c.rgb;
        if (c.a < 1.0) {
            float3 k = floor(c.rgb * c.a * 255.0 + 0.5);
            p = float3(oitoBits(k.r), oitoBits(k.g), oitoBits(k.b));
        }
        __nv_out = float4(p, c.a);
        return __nv_out;
    }
    if (eng.acPass == 1) {
        __nv_out = pre.sample(__nv_smp, in.acScreenNorm);
        return __nv_out;
    }
    if (eng.acPass == 2) {
        float2 passo = float2(1.0 / float2(int2(int(downImg.get_width()), int(downImg.get_height()))).x, 0.0);
        __nv_out = desfocar(downImg, passo, in.acScreenNorm, ladoDoDesfoque());
        return __nv_out;
    }
    if (eng.acPass == 3) {
        // Na tela a entrada chega de pé (t = 0 embaixo, como no AM): o passo aponta para CIMA e a soma do par fica na
        // mesma ordem da dele (o de baixo primeiro). Deitada, o passo vira para baixo.
        float cima = eng.acEntradaDePe == 1 ? 1.0 : -1.0;
        float2 passo = float2(0.0, cima / float2(int2(int(blurH.get_width()), int(blurH.get_height()))).y);
        float4 r = desfocar(blurH, passo, in.acScreenNorm, ladoDoDesfoque());
        // Tamanho da Borda 0: o Gaussian do AM lê a própria camada aqui (na meia resolução: a média de 2 × 2).
        __nv_out = u.strength <= 0.0 ? pre.sample(__nv_smp, in.acScreenNorm) : r;
        return __nv_out;
    }
    if (eng.acPass == 4) {
        __nv_out = blurV.sample(__nv_smp, in.acScreenNorm);
        return __nv_out;
    }
    if (eng.acPass == 5) {
        // O `main` do Grunge do AM, na mesma ordem. A coordenada da camada do AM: o retângulo do conteúdo de 0 a 1, com
        // o meio no meio do buffer (que cobre a composição, `eng.acTamanhoDaTela`) e o Y para CIMA (o do buffer de camada
        // do Nova cresce para baixo).
        // As chaves `u.d1active`, `u.d2active` e `u.c1active` não entram aqui, como no AM: lá elas só fariam acender controles
        // que já nascem acesos (sem `enabled="false"`). Um Deslocamento empurra sempre que for ≠ 0, e a Sobreposição
        // mistura sempre pelo Montante. Ficam no painel porque o projeto do AM as traz.
        float4 blurTexColor = blurBuf.sample(__nv_smp, in.acScreenNorm);
        float2 uv = 0.5 + (naCamada(__nv_acTela(in.acScreenNorm)) - 0.5) * eng.acTamanhoDaTela / eng.acTamanhoDaCamada;
        uv.y = 1.0 - uv.y;
        uv.x *= eng.acTamanhoDaCamada.x / eng.acTamanhoDaCamada.y;

        float2 displace = float2(0.);

        displace = applyDisplace(displace,blurTexColor,u.d1offset,u.d1fromctr,u.d1region,uv,int(u.d1grain),u.d1gamma,u.d1contrast,u.d1scale,u.d1angle,u.d1toffset);
        uv += displace;
        displace = applyDisplace(displace,blurTexColor,u.d2offset,u.d2fromctr,u.d2region,uv,int(u.d2grain),u.d2gamma,u.d2contrast,u.d2scale,u.d2angle,u.d2toffset);
        uv += displace;

        displace.x *= eng.acTamanhoDaTela.x / eng.acTamanhoDaTela.y;

        // A imagem deslocada, na tela, no `pre` (a camada pré-multiplicada de 8 bits, filtro linear da GPU): a textura
        // do AM. Deitada, o Y da tela vira.
        float2 sentido = float2(1.0, eng.acEntradaDePe == 1 ? 1.0 : -1.0);
        float4 texColor = pre.sample(__nv_smp, in.acScreenNorm + displace * sentido);

        texColor = mix(texColor,u.fillColor*texColor.a,u.fillColorBlend);

        float4 result = texColor;

        result = blendGrain(result, texColor, blurTexColor, u.t1color, u.t1alpha, u.t1blendMode, u.t1active ? u.t1region : 0, u.t1spread, u.t1choke, u.t1burn, uv, int(u.t1grain), u.t1gamma, u.t1contrast, u.t1scale, u.t1angle, u.t1offset, u.t1invert, u.t1light, u.t1lightAngle);
        result = blendGrain(result, texColor, blurTexColor, u.t2color, u.t2alpha, u.t2blendMode, u.t2active ? u.t2region : 0, u.t2spread, u.t2choke, u.t2burn, uv, int(u.t2grain), u.t2gamma, u.t2contrast, u.t2scale, u.t2angle, u.t2offset, u.t2invert, u.t2light, u.t2lightAngle);
        result = blendGrain(result, texColor, blurTexColor, u.t3color, u.t3alpha, u.t3blendMode, u.t3active ? u.t3region : 0, u.t3spread, u.t3choke, u.t3burn, uv, int(u.t3grain), u.t3gamma, u.t3contrast, u.t3scale, u.t3angle, u.t3offset, u.t3invert, u.t3light, u.t3lightAngle);
        result = blendGrain(result, texColor, blurTexColor, u.t4color, u.t4alpha, u.t4blendMode, u.t4active ? u.t4region : 0, u.t4spread, u.t4choke, u.t4burn, uv, int(u.t4grain), u.t4gamma, u.t4contrast, u.t4scale, u.t4angle, u.t4offset, u.t4invert, u.t4light, u.t4lightAngle);
        result = blendGrain(result, texColor, blurTexColor, u.t5color, u.t5alpha, u.t5blendMode, u.t5active ? u.t5region : 0, u.t5spread, u.t5choke, u.t5burn, uv, int(u.t5grain), u.t5gamma, u.t5contrast, u.t5scale, u.t5angle, u.t5offset, u.t5invert, u.t5light, u.t5lightAngle);
        result = blendGrain(result, texColor, blurTexColor, u.t6color, u.t6alpha, u.t6blendMode, u.t6active ? u.t6region : 0, u.t6spread, u.t6choke, u.t6burn, uv, int(u.t6grain), u.t6gamma, u.t6contrast, u.t6scale, u.t6angle, u.t6offset, u.t6invert, u.t6light, u.t6lightAngle);
        result = blendGrain(result, texColor, blurTexColor, u.t7color, u.t7alpha, u.t7blendMode, u.t7active ? u.t7region : 0, u.t7spread, u.t7choke, u.t7burn, uv, int(u.t7grain), u.t7gamma, u.t7contrast, u.t7scale, u.t7angle, u.t7offset, u.t7invert, u.t7light, u.t7lightAngle);
        result = blendGrain(result, texColor, blurTexColor, u.t8color, u.t8alpha, u.t8blendMode, u.t8active ? u.t8region : 0, u.t8spread, u.t8choke, u.t8burn, uv, int(u.t8grain), u.t8gamma, u.t8contrast, u.t8scale, u.t8angle, u.t8offset, u.t8invert, u.t8light, u.t8lightAngle);

        // O corte em 0..1 é o do alvo de 8 bits; escrito para o projeto de 32 bits sair igual.
        __nv_out = clamp(result, 0.0, 1.0);
        return __nv_out;
    }

    // A saída do AM (pré-multiplicada, já em 8 bits) em cor reta.
    float4 q = grunge.sample(__nv_smp, in.acScreenNorm);
    __nv_out = q.a > 0.0 ? float4(min(q.rgb / q.a, float3(1.0)), q.a) : float4(0.0);
    return __nv_out;
}
