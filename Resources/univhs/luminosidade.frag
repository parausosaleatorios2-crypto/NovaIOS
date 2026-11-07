// uni.VHS — fx.rgbToLightness: (mín + máx)/2 do original, preso em 0..1; o alfa fica.
out vec4 fragColor;

void main() {
    vec4 o = lerAe(uEntrada, pxAe());
    float l = clamp((min(min(o.r, o.g), o.b) + max(max(o.r, o.g), o.b)) * 0.5, 0.0, 1.0);
    fragColor = meia(vec4(vec3(l), o.a));
}
