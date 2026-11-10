/* Teste do CI: desenha o flare padrao do APK num quadro preto e grava PPM. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "OFCore.h"

static unsigned char *ler(const char *p, size_t *n) {
    FILE *f = fopen(p, "rb"); if (!f) { perror(p); exit(1); }
    fseek(f, 0, SEEK_END); *n = (size_t)ftell(f); fseek(f, 0, SEEK_SET);
    unsigned char *b = malloc(*n); if (fread(b, 1, *n, f) != *n) exit(1); fclose(f); return b;
}

int main(int argc, char **argv) {
    size_t nt, no;
    unsigned char *tab = ler(argv[1], &nt), *ofp = ler(argv[2], &no);
    if (!of_carregar_tabelas(tab, nt)) { puts("tabelas falharam"); return 1; }
    int w = 640, h = 360;
    unsigned char *in = calloc((size_t)w * h * 4, 1), *out = calloc((size_t)w * h * 4, 1);
    for (int i = 0; i < w * h; i++) in[i * 4 + 3] = 255;
    OFControles c = { w * 0.35f, h * 0.35f, w * 0.5f, h * 0.5f, 100, 100, 0, 255, 255, 255, 1, 1, 0, 0, 0 };
    int ok = of_render(ofp, (int)no, &c, w, h, 4, in, out);
    printf("of_render = %d\n", ok);
    double soma = 0; int max = 0;
    for (int i = 0; i < w * h * 4; i++) { soma += out[i]; if (out[i] > max) max = out[i]; }
    printf("media %.3f max %d\n", soma / (w * h * 4), max);
    FILE *f = fopen(argc > 3 ? argv[3] : "flare.ppm", "wb");
    fprintf(f, "P6\n%d %d\n255\n", w, h);
    for (int i = 0; i < w * h; i++) fwrite(out + i * 4, 1, 3, f);
    fclose(f);
    return ok ? 0 : 2;
}
