// ---------------------------------------------------------------------------
// Money Filter
// origem : assets/effects/toji-skexnxxmoney.xml
// id     : com.alightcreative.effects.money
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxmoneyParams {
    float amplitud;
    float frecuencia;
    float xnxx;
    float nxnn;
    float bright;
    float alpha;
    int blendMode;
};

// --- funcoes auxiliares do efeito
static float4 newLayer( float4 a, float4 b) {
    return a * (1. - b.a) + b;
    }
    
    float2x2 rot2m(float a){
        
	float s = sin(a);
	float c = cos(a);
	
	return float2x2(c, -s, s, c);
    }
    
    float2 l2s( float2 v ) {
        return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
    }
    
   #define fragCoord __nv_fragCoord.xy
    
   /////////////////////////
   
   
   
   /////////////////////////

fragment float4 fx_toji_skexnxxmoney(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxmoneyParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            
        float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
        float4 texColorX = float4(0.0,0.0,0.0,1.0) * texColor.a;
        
        float2 image_size = __nv_getTexSize(inputImg_info.size);
        float2 iRes = float2(eng.acScreenSize.x, eng.acScreenSize.y);
        
        float maxF = max(eng.acScreenSize.x, eng.acScreenSize.y);
        float2 texelSize = 1.0 / float2(maxF, maxF);
        
        float2 syamjaidtz;
        syamjaidtz = in.acScreenNorm; 

        /////////////////////////
        
    	float4 __nv_out;
    	
            float2 xy = syamjaidtz;
            // float2 xy = fragCoord.xy / iResolution.yy;
            
            // float u.amplitud = 0.03;
            // float u.frecuencia = 10.0;
            float gris = 1.0;
            float divisor = u.xnxx / eng.acScreenSize.y;
            float grosorInicial = divisor * u.nxnn;
            
            const int kNumPatrones = 6;
            
            // x: seno del angulo, y: coseno del angulo, z: factor de suavizado
        	float3 datosPatron[kNumPatrones];
            datosPatron[0] = float3(-0.7071, 0.7071, 3.0); // -45
            datosPatron[1] = float3(0.0, 1.0, 0.6); // 0
            datosPatron[2] = float3(0.0, 1.0, 0.5); // 0
            datosPatron[3] = float3(1.0, 0.0, 0.4); // 90
            datosPatron[4] = float3(1.0, 0.0, 0.3); // 90
            datosPatron[5] = float3(0.0, 1.0, 0.2); // 0
        
            float4 color = inputImg.sample(__nv_smp, xy);
            // float4 color = inputImg.sample(__nv_smp, float2(fragCoord.x / eng.acScreenSize.x, xy.y));
            __nv_out = color;
            
            for(int i = 0; i < kNumPatrones; i++)
            {
                float coseno = datosPatron[i].x;
                float seno = datosPatron[i].y;
                
                // RotaciÃ³n del patrÃ³n
                float2 punto = float2(
                    xy.x * coseno - xy.y * seno,
                    xy.x * seno + xy.y * coseno
                );
        
                float grosor = grosorInicial * float(i + 1);
                float dist = __nv_mod(punto.y + grosor * 0.5 - sin(punto.x * u.frecuencia) * u.amplitud, divisor);
                float brillo = 0.3 * color.r + 0.4 * color.g + 0.3 * color.b;
        
                if(dist < grosor && brillo < 0.75 - 0.12 * float(i))
                {
                    // Suavizado
                    float k = datosPatron[i].z;
                    float x = (grosor - dist) / grosor;
                    float fx = abs((x - 0.5) / k) - (0.5 - k) / k; 
                    gris = min(fx, gris);
                }
            }
            
            
            __nv_out = float4(gris, gris, gris, 1.0);
        
    	float4 factor = mix(texColorX,__nv_out,1.0);

        float4 resultfinal;
        if( u.blendMode==0 ) {                // normal
            resultfinal = (factor * u.bright) * texColor.a;
            // resultfinal = (newLayer(texColor, factor) * u.bright) * texColor.a;
        } else if( u.blendMode==1 ) {         // multiply
            factor *= u.bright;
            float4 c = factor + float4(1.)*(1.-factor.a);
            resultfinal = float4((texColor.rgb/texColor.a)*c.rgb,1.0) * texColor.a;
        } else if( u.blendMode==2 ) {         // screen
            factor *= u.bright;
            resultfinal = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-factor.rgb)),1.0) * texColor.a;
        }
            
    	__nv_out = mix(texColor, resultfinal, u.alpha);
    	//
    return __nv_out;
}
