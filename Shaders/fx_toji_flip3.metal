// ---------------------------------------------------------------------------
// @am:string/effect_flip2_name
// origem : assets/effects/toji-flip3.xml
// id     : com.alightcreative.effects.flip3
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_flip3Params {
    float angle;
    float axis;
    float2 pivot;
    float crop;
    float zdist;
    int solid;
    float4 solidColor;
    float thickness;
    int enableLight;
    float lightIntensity;
    float4 lightColor;
    float shine;
    float spec;
    float ambient;
    float2 lightDir;
    float lightDepth;
};

// --- funcoes auxiliares do efeito
// returns t and normal
        float4 iBox( in float3 ro, in float3 rd, in float4x4 txx, in float4x4 txi, in float3 rad )
        {
            // convert from ray to box space
            float3 rdd = (txx*float4(rd,0.0)).xyz;
            float3 roo = (txx*float4(ro,1.0)).xyz;

            // ray-box intersection in box space
            float3 m = 1.0/rdd;
            float3 n = m*roo;
            float3 k = abs(m)*rad;

            float3 t1 = -n - k;
            float3 t2 = -n + k;

            float tN = max( max( t1.x, t1.y ), t1.z );
            float tF = min( min( t2.x, t2.y ), t2.z );

            if( tN > tF || tF < 0.0) return float4(-1.0);

            float3 nor = -sign(rdd)*step(t1.yzx,t1.xyz)*step(t1.zxy,t1.xyz);

            // convert to ray space

            nor = (txi * float4(nor,0.0)).xyz;

            return float4( tN, nor );
        }

        float sBox( in float3 ro, in float3 rd, in float4x4 txx, in float3 rad )
        {
            float3 rdd = (txx*float4(rd,0.0)).xyz;
            float3 roo = (txx*float4(ro,1.0)).xyz;

            float3 m = 1.0/rdd;
            float3 n = m*roo;
            float3 k = abs(m)*rad;

            float3 t1 = -n - k;
            float3 t2 = -n + k;

            float tN = max( max( t1.x, t1.y ), t1.z );
            float tF = min( min( t2.x, t2.y ), t2.z );
            if( tN > tF || tF < 0.0) return -1.0;

            return tN;
        }

        float4x4 rotationAxisAngle( float3 v, float u.angle )
        {
            float s = sin( u.angle );
            float c = cos( u.angle );
            float ic = 1.0 - c;

            return float4x4( v.x*v.x*ic + c,     v.y*v.x*ic - s*v.z, v.z*v.x*ic + s*v.y, 0.0,
                         v.x*v.y*ic + s*v.z, v.y*v.y*ic + c,     v.z*v.y*ic - s*v.x, 0.0,
                         v.x*v.z*ic - s*v.y, v.y*v.z*ic + s*v.x, v.z*v.z*ic + c,     0.0,
                         0.0,                0.0,                0.0,                1.0 );
        }

        float4x4 translate( float x, float y, float z )
        {
            return float4x4( 1.0, 0.0, 0.0, 0.0,
                         0.0, 1.0, 0.0, 0.0,
                         0.0, 0.0, 1.0, 0.0,
                         x,   y,   z,   1.0 );
        }

        float4x4 translate( float3 v )
        {
            return float4x4( 1.0, 0.0, 0.0, 0.0,
                         0.0, 1.0, 0.0, 0.0,
                         0.0, 0.0, 1.0, 0.0,
                         v.x, v.y, v.z, 1.0 );
        }

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

fragment float4 fx_toji_flip3(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_flip3Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            float2 st = in.acLayerNorm;
            st -= 0.5;

            float width;
            float height;

            if( eng.acLayerSize.x > eng.acLayerSize.y ) {
                width = eng.acLayerSize.x/eng.acLayerSize.y;
                height = 1.0;
                st.x *= eng.acLayerSize.x/eng.acLayerSize.y;
            }  else {
                height = eng.acLayerSize.y/eng.acLayerSize.x;
                width = 1.0;
                st.y *= eng.acLayerSize.y/eng.acLayerSize.x;
            }

            float depth = u.solid? max(0.00001,u.thickness/10.0) : 0.00001 ;

            float2 p = st;

             // camera movement
            float3 ro = float3( 0.0, 0.0, 2.0 );
            float3 ta = float3( 0.0, 0.0, 0.0 );
            // camera matrix
            float3 ww = normalize( ta - ro );
            float3 uu = normalize( cross(ww,float3(0.0,1.0,0.0) ) );
            float3 vv = normalize( cross(uu,ww));
            // create view ray
            float3 rd = normalize( p.x*uu + p.y*vv + 2.0*ww );

            // rotate and translate box
            float axisRad = u.axis * 3.14159 / 180.0;
            float2x2 rotAxis = float2x2(
                cos(axisRad), -sin(axisRad),
                sin(axisRad), cos(axisRad)
            );
            float3 adjPivot = float3( u.pivot.x/200.0*width, -u.pivot.y/200.0*height, 0.0 );
            float2 axisVec = float2(0.0,1.0) * rotAxis;
            float4x4 orient = rotationAxisAngle(float3(axisVec,0.0),u.angle * 3.14159 / 180.0);
            float4x4 tra = translate( 0.0, 0.0, -u.zdist );
            float4x4 txi = tra * translate( adjPivot ) * orient * translate( -adjPivot );
            float4x4 txx = __nv_inverse(txi);

            // raytrace
            float tmin = 10000.0;
            float3  nor = float3(0.0);
            float3  pos = float3(0.0);

            // raytrace box
            float3 box = float3(width/2.,height/2.,depth/2.) ;
            float4 res = iBox( ro, rd, txx, txi, box);
            if( res.x>0.0 && res.x<tmin )
            {
                tmin = res.x;
                nor = res.yzw;
            }

            // shading/lighting
            if( tmin<100.0 )
            {
                float3 lightPos = normalize((txx*float4(u.lightDir.x/2.0, -u.lightDir.y/2.0, -u.lightDepth*2.0, 0.0)).xyz);
                pos = ro + tmin*rd;

                float occ = 1.0;

                // recover box space data (we want to do shading in object space)
                float3 opos = (txx*float4(pos,1.0)).xyz;
                float3 onor = (txx*float4(nor,0.0)).xyz;
                float4 texColor = abs(onor.z)*inputImg.sample(__nv_smp, (float4(__nv_mod(u.crop*0.5*opos.xy/box.xy+0.5, 1.0),0.,1.)*eng.acLayerToScreen).xy);
                occ = 0.6 + 0.4*nor.y;

                float4 result = texColor;

                if( u.solid ) {
                    result = u.solidColor*(1.-result.a) + result;
                }

                if( u.enableLight ) {

                    // lighting
                    float l = clamp( dot(onor,normalize(lightPos)), 0.0, 1.0 );
                    float3 tc = result.rgb;
                    float3 surface = tc * u.ambient + tc * u.lightColor.rgb * l * (1.-u.ambient);
                    surface *= u.lightIntensity;
                    float s = pow(l,u.spec);
                    surface = mix(surface*(1.-u.shine*0.1),float3(1.),u.shine*s);
                    
                    result.rgb = surface;
                }

                __nv_out = result;
            } else {
                __nv_out = float4( 0. );
            }
    return __nv_out;
}
