// ---------------------------------------------------------------------------
// @am:string/effect_heart_name
// origem : assets/effects/toji-s3d-heart2.xml
// id     : com.alightcreative.effects.heart2
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_s3d_heart2Params {
    float4 orient;
    float3 rotate;
    float size;
    float shape;
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
    float texCrop;
    float texScale;
    float2 texStretch;
    float texAngle;
    float texTwirl;
    float2 texOffset;
    float MAX_ITER;
};

// --- funcoes auxiliares do efeito
varying float4x4 orientAndRotate;

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

fragment float4 fx_toji_s3d_heart2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_s3d_heart2Params&  u    [[buffer(1)]],
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
            orientAndRotate = u.orient * rz * rx * ry;
    return __nv_out;
}
