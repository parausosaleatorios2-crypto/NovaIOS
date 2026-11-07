// ---------------------------------------------------------------------------
// Passada de luz
// origem : assets/effects/light-sweep.xml
// id     : nova.effect.lightsweep
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct light_sweepParams {
    float2 center;
    float direction;
    int shape;
    float width;
    float sweepIntensity;
    float edgeIntensity;
    float edgeThickness;
    int lightReception;
    float4 lightColor;
};

// --- funcoes auxiliares do efeito
static float sweepProfile(float normalizedDistance) {
    float x = 1.0 - clamp(normalizedDistance, 0.0, 1.0);
    if (u.shape == 0) return x;
    if (u.shape == 1) return x * x * (3.0 - 2.0 * x);
    // Perfil concentrado: núcleo nítido, mas ainda contínuo e anti-aliased.
    return pow(x, 4.0);
}

fragment float4 fx_light_sweep(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant light_sweepParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 source = inputImg.sample(__nv_smp, in.acScreenNorm);

    // Trabalhar em espaço com aspecto corrigido impede a faixa de mudar de
    // largura quando a camada não é quadrada. `normal` é perpendicular ao eixo
    // da faixa; sua projeção dá a distância assinada do pixel ao sweep.
    float radiansDirection = radians(u.direction);
    float2 normal = float2(cos(radiansDirection), sin(radiansDirection));
    float2 pixelFromCenter = (in.acScreenNorm - u.center) * float2(eng.acAspect, 1.0);
    float signedDistance = dot(pixelFromCenter, normal);
    float normalizedDistance = abs(signedDistance) / max(u.width, 0.00001);
    float bandProfile = sweepProfile(normalizedDistance);

    // A contribuição principal nunca acende o vazio de um PNG/texto. Alfa
    // parcial continua parcial — nenhum threshold binário é introduzido aqui.
    float mainLight = bandProfile * u.sweepIntensity * source.a;

    // Gradiente central do alpha, em uma vizinhança controlada pela espessura.
    // A distância das amostras alarga a região de influência sem transformar a
    // borda num blur genérico. O x é corrigido pelo aspecto para compartilhar o
    // mesmo espaço geométrico da direção da luz.
    float2 edgeOffset = eng.acTexelSize * max(u.edgeThickness * 0.5, 0.5) * eng.acEscalaDePixel;
    float alphaLeft = inputImg.sample(__nv_smp, in.acScreenNorm - float2(edgeOffset.x, 0.0)).a;
    float alphaRight = inputImg.sample(__nv_smp, in.acScreenNorm + float2(edgeOffset.x, 0.0)).a;
    float alphaDown = inputImg.sample(__nv_smp, in.acScreenNorm - float2(0.0, edgeOffset.y)).a;
    float alphaUp = inputImg.sample(__nv_smp, in.acScreenNorm + float2(0.0, edgeOffset.y)).a;
    float2 alphaGradient = float2((alphaRight - alphaLeft) / max(eng.acAspect, 0.0001),
                              alphaUp - alphaDown);
    float gradientLength = length(alphaGradient);
    float2 edgeNormal = gradientLength > 0.00001
        ? alphaGradient / gradientLength
        : float2(0.0);

    // O gradiente aponta para dentro da região opaca. A luz chega no sentido
    // oposto à normal do sweep, portanto só a face que a encara recebe destaque.
    float facing = max(dot(edgeNormal, -normal), 0.0);
    float edgeMask = smoothstep(0.005, 0.25, gradientLength);
    float edgeLight = bandProfile * edgeMask * facing * u.edgeIntensity * source.a;

    float lightStrength = (mainLight + edgeLight) * u.lightColor.a;
    float3 lightContribution = u.lightColor.rgb * lightStrength;

    if (u.lightReception == 2) {
        // Recorte mostra somente a luz produzida. O alpha carrega a cobertura
        // iluminada, mantendo as áreas transparentes transparentes.
        float cutoutAlpha = clamp(lightStrength, 0.0, 1.0);
        __nv_out = float4(u.lightColor.rgb, cutoutAlpha);
    } else if (u.lightReception == 1) {
        // Uma camada de luz normal composta sobre a fonte; o alpha original da
        // camada é preservado para a composição posterior no renderer.
        float compositeAmount = clamp(lightStrength, 0.0, 1.0);
        __nv_out = float4(mix(source.rgb, u.lightColor.rgb, compositeAmount), source.a);
    } else {
        // Adição é o modo de brilho clássico. Não limitar antes da saída deixa
        // o pipeline usar o alcance que o framebuffer de destino suportar.
        __nv_out = float4(source.rgb + lightContribution, source.a);
    }
    return __nv_out;
}
