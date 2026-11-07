#pragma once
#include <metal_stdlib>
using namespace metal;

// ---------------------------------------------------------------- helpers
// Gerado por glsl2msl.py. GLSL mod() nao e fmod(): difere para negativos.
inline float  __nv_mod(float x, float y)   { return x - y * floor(x / y); }
inline float2 __nv_mod(float2 x, float2 y) { return x - y * floor(x / y); }
inline float3 __nv_mod(float3 x, float3 y) { return x - y * floor(x / y); }
inline float4 __nv_mod(float4 x, float4 y) { return x - y * floor(x / y); }
inline float2 __nv_mod(float2 x, float y)  { return x - y * floor(x / y); }
inline float3 __nv_mod(float3 x, float y)  { return x - y * floor(x / y); }
inline float4 __nv_mod(float4 x, float y)  { return x - y * floor(x / y); }

// atan(y,x) do GLSL -> atan2; atan(x) continua atan.
inline float  __nv_atan(float y, float x)  { return atan2(y, x); }
inline float2 __nv_atan(float2 y, float2 x){ return float2(atan2(y.x,x.x), atan2(y.y,x.y)); }
inline float3 __nv_atan(float3 y, float3 x){ return float3(atan2(y.x,x.x), atan2(y.y,x.y), atan2(y.z,x.z)); }
inline float  __nv_atan(float x)           { return atan(x); }
inline float2 __nv_atan(float2 x)          { return atan(x); }
inline float3 __nv_atan(float3 x)          { return atan(x); }

// MSL nao tem inverse() de matriz.
inline float2x2 __nv_inverse(float2x2 m) {
    float d = m[0][0]*m[1][1] - m[0][1]*m[1][0];
    float i = (abs(d) < 1e-20f) ? 0.0f : 1.0f / d;
    return float2x2(float2( m[1][1]*i, -m[0][1]*i), float2(-m[1][0]*i,  m[0][0]*i));
}
inline float3x3 __nv_inverse(float3x3 m) {
    float3 a = m[0], b = m[1], c = m[2];
    float3 r0 = cross(b, c), r1 = cross(c, a), r2 = cross(a, b);
    float d = dot(a, r0);
    float i = (abs(d) < 1e-20f) ? 0.0f : 1.0f / d;
    return float3x3(float3(r0.x,r1.x,r2.x)*i, float3(r0.y,r1.y,r2.y)*i, float3(r0.z,r1.z,r2.z)*i);
}
inline float4x4 __nv_inverse(float4x4 m) {
    float a00=m[0][0],a01=m[0][1],a02=m[0][2],a03=m[0][3];
    float a10=m[1][0],a11=m[1][1],a12=m[1][2],a13=m[1][3];
    float a20=m[2][0],a21=m[2][1],a22=m[2][2],a23=m[2][3];
    float a30=m[3][0],a31=m[3][1],a32=m[3][2],a33=m[3][3];
    float b00=a00*a11-a01*a10, b01=a00*a12-a02*a10, b02=a00*a13-a03*a10;
    float b03=a01*a12-a02*a11, b04=a01*a13-a03*a11, b05=a02*a13-a03*a12;
    float b06=a20*a31-a21*a30, b07=a20*a32-a22*a30, b08=a20*a33-a23*a30;
    float b09=a21*a32-a22*a31, b10=a21*a33-a23*a31, b11=a22*a33-a23*a32;
    float det=b00*b11-b01*b10+b02*b09+b03*b08-b04*b07+b05*b06;
    float i=(abs(det)<1e-20f)?0.0f:1.0f/det;
    return float4x4(
      float4(( a11*b11-a12*b10+a13*b09)*i, (-a01*b11+a02*b10-a03*b09)*i,
             ( a31*b05-a32*b04+a33*b03)*i, (-a21*b05+a22*b04-a23*b03)*i),
      float4((-a10*b11+a12*b08-a13*b07)*i, ( a00*b11-a02*b08+a03*b07)*i,
             (-a30*b05+a32*b02-a33*b01)*i, ( a20*b05-a22*b02+a23*b01)*i),
      float4(( a10*b10-a11*b08+a13*b06)*i, (-a00*b10+a01*b08-a03*b06)*i,
             ( a30*b04-a31*b02+a33*b00)*i, (-a20*b04+a21*b02-a23*b00)*i),
      float4((-a10*b09+a11*b07-a12*b06)*i, ( a00*b09-a01*b07+a02*b06)*i,
             (-a30*b03+a31*b01-a32*b00)*i, ( a20*b03-a21*b01+a22*b00)*i));
}

// Dialeto Alight Motion.
inline float2 __nv_getTexSize(float2 s) { return s; }
inline void   __nv_vertShaderInit() { }
// No AM a UV da tela tem t = 0 EMBAIXO; no Metal tem t = 0 EM CIMA.
inline float2 __nv_acTela(float2 uv) { return float2(uv.x, 1.0f - uv.y); }
inline float2 __nv_acPontoNoBuffer(float2 p) { return p; }

inline float2x2 __nv_matCompMult(float2x2 a, float2x2 b){ return float2x2(a[0]*b[0], a[1]*b[1]); }
inline float3x3 __nv_matCompMult(float3x3 a, float3x3 b){ return float3x3(a[0]*b[0], a[1]*b[1], a[2]*b[2]); }
inline float4x4 __nv_matCompMult(float4x4 a, float4x4 b){ return float4x4(a[0]*b[0], a[1]*b[1], a[2]*b[2], a[3]*b[3]); }

// GLSL radians()/degrees(): o MSL nao tem.
inline float  radians(float d)  { return d * 0.017453292519943295f; }
inline float2 radians(float2 d) { return d * 0.017453292519943295f; }
inline float3 radians(float3 d) { return d * 0.017453292519943295f; }
inline float4 radians(float4 d) { return d * 0.017453292519943295f; }
inline float  degrees(float r)  { return r * 57.29577951308232f; }
inline float2 degrees(float2 r) { return r * 57.29577951308232f; }
inline float3 degrees(float3 r) { return r * 57.29577951308232f; }
inline float4 degrees(float4 r) { return r * 57.29577951308232f; }
