// ---------------------------------------------------------------------------
// S_MathOps
// origem : assets/effects/sapphire-math-ops.xml
// id     : nova.effect.smathops
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct sapphire_math_opsParams {
    int operation;
    int swapInputs;
    float aLights;
    float aDarks;
    float aSaturation;
    float bLights;
    float bDarks;
    float bSaturation;
    float destLights;
    float destDarks;
    float destSaturation;
};

// --- funcoes auxiliares do efeito
// `sat_scale` do Sapphire (legacy luma, 0.3/0.59/0.11 — Rec.601 arredondado). O alfa não é tocado.
static float4 satScale(float4 c, float s) {
    float y = 0.3 * c.r + 0.59 * c.g + 0.11 * c.b;
    return float4(y + (c.rgb - y) * s, c.a);
}

// bounce(x, b) = b − |__nv_mod(x, 2b) − b|. Com b = 0 o resultado é 0 (o plugin trata o degenerado
// quieto; se alguém colocar Round com Dest B = 0, cai aqui também).
static float4 bounce4(float4 x, float4 b) {
    float4 twoB = 2.0 * b;
    float4 m = __nv_mod(x, max(twoB, float4(1e-30)));
    float4 r = b - abs(m - b);
    return mix(r, float4(0.0), float4(lessThanEqual(abs(b), float4(1e-30))));
}

// Bitwise em 8 bits, canal a canal. O plugin converte para inteiro antes da operação.
static float4 andBits(float4 a, float4 b) {
    int4 ia = int4(clamp(a, 0.0, 1.0) * 255.0 + 0.5);
    int4 ib = int4(clamp(b, 0.0, 1.0) * 255.0 + 0.5);
    return float4(ia & ib) / 255.0;
}
static float4 orBits(float4 a, float4 b) {
    int4 ia = int4(clamp(a, 0.0, 1.0) * 255.0 + 0.5);
    int4 ib = int4(clamp(b, 0.0, 1.0) * 255.0 + 0.5);
    return float4(ia | ib) / 255.0;
}
static float4 xorBits(float4 a, float4 b) {
    int4 ia = int4(clamp(a, 0.0, 1.0) * 255.0 + 0.5);
    int4 ib = int4(clamp(b, 0.0, 1.0) * 255.0 + 0.5);
    return float4(ia ^ ib) / 255.0;
}

// Round do Sapphire: snap(i1 / i2) · i2. Com i2 = 0 o quociente estoura; o plugin pisa igual
// (resultado NaN/∞). Devolver 0 ali evita a propagação de NaN sem reaproximar a conta.
static float4 roundOp(float4 a, float4 b) {
    float4 safeB = mix(b, float4(1e-30), float4(equal(b, float4(0.0))));
    float4 q = floor(a / safeB + 0.5);
    return mix(q * b, float4(0.0), float4(equal(b, float4(0.0))));
}

static float4 aplicarGrading(float4 c, float lights, float darks, float sat) {
    float4 g = satScale(c, sat);
    return (lights - darks) * g + darks;
}

fragment float4 fx_sapphire_math_ops(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant sapphire_math_opsParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> sourceB [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 srcA = inputImg.sample(__nv_smp, in.acScreenNorm);
    // SourceB em "None" (textura 1×1 transparente, como o `empty="transparent"` entrega) =
    // float4(0,0,0,0), como o AE trata.
    float4 srcB = int2(int(sourceB.get_width()), int(sourceB.get_height())).x <= 1 ? float4(0.0) : sourceB.sample(__nv_smp, in.acScreenNorm);

    float4 a = u.swapInputs ? srcB : srcA;
    float4 b = u.swapInputs ? srcA : srcB;

    float4 i1 = aplicarGrading(a, u.aLights, u.aDarks, u.aSaturation);
    float4 i2 = aplicarGrading(b, u.bLights, u.bDarks, u.bSaturation);

    float4 d;
    if (u.operation == 0) {           // Add
        d = i1 + i2;
    } else if (u.operation == 1) {    // Subtract
        d = i1 - i2;
    } else if (u.operation == 2) {    // Multiply
        d = i1 * i2;
    } else if (u.operation == 3) {    // Divide
        d = i1 / i2;
    } else if (u.operation == 4) {    // Screen
        d = i1 + i2 - i1 * i2;
    } else if (u.operation == 5) {    // Average
        d = 0.5 * (i1 + i2);
    } else if (u.operation == 6) {    // Overlay
        float4 screenV = i1 + i2 - i1 * i2;
        float4 multiV = i1 * i2;
        d = mix(2.0 * multiV, 2.0 * screenV - 1.0, float4(greaterThan(i2, float4(0.5))));
    } else if (u.operation == 7) {    // Minimum
        d = min(i1, i2);
    } else if (u.operation == 8) {    // Maximum
        d = max(i1, i2);
    } else if (u.operation == 9) {    // Difference
        d = abs(i1 - i2);
    } else if (u.operation == 10) {   // Xor (triangular)
        d = bounce4(clamp(i1, 0.0, 1.0) + clamp(i2, 0.0, 1.0), float4(1.0));
    } else if (u.operation == 11) {   // Xor Bits
        d = xorBits(i1, i2);
    } else if (u.operation == 12) {   // And Bits
        d = andBits(i1, i2);
    } else if (u.operation == 13) {   // Or Bits
        d = orBits(i1, i2);
    } else if (u.operation == 14) {   // Mod
        float4 safe = mix(i2, float4(1e-30), float4(equal(i2, float4(0.0))));
        d = i1 - i2 * floor(i1 / safe);
    } else if (u.operation == 15) {   // Bounce
        d = bounce4(i1, i2);
    } else {                        // Round
        d = roundOp(i1, i2);
    }

    __nv_out = aplicarGrading(d, u.destLights, u.destDarks, u.destSaturation);
    return __nv_out;
}
