// ---------------------------------------------------------------------------
// jpeg quality
// origem : assets/effects/toji-jpegquality.xml
// id     : com.alightcreative.effects.dct_compress_demo
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_jpegqualityParams {
    float quality;
    int detail;
    float split;
    int showGrid;
    float alpha;
};

// --- funcoes auxiliares do efeito
// DCT Compress Demo (single pass)
    // - AM official style: fixed loops, only builtins

    const float PI = 3.141592653589793;

    float3 rgb2ybr(float3 rgb){
      // Y, Cb, Cr in [0,1]
      float3 ybr = float3(0.299,0.587,0.114) * rgb.r +
                 float3(0.0,0.0,0.0);
      float y = dot(rgb, float3(0.299,0.587,0.114));
      float cb = (rgb.b - y) * 0.564 + 0.5;
      float cr = (rgb.r - y) * 0.713 + 0.5;
      return float3(y, cb, cr);
    }
    float3 ybr2rgb(float3 ybr){
      float y=ybr.x, cb=ybr.y-0.5, cr=ybr.z-0.5;
      float r = y + 1.403*cr;
      float b = y + 1.773*cb;
      float g = (y - 0.299*r - 0.114*b) / max(0.587, 1e-6);
      return clamp(float3(r,g,b), 0.0, 1.0);
    }

    float aScale(float k){ return (k==0.0)? 1.0/sqrt(2.0) : 1.0; }

    // JPEG-like luminance quant matrix (subset via function)
    float qLuma(int u, int v){
      // Values from standard table
      int idx = v*8 + u;
      int qv[64];
      // Manually unrolled initialization for GLSL ES compatibility
      qv[0]=16; qv[1]=11; qv[2]=10; qv[3]=16; qv[4]=24; qv[5]=40; qv[6]=51; qv[7]=61;
      qv[8]=12; qv[9]=12; qv[10]=14; qv[11]=19; qv[12]=26; qv[13]=58; qv[14]=60; qv[15]=55;
      qv[16]=14; qv[17]=13; qv[18]=16; qv[19]=24; qv[20]=40; qv[21]=57; qv[22]=69; qv[23]=56;
      qv[24]=14; qv[25]=17; qv[26]=22; qv[27]=29; qv[28]=51; qv[29]=87; qv[30]=80; qv[31]=62;
      qv[32]=18; qv[33]=22; qv[34]=37; qv[35]=56; qv[36]=68; qv[37]=109; qv[38]=103; qv[39]=77;
      qv[40]=24; qv[41]=35; qv[42]=55; qv[43]=64; qv[44]=81; qv[45]=104; qv[46]=113; qv[47]=92;
      qv[48]=49; qv[49]=64; qv[50]=78; qv[51]=87; qv[52]=103; qv[53]=121; qv[54]=120; qv[55]=101;
      qv[56]=72; qv[57]=92; qv[58]=95; qv[59]=98; qv[60]=112; qv[61]=100; qv[62]=103; qv[63]=99;
      return float(qv[idx]);
    }

    // Kept coefficient mask for Low/Medium/High u.detail
    bool keepCoeff(int u, int v, int mode){
      if(mode==0){ // Low: (0,0),(1,0),(0,1)
        return (u==0 && v==0) || (u==1 && v==0) || (u==0 && v==1);
      } else if(mode==1){ // Medium: add (1,1),(2,0),(0,2)
        if((u==0 && v==0)||(u==1&&v==0)||(u==0&&v==1)||(u==1&&v==1)||(u==2&&v==0)||(u==0&&v==2)) return true;
        return false;
      } else { // High: include first 10 zigzag approx
        int sum = u+v;
        return (sum<=3) || (u==3&&v==0) || (u==0&&v==3);
      }
    }

fragment float4 fx_toji_jpegquality(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_jpegqualityParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 uv = in.acScreenNorm;
      float2 texel = float2(1.0) / max(eng.acScreenSize, float2(1.0));

      // Split view position in pixels
      float splitPx = u.split * eng.acScreenSize.x;
      float xPx = uv.x * eng.acScreenSize.x;
      float3 srcRGB = inputImg.sample(__nv_smp, uv).rgb;

      if(xPx < splitPx){
        // Original on left
        __nv_out = float4(srcRGB, 1.0) * u.alpha;
        return __nv_out;
      }

      // Determine 8x8 block origin in pixel space
      float2 pPx = floor(uv * eng.acScreenSize);
      float2 blockBase = floor(pPx / 8.0) * 8.0;
      float2 xy = pPx - blockBase; // 0..7 within block

      // Build YCbCr samples for the block (centered around 0 for DCT)
      float3 S[64];
      int k=0;
      for(int j=0;j<8;j++){
        for(int i=0;i<8;i++){
          float2 sp = (blockBase + float2(float(i), float(j)) + 0.5) * texel;
          float3 ybr = rgb2ybr(inputImg.sample(__nv_smp, sp).rgb);
          S[k] = (ybr - float3(0.0,0.5,0.5)) * 256.0; // match shadertoy scaling
          k++;
        }
      }

      int mode = u.detail; // 0,1,2
      float qScale = u.quality; // larger -> stronger quantization

      // Compute selected DCT coefficients per channel
      float3 recon = float3(0.0);
      for(int v=0; v<8; v++){
        for(int u=0; u<8; u++){
          if(!keepCoeff(u,v,mode)) continue;
          // Compute F(u,v)
          float3 F = float3(0.0);
          int idx=0;
          for(int yb=0; yb<8; yb++){
            for(int xb=0; xb<8; xb++){
              float cx = cos(( (2.0*float(xb)+1.0)*float(u)*PI )/16.0);
              float cy = cos(( (2.0*float(yb)+1.0)*float(v)*PI )/16.0);
              F += S[idx] * (cx*cy);
              idx++;
            }
          }
          F *= 0.25 * aScale(float(u)) * aScale(float(v));
          // Quantize using luma table scale (apply same to all channels for simplicity)
          float qv = qLuma(u,v) * qScale;
          F = floor(F / qv + 0.5) * qv;

          // Add this coefficient's contribution to current pixel via IDCT
          float cxp = cos(( (2.0*xy.x+1.0)*float(u)*PI )/16.0);
          float cyp = cos(( (2.0*xy.y+1.0)*float(v)*PI )/16.0);
          recon += F * (cxp*cyp) * 0.25 * aScale(float(u)) * aScale(float(v));
        }
      }

      // Back to rgb
      float3 ybrRec = recon / 256.0 + float3(0.0,0.5,0.5);
      float3 rgbRec = ybr2rgb(ybrRec);

      // Optional block grid overlay
      if(u.showGrid){
        float2 g = fract(pPx/8.0);
        float edge = step(g.x,0.02)+step(0.98,g.x)+step(g.y,0.02)+step(0.98,g.y);
        rgbRec = mix(rgbRec, float3(0.0), clamp(edge,0.0,1.0));
      }

      __nv_out = float4(rgbRec, 1.0) * u.alpha;
    return __nv_out;
}
