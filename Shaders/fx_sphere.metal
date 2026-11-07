// ---------------------------------------------------------------------------
// Esfera
// origem : assets/effects/sphere.xml
// id     : nova.effect.sphere
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct sphereParams {
    int mode;
    float radius;
    float spin;
    float tilt;
    float2 center;
    float autoSpin;
    float fov;
    float shading;
    float lightAngle;
    float rim;
    int keepLayer;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265;

float3 girarY(float3 v, float a) {
    float c = cos(a);
    float s = sin(a);
    return float3(v.x * c + v.z * s, v.y, -v.x * s + v.z * c);
}

float3 girarX(float3 v, float a) {
    float c = cos(a);
    float s = sin(a);
    return float3(v.x, v.y * c - v.z * s, v.y * s + v.z * c);
}

/** Latitude e longitude viram coordenada de textura equirretangular. */
float2 paraEquirretangular(float3 dir) {
    float u = __nv_atan(dir.z, dir.x) / (2.0 * PI) + 0.5;
    float v = acos(clamp(dir.y, -1.0, 1.0)) / PI;
    return float2(u, v);
}

fragment float4 fx_sphere(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant sphereParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    float volta = (u.spin / 360.0 + eng.acTime * u.autoSpin) * 2.0 * PI;
    float inclinacao = u.tilt * PI / 180.0;

    if (u.mode == 1) {
        // ----------------------------------------------------- ver de dentro
        //
        // A câmera está no centro da esfera e olha para fora. O raio é montado
        // a partir do campo de visão, e a direção dele já é a coordenada.
        float2 tela = (in.acScreenNorm - 0.5) * float2(eng.acAspect, 1.0) * 2.0;
        float f = tan(u.fov * PI / 360.0);
        float3 raio = normalize(float3(tela.x * f, -tela.y * f, 1.0));
        raio = girarX(raio, inclinacao);
        raio = girarY(raio, volta);

        __nv_out = inputImg.sample(__nv_smp, paraEquirretangular(raio));
        return __nv_out;
    }

    // --------------------------------------------------- enrolar na esfera
    float2 p = (in.acScreenNorm - u.center) * float2(eng.acAspect, 1.0);
    float d = length(p) / max(u.radius, 1e-4);

    if (d > 1.0) {
        // Fora da bola: ou fica a camada, ou fica nada.
        __nv_out = u.keepLayer ? original : float4(original.rgb, 0.0);
        return __nv_out;
    }

    // O ponto da esfera que este pixel enxerga. `z` sai de x²+y²+z²=1 — é a
    // interseção do raio com a esfera, resolvida de cabeça.
    float3 ponto = float3(p / max(u.radius, 1e-4), sqrt(max(1.0 - d * d, 0.0)));

    float3 naEsfera = girarX(ponto, inclinacao);
    naEsfera = girarY(naEsfera, volta);

    float2 uv = paraEquirretangular(normalize(naEsfera));
    float3 cor = inputImg.sample(__nv_smp, uv).rgb;

    // O sombreamento é o que faz o círculo virar bola. `ponto` já é a normal da
    // superfície: numa esfera de raio 1 centrada na origem, as duas são a mesma
    // coisa — e isso economiza a conta inteira.
    float ang = u.lightAngle * PI / 180.0;
    float3 luz = normalize(float3(cos(ang), -sin(ang), 0.75));
    float difuso = max(dot(ponto, luz), 0.0);
    cor *= mix(1.0, 0.25 + 0.75 * difuso, u.shading);

    // Luz de contorno: a borda da esfera acende, como todo objeto redondo
    // iluminado por trás. É o detalhe que descola a bola do fundo.
    float contorno = pow(1.0 - ponto.z, 3.0) * u.rim;
    cor += contorno;

    // Uma borda suave de um pixel e meio, senão a bola sai serrilhada.
    float suave = 1.0 - smoothstep(1.0 - 1.5 / max(eng.acResolution.y * u.radius, 1.0), 1.0, d);
    float alfa = suave;

    if (u.keepLayer) {
        float saidaAlfa = alfa + original.a * (1.0 - alfa);
        float3 saidaCor = saidaAlfa > 0.0
            ? (cor * alfa + original.rgb * original.a * (1.0 - alfa)) / saidaAlfa
            : float3(0.0);
        __nv_out = float4(saidaCor, saidaAlfa);
    } else {
        __nv_out = float4(cor, alfa);
    }
    return __nv_out;
}
