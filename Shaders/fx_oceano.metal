// ---------------------------------------------------------------------------
// Oceano
// origem : assets/effects/oceano.xml
// id     : nova.effect.oceano
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct oceanoParams {
    int camada;
    float linhaDagua;
    float reflexoDaCamada;
    int qualidade;
    float alturaDaCamera;
    float inclinacao;
    float giro;
    float zoom;
    float alturaDasOndas;
    float tamanhoDasOndas;
    float agitacao;
    float velocidade;
    float vento;
    float espuma;
    float4 corDaAgua;
    float4 corDaCrista;
    float sol;
    float alturaDoSol;
    float4 corDoCeu;
    float nuvens;
    float velocidadeDasNuvens;
    float nevoa;
    float exposicao;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265358979;

float h12(float2 p) { float3 q = fract(float3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float ruido(float2 p) {
    float2 i = floor(p), f = fract(p), u = f * f * (3.0 - 2.0 * f);
    return mix(mix(h12(i), h12(i + float2(1.0, 0.0)), u.x), mix(h12(i + float2(0.0, 1.0)), h12(i + float2(1.0, 1.0)), u.x), u.y);
}
float fbm(float2 p, int oitavas) {
    float s = 0.0, a = 0.5;
    for (int i = 0; i < 6; i++) {
        if (i >= oitavas) break;
        s += a * ruido(p);
        p = float2x2(1.6, 1.2, -1.2, 1.6) * p + 11.7;
        a *= 0.5;
    }
    return s;
}

float3 direcaoDoSol() {
    float az = radians(u.sol), el = radians(u.alturaDoSol);
    return normalize(float3(sin(az) * cos(el), sin(el), -cos(az) * cos(el)));
}

// ------------------------------------------------------------------ as ondas
/**
 * A altura da água em `p` (plano XZ), de 0 (vale) a 1 (crista).
 *
 * Cada onda é exp(sin x − 1): vale largo, crista afiada. A posição da onda
 * seguinte é empurrada pela inclinação desta — as cristas se juntam e o mar fica
 * "picado" em vez de parecer uma soma de senos.
 */
float alturaDoMar(float2 p, int oitavas) {
    float t = eng.acTime * u.velocidade;
    p /= u.tamanhoDasOndas;
    float freq = 0.42, peso = 1.0, soma = 0.0, total = 0.0;
    float ang = radians(u.vento);
    float arrasto = mix(0.05, 0.42, u.agitacao);
    for (int i = 0; i < 28; i++) {
        if (i >= oitavas) break;
        float2 d = float2(sin(ang), cos(ang));
        float x = dot(d, p) * freq + t * (1.1 + 0.9 * sqrt(freq));
        float onda = exp(sin(x) - 1.0);
        float inclinacaoDaOnda = onda * cos(x);
        p -= d * inclinacaoDaOnda * peso * arrasto;
        soma += onda * peso;
        total += peso;
        peso *= 0.81;
        freq *= 1.19;
        ang += 2.39996;          // o ângulo de ouro: nenhuma direção se repete
    }
    return soma / max(total, 1e-4);
}

float fundoDoMar() { return 1.4 * u.alturaDasOndas * u.tamanhoDasOndas; }

/** Onde o raio cruza a água; devolve a distância (ou −1 para o céu). */
float cruzarOMar(float3 origem, float3 dir, int passos, int oitavas) {
    if (dir.y >= -1e-4) return -1.0;
    float fundo = fundoDoMar();
    float tTopo = -origem.y / dir.y;                 // o plano das cristas é y = 0
    float tFundo = (-fundo - origem.y) / dir.y;
    float t = max(tTopo, 0.0);
    for (int i = 0; i < 48; i++) {
        if (i >= passos) break;
        float3 q = origem + dir * t;
        float h = (alturaDoMar(q.xz, oitavas) - 1.0) * fundo;
        float falta = q.y - h;
        if (falta < 0.004 * t) break;
        t += falta * 0.75 / max(-dir.y, 0.08);
        if (t > tFundo) { t = tFundo; break; }
    }
    return t;
}

float3 normalDoMar(float2 p, float e, int oitavas) {
    float fundo = fundoDoMar();
    float h = alturaDoMar(p, oitavas) * fundo;
    float hx = alturaDoMar(p + float2(e, 0.0), oitavas) * fundo;
    float hz = alturaDoMar(p + float2(0.0, e), oitavas) * fundo;
    return normalize(float3(h - hx, e, h - hz));
}

// ------------------------------------------------------------------ o céu
/** `suave` = as u.nuvens desfocadas, para o reflexo na água (nuvem nítida no espelho ondulado vira anel). */
float3 ceu(float3 dir, float3 sd, bool comNuvens, bool suave) {
    float y = max(dir.y, 0.0);
    float mu = max(dot(dir, sd), 0.0);
    float3 horizonte = mix(float3(0.72, 0.84, 0.95), float3(1.0, 0.86, 0.68), 0.35 * exp(-3.0 * sd.y));
    float3 c = mix(horizonte, u.corDoCeu.rgb, 1.0 - exp(-7.0 * y));
    c += float3(1.0, 0.85, 0.6) * (0.18 * pow(mu, 14.0) + 1.2 * pow(mu, 300.0));
    c *= 1.2;
    if (comNuvens && u.nuvens > 0.0 && dir.y > 0.01) {
        // uma u.camada de u.nuvens num plano, vista em perspectiva
        float2 q = dir.xz / (dir.y + 0.06) * 2.1 + float2(0.02, 0.013) * eng.acTime * u.velocidadeDasNuvens;
        float cobre = mix(0.74, 0.34, u.nuvens);
        float d = fbm(q, suave ? 3 : 6);
        float dens = smoothstep(cobre - (suave ? 0.12 : 0.0), cobre + (suave ? 0.22 : 0.1), d) * (suave ? 0.8 : 1.0);
        if (dens > 0.0) {
            // a luz: menos nuvem na direção do u.sol = borda clara
            float dSol = fbm(q + sd.xz * 0.3, suave ? 3 : 5);
            float sombra = clamp((d - dSol) * 4.0 + 0.3 + 1.6 * (d - cobre - 0.1), 0.0, 1.0);
            float3 claro = float3(2.3, 2.25, 2.15) + float3(1.0, 0.8, 0.5) * pow(mu, 6.0);
            float3 escuro = mix(u.corDoCeu.rgb, float3(0.5, 0.55, 0.66), 0.7) * 0.75;
            float3 nuvem = mix(claro, escuro, sombra);
            float longe = smoothstep(0.0, 0.07, dir.y);      // somem na bruma do horizonte
            c = mix(c, nuvem, dens * longe);
        }
    }
    return c;
}

float ggx(float nh, float r) { float a = r * r; float d = nh * nh * (a * a - 1.0) + 1.0; return a * a / (PI * d * d); }

float3 aces(float3 x) { return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0); }

fragment float4 fx_oceano(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant oceanoParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;
    float2 v = (uv - 0.5) * float2(eng.acAspect, -1.0) * 2.0;

    // a câmera
    float yaw = radians(u.giro), pit = radians(u.inclinacao);
    float3 frente = float3(sin(yaw) * cos(pit), sin(pit), -cos(yaw) * cos(pit));
    float3 lado = normalize(cross(frente, float3(0.0, 1.0, 0.0)));
    float3 cima = cross(lado, frente);
    float3 dir = normalize(v.x * lado + v.y * cima + u.zoom * frente);
    float3 origem = float3(0.0, u.alturaDaCamera, 0.0);
    float3 sd = direcaoDoSol();

    int passos = u.qualidade == 0 ? 12 : u.qualidade == 1 ? 22 : 40;
    int oitGeo = u.qualidade == 0 ? 6 : u.qualidade == 1 ? 9 : 12;
    int oitNor = u.qualidade == 0 ? 12 : u.qualidade == 1 ? 20 : 28;

    float3 cor;
    float3 N = float3(0.0, 1.0, 0.0);
    float distMar = cruzarOMar(origem, dir, passos, oitGeo);
    float3 bruma = ceu(normalize(float3(dir.x, 0.02, dir.z)), sd, false, false);
    if (distMar < 0.0) {
        cor = ceu(dir, sd, true, false);
    } else {
        float3 p = origem + dir * distMar;
        // o passo da normal cresce com a distância: longe, onda pequena vira ruído
        N = normalDoMar(p.xz, 0.006 + distMar * 0.002, oitNor);
        // longe, a normal volta para cima (o mar "alisa" no horizonte, como na foto)
        N = normalize(mix(N, float3(0.0, 1.0, 0.0), 0.8 * smoothstep(12.0, 260.0, distMar)));
        float3 V = -dir;
        float nv = clamp(dot(N, V), 0.0, 1.0);
        float fresnel = 0.02 + 0.98 * pow(1.0 - nv, 5.0);

        float3 R = reflect(dir, N);
        R.y = abs(R.y);
        float3 reflexo = ceu(R, sd, true, true) * 0.9;

        float altura = alturaDoMar(p.xz, oitGeo);            // 0 = vale, 1 = crista
        // a luz que atravessa a crista (mais forte olhando contra o u.sol)
        float contraSol = pow(max(dot(dir, sd) * 0.5 + 0.5, 0.0), 3.0);
        float3 fundo = u.corDaAgua.rgb * (0.5 + 0.7 * sd.y);
        float3 atravessa = u.corDaCrista.rgb * (0.12 + 0.9 * contraSol) * smoothstep(0.45, 1.0, altura) * 0.45;
        cor = mix(fundo + atravessa, reflexo, fresnel);

        // o u.sol na água
        float3 H = normalize(V + sd);
        float nl = max(dot(N, sd), 0.0);
        cor += float3(1.0, 0.9, 0.7) * 10.0 * nl * fresnel * min(ggx(max(dot(N, H), 0.0), 0.12), 60.0) * 0.05;

        // u.espuma: crista alta e íngreme, quebrada por ruído
        if (u.espuma > 0.0) {
            float ingreme = 1.0 - N.y;
            float f = smoothstep(0.62 - 0.3 * u.espuma, 0.95, altura) * smoothstep(0.02, 0.22, ingreme);
            f *= 0.55 + 0.9 * fbm(p.xz * 2.3 / u.tamanhoDasOndas + eng.acTime * 0.15, 3);
            cor = mix(cor, float3(1.25) * (0.5 + 0.7 * nl + 0.3 * sd.y), clamp(f * u.espuma * 1.6, 0.0, 1.0));
        }

        // névoa até o horizonte
        float longe = 1.0 - exp(-distMar * mix(0.0002, 0.006, u.nevoa));
        cor = mix(cor, bruma, longe);
    }

    cor = aces(cor * 0.5 * u.exposicao);
    cor = pow(cor, float3(1.0 / 2.2));

    // a u.camada: o reflexo dela na água (espelhado na linha d'água, ondulado pelas ondas) e ela por cima
    if (u.camada >= 1) {
        if (u.camada == 2 && distMar >= 0.0 && u.reflexoDaCamada > 0.0) {
            float2 esp = float2(uv.x, 2.0 * u.linhaDagua - uv.y);
            esp += N.xz * float2(0.22, 0.5) * (0.4 + 0.6 * u.alturaDasOndas);
            if (esp.x > 0.0 && esp.x < 1.0 && esp.y > 0.0 && esp.y < u.linhaDagua) {
                float4 r = inputImg.sample(__nv_smp, esp);
                float longeDaLinha = clamp((uv.y - u.linhaDagua) * 2.2, 0.0, 1.0);
                cor = mix(cor, r.rgb * float3(0.85, 0.9, 0.95), r.a * u.reflexoDaCamada * (1.0 - longeDaLinha) * 0.85);
            }
        }
        float4 orig = inputImg.sample(__nv_smp, uv);
        cor = mix(cor, orig.rgb, orig.a);
    }
    __nv_out = float4(cor, 1.0);
    return __nv_out;
}
