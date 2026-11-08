#pragma once
#include <metal_stdlib>
using namespace metal;

// LUT 3D entregue pelo motor (EffectParamTextures): .cube, PNG em tiras ou
// identidade. Amostra no centro dos texels das pontas, com filtro linear.
inline float3 nova_lut3d(texture3d<float> lut, float3 c) {
    constexpr sampler s(filter::linear, address::clamp_to_edge);
    float n = float(max(lut.get_width(), 2u));
    float3 uvw = clamp(c, 0.0, 1.0) * ((n - 1.0) / n) + 0.5 / n;
    return lut.sample(s, uvw).rgb;
}
