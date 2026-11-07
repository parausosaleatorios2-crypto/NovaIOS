// ---------------------------------------------------------------------------
// Caixa
// origem : assets/effects/am-box.xml
// id     : nova.effect.am-box
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_boxParams {
    float4 orient;
    float3 rotate;
    float width;
    float height;
    float depth;
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
static float4 preMultiplicada(float4 c) { return float4(c.rgb * c.a, c.a); }

// O filtro linear da GPU, à mão, sobre a camada PRÉ-multiplicada (a textura do AM é assim): os 4 pixels em volta,
// presos à borda como o CLAMP_TO_EDGE.
static float4 camadaNoPonto(float2 uv) {
    int2 T = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    float2 q = uv * float2(T) - 0.5;
    float2 i = floor(q);
    float2 f = q - i;
    int2 a = int2(i);
    int2 m = T - 1;
    float4 c00 = preMultiplicada(inputImg.read(uint2(clamp(a, int2(0), m)), uint(0)));
    float4 c10 = preMultiplicada(inputImg.read(uint2(clamp(a + int2(1, 0), int2(0), m)), uint(0)));
    float4 c01 = preMultiplicada(inputImg.read(uint2(clamp(a + int2(0, 1), int2(0), m)), uint(0)));
    float4 c11 = preMultiplicada(inputImg.read(uint2(clamp(a + int2(1, 1), int2(0), m)), uint(0)));
    return mix(mix(c00, c10, f.x), mix(c01, c11, f.x), f.y);
}

// O fundo (a cena montada atrás da camada) no pixel da tela, pré-multiplicado.
static float3 fundoNoPixel() {
    int2 T = int2(int(comp.get_width()), int(comp.get_height()));
    int2 px = clamp(int2(floor(__nv_acTela(in.acScreenNorm) * float2(T))), int2(0), T - 1);
    float4 f = comp.read(uint2(px), uint(0));
    return f.rgb * f.a;
}

// A saída pré-multiplicada do AM em cor reta (a mesma conta do `am-ring.xml`, de onde veio). O comum (cor ≤ alfa) é
// só dividir. Mas o brilho especular do AM cai também onde a camada é transparente: sai cor ACIMA do alfa (até cor
// > 0 com alfa 0), luz que a composição dele SOMA ao que está atrás (`op·p + fundo·(1 − op·alfa)`), e a cor reta
// não guarda isso. Aí este pixel leva junto o fundo dele: com o menor alfa `a` em que a cor reta
// `s = fundo + (p − fundo·alfa)/a` cabe entre 0 e 1, a composição Normal do Nova, `s·a·op + fundo·(1 − a·op)`, dá o
// mesmo `op·p + fundo·(1 − op·alfa)` do AM com QUALQUER opacidade da camada. Não cabe só quando a soma passa de 1
// (`fundo + p − fundo·alfa`): com a opacidade cheia ela vira 1 lá e aqui; com menos, aqui sai um pouco mais escuro.
static float4 paraReta(float4 p) {
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
static float2 naCamada(float2 t) {
    float3 c = __nv_inverse(eng.acCamadaParaTela) * float3(t, 1.0);
    return c.xy / c.z;
}

// ------------------------------------------------------------------ a conta do AM, linha por linha

#define OBJECT_CENTER (u.position/100.)

// O `varying float4x4 invOrient` do AM (calculado no vértice): aqui, no começo do main.
float4x4 invOrient;

static float4x4 rotationAxisAngle( float3 v, float angle )
{
    float s = sin( angle );
    float c = cos( angle );
    float ic = 1.0 - c;

    return float4x4( v.x*v.x*ic + c,     v.y*v.x*ic - s*v.z, v.z*v.x*ic + s*v.y, 0.0,
                 v.x*v.y*ic + s*v.z, v.y*v.y*ic + c,     v.z*v.y*ic - s*v.x, 0.0,
                 v.x*v.z*ic - s*v.y, v.y*v.z*ic + s*v.x, v.z*v.z*ic + c,     0.0,
                 0.0,                0.0,                0.0,                1.0 );
}

// O `main` do shader de vértice do AM.
static float4x4 orientacaoDoVertice() {
    float3 r = u.rotate * 0.0174533;
    float4x4 rx = rotationAxisAngle(float3(1.,0.,0.),r.x);
    float4x4 ry = rotationAxisAngle(float3(0.,1.,0.),r.y);
    float4x4 rz = rotationAxisAngle(float3(0.,0.,1.),r.z);
    return u.orient * rz * rx * ry;
}

static float sdBox( float3 p, float3 b )
{
  float3 d = abs(p) - b;
  return length(max(d,0.0))
         + min(max(d.x,max(d.y,d.z)),0.0);
}

static float dist(float3 p) {
    float d = 100000000.0;

    p = p-OBJECT_CENTER;
    p = (float4(p,1.) * invOrient).xyz;

    d = min(d,sdBox(p,float3(u.width-u.smoothing,u.height-u.smoothing,u.depth-u.smoothing))-u.smoothing);
    return d;
}

static float march(float3 ro, float3 rd) {
    float d = 0.0;
    for( int i=0; i<int(u.MAX_ITER); i++ ) {
        float3 p = ro + rd*d;
        float dd = dist(p);
        d += dd;
        if( dd < 0.00001 || d > 1000.0 ) break;
    }
    return d;
}

static float4x4 vecToVec( float3 from, float3 to ) {
    float3 w = cross(normalize(from),normalize(to));
    float3 axis = normalize(w);
    float angle = asin(length(w));
    return rotationAxisAngle(axis,angle);
}

static float3 calcNormal(float3 p) {
    float d = dist(p);
    float2 e = float2(.01,0.);
    return normalize(d - float3(
        dist(p-e.xyy),
        dist(p-e.yxy),
        dist(p-e.yyx)));
}

static float lighting(float3 p, float3 n) {
    float3 lightPos = float3(u.lightDir.x/2.0, -u.lightDir.y/2.0, -u.lightDepth*2.0);
    float3 l = normalize(lightPos-p);
    return dot(n,l);
}

static float directionalLighting(float3 p, float3 n) {
    float3 lightPos = float3(u.lightDir.x/2.0, -u.lightDir.y/2.0, -u.lightDepth*2.0);
    float3 l = normalize(lightPos);
    return dot(n,l);
}

static float4 applyShading(float4 texColor, float3 p, float3 n, float d ) {
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
        float ds = max(max(u.width,u.height),u.depth)*2.5;
        float dd = 1. - ((d - OBJECT_CENTER.z + ds/2.)/ds);
        result = float4( dd,dd,dd, 1. ) * a;
    } else if( u.shadingType == 4 ) {         // Normal Map
        result = float4( (n/2.)+0.5, 1. ) * a;
    } else if( u.shadingType == 5 ) {         // Normal * Depth
        float ds = max(max(u.width,u.height),u.depth)*2.5;
        float dd = 1. - ((d - OBJECT_CENTER.z + ds/2.)/ds);
        result = float4( ((n/2.)+0.5)*dd, 1. ) * a;
    }

    return result;
}

static float2 mapTexture( float2 texCoord ) {
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
    if( u.mirror ) {
        texCoord = abs(__nv_mod(texCoord, 2.0)-1.0);
    } else {
        texCoord = __nv_mod(texCoord, 1.);
    }

    texCoord -= 0.5;
    // O `eng.acScreenSize` do AM (a tela em px da cena) é o `eng.acTamanhoDaTela`.
    texCoord = texCoord * (1.-5./eng.acTamanhoDaTela);
    texCoord *= u.texCrop;
    texCoord *= texTwirlRot;
    texCoord += 0.5;
    return texCoord;
}

fragment float4 fx_am_box(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_boxParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> comp [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& comp_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    invOrient = orientacaoDoVertice();

    // O `in.acLayerNorm` do AM: o pixel na tela levado à coordenada da camada (o retângulo do conteúdo de 0 a 1,
    // com o meio no meio do buffer), com o Y para CIMA como o do AM (a ponte do Túnel (AM)).
    float2 conteudo = max(eng.acTamanhoDaCamada, float2(1e-6));
    float2 eng.acLayerNormAm = 0.5 + (naCamada(__nv_acTela(in.acScreenNorm)) - 0.5) * eng.acTamanhoDaTela / conteudo;
    eng.acLayerNormAm.y = 1.0 - eng.acLayerNormAm.y;

    float2 st = eng.acLayerNormAm;
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
    n = (float4(n,0.) * invOrient).xyz;
    localCoord *= invOrient;
    float4 pp = localCoord;

    if( u.texStretch ) {
        pp /= float4(u.width,u.height,u.depth,1.);
    }

    float2 texCoord;
    float a;
    if( n.x > 0.5 ) {
        texCoord = ((pp.zy+1.)/2.);
        a = u.height<0.0105 || u.depth<0.0105 ? 0.0 : 1.0;
    } else if ( n.x < -0.5 ) {
        texCoord = ((pp.zy+1.)/2.);
        texCoord.x = 1.-texCoord.x;
        a = u.height<0.0105 || u.depth<0.0105 ? 0.0 : 1.0;
    } else if ( n.y > 0.5 ) {
        texCoord = ((pp.xz+1.)/2.);
        a = u.width<0.0105 || u.depth<0.0105 ? 0.0 : 1.0;
    } else if ( n.y < -0.5 ) {
        texCoord = 1.-((pp.xz+1.)/2.);
        texCoord.x = 1.-texCoord.x;
        a = u.width<0.0105 || u.depth<0.0105 ? 0.0 : 1.0;
    } else if ( n.z > 0.5 ) {
        texCoord = (pp.xy+1.)/2.;
        texCoord.x = 1.-texCoord.x;
        a = u.width<0.0105 || u.height<0.0105 ? 0.0 : 1.0;
    } else if ( n.z < -0.5 ) {
        texCoord = (pp.xy+1.)/2.;
        a = u.width<0.0105 || u.height<0.0105 ? 0.0 : 1.0;
    } else {
        texCoord = float2(0.,0.);
        a = 1.0;
    }

    texCoord = mapTexture(texCoord);

    // O `inputImg.sample(__nv_smp, (float4(texCoord,0,1) * eng.acLayerToScreen).xy)` do AM: a coordenada da camada
    // levada ao buffer (o Y volta para baixo) e, na tela, pela `eng.acCamadaParaTela` (sem a divisão da perspectiva
    // quando ela é afim, como a matriz do AM); no filho de grupo, a própria UV do buffer.
    float2 b = 0.5 + (float2(texCoord.x, 1.0 - texCoord.y) - 0.5) * conteudo / eng.acTamanhoDaTela;
    float2 naTela = b;
    if (eng.acParaTela == float3x3(1.0)) {
        float3 c = eng.acCamadaParaTela * float3(b, 1.0);
        bool afim = eng.acCamadaParaTela[0].z == 0.0 && eng.acCamadaParaTela[1].z == 0.0 && eng.acCamadaParaTela[2].z == 1.0;
        naTela = afim ? c.xy : c.xy / c.z;
    }
    bool foraDaConta = any(isinf(naTela)) || any(isnan(naTela));
    float4 texColor = foraDaConta ? preMultiplicada(inputImg.sample(__nv_smp, naTela)) : camadaNoPonto(naTela);

    // A saída do AM é pré-multiplicada, num alvo de 8 bits (que corta abaixo de 0 e acima de 1); aqui ela volta reta,
    // com a luz acima do alfa levada pelo fundo (`paraReta`).
    __nv_out = paraReta(clamp(applyShading(texColor, p, nn, d) * a, 0.0, 1.0));
    return __nv_out;
}
