// Lift-Gamma-Gain (`lggn`, linear) — `ColorKernel_LiftGammaGain` na ordem do DXIL (`tools/looks/dxil/035`); o host
// (`0x1803f5b70` → `0x180419410`) é o ContasDoLooks.liftGammaGain. O kernel roda sempre (não há caso de "nada roda").
uniform vec4 uF;      // f0 = máx(Gamma Space, 0,1), f1 = 1/f0, f2 = Strength · 0,01, f3 = 2^Exposure Compensation
uniform vec3 uA;      // Lift − 1
uniform vec3 uInvG;   // 1 / máx(Gamma, 0,1)
uniform vec3 uGain;
uniform vec3 uM1;     // 1 − a
out vec4 fragColor;

const float EPS = 0.000001;

vec3 potencia(vec3 x, vec3 k) { return exp2(log2(max(x, EPS)) * k); }

void main() {
    vec4 px = texelFetch(uEntrada, pxMemoria(), 0);
    vec3 c = px.rgb;
    vec3 b = potencia(c, vec3(uF.y));
    vec3 d = (b * uInvG + uA) * uGain;
    vec3 e = potencia(d, uM1);
    vec3 g = potencia(e, vec3(uF.x));
    fragColor = vec4(meia(((g - c) * uF.z + c) * uF.w), px.a);
}
