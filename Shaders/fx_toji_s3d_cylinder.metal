// ---------------------------------------------------------------------------
// @am:string/effect_cylinder_name
// origem : assets/effects/toji-s3d-cylinder.xml
// id     : com.alightcreative.effects.cylinder
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_s3d_cylinderParams {
    float4 orient;
    float3 rotate;
    float radius;
    float height;
    float smooth;
    float3 position;
    float scale;
    int shadingType;
    float lightIntensity;
    float shine;
    float spec;
    float ambient;
    float4 lightColor;
    float2 lightDir;
    float lightDepth;
    int mirror;
    float texRepeatX;
    float texRepeatY;
    float texAngle;
    float texCrop;
    float texTwirl;
    float2 texOffset;
    float MAX_ITER;
};

// --- funcoes auxiliares do efeito
varying float4x4 invOrient;

        float4x4 __nv_inverse(in float4x4 m)
        {
            return float4x4(
                m[0][0], m[1][0], m[2][0], 0.0,
                m[0][1], m[1][1], m[2][1], 0.0,
                m[0][2], m[1][2], m[2][2], 0.0,
                -dot(m[0].xyz,m[3].xyz),
                -dot(m[1].xyz,m[3].xyz),
                -dot(m[2].xyz,m[3].xyz),
                1.0 );
        }

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

fragment float4 fx_toji_s3d_cylinder(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_s3d_cylinderParams&  u    [[buffer(1)]],
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
            invOrient = u.orient * rz * rx * ry;
    return __nv_out;
}
