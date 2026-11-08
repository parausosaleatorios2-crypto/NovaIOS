#pragma once
#include <metal_stdlib>
using namespace metal;
// Funcoes GLSL de comparacao vetorial que o MSL nao tem.
// Incluido so nos efeitos reparados por Tools/reparar_shader.py.
template <typename A, typename B> inline auto equal(A a, B b)            -> decltype(a == b) { return a == b; }
template <typename A, typename B> inline auto notEqual(A a, B b)         -> decltype(a != b) { return a != b; }
template <typename A, typename B> inline auto lessThan(A a, B b)         -> decltype(a <  b) { return a <  b; }
template <typename A, typename B> inline auto lessThanEqual(A a, B b)    -> decltype(a <= b) { return a <= b; }
template <typename A, typename B> inline auto greaterThan(A a, B b)      -> decltype(a >  b) { return a >  b; }
template <typename A, typename B> inline auto greaterThanEqual(A a, B b) -> decltype(a >= b) { return a >= b; }

// sampler2D do GLSL como parametro de funcao auxiliar.
typedef texture2d<float> sampler2D;

// Luminancia que o motor Android injeta nos efeitos gm-* (Rec. 709).
inline float gmLum(float3 c) { return dot(c, float3(0.2126, 0.7152, 0.0722)); }
inline float gmLum(float4 c) { return gmLum(c.rgb); }

// mix(a, b, bvec) do GLSL escolhe por componente: no MSL e select.
inline float2 mix(float2 a, float2 b, bool2 c) { return select(a, b, c); }
inline float3 mix(float3 a, float3 b, bool3 c) { return select(a, b, c); }
inline float4 mix(float4 a, float4 b, bool4 c) { return select(a, b, c); }
