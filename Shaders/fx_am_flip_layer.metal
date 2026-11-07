// ---------------------------------------------------------------------------
// Virar Camada
// origem : assets/effects/am-flip-layer.xml
// id     : nova.effect.am-flip-layer
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_flip_layerParams {
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

// A saída pré-multiplicada do AM em cor reta (a conta do `am-ring.xml`, a mesma da Caixa). O comum (cor ≤ alfa) é
// só dividir. Onde o especular deixa a cor ACIMA do alfa (luz que a composição do AM soma ao fundo), este pixel leva
// junto o fundo dele: com o menor alfa `a` em que a cor reta `s = fundo + (p − fundo·alfa)/a` cabe entre 0 e 1, a
// composição Normal do Nova, `s·a·op + fundo·(1 − a·op)`, dá o mesmo `op·p + fundo·(1 − op·alfa)` do AM com
// qualquer opacidade. Não cabe só quando a soma passa de 1 com a opacidade abaixo da cheia.
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

// O `inputImg.sample(__nv_smp, (float4(uv, 0, 1) * eng.acLayerToScreen).xy)` do AM: a coordenada da camada (Y para
// cima) levada ao buffer (o Y volta para baixo) e, na tela, pela `eng.acCamadaParaTela` (sem a divisão da perspectiva
// quando ela é afim, como a matriz do AM); no filho de grupo, a própria UV do buffer.
static float4 camadaDoAm(float2 uv) {
    float2 conteudo = max(eng.acTamanhoDaCamada, float2(1e-6));
    float2 b = 0.5 + (float2(uv.x, 1.0 - uv.y) - 0.5) * conteudo / eng.acTamanhoDaTela;
    float2 naTela = b;
    if (eng.acParaTela == float3x3(1.0)) {
        float3 c = eng.acCamadaParaTela * float3(b, 1.0);
        bool afim = eng.acCamadaParaTela[0].z == 0.0 && eng.acCamadaParaTela[1].z == 0.0 && eng.acCamadaParaTela[2].z == 1.0;
        naTela = afim ? c.xy : c.xy / c.z;
    }
    bool foraDaConta = any(isinf(naTela)) || any(isnan(naTela));
    return foraDaConta ? preMultiplicada(inputImg.sample(__nv_smp, naTela)) : camadaNoPonto(naTela);
}

// ------------------------------------------------------------------ a conta do AM, na ordem dele

// O raio contra a caixa no espaço dela (o `iBox` de Inigo Quilez que o AM usa): devolve a distância e o normal.
static float4 raioNaCaixa(float3 ro, float3 rd, float4x4 txx, float4x4 txi, float3 rad) {
    float3 rdd = (txx*float4(rd,0.0)).xyz;
    float3 roo = (txx*float4(ro,1.0)).xyz;

    float3 m = 1.0/rdd;
    float3 n = m*roo;
    float3 k = abs(m)*rad;

    float3 t1 = -n - k;
    float3 t2 = -n + k;

    float tN = max( max( t1.x, t1.y ), t1.z );
    float tF = min( min( t2.x, t2.y ), t2.z );

    if( tN > tF || tF < 0.0) return float4(-1.0);

    float3 nor = -sign(rdd)*step(t1.yzx,t1.xyz)*step(t1.zxy,t1.xyz);
    nor = (txi * float4(nor,0.0)).xyz;
    return float4( tN, nor );
}

static float4x4 rotationAxisAngle( float3 v, float u.angle )
{
    float s = sin( u.angle );
    float c = cos( u.angle );
    float ic = 1.0 - c;

    return float4x4( v.x*v.x*ic + c,     v.y*v.x*ic - s*v.z, v.z*v.x*ic + s*v.y, 0.0,
                 v.x*v.y*ic + s*v.z, v.y*v.y*ic + c,     v.z*v.y*ic - s*v.x, 0.0,
                 v.x*v.z*ic - s*v.y, v.y*v.z*ic + s*v.x, v.z*v.z*ic + c,     0.0,
                 0.0,                0.0,                0.0,                1.0 );
}

static float4x4 transladar( float3 v )
{
    return float4x4( 1.0, 0.0, 0.0, 0.0,
                 0.0, 1.0, 0.0, 0.0,
                 0.0, 0.0, 1.0, 0.0,
                 v.x, v.y, v.z, 1.0 );
}

// A `inverse` do AM: a de um giro + translação (o giro transposto, a translação por −dot).
static float4x4 inversaRigida( float4x4 m )
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

fragment float4 fx_am_flip_layer(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_flip_layerParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> comp [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& comp_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    // O `in.acLayerNorm` do AM: o pixel na tela levado à coordenada da camada (o retângulo do conteúdo de 0 a 1,
    // com o meio no meio do buffer), com o Y para CIMA como o do AM (a ponte do Túnel (AM)).
    float2 conteudo = max(eng.acTamanhoDaCamada, float2(1e-6));
    float2 eng.acLayerNormAm = 0.5 + (naCamada(__nv_acTela(in.acScreenNorm)) - 0.5) * eng.acTamanhoDaTela / conteudo;
    eng.acLayerNormAm.y = 1.0 - eng.acLayerNormAm.y;

    float2 st = eng.acLayerNormAm;
    st -= 0.5;

    float width;
    float height;
    if( eng.acTamanhoDaCamada.x > eng.acTamanhoDaCamada.y ) {
        width = eng.acTamanhoDaCamada.x/eng.acTamanhoDaCamada.y;
        height = 1.0;
        st.x *= eng.acTamanhoDaCamada.x/eng.acTamanhoDaCamada.y;
    } else {
        height = eng.acTamanhoDaCamada.y/eng.acTamanhoDaCamada.x;
        width = 1.0;
        st.y *= eng.acTamanhoDaCamada.y/eng.acTamanhoDaCamada.x;
    }

    float depth = u.solid? max(0.00001,u.thickness/10.0) : 0.00001;

    float2 p = st;

    // A câmera em (0, 0, 2) olhando para a origem.
    float3 ro = float3( 0.0, 0.0, 2.0 );
    float3 ta = float3( 0.0, 0.0, 0.0 );
    float3 ww = normalize( ta - ro );
    float3 uu = normalize( cross(ww,float3(0.0,1.0,0.0) ) );
    float3 vv = normalize( cross(uu,ww));
    float3 rd = normalize( p.x*uu + p.y*vv + 2.0*ww );

    // O giro em volta do eixo no plano, pelo Ponto de origem, e a Distância.
    float axisRad = u.axis * 3.14159 / 180.0;
    float2x2 rotAxis = float2x2(
        cos(axisRad), -sin(axisRad),
        sin(axisRad), cos(axisRad)
    );
    float3 adjPivot = float3( u.pivot.x/200.0*width, -u.pivot.y/200.0*height, 0.0 );
    float2 axisVec = float2(0.0,1.0) * rotAxis;
    float4x4 orient = rotationAxisAngle(float3(axisVec,0.0),u.angle * 3.14159 / 180.0);
    float4x4 tra = transladar( float3(0.0, 0.0, -u.zdist) );
    float4x4 txi = tra * transladar( adjPivot ) * orient * transladar( -adjPivot );
    float4x4 txx = inversaRigida( txi );

    float tmin = 10000.0;
    float3 nor = float3(0.0);
    float3 pos = float3(0.0);

    float3 box = float3(width/2.,height/2.,depth/2.);
    float4 res = raioNaCaixa( ro, rd, txx, txi, box );
    if( res.x>0.0 && res.x<tmin ) {
        tmin = res.x;
        nor = res.yzw;
    }

    float4 saida = float4(0.0);
    if( tmin<100.0 ) {
        float3 lightPos = normalize((txx*float4(u.lightDir.x/2.0, -u.lightDir.y/2.0, -u.lightDepth*2.0, 0.0)).xyz);
        pos = ro + tmin*rd;

        // No espaço da caixa: a face da frente e a de trás levam a camada.
        float3 opos = (txx*float4(pos,1.0)).xyz;
        float3 onor = (txx*float4(nor,0.0)).xyz;
        float4 texColor = abs(onor.z)*camadaDoAm( __nv_mod(u.crop*0.5*opos.xy/box.xy+0.5, 1.0) );

        float4 result = texColor;
        if( u.solid ) {
            result = u.solidColor*(1.-result.a) + result;
        }

        if( u.enableLight ) {
            float l = clamp( dot(onor,normalize(lightPos)), 0.0, 1.0 );
            float3 tc = result.rgb;
            float3 surface = tc * u.ambient + tc * u.lightColor.rgb * l * (1.-u.ambient);
            surface *= u.lightIntensity;
            float s = pow(l,u.spec);
            surface = mix(surface*(1.-u.shine*0.1),float3(1.),u.shine*s);
            result.rgb = surface;
        }
        saida = result;
    }

    // A saída do AM é pré-multiplicada, num alvo de 8 bits (que corta abaixo de 0 e acima de 1); aqui ela volta reta,
    // com a luz acima do alfa levada pelo fundo (`paraReta`).
    __nv_out = paraReta(clamp(saida, 0.0, 1.0));
    return __nv_out;
}
