// ---------------------------------------------------------------------------
// toji-skexnxxshsl.xml
// origem : assets/effects/toji-skexnxxshsl.xml
// id     : 636f6d2e616c6967687463726561746976652e656666656374732e68736c
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxshslParams {
    float rex;
    float rey;
    float rez;
    float orx;
    float ory;
    float orz;
    float yex;
    float yey;
    float yez;
    float grx;
    float gry;
    float grz;
    float cyx;
    float cyy;
    float cyz;
    float blx;
    float bly;
    float blz;
    float pux;
    float puy;
    float puz;
    float maxx;
    float may;
    float maz;
    float bright;
    float alpha;
    int blendMode;
};

// --- funcoes auxiliares do efeito
//////////////////////////
    float2x2 rot2m(float a){
        
	float s = sin(a);
	float c = cos(a);
	
	return float2x2(c, -s, s, c);
    }
    
    float2 l2s( float2 v ) {
        return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
    }
    
   #define fragCoord __nv_fragCoord
   const float hue = 1.0;
   const float saturation = 1.0;
   const float brightness = 1.0;
    
   /////////////////////////
   
   float3 RGB2HSL(float3 rgb) {
        float h = 0.0, s = 0.0, l = 0.0;
        float r = rgb.r;
        float g = rgb.g;
        float b = rgb.b;
        float cmax = max(r, max(g, b));
        float cmin = min(r, min(g, b));
        float delta = cmax - cmin;
        l = (cmax + cmin) / 2.0;
        if (delta == 0.0) {
            s = 0.0;
            h = 0.0;
        } else {
            if (l <= 0.5)
                s = delta / (cmax + cmin);
            else
                s = delta / (2.0 - (cmax + cmin));
            if (cmax == r) {
                if (g >= b)
                    h = 60.0 * (g - b) / delta;
                else
                    h = 60.0 * (g - b) / delta + 360.0;
            } else if (cmax == g) {
                h = 60.0 * (b - r) / delta + 120.0;
            } else {
                h = 60.0 * (r - g) / delta + 240.0;
            }
        }
        return float3(h, s, l);
    }
    
    float hueToRgb(float p, float q, float t) {
        if (t < 0.0)
            t += 1.0;
        if (t > 1.0)
            t -= 1.0;
        if (t < 1.0 / 6.0)
            return p + (q - p) * 6.0 * t;
        if (t < 1.0 / 2.0)
            return q;
        if (t < 2.0 / 3.0)
            return p + (q - p) * (2.0 / 3.0 - t) * 6.0;
        return p;
    }
    
    float3 HSL2RGB(float3 hsl) {
        float r, g, b;
        float h = hsl.x / 360.0;
        if (hsl.y == 0.0) {
            r = g = b = hsl.z;   // gray
        } else {
            float q = hsl.z < 0.5 ? hsl.z * (1.0 + hsl.y) : (hsl.z + hsl.y - hsl.z * hsl.y);
            float p = 2.0 * hsl.z - q;
            r = hueToRgb(p, q, h + 1.0 / 3.0);
            g = hueToRgb(p, q, h);
            b = hueToRgb(p, q, h - 1.0 / 3.0);
        }
        return float3(r, g, b);
    }
    
    float3 pixel_adjust(float h, float hue, float saturation, float brightness, float left_left, float left, float right, float right_right, float3 delta_hsb) {
        if (left_left < left && left > right && right < right_right) {
            if (h >= left && h <= 360.0) {
                delta_hsb.x += hue;
                delta_hsb.y += saturation;
                delta_hsb.z += brightness;
                return delta_hsb;
            }
            if (h >= 0.0 && h <= right) {
                delta_hsb.x += hue;
                delta_hsb.y += saturation;
                delta_hsb.z += brightness;
                return delta_hsb;
            }
            if (h >= left_left && h <= left) {
                delta_hsb.x += hue * (h - left_left) / (left - left_left);
                delta_hsb.y += saturation * (h - left_left) / (left - left_left);
                delta_hsb.z += brightness * (h - left_left) / (left - left_left);
                return delta_hsb;
            }
            if (h >= right && h <= right_right) {
                delta_hsb.x += hue * (right_right - h) / (right_right - right);
                delta_hsb.y += saturation * (right_right - h) / (right_right - right);
                delta_hsb.z += brightness * (right_right - h) / (right_right - right);
                return delta_hsb;
            }
        }
        if (left_left > left && left < right && right < right_right) {
            if (h >= left && h <= right) {
                delta_hsb.x += hue;
                delta_hsb.y += saturation;
                delta_hsb.z += brightness;
                return delta_hsb;
            }
            if (h >= 0.0 && h <= left) {
                delta_hsb.x += hue * (h + 360.0 - left_left) / (left + 360.0 - left_left);
                delta_hsb.y += saturation * (h + 360.0 - left_left) / (left + 360.0 - left_left);
                delta_hsb.z += brightness * (h + 360.0 - left_left) / (left + 360.0 - left_left);
                return delta_hsb;
            }
            if (h >= left_left && h <= 360.0) {
                delta_hsb.x += hue * (h - left_left) / (left + 360.0 - left_left);
                delta_hsb.y += saturation * (h - left_left) / (left + 360.0 - left_left);
                delta_hsb.z += brightness * (h - left_left) / (left + 360.0 - left_left);
                return delta_hsb;
            }
            if (h >= right && h <= right_right) {
                delta_hsb.x += hue * (right_right - h) / (right_right - right);
                delta_hsb.y += saturation * (right_right - h) / (right_right - right);
                delta_hsb.z += brightness * (right_right - h) / (right_right - right);
                return delta_hsb;
            }
        }
        if (left_left <= left && left < right && right <= right_right) {
    
            if (h >= left && h <= right) {
                delta_hsb.x += hue;
                delta_hsb.y += saturation;
                delta_hsb.z += brightness;
                return delta_hsb;
            }
            if (h >= left_left && h <= left) {
                delta_hsb.x += hue * (h - left_left) / (left - left_left);
                delta_hsb.y += saturation * (h - left_left) / (left - left_left);
                delta_hsb.z += brightness * (h - left_left) / (left - left_left);
                return delta_hsb;
            }
            if (h >= right && h <= right_right) {
                delta_hsb.x += hue * (right_right - h) / (right_right - right);
                delta_hsb.y += saturation * (right_right - h) / (right_right - right);
                delta_hsb.z += brightness * (right_right - h) / (right_right - right);
                return delta_hsb;
            }
        }
        if (left_left < left && left < right && right > right_right) {
            if (h >= left && h <= right) {
                delta_hsb.x += hue;
                delta_hsb.y += saturation;
                delta_hsb.z += brightness;
                return delta_hsb;
            }
            if (h >= left_left && h <= left) {
                delta_hsb.x += hue * (h - left_left) / (left - left_left);
                delta_hsb.y += saturation * (h - left_left) / (left - left_left);
                delta_hsb.z += brightness * (h - left_left) / (left - left_left);
                return delta_hsb;
            }
            if (h >= right && h <= 360.0) {
                delta_hsb.x += hue * (right_right + 360.0 - h) / (right_right + 360.0 - right);
                delta_hsb.y += saturation * (right_right + 360.0 - h) / (right_right + 360.0 - right);
                delta_hsb.z += brightness * (right_right + 360.0 - h) / (right_right + 360.0 - right);
                return delta_hsb;
            }
            if (h >= 0.0 && h <= right_right) {
                delta_hsb.x += hue * (right_right - h) / (right_right + 360.0 - right);
                delta_hsb.y += saturation * (right_right - h) / (right_right + 360.0 - right);
                delta_hsb.z += brightness * (right_right - h) / (right_right + 360.0 - right);
                return delta_hsb;
            }
        }
        return delta_hsb;
    }
    //////////////////////////

fragment float4 fx_toji_skexnxxshsl(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxshslParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> xcipher [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& xcipher_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

        if( eng.acPass == 0 ) { __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm.st); } else if( eng.acPass==1 ) {
        float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
        float4 texColorX = float4(0.0,0.0,0.0,1.0) * texColor.a;
        
        float2 syamjaidtz;
        syamjaidtz = in.acScreenNorm; 
        /////////////////////////

    	float4 __nv_out;
    	
    	float3 clO;
        float3 clA;
        float3 RedHSL;
        float3 OrangeHSL;
        float3 YellowHSL;
        float3 GreenHSL;
        float3 CyanHSL;
        float3 BlueHSL;
        float3 PurpleHSL;
        float3 MagentaHSL;
    
        RedHSL = float3(u.rex * 0.25, u.rey, u.rez / 2.7);
        OrangeHSL = float3(u.orx * 0.15, u.ory, u.orz / 2.7);
        YellowHSL = float3(u.yex * 0.3, u.yey, u.yez / 2.7);
        GreenHSL = float3(u.grx * 0.3, u.gry * 1.1, u.grz / 2.7);
        CyanHSL = float3(u.cyx * 0.4, u.cyy, u.cyz / 2.2);
        BlueHSL = float3(u.blx * 0.4, u.bly * 1.2, u.blz / 2.0);
        PurpleHSL = float3(u.pux * 0.4, u.puy, u.puz / 2.7);
        MagentaHSL = float3(u.maxx * 0.4, u.may, u.maz / 2.7);
    
        float4 baseColor;
        baseColor = inputImg.sample(__nv_smp, syamjaidtz);
        clO = baseColor.rgb;
    
        float3 hsb;
        hsb = RGB2HSL(clO);
        // adjust each channel
        float3 delta_hsb = float3(0.0);
        delta_hsb = pixel_adjust(hsb.x, RedHSL.x, RedHSL.y, RedHSL.z, 315.0, 330.0, 5.0, 20.0, delta_hsb);
        delta_hsb = pixel_adjust(hsb.x, OrangeHSL.x, OrangeHSL.y, OrangeHSL.z, 350.0, 20.0, 40.0, 60.0, delta_hsb);
        delta_hsb = pixel_adjust(hsb.x, YellowHSL.x, YellowHSL.y, YellowHSL.z, 25.0, 50.0, 70.0, 90.0, delta_hsb);
        delta_hsb = pixel_adjust(hsb.x, GreenHSL.x, GreenHSL.y, GreenHSL.z, 50.0, 70.0, 160.0, 190.0, delta_hsb);
        delta_hsb = pixel_adjust(hsb.x, CyanHSL.x, CyanHSL.y, CyanHSL.z, 135.0, 165., 195.0, 225.0, delta_hsb);
        delta_hsb = pixel_adjust(hsb.x, BlueHSL.x, 0.0, 0.0, 145.0, 180., 235.0, 275.0, delta_hsb);
        delta_hsb = pixel_adjust(hsb.x, 0.0, BlueHSL.y, BlueHSL.z, 145.0, 180., 235.0, 270.0, delta_hsb);
        delta_hsb = pixel_adjust(hsb.x, PurpleHSL.x, PurpleHSL.y, PurpleHSL.z, 235.0, 255.0, 315.0, 335.0, delta_hsb);
        delta_hsb = pixel_adjust(hsb.x, MagentaHSL.x, MagentaHSL.y, MagentaHSL.z, 255.0, 285.0, 335.0, 5.0, delta_hsb);
    
        // adjust hue
        hsb.x = hsb.x + delta_hsb.x;
        for (float j = 0.1; j >= 0.0; j += 1.0) {
            if (hsb.x > 360.0) {
                hsb.x -= 360.0;
            }
            if (hsb.x < 0.0) {
                hsb.x += 360.0;
            }
            if (hsb.x <= 360.0 && hsb.x >= 0.0)
                break;
        }
    
        // adjust saturation
        delta_hsb.y = clamp(delta_hsb.y / 100.0, -1.0, 1.0);
        if (delta_hsb.y < 0.0) {
            hsb.y = hsb.y * (1.0 + delta_hsb.y);
        } else {
            delta_hsb.y = delta_hsb.y / 2.0;   // TODO：移到业务层
            float temp = hsb.y * (1.0 - delta_hsb.y);
            hsb.y = hsb.y + (hsb.y - temp);
        }
    
        // adjust brightness
        delta_hsb.z = clamp(delta_hsb.z / 100.0, -1.0, 1.0);
        if (delta_hsb.z <= 0.0) {
            float radio = hsb.y;
            if (hsb.z >= 0.5) {
                radio = hsb.y * 1.0;
            }
            if (hsb.z < 0.5) {
                radio = hsb.y * 2.0 * hsb.z;
            }
            float temp = hsb.z - radio * (1.0 - hsb.z) * delta_hsb.z;
            hsb.z = hsb.z + (hsb.z - temp);
        } else {
            float radio = hsb.y;
            if (hsb.z >= 0.5) {
                radio = hsb.y * 1.0;
            }
            if (hsb.z < 0.5) {
                radio = hsb.y * 2.0 * hsb.z;
            }
            delta_hsb.z = (1.0 - delta_hsb.y) * delta_hsb.z;
            hsb.z = hsb.z + radio * (1.15 - hsb.z) * delta_hsb.z;
        }
        hsb.y = clamp(hsb.y, 0.0, 1.0);
        hsb.z = clamp(hsb.z, 0.0, 1.0);
    
        clO = HSL2RGB(hsb);
        __nv_out = float4(clO, baseColor.a);
                
    	float4 factor = mix(texColorX,__nv_out,1.0);
    	
        float4 resultfinal;
        if( u.blendMode==0 ) {                // normal
            resultfinal = (factor * u.bright) * texColor.a;
        } else if( u.blendMode==1 ) {         // multiply
            factor *= u.bright;
            float4 c = factor + float4(1.)*(1.-factor.a);
            resultfinal = float4((texColor.rgb/texColor.a)*c.rgb,1.0) * texColor.a;
        } else if( u.blendMode==2 ) {         // screen
            factor *= u.bright;
            resultfinal = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-factor.rgb)),1.0) * texColor.a;
        }
            
    	__nv_out = mix(texColor,resultfinal,u.alpha);
          }
    return __nv_out;
}
