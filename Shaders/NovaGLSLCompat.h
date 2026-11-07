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
