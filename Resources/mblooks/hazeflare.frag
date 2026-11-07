// Haze/Flare (`haze`, linear), último passe — `FXKernel_HazeFlare`: f = (alfa do Matte Box·1,1 − 1)·Shade + 1;
// saída = o + 1,1·2^Exposure·tint·haze·f, mais o reflexo 2^Reflection Exposure·tint·f·haze espelhado na
// horizontal (W − 1 − x) se Reflection liga. O alfa é o do original. Host: ContasDoLooks.haze.
uniform highp sampler2D uHaze;
uniform float uShade;
uniform float uExpo;
uniform bool uRefl;
uniform float uReflExpo;
uniform vec3 uTint;
out vec4 fragColor;

void main() {
    vec4 px = texelFetch(uEntrada, pxMemoria(), 0);
    vec4 h = texelFetch(uHaze, pxMemoria(), 0);
    float f = (h.a * 1.1 + -1.0) * uShade + 1.0;
    vec3 o = ((uExpo * 1.1) * uTint * h.rgb) * f + px.rgb;
    if (uRefl) {
        ivec2 q = pxAe();
        vec3 e = lerAe(uHaze, ivec2(uTamanho.x - 1 - q.x, q.y)).rgb;
        o = ((uTint * uReflExpo) * f) * e + o;
    }
    fragColor = vec4(meia(o), px.a);
}
