// ---------------------------------------------------------------------------
// @am:string/effect_cube_name
// origem : assets/effects/toji-cube.xml
// id     : com.alightcreative.effects.cube
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_cubeParams {
    float4 orient;
    float width;
    float height;
    float depth;
    float crop;
    float zdist;
    int enableLight;
    float lightIntensity;
    float4 lightColor;
    float light;
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

        float4x4 translate( float x, float y, float z )
        {
            return float4x4( 1.0, 0.0, 0.0, 0.0,
                         0.0, 1.0, 0.0, 0.0,
                         0.0, 0.0, 1.0, 0.0,
                         x,   y,   z,   1.0 );
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

fragment float4 fx_toji_cube(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_cubeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            float2 st = in.acLayerNorm;
            st -= 0.5;
            st.x *= eng.acLayerSize.x/eng.acLayerSize.y;


            float2 p = st;
            //float iTime = angle;

             // camera movement
            //float an = 0.4*iTime;
            //float3 ro = float3( 2.5, 1.0, 2.5 );
            //float3 ta = float3( 0.0, 1.0, 0.0 );
            float3 ro = float3( 0.0, 0.0, 2.0 );
            float3 ta = float3( 0.0, 0.0, 0.0 );
            // camera matrix
            float3 ww = normalize( ta - ro );
            float3 uu = normalize( cross(ww,float3(0.0,1.0,0.0) ) );
            float3 vv = normalize( cross(uu,ww));
            // create view ray
            float3 rd = normalize( p.x*uu + p.y*vv + 2.0*ww );

            // rotate and translate box
            //float4x4 rot = rotationAxisAngle( normalize(float3(1.0,1.0,0.0)), iTime );
            //float4x4 rotx = rotationAxisAngle( normalize(float3(1.0,0.0,0.0)), position.x/1000. );
            //float4x4 roty = rotationAxisAngle( normalize(float3(0.0,1.0,0.0)), position.y/1000. );
            //float4x4 rot = rotx * roty;
            float4x4 rot45y = float4x4(
                cos(-0.25*3.14159), 0.0, sin(-0.25*3.14159), 0.0,
                0.0, 1.0, 0.0, 0.0,
                -sin(-0.25*3.14159), 0.0, cos(-0.25*3.14159), 0,
                0.0, 0.0, 0.0, 1.0
            );
            //float4x4 tra = translate( 0.0, 0.0, 0.0 );
           // float4x4 txi = tra * rot45y * u.orient;
            float4x4 tra = translate( 0.0, 0.0, -u.zdist );
            float4x4 txi = tra * u.orient;
            float4x4 txx = __nv_inverse(txi);

            // raytrace
            float tmin = 10000.0;
            float3  nor = float3(0.0);
            float3  pos = float3(0.0);

            // raytrace box
            float3 box = float3(u.width/2.,u.height/2.,u.depth/2.) ;
            float4 res = iBox( ro, rd, txx, txi, box);
            if( res.x>0.0 && res.x<tmin )
            {
                tmin = res.x;
                nor = res.yzw;
            }

            // shading/lighting
            float3 col = float3(0.9);
            if( tmin<100.0 )
            {
                float lightAngle = u.light * 0.0174533;
                float3 lig = normalize(float3(cos(lightAngle),-sin(lightAngle),u.lightDepth));
                pos = ro + tmin*rd;

                // material
                float occ = 1.0;
                float3  mate = float3(1.0);

                {
                    // recover box space data (we want to do shading in object space)
                    float3 opos = (txx*float4(pos,1.0)).xyz;
                    float3 onor = (txx*float4(nor,0.0)).xyz;

                    mate = abs(onor.x)*inputImg.sample(__nv_smp, (float4(__nv_mod(u.crop*0.5*opos.yz/box.yz+0.5, 1.0),0.,1.)*eng.acLayerToScreen).xy).xyz +
                           abs(onor.y)*inputImg.sample(__nv_smp, (float4(__nv_mod(u.crop*0.5*opos.zx/box.zx+0.5, 1.0),0.,1.)*eng.acLayerToScreen).xy).xyz +
                           abs(onor.z)*inputImg.sample(__nv_smp, (float4(__nv_mod(u.crop*0.5*opos.xy/box.xy+0.5, 1.0),0.,1.)*eng.acLayerToScreen).xy).xyz;

                    // wireframe
                    //mate *= 1.0 - (1.0-abs(onor.x))*smoothstep( box.x-0.04, box.x-0.02, abs(opos.x) );
                    //mate *= 1.0 - (1.0-abs(onor.y))*smoothstep( box.y-0.04, box.y-0.02, abs(opos.y) );
                    //mate *= 1.0 - (1.0-abs(onor.z))*smoothstep( box.z-0.04, box.z-0.02, abs(opos.z) );

                    occ = 0.6 + 0.4*nor.y;
                }
                mate = mate*mate*1.5;

                // lighting
                float dif = clamp( dot(nor,lig), 0.0, 1.0 );
                dif *= step( sBox( pos+0.01*nor, lig, txx, box ), 0.0 );
                col = u.lightColor.rgb*u.lightIntensity*occ*3.0 + 1.5*dif*u.lightColor.rgb*u.lightIntensity;

                // material * lighting
                col *= mate;

                // fog
                col = mix( col, float3(0.9), 1.0-exp( -0.003*tmin*tmin ) );
                col = sqrt( col );

                if( !u.enableLight ) {
                    col = mate;
                }

                __nv_out = float4( col, 1.0 );
            } else {
                __nv_out = float4( 0. );
            }



            //float4 texColor = inputImg.sample(__nv_smp, (float4(uv,0.,1.)*eng.acLayerToScreen).xy);

            //__nv_out = radius > 0.5 ? float4(0.) : mix(texColor,fogColor,clamp((1.-radius*2.)*fog,0.,1.));
    return __nv_out;
}
