// ---------------------------------------------------------------------------
// Desfoque de movimento (AM)
// origem : assets/effects/am-motion-blur.xml
// id     : nova.effect.am-motion-blur
// passes : 4
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_motion_blurParams {
    float tune;
    int usePos;
    int useScale;
    int useAngle;
};

// --- funcoes auxiliares do efeito
// ------------------------------------------------------------------ a ponte para a tela do Nova

// O `(float4(uv, 0, 1) * eng.acLayerToScreen).xy` do AM: a coordenada da camada (Y para cima) levada ao buffer (o Y volta
// para baixo) e, na tela, pela `eng.acCamadaParaTela` (sem a divisão da perspectiva quando ela é afim, como a matriz do
// AM); no filho de grupo, a própria UV do buffer.
static float2 camadaParaTelaDoAm(float2 uv) {
    float2 conteudo = max(eng.acTamanhoDaCamada, float2(1e-6));
    float2 b = 0.5 + (float2(uv.x, 1.0 - uv.y) - 0.5) * conteudo / eng.acTamanhoDaTela;
    if (eng.acParaTela != float3x3(1.0)) return b;
    float3 c = eng.acCamadaParaTela * float3(b, 1.0);
    bool afim = eng.acCamadaParaTela[0].z == 0.0 && eng.acCamadaParaTela[1].z == 0.0 && eng.acCamadaParaTela[2].z == 1.0;
    return afim ? c.xy : c.xy / c.z;
}

// O `in.acLayerNorm` do AM: o pixel na tela levado à coordenada da camada (o retângulo do conteúdo de 0 a 1), com o Y
// para CIMA.
static float2 camadaDoPixelAm() {
    float3 c = __nv_inverse(eng.acCamadaParaTela) * float3(__nv_acTela(in.acScreenNorm), 1.0);
    float2 conteudo = max(eng.acTamanhoDaCamada, float2(1e-6));
    float2 st = 0.5 + (c.xy / c.z - 0.5) * eng.acTamanhoDaTela / conteudo;
    return float2(st.x, 1.0 - st.y);
}

// ------------------------------------------------------------------ o script do AM (`animate`)

// Cada passe só roda quando o movimento dele passa de 0,0001 (e a chave dele está ligada).
static bool giroLigado() { return u.useAngle && abs(eng.acGiroPorQuadroDoAm) > 0.0001; }
static bool escalaLigada() { return u.useScale && abs(eng.acEscalaPorQuadroDoAm) > 0.0001; }
static bool posicaoLigada() { return u.usePos && (abs(eng.acVelocidadeDoAm.x) > 0.0001 || abs(eng.acVelocidadeDoAm.y) > 0.0001); }

// Um buffer do mesmo tamanho, pixel por pixel (no meio do texel o filtro linear devolve o próprio texel).
static float4 copia(sampler2D img) { return img.sample(__nv_smp, in.acScreenNorm); }

// ------------------------------------------------------------------ os três grupos do AM, na ordem dele

// Grupo 0: o GIRO.
static float4 passeDoGiro(sampler2D img) {
    float angle = abs(eng.acGiroPorQuadroDoAm*u.tune);
    float cx = 0.5 + eng.acPivoDoAm.x/eng.acTamanhoDaCamada.x;
    float cy = 0.5 - eng.acPivoDoAm.y/eng.acTamanhoDaCamada.y;
    float2 image_size = float2(int2(int(img.get_width()), int(img.get_height())));
    float maxF = max(eng.acTamanhoDaTela.x, eng.acTamanhoDaTela.y);
    float2 texelSize = 1.0 / float2(maxF, maxF);
    float2 center = camadaParaTelaDoAm(float2(cx,cy));
    float2 v = in.acScreenNorm.st - center;
    v.y *= image_size.y / image_size.x;
    float r = length(v);
    float d = 6.283185*r;
    float l = d*angle/360.0;
    float a = angle * 0.0174533;
    float amin = a/2.0;
    float speed = l/texelSize.x;
    int nSamples = int(clamp(speed, 1.01, 100.01));
    float4 outColor = img.sample(__nv_smp, in.acScreenNorm.st);
    for(int i=1; i<nSamples; i++ ) {
        float sampleAngle = -amin + a * float(i)/float(nSamples);
        float s = sin(sampleAngle);
        float c = cos(sampleAngle);
        float2x2 rot = float2x2(c, -s, s, c);
        float2 temp = v*rot;
        temp.y = temp.y * image_size.x / image_size.y;
        outColor += img.sample(__nv_smp, center + temp);
    }
    return outColor/float(nSamples);
}

// Grupo 1: a ESCALA.
static float4 passeDaEscala(sampler2D img) {
    float2 image_size = float2(int2(int(img.get_width()), int(img.get_height())));
    float maxF = max(eng.acTamanhoDaTela.x, eng.acTamanhoDaTela.y);
    float2 texelSize = 1.0 / float2(maxF, maxF);
    float cx = 0.5 + eng.acPivoDoAm.x/eng.acTamanhoDaCamada.x;
    float cy = 0.5 - eng.acPivoDoAm.y/eng.acTamanhoDaCamada.y;
    float2 center = float2(cx,cy);
    float2 v = in.acScreenNorm.st - camadaParaTelaDoAm(center);
    v.y *= image_size.y / image_size.x;
    float speed = abs(eng.acEscalaPorQuadroDoAm*u.tune) / 2.0;
    speed *= length( camadaDoPixelAm() - center ); // Adaptive
    int nSamples = int(clamp(speed, 1.01, 100.01));
    float4 outColor = img.sample(__nv_smp, in.acScreenNorm.st);
    float2 vnorm = normalize(v)*length(texelSize)*speed;
    for(int i=1; i<nSamples; i++ ) {
        float2 offset = vnorm * (float(i) / float(nSamples - 1) - 0.5);
        offset.y = offset.y * image_size.x / image_size.y;
        outColor += img.sample(__nv_smp, in.acScreenNorm.st-offset);
    }
    return outColor/float(nSamples);
}

// Grupo 2: a POSIÇÃO.
static float4 passeDaPosicao(sampler2D img) {
    float2 image_size = float2(int2(int(img.get_width()), int(img.get_height())));
    float maxF = max(eng.acTamanhoDaTela.x, eng.acTamanhoDaTela.y);
    float2 texelSize = 1.0 / float2(maxF, maxF);
    float2 velocity = eng.acVelocidadeDoAm*u.tune / eng.acTamanhoDaTela;
    float speed = length(velocity / texelSize);
    int nSamples = int(clamp(speed, 1.01, 100.01));
    float4 outColor = img.sample(__nv_smp, in.acScreenNorm.st);
    for(int i=1; i<nSamples; i++ ) {
        float2 offset = velocity * (float(i) / float(nSamples - 1) - 0.5);
        offset.y = offset.y * image_size.x / image_size.y;
        outColor += img.sample(__nv_smp, in.acScreenNorm.st-offset);
    }
    return outColor/float(nSamples);
}

fragment float4 fx_am_motion_blur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_motion_blurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> pre [[texture(1)]],
    texture2d<float> giro [[texture(2)]],
    texture2d<float> escala [[texture(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 0) {
        // A camada pré-multiplicada, como a textura do AM.
        float4 c = copia(inputImg);
        __nv_out = float4(c.rgb * c.a, c.a);
        return __nv_out;
    }
    if (eng.acPass == 1) {
        __nv_out = giroLigado() ? passeDoGiro(pre) : copia(pre);
        return __nv_out;
    }
    if (eng.acPass == 2) {
        __nv_out = escalaLigada() ? passeDaEscala(giro) : copia(giro);
        return __nv_out;
    }
    // Sem nenhum passe ligado o AM tira o efeito da lista: a camada passa como está.
    if (!giroLigado() && !escalaLigada() && !posicaoLigada()) {
        __nv_out = copia(inputImg);
        return __nv_out;
    }
    float4 p = posicaoLigada() ? passeDaPosicao(escala) : copia(escala);
    __nv_out = p.a > 0.0 ? float4(min(p.rgb / p.a, float3(1.0)), p.a) : float4(0.0);
    return __nv_out;
}
