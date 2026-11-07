// ---------------------------------------------------------------------------
// Sombra de anime
// origem : assets/effects/anime-shadow.xml
// id     : nova.effect.anime-shadow
// passes : 6
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct anime_shadowParams {
    int tipoDeLuz;
    float2 posicaoDaLuz;
    float alturaDaLuz;
    float alcance;
    float direcao;
    float elevacao;
    float4 corDaLuz;
    float exposicao;
    float tons;
    float limiar;
    float suavidade;
    float4 corDaSombra;
    float escuridao;
    float limpeza;
    float antiSerrilhado;
    float brilho;
    float tamanhoDoBrilho;
    float4 corDoBrilho;
    float contorno;
    float larguraDoContorno;
    float4 corDoContorno;
    int contornoSoNoLadoDaLuz;
    int tipoDoMapa;
    int inverterMapa;
    float volume;
    float relevo;
    float detalhe;
    float forcaAO;
    float ambiente;
    int ver;
};

// --- funcoes auxiliares do efeito
float luma(float3 c) { return dot(c, float3(0.299, 0.587, 0.114)); }

float4 empacotar(float h) {
    float s = clamp(h, 0.0, 1.0) * 255.0;
    float alto = floor(s);
    return float4(alto / 255.0, s - alto, 0.0, 1.0);
}
float desempacotar(float4 v) { return v.r + v.g / 255.0; }

/** Há mapa NESTE pixel? (camada não escolhida chega transparente) */
bool temMapa(float2 uv) { return mapa.sample(__nv_smp, uv).a > 0.01; }

/** A fonte de altura: o mapa de profundidade, ou a silhueta da própria arte. */
float fonteDeAltura(float2 uv) {
    if (u.tipoDoMapa == 1) {
        float4 m = mapa.sample(__nv_smp, uv);
        if (m.a > 0.01) {
            float d = luma(m.rgb);
            return u.inverterMapa ? 1.0 - d : d;
        }
    }
    return inputImg.sample(__nv_smp, uv).a;
}

/**
 * Bilinear à mão sobre um buffer EMPACOTADO (r + g/255): ler o número inteiro nos
 * quatro texels e só então misturar. Ler por texel mais perto fazia degraus (os
 * riscos do primeiro teste); deixar o filtro da GPU misturar os bytes daria lixo.
 */
float bilinear(sampler2D buf, float2 uv) {
    int2 t = int2(int(buf.get_width()), int(buf.get_height()));
    float2 p = uv * float2(t) - 0.5;
    int2 i = int2(floor(p));
    float2 f = fract(p);
    int2 m = t - 1;
    float a = desempacotar(buf.read(uint2(clamp(i, int2(0), m)), uint(0)));
    float b = desempacotar(buf.read(uint2(clamp(i + int2(1, 0), int2(0), m)), uint(0)));
    float c = desempacotar(buf.read(uint2(clamp(i + int2(0, 1), int2(0), m)), uint(0)));
    float d = desempacotar(buf.read(uint2(clamp(i + int2(1, 1), int2(0), m)), uint(0)));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

/** O raio do borrão da altura, em UV (da altura da camada). */
float raioDaAltura() {
    return u.tipoDoMapa == 1 ? u.volume * 0.12 : u.volume;
}

/**
 * Borrão gaussiano de 49 amostras ao longo de [eixo] (UV). Com 25, a distância
 * entre amostras passava do u.detalhe da fonte e a soma ondulava (uma grade fraca
 * que o corte do cel transformava em degraus).
 */
float borrar(float2 uv, float2 eixo, bool primeiro) {
    float raio = raioDaAltura();
    float soma = 0.0;
    float peso = 0.0;
    for (int i = -24; i <= 24; i++) {
        float f = float(i) / 24.0;
        float w = exp(-f * f * 4.0);
        float2 q = uv + eixo * f * raio;
        float v = primeiro ? fonteBuf.sample(__nv_smp, q).r : bilinear(alturaH, q);
        soma += v * w;
        peso += w;
    }
    return soma / peso;
}

/** A altura borrada em qualquer UV: bilinear feito à mão sobre o empacotado. */
float alturaEm(float2 uv) { return bilinear(alturaV, uv); }

/**
 * A normal no espaço da camada (x para a direita, y PARA BAIXO, z para fora da
 * tela). Do mapa de normais quando há, senão da inclinação da altura — mais o
 * traço da arte como u.relevo fino.
 */
float3 normalEm(float2 uv) {
    if (u.tipoDoMapa >= 2) {
        float4 m = mapa.sample(__nv_smp, uv);
        if (m.a > 0.01) {
            float3 n = m.rgb * 2.0 - 1.0;
            // OpenGL: verde = para cima, e aqui o y desce.
            if (u.tipoDoMapa == 2) n.y = -n.y;
            n.xy *= u.relevo;
            return normalize(n);
        }
    }
    // Passo de 4 texels (meia resolução): a altura interpolada em linha reta tem
    // inclinação aos saltos de texel em texel; medir mais largo deixa a normal lisa
    // (com 1,5 o corte do cel pegava uma trama de pontinhos).
    float2 passo = float2(4.0) / float2(int2(int(alturaV.get_width()), int(alturaV.get_height())));
    float hx = alturaEm(uv + float2(passo.x, 0.0)) - alturaEm(uv - float2(passo.x, 0.0));
    float hy = alturaEm(uv + float2(0.0, passo.y)) - alturaEm(uv - float2(0.0, passo.y));
    // A inclinação por UNIDADE de UV (corrigida pelo aspecto), vezes o u.relevo.
    float2 g = float2(hx / (2.0 * passo.x * eng.acAspect), hy / (2.0 * passo.y));
    // A borda do "travesseiro" (degrau borrado) inclina até ~1,13/raio; vezes 2,5·raio
    // dá ~2,8 — a normal deita quase de lado na silhueta, como uma esfera.
    float escala = u.relevo * (u.tipoDoMapa == 1 ? 0.6 : raioDaAltura() * 2.5);
    g *= escala;

    // O traço da arte: o gradiente da luminância vira um u.relevo raso.
    if (u.detalhe > 0.0) {
        float2 px = eng.acTexelSize * 1.5 * eng.acEscalaDePixel;
        float lx = luma(inputImg.sample(__nv_smp, uv + float2(px.x, 0.0)).rgb) - luma(inputImg.sample(__nv_smp, uv - float2(px.x, 0.0)).rgb);
        float ly = luma(inputImg.sample(__nv_smp, uv + float2(0.0, px.y)).rgb) - luma(inputImg.sample(__nv_smp, uv - float2(0.0, px.y)).rgb);
        g += float2(lx, ly) * u.detalhe * 0.5;
    }
    return normalize(float3(-g.x, -g.y, 1.0));
}

/** O vetor que vai do pixel até a luz (normalizado) e quanto a luz chega (u.alcance). */
float4 vetorDaLuz(float2 uv) {
    if (u.tipoDeLuz == 1) {
        float az = radians(u.direcao);
        float el = radians(u.elevacao);
        return float4(normalize(float3(cos(el) * cos(az), cos(el) * sin(az), sin(el))), 1.0);
    }
    float3 p = float3(uv.x * eng.acAspect, uv.y, 0.0);
    float3 l = float3(u.posicaoDaLuz.x * eng.acAspect, u.posicaoDaLuz.y, u.alturaDaLuz);
    float3 d = l - p;
    float dist = length(d);
    float queda = u.alcance > 0.0 ? 1.0 / (1.0 + pow(dist / u.alcance, 2.0)) : 1.0;
    return float4(d / max(dist, 1e-5), queda);
}

fragment float4 fx_anime_shadow(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant anime_shadowParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> fonteBuf [[texture(1)]],
    texture2d<float> alturaH [[texture(2)]],
    texture2d<float> alturaV [[texture(3)]],
    texture2d<float> luzBuf [[texture(4)]],
    texture2d<float> limpoBuf [[texture(5)]],
    texture2d<float> mapa [[texture(6)]],
    texture2d<float> mapaAO [[texture(7)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;

    if (eng.acPass == 0) {
        // A fonte reduzida a 1/8 com MÉDIA de 8×8: o borrão largo que vem depois
        // pula vários pixels entre amostras, e lendo a arte cheia ele "ondulava"
        // (estrias na parte plana do rosto no primeiro teste).
        float2 px = 1.0 / float2(int2(int(inputImg.get_width()), int(inputImg.get_height())));
        float soma = 0.0;
        for (int y = 0; y < 8; y++) {
            for (int x = 0; x < 8; x++) {
                soma += fonteDeAltura(uv + (float2(float(x), float(y)) - 3.5) * px);
            }
        }
        __nv_out = float4(float3(soma / 64.0), 1.0);
        return __nv_out;
    }
    if (eng.acPass == 1) {
        __nv_out = empacotar(borrar(uv, float2(1.0 / eng.acAspect, 0.0), true));
        return __nv_out;
    }
    if (eng.acPass == 2) {
        __nv_out = empacotar(borrar(uv, float2(0.0, 1.0), false));
        return __nv_out;
    }

    if (eng.acPass == 3) {
        float3 n = normalEm(uv);
        float4 luz = vetorDaLuz(uv);
        float3 l = luz.xyz;
        float difusa = dot(n, l) * 0.5 + 0.5;
        difusa *= luz.w;
        // AO: escurece as dobras ANTES do corte, para a sombra nascer nelas.
        float4 ao = mapaAO.sample(__nv_smp, uv);
        if (ao.a > 0.01) difusa *= mix(1.0, luma(ao.rgb), clamp(u.forcaAO, 0.0, 2.0) * 0.5);
        difusa = mix(difusa, 1.0, u.ambiente);

        float3 h = normalize(l + float3(0.0, 0.0, 1.0));
        float especular = pow(max(dot(n, h), 0.0), mix(160.0, 6.0, u.tamanhoDoBrilho)) * luz.w;

        // Contorno: o quanto a superfície vira de lado (1 − n.z), e — com "Só do
        // lado da luz" — só na metade virada para a luz. O corte em largura é no
        // passe do cel.
        float borda = clamp(1.0 - n.z, 0.0, 1.0);
        float lado = u.contornoSoNoLadoDaLuz
            ? smoothstep(0.15, 0.55, dot(normalize(n.xy + float2(1e-5)), normalize(l.xy + float2(1e-5))))
            : 1.0;
        float rim = borda * lado * luz.w;

        __nv_out = float4(clamp(difusa, 0.0, 1.0), rim, clamp(especular, 0.0, 1.0), 1.0);
        return __nv_out;
    }

    if (eng.acPass == 4) {
        // LIMPEZA: um borrão em disco de 13 amostras, do tamanho pedido.
        float4 centro = luzBuf.sample(__nv_smp, uv);
        float raio = u.limpeza * 4.0;
        if (raio < 0.01) {
            __nv_out = centro;
            return __nv_out;
        }
        float4 soma = centro;
        float peso = 1.0;
        for (int i = 0; i < 12; i++) {
            float a = float(i) * 0.5235988;
            float r = (i % 2 == 0) ? 1.0 : 0.55;
            float2 q = uv + float2(cos(a), sin(a)) * r * raio * eng.acEscalaDePixel * eng.acTexelSize;
            soma += luzBuf.sample(__nv_smp, q);
            peso += 1.0;
        }
        __nv_out = soma / peso;
        return __nv_out;
    }

    // ------------------------------------------------------------- 4. o cel
    float4 arte = inputImg.sample(__nv_smp, uv);
    float4 luz = limpoBuf.sample(__nv_smp, uv);

    if (u.ver == 2) { __nv_out = float4(normalEm(uv) * 0.5 + 0.5, arte.a); return __nv_out; }
    if (u.ver == 3) { __nv_out = float4(float3(luz.r), arte.a); return __nv_out; }
    if (u.ver == 4) { __nv_out = float4(float3(alturaEm(uv)), 1.0); return __nv_out; }

    float v = luz.r;
    float aa = max(fwidth(v), 1e-4) * u.antiSerrilhado;
    float s = u.suavidade + aa;
    int n = clamp(int(u.tons + 0.5), 1, 4);
    float iluminado = 0.0;
    for (int i = 0; i < 4; i++) {
        if (i >= n) break;
        float corte = u.limiar + (1.0 - u.limiar) * float(i) / float(n) * 0.85;
        iluminado += smoothstep(corte - s, corte + s, v);
    }
    iluminado /= float(n);

    float3 sombra = mix(float3(1.0), u.corDaSombra.rgb, u.escuridao) * (1.0 - u.escuridao * 0.35);
    float3 acesa = u.corDaLuz.rgb * u.exposicao;
    float3 cor = arte.rgb * mix(sombra, acesa, iluminado);

    float sb = u.suavidade + max(fwidth(luz.b), 1e-4) * u.antiSerrilhado;
    float realce = smoothstep(0.5 - sb, 0.5 + sb, luz.b) * iluminado * u.brilho;
    cor += u.corDoBrilho.rgb * realce;

    /*
     * A LUZ DE CONTORNO É UM FILETE, NÃO UMA MANCHA. Pela normal (1 − n.z), a
     * faixa tinha a largura do VOLUME — no automático, um quarto da cabeça. O
     * filete do anime é colado na borda do lado da luz: um pixel da arte ganha
     * u.contorno quando, andando [largura] na direção da luz, ele SAI da arte.
     * Largura constante, borda dura, sempre no recorte. Sem "Só do lado da luz",
     * vale a saída mais perto em oito direções (o u.contorno em volta toda).
     */
    float rim = 0.0;
    float w = u.larguraDoContorno * 0.03;
    if (u.contorno > 0.0 && w > 0.0) {
        float2 rumo;
        if (u.tipoDeLuz == 1) {
            rumo = float2(cos(radians(u.direcao)), sin(radians(u.direcao)));
        } else {
            rumo = (u.posicaoDaLuz - uv) * float2(eng.acAspect, 1.0);
        }
        rumo = normalize(rumo + float2(1e-6)) * float2(1.0 / eng.acAspect, 1.0);
        float fora = 0.0;
        if (u.contornoSoNoLadoDaLuz) {
            for (int k = 1; k <= 3; k++) fora += 1.0 - inputImg.sample(__nv_smp, uv + rumo * w * float(k) / 3.0).a;
            fora /= 3.0;
        } else {
            for (int k = 0; k < 8; k++) {
                float a = float(k) * 0.7853982;
                float2 d = float2(cos(a) / eng.acAspect, sin(a)) * w;
                fora = max(fora, 1.0 - inputImg.sample(__nv_smp, uv + d).a);
            }
        }
        float sr = 0.15 + u.suavidade;
        rim = smoothstep(0.5 - sr, 0.5 + sr, fora) * arte.a * u.contorno * vetorDaLuz(uv).w;
    }
    if (u.ver == 1) {
        cor = arte.rgb * sombra + u.corDoContorno.rgb * rim;
    } else {
        cor += u.corDoContorno.rgb * rim;
    }

    __nv_out = float4(cor, arte.a);
    return __nv_out;
}
