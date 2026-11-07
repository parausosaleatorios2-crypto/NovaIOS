// ---------------------------------------------------------------------------
// @am:string/effect_triprism_name
// origem : assets/effects/toji-s3d-triprism.xml
// id     : com.alightcreative.effects.triprism
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_s3d_triprismParams {
    float4 orient;
    float radius;
    float height;
    float zdist;
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
    float texStretch;
    float texAngle;
    float texTwirl;
    float2 texOffset;
};

// --- funcoes auxiliares do efeito
varying float4x4 invOrient;

        static float4x4 __nv_inverse(in float4x4 m)
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

fragment float4 fx_toji_s3d_triprism(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_s3d_triprismParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            __nv_vertShaderInit();
            invOrient = (u.orient);
    return __nv_out;
}
