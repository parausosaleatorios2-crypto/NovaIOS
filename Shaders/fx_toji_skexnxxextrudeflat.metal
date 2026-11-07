// ---------------------------------------------------------------------------
// 3D Extrude Flat
// origem : assets/effects/toji-skexnxxextrudeflat.xml
// id     : com.alightcreative.effects.extrudeflat
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxextrudeflatParams {
    float4 orient;
    float3 rotate;
    float3 position;
    float2 stretch;
    float depth;
    float scale;
    float MAX_ITER;
    int inton;
    float4 interiorColor;
    float interiorBlend;
    float4 fadeColor;
    float fadeBlend;
};

// --- funcoes auxiliares do efeito
varying float4x4 rotateAndOrient;

        float4x4 rotationAxisAngle( float3 v, float angle )
        {
            float s = sin( angle );
            float c = cos( angle );
            float ic = 1.0 - c;

            return float4x4( v.x*v.x*ic + c,     v.y*v.x*ic - s*v.z, v.z*v.x*ic + s*v.y, 0.0,
                         v.x*v.y*ic + s*v.z, v.y*v.y*ic + c,     v.z*v.y*ic - s*v.x, 0.0,
                         v.x*v.z*ic - s*v.y, v.y*v.z*ic + s*v.x, v.z*v.z*ic + c,     0.0,
                         0.0,                0.0,                0.0,                1.0 );
        }

fragment float4 fx_toji_skexnxxextrudeflat(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxextrudeflatParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            __nv_vertShaderInit();
            float3 r = u.rotate * 0.0174533;
            float4x4 rx = rotationAxisAngle(float3(1.,0.,0.),r.x);
            float4x4 ry = rotationAxisAngle(float3(0.,1.,0.),r.y);
            float4x4 rz = rotationAxisAngle(float3(0.,0.,1.),r.z);
            rotateAndOrient = u.orient * rz * rx * ry;
    return __nv_out;
}
