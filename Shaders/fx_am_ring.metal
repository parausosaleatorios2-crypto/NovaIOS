// ---------------------------------------------------------------------------
// Anel
// origem : assets/effects/am-ring.xml
// id     : nova.effect.am-ring
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_ringParams {
    float4 orient;
    float3 rotate;
    float radius;
    float thickness;
    float height;
    float smoothing;
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
    int texStretch;
    float texRepeatX;
    float texRepeatY;
    float texAngle;
    float texCrop;
    float texTwirl;
    float2 texOffset;
    float MAX_ITER;
};

// --- funcoes auxiliares do efeito
// O varying do vértice do AM (`u.orient * rz * rx * ry`, constante na tela toda): aqui, feito uma vez no `main`.
float4x4 orientAndRotate;

#define OBJECT_CENTER (u.position/100.)

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

float sdCappedCylinder( float3 p, float h, float r )
{
  float2 d = abs(float2(length(p.xz),p.y)) - float2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float opSmoothSubtraction( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h); }

float dist(float3 p) {
    float d = 100000000.0;

    p = p-OBJECT_CENTER;
    p = (float4(p,1.) * orientAndRotate).xyz;

    float outer = sdCappedCylinder(p,u.radius-u.smoothing,u.height-u.smoothing)-u.smoothing;
    float inner = sdCappedCylinder(p,u.radius-u.thickness,u.height+0.1);
    return opSmoothSubtraction(inner,outer,u.smoothing);
}

float march(float3 ro, float3 rd) {
    float d = 0.0;
    for( int i=0; i<int(u.MAX_ITER); i++ ) {
        float3 p = ro + rd*d;
        float dd = dist(p);
        d += dd;
        if( dd < 0.00001 || d > 1000.0 ) break;
    }
    return d;
}

float3 calcNormal(float3 p) {
    float d = dist(p);
    float2 e = float2(.01,0.);
    return normalize(d - float3(
        dist(p-e.xyy),
        dist(p-e.yxy),
        dist(p-e.yyx)));
}

float lighting(float3 p, float3 n) {
    float3 lightPos = float3(u.lightDir.x/2.0, -u.lightDir.y/2.0, -u.lightDepth*2.0);
    float3 l = normalize(lightPos-p);
    return dot(n,l);
}

float directionalLighting(float3 p, float3 n) {
    float3 lightPos = float3(u.lightDir.x/2.0, -u.lightDir.y/2.0, -u.lightDepth*2.0);
    float3 l = normalize(lightPos);
    return dot(n,l);
}

float4 applyShading(float4 texColor, float3 p, float3 n, float d ) {
    float4 result = float4(0.);
    float a = smoothstep(30.0,9.,d);
    a *= smoothstep(0.3,0.2,n.z);
    if( u.shadingType == 0 ) {                // Flat
        result = texColor * a;
    } else if( u.shadingType == 1 ) {         // Point Light
        float l = lighting(p,n);
        float3 tc = texColor.rgb;
        float3 surface = tc * u.ambient + tc * u.lightColor.rgb * l * (1.-u.ambient);
        surface *= u.lightIntensity;
        float s = pow(l,u.spec);
        surface = mix(surface*(1.-u.shine*0.1),float3(1.),u.shine*s);
        result = float4(surface, texColor.a) * a;
    } else if( u.shadingType == 2 ) {         // Directonal Light
        float l = directionalLighting(p,n);
        float3 tc = texColor.rgb;
        float3 surface = tc * u.ambient + tc * u.lightColor.rgb * l * (1.-u.ambient);
        surface *= u.lightIntensity;
        float s = pow(l,u.spec);
        surface = mix(surface*(1.-u.shine*0.1),float3(1.),u.shine*s);
        result = float4(surface, texColor.a) * a;
    } else if( u.shadingType == 3 ) {         // Depth Map
        float ds = max(u.radius,u.height)*2.5;
        float dd = 1. - ((d - OBJECT_CENTER.z + ds/2.)/ds);
        result = float4( dd,dd,dd, 1. ) * a;
    } else if( u.shadingType == 4 ) {         // Normal Map
        result = float4( (n/2.)+0.5, 1. ) * a;
    } else if( u.shadingType == 5 ) {         // Normal * Depth
        float ds = max(u.radius,u.height)*2.5;
        float dd = 1. - ((d - OBJECT_CENTER.z + ds/2.)/ds);
        result = float4( ((n/2.)+0.5)*dd, 1. ) * a;
    }

    return result;
}

float2 mapTexture( float2 texCoord ) {
    float texRad = u.texAngle * 0.0174533;
    float texCos = cos(texRad);
    float texSin = sin(texRad);
    float2x2 texRot = float2x2( texCos, -texSin, texSin, texCos );

    float texTwirlRad = u.texTwirl * 0.0174533;
    float texTwirlCos = cos(texTwirlRad);
    float texTwirlSin = sin(texTwirlRad);
    float2x2 texTwirlRot = float2x2( texTwirlCos, -texTwirlSin, texTwirlSin, texTwirlCos );

    float2 texScaleVec = float2(1./u.texRepeatX,1./u.texRepeatY);

    texCoord *= texRot;

    texCoord += u.texOffset / 1000.0;
    texCoord /= texScaleVec;
    if(u.mirror) {
        texCoord = abs(__nv_mod(texCoord-float2(1.0,1.0), float2(2.0,2.0))-float2(1.0,1.0));
    } else {
        texCoord = __nv_mod(texCoord, float2(1.0,1.0));
    }

    texCoord -= 0.5;
    // O `eng.acScreenSize` do AM é o tamanho da cena (`eng.acTamanhoDaTela`).
    texCoord = texCoord * (1.-5./eng.acTamanhoDaTela);
    texCoord *= u.texCrop;
    texCoord *= texTwirlRot;
    texCoord += 0.5;
    return texCoord;
}

float4 preMultiplicada(float4 c) { return float4(c.rgb * c.a, c.a); }

// O filtro linear da GPU, à mão, sobre a camada PRÉ-multiplicada (a textura do AM é assim): os 4 pixels em volta,
// presos à borda como o CLAMP_TO_EDGE (o mesmo do Túnel).
float4 camadaNoPonto(float2 uv) {
    int2 T = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    float2 p = uv * float2(T) - 0.5;
    float2 i = floor(p);
    float2 f = p - i;
    int2 a = int2(i);
    int2 m = T - 1;
    float4 c00 = preMultiplicada(inputImg.read(uint2(clamp(a, int2(0), m)), uint(0)));
    float4 c10 = preMultiplicada(inputImg.read(uint2(clamp(a + int2(1, 0), int2(0), m)), uint(0)));
    float4 c01 = preMultiplicada(inputImg.read(uint2(clamp(a + int2(0, 1), int2(0), m)), uint(0)));
    float4 c11 = preMultiplicada(inputImg.read(uint2(clamp(a + int2(1, 1), int2(0), m)), uint(0)));
    return mix(mix(c00, c10, f.x), mix(c01, c11, f.x), f.y);
}

// O fundo (a cena montada atrás da camada) no pixel da tela, pré-multiplicado.
float3 fundoNoPixel() {
    int2 T = int2(int(comp.get_width()), int(comp.get_height()));
    int2 px = clamp(int2(floor(__nv_acTela(in.acScreenNorm) * float2(T))), int2(0), T - 1);
    float4 f = comp.read(uint2(px), uint(0));
    return f.rgb * f.a;
}

// A saída pré-multiplicada do AM em cor reta. O comum (cor ≤ alfa) é só dividir. Mas o brilho especular do AM cai
// também onde a camada é transparente: sai cor ACIMA do alfa (até cor > 0 com alfa 0), luz que a composição dele
// SOMA ao que está atrás (`p + fundo·(1 − op·alfa)`), e a cor reta não guarda isso. Aí este pixel leva junto o
// fundo dele: com o menor alfa `a` em que a cor reta `s = fundo + (p − fundo·alfa)/a` cabe entre 0 e 1, a
// composição Normal do Nova, `s·a·op + fundo·(1 − a·op)`, dá o mesmo `op·p + fundo·(1 − op·alfa)` do AM com
// QUALQUER opacidade da camada. Não cabe só quando a soma passa de 1 (`fundo + p − fundo·alfa`): com a opacidade
// cheia ela vira 1 lá e aqui; com menos, aqui sai um pouco mais escuro.
float4 paraReta(float4 p) {
    // Quem decide se a cor passou do alfa é o alvo de 8 bits do AM (um resto de conta abaixo de meio nível some lá).
    float4 q = floor(p * 255.0 + 0.5) / 255.0;
    if (all(lessThanEqual(q.rgb, float3(q.a)))) return p.a > 0.0 ? float4(min(p.rgb / p.a, float3(1.0)), p.a) : float4(0.0);
    float3 d = fundoNoPixel();
    float3 sobra = q.rgb - d * q.a;
    float3 folga = 1.0 - d;
    float a = q.a;
    for (int i = 0; i < 3; i++) {
        // Canal com o fundo cheio (1): lá e aqui a soma fica em 1 com qualquer alfa, então ele não pede nada.
        if (sobra[i] > 0.0 && folga[i] > 0.0) a = max(a, sobra[i] / folga[i]);
    }
    a = min(a, 1.0);
    return a > 0.0 ? float4(clamp(d + sobra / a, 0.0, 1.0), a) : float4(0.0);
}

// A volta da `eng.acCamadaParaTela`: UV da tela → UV do buffer da camada.
float2 naCamada(float2 t) {
    float3 c = __nv_inverse(eng.acCamadaParaTela) * float3(t, 1.0);
    return c.xy / c.z;
}

fragment float4 fx_am_ring(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_ringParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> comp [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& comp_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    // O vértice do AM.
    float3 r = u.rotate * 0.0174533;
    float4x4 rx = rotationAxisAngle(float3(1.,0.,0.),r.x);
    float4x4 ry = rotationAxisAngle(float3(0.,1.,0.),r.y);
    float4x4 rz = rotationAxisAngle(float3(0.,0.,1.),r.z);
    orientAndRotate = u.orient * rz * rx * ry;

    // O pixel na tela e, de lá, a coordenada da camada do AM (o `in.acLayerNorm`): o retângulo do conteúdo de 0 a 1, com
    // o Y para CIMA (a matriz do AM inverte o Y da tela; o buffer de camada do Nova cresce para baixo).
    float2 conteudo = max(eng.acTamanhoDaCamada, float2(1e-6));
    float2 st = 0.5 + (naCamada(__nv_acTela(in.acScreenNorm)) - 0.5) * eng.acTamanhoDaTela / conteudo;
    st.y = 1.0 - st.y;

    // O fragmento do AM, linha por linha.
    st -= 0.5;
    st.x *= eng.acTamanhoDaCamada.x/eng.acTamanhoDaCamada.y;

    st /= u.scale;

    float3 ro = float3(0., 1., -1.);
    float3 rd = normalize(float3(st, 1.));

    float d = march(ro,rd);
    float3 p = ro + rd * d;

    float3 n = calcNormal(p);
    float3 nn = n;

    float4 localCoord = float4(p-OBJECT_CENTER, 1.);
    n = (float4(n,1.) * orientAndRotate).xyz;
    localCoord *= orientAndRotate;
    float4 pp = localCoord;

    if( u.texStretch ) {
        pp.y /= u.height;
    }

    float aa = __nv_atan(pp.x, pp.z)/6.2831+0.5;
    if( !u.texStretch ) {
        aa *= u.radius * 3.14159;
    }
    float2 texCoordOutside = float2(aa,pp.y/2. + 0.5);
    texCoordOutside.x = 1.-__nv_mod(texCoordOutside.x + 0.5, 1.);
    float2 texCoordEnds = localCoord.xz / (u.radius/1.5);
    texCoordEnds = (texCoordEnds + 1.) / 2.;
    texCoordEnds.y = n.y < 0.0 ? 1. - texCoordEnds.y : texCoordEnds.y;
    float2 texCoord = mix(texCoordOutside,texCoordEnds,abs(n.y));

    texCoord = mapTexture(texCoord);

    // `inputImg.sample(__nv_smp, (float4(texCoord,0,1) * eng.acLayerToScreen).xy)`: de volta ao buffer da camada (o Y
    // volta para baixo) e, na tela, pela `eng.acCamadaParaTela` sem a divisão da perspectiva quando ela é afim.
    float2 b = 0.5 + (float2(texCoord.x, 1.0 - texCoord.y) - 0.5) * conteudo / eng.acTamanhoDaTela;
    float2 q = b;
    if (eng.acParaTela == float3x3(1.0)) {
        float3 c = eng.acCamadaParaTela * float3(b, 1.0);
        bool afim = eng.acCamadaParaTela[0].z == 0.0 && eng.acCamadaParaTela[1].z == 0.0 && eng.acCamadaParaTela[2].z == 1.0;
        q = afim ? c.xy : c.xy / c.z;
    }
    bool foraDaConta = any(isinf(q)) || any(isnan(q));
    float4 texColor = foraDaConta ? preMultiplicada(inputImg.sample(__nv_smp, q)) : camadaNoPonto(q);

    // A saída do AM é pré-multiplicada, num alvo de 8 bits (que corta abaixo de 0 e acima de 1); aqui ela volta reta.
    __nv_out = paraReta(clamp(applyShading(texColor, p, nn, d), 0.0, 1.0));
    return __nv_out;
}
