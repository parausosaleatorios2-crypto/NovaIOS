// O meio do script, por pixel: o Radial Blur volta da polar (despré-multiplica e fx.toPolar, op 0x162) e entra
// por cima da camada (bx.infront); a textura de lente (camada escolhida: fx.unmult e bx.lumaMask com a
// texture_mask) entra no modo Luma (bx.luma, trocado: a luminância da textura sobre a camada, na quantidade
// Texture Amount); com Edge Blur, fx.clamp(0, 1) e o pré-multiplicar do compoundBlur. Cada passe grava meia().
// `uEntrada` = canais.frag (RGBA8); `uPolar` = a polar desfocada (RGBA16F, pré-multiplicada) se há radial.
uniform highp sampler2D uPolar;
uniform bool uRadial;
uniform highp sampler2D uTextura;   // a camada da textura (como ela aparece, no espaço do buffer da cadeia)
uniform ivec2 uOrigemTextura;       // onde a camada começa no buffer da cadeia (memória)
uniform vec2 uTamanhoBuffer;        // o tamanho do buffer da cadeia
uniform bool uComTextura;
uniform bool uMascaraDaTextura;
uniform float uQuantidade;          // Texture Amount · 0,01
uniform bool uPreparaComposto;      // Edge Blur ligado: clamp + pré-multiplica
uniform vec4 uMascA;
uniform vec4 uMascB;
uniform vec4 uMascC;
uniform vec4 uTexA;
uniform vec4 uTexB;
uniform vec4 uTexC;
out vec4 fragColor;

const float PI = 3.1415926535897;

/** A polar desfocada, despré-multiplicada, no texel `p`. */
vec4 polar(ivec2 p) { return meia(despre(lerAe(uPolar, p))); }

vec4 bilinearPolar(vec2 pos) {
    vec2 q = pos - 0.5;
    vec2 i0 = floor(q);
    vec2 f = vec2(peso8(q.x - i0.x), peso8(q.y - i0.y));
    ivec2 a = ivec2(i0);
    vec4 c0 = polar(a) * (1.0 - f.x) + polar(a + ivec2(1, 0)) * f.x;
    vec4 c1 = polar(a + ivec2(0, 1)) * (1.0 - f.x) + polar(a + ivec2(1, 1)) * f.x;
    return c0 * (1.0 - f.y) + c1 * f.y;
}

/** fx.toPolar: o px cartesiano `uv` lê a polar no (ângulo, raio). Na emenda (y = 0, x < 0) a AMD dá −π. */
vec4 dePolar(vec2 uv) {
    vec2 w = vec2(uTamanho);
    float x = uv.x * (1.0 / w.x) - 0.5;
    float y = uv.y * (1.0 / w.y) - 0.5;
    x *= w.x * (1.0 / w.y);
    float r = sqrt(x * x + y * y);
    float ang = (y == 0.0 && x < 0.0) ? -PI : atan(y, x);
    float q = 0.5 * (ang + PI) / PI;
    return bilinearPolar(vec2(q * w.x, r * w.y));
}

float lum(vec3 c) { return 0.3 * c.r + 0.59 * c.g + 0.11 * c.b; }

vec3 clipColor(vec3 C) {
    float l = lum(C);
    float n = min(C.r, min(C.g, C.b));
    float x = max(C.r, max(C.g, C.b));
    if (n < 0.0) C = l + ((C - l) * l) / (l - n);
    if (x > 1.0) C = l + ((C - l) * (1.0 - l)) / (x - l);
    return C;
}

void main() {
    ivec2 p = pxAe();
    vec2 uv = vec2(p) + 0.5;
    vec4 pre = meia(lerAe(uEntrada, p));                 // fx.blit(preRadial)
    // o Radial Blur (ou só o lumaMask, sem ele)
    vec4 comp;
    if (uRadial) {
        comp = meia(dePolar(uv));
    } else {
        float m = mascara(uv, uMascA, uMascB, uMascC);
        comp = pre;
        comp.a *= (1.0 + 1.0 + 1.0) * 0.3333333 * m;
        comp = meia(comp);
    }
    // bx.infront(100, 100, 100, 100): comp por cima da camada
    float a = clamp(comp.a + pre.a - comp.a * pre.a, 0.0, 1.0);
    vec3 rgb = comp.rgb * vec3(comp.a) + pre.rgb * pre.a * vec3(1.0 - comp.a);
    if (a != 0.0) rgb /= a;
    vec4 pretex = meia(vec4(rgb, a));
    // a textura de lente
    vec4 suj = pretex;
    if (uComTextura) {
        ivec2 q = p;
        if (uDePe) q.y = uTamanho.y - 1 - q.y;
        vec4 g = meia(texture(uTextura, (vec2(q + uOrigemTextura) + 0.5) / uTamanhoBuffer));
        float n = clamp(max(g.r, max(g.g, g.b)), 0.0, 1.0);    // fx.unmult
        g.a *= n;
        if (n != 0.0) g.rgb /= n;
        g = meia(g);
        if (uMascaraDaTextura) {
            float mt = mascara(uv, uTexA, uTexB, uTexC);
            g.a *= (1.0 + 1.0 + 1.0) * 0.3333333 * mt;
            g = meia(g);
        }
        suj = g;
    }
    // bx.luma(100, 100, Texture Amount, 100, true): fg = a textura, bg = a camada
    vec4 fg = suj, bg = pretex;
    fg.a *= uQuantidade;
    float al = clamp(fg.a + bg.a - fg.a * bg.a, 0.0, 1.0);
    vec3 o = clipColor(bg.rgb + vec3(lum(fg.rgb) - lum(bg.rgb)));
    o *= al;
    vec3 bgp = bg.rgb * bg.a;
    o = mistura(fg.rgb, o, bg.a);
    o = mistura(bgp, o, fg.a);
    if (al != 0.0) o /= al;
    vec4 l = meia(vec4(o, al));
    if (uPreparaComposto) {
        l = meia(vec4(clamp(l.rgb, 0.0, 1.0), l.a));      // fx.clamp(0, 1)
        l = meia(vec4(l.rgb * l.a, l.a));                 // o compoundBlur pré-multiplica
    }
    fragColor = l;
}
