// ---------------------------------------------------------------------------
// Olho de peixe
// origem : assets/effects/fisheye.xml
// id     : nova.effect.fisheye
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct fisheyeParams {
    int mode;
    float fov;
    int projection;
    float zoom;
    float2 center;
    int circular;
    float squeeze;
    int edge;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265;

fragment float4 fx_fisheye(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant fisheyeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    // Coordenada com a proporção corrigida: sem isso, o "círculo" do olho de
    // peixe sai oval em composição que não é quadrada, e o efeito inteiro fica
    // errado num vídeo vertical — que é a maioria aqui.
    float2 p = (in.acScreenNorm - u.center) * float2(eng.acAspect, 1.0) * 2.0 / max(u.zoom, 1e-3);

    // Achatar: uma lente anamórfica de pobre. Positivo estica na horizontal.
    p.x *= 1.0 + u.squeeze;
    p.y *= 1.0 - u.squeeze;

    float raio = length(p);
    float meioCampo = radians(u.fov) * 0.5;
    float tanMeio = tan(min(meioCampo, radians(89.0)));

    float fator;

    if (u.mode == 1) {
        // ------------------------------------------------------ desfazer
        //
        // O caminho de volta: a tela é a imagem já entortada, e queremos onde
        // aquele ponto estaria numa lente reta. É a mesma conta ao contrário.
        float theta;
        if (u.projection == 1) {
            theta = 2.0 * __nv_atan(raio * tan(meioCampo * 0.5));
        } else if (u.projection == 2) {
            theta = asin(clamp(raio * sin(meioCampo), -1.0, 1.0));
        } else {
            theta = raio * meioCampo;
        }
        fator = (raio > 1e-5) ? (tan(min(theta, radians(89.0))) / tanMeio) / raio : 1.0;
    } else {
        // ------------------------------------------------------- aplicar
        //
        // O ângulo que este pixel representa, e onde a fonte reta seria lida.
        float theta = __nv_atan(raio * tanMeio);

        float rProjetado;
        if (u.projection == 1) {
            // Estereográfica: r = 2·tan(θ/2), normalizada pelo campo.
            rProjetado = 2.0 * tan(theta * 0.5) / (2.0 * tan(meioCampo * 0.5));
        } else if (u.projection == 2) {
            // Ortográfica: r = sin(θ).
            rProjetado = sin(theta) / sin(meioCampo);
        } else {
            // Equidistante: r = θ.
            rProjetado = theta / meioCampo;
        }

        // A razão entre "onde deveria estar" e "onde está" é o que estica ou
        // encolhe cada anel da imagem.
        fator = (rProjetado > 1e-5) ? (raio / rProjetado) : 1.0;
    }

    float2 fonte = u.center + (p * fator) / (2.0 * float2(eng.acAspect, 1.0));

    // Fora da imagem: três respostas, e a diferença se vê nas quinas.
    float4 cor;
    bool fora = fonte.x < 0.0 || fonte.x > 1.0 || fonte.y < 0.0 || fonte.y > 1.0;

    if (!fora) {
        cor = inputImg.sample(__nv_smp, fonte);
    } else if (u.edge == 1) {
        // Esticar: a textura já é CLAMP_TO_EDGE, então basta ler aparado.
        cor = inputImg.sample(__nv_smp, clamp(fonte, 0.0, 1.0));
    } else if (u.edge == 2) {
        // Espelhar: dobra a coordenada de volta para dentro.
        float2 espelhada = abs(fract(fonte * 0.5) * 2.0 - 1.0);
        cor = inputImg.sample(__nv_smp, espelhada);
    } else {
        cor = float4(0.0);
    }

    // O recorte u.circular, com a borda macia de um pixel e meio — é o que faz o
    // resultado parecer uma lente, e não uma imagem entortada.
    if (u.circular) {
        float suave = 1.5 / max(eng.acResolution.y, 1.0) * 2.0;
        float dentro = 1.0 - smoothstep(1.0 - suave, 1.0, raio);
        cor *= dentro;
    }

    __nv_out = cor;
    return __nv_out;
}
