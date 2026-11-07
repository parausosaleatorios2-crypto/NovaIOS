// O float16 do motor do Looks (vem antes de todo shader desta pasta, de fragmento ou de computação).
// O valor é devolvido em float, mas já representável em float16: gravado num alvo RGBA16F, não muda.

precision highp float;
precision highp int;
precision highp sampler2D;

/** float16 arredondado para zero, devolvido em float. */
float meia(float x) {
    uint b = floatBitsToUint(x);
    uint e = (b >> 23) & 0xFFu;
    if (e == 0xFFu) return x;
    float a = abs(x);
    if (a >= 65504.0) return x < 0.0 ? -65504.0 : 65504.0;
    if (a < 6.103515625e-05) {
        // subnormal do float16: quantum 2^-24 (a escala por potência de 2 é exata em float)
        return trunc(x * 16777216.0) * 5.9604644775390625e-08;
    }
    return uintBitsToFloat(b & 0xFFFFE000u);
}

vec4 meia(vec4 v) { return vec4(meia(v.x), meia(v.y), meia(v.z), meia(v.w)); }
vec3 meia(vec3 v) { return vec3(meia(v.x), meia(v.y), meia(v.z)); }

/**
 * float16 arredondado ao mais próximo (empate para o par), devolvido em float.
 *
 * Sem desvio, só seleções: com `if` por canal o gaussiano (`gauss.comp`, que grava isto a cada passo da série)
 * gastava um terço do tempo aqui. Nos 13 bits que saem, somar 0xFFF + o último bit que fica faz o arredondamento
 * ao par (resto > meio sobe; = meio sobe só com o último bit 1; o vai-um entra no expoente). Conferido contra a
 * forma antiga com `if` nos 2^32 floats na GPU do PC: 0 diferenças (0.878.0).
 */
float meiaPerto(float x) {
    uint b = floatBitsToUint(x);
    float normal = uintBitsToFloat((b + 0xFFFu + ((b >> 13) & 1u)) & 0xFFFFE000u);
    float a = abs(x);
    // subnormal do float16: quantum 2^-24
    float y = a < 6.103515625e-05 ? roundEven(x * 16777216.0) * 5.9604644775390625e-08 : normal;
    y = a >= 65520.0 ? uintBitsToFloat((b & 0x80000000u) | 0x7F800000u) : y;
    // infinito e NaN passam como vieram
    return (b & 0x7F800000u) == 0x7F800000u ? x : y;
}

vec4 meiaPerto(vec4 v) { return vec4(meiaPerto(v.x), meiaPerto(v.y), meiaPerto(v.z), meiaPerto(v.w)); }
