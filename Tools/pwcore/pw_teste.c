/* pw_teste.c - desenha o CC Particle World (PWCore) no Linux do CI e grava PPMs.
 * uso: pw_teste <pasta de saida> */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "PWCore.h"

/* (indice do plugin, tipo, valor): 0 numero, 1 inteiro/menu, 2 caixa, 3 cor (r,g,b em v,v2,v3) */
typedef struct { int idx, tipo; double v, v2, v3; } Par;

static const Par PADRAO[] = {
    {14,0,2},{15,0,1},{17,0,0},{18,0,0},{19,0,0},{20,0,0.025},{21,0,0.025},{22,0,0.025},
    {25,1,1},{26,0,1},{27,0,0},{28,0,0.5},{29,0,0},{30,0,0.5},{31,0,360},{33,0,0.2},
    {34,1,1},{35,1,1},{36,1,1},{37,0,65},{38,0,25},{39,0,10},{42,0,0},{43,0,-1},{44,0,0},
    {47,0,0},{48,0,1},{49,0,0},{53,1,1},{56,0,0},{57,1,2},{58,2,0},{60,0,180},{61,0,360},
    {62,1,4},{63,0,0.25},{64,0,0.25},{65,0,50},{66,0,75},{69,1,2},{70,3,255,255,80},
    {71,3,200,40,40},{73,3,255,255,255},{74,3,255,255,80},{75,3,255,160,40},{76,3,192,92,20},
    {77,3,128,0,0},{79,0,0},{80,1,1},{84,0,1},{85,0,0},{86,0,0},{87,0,0},{88,0,45},{91,1,1},
    {92,0,2},{93,3,128,128,128},{96,0,-0.5773468017578125},{97,0,0.5773468017578125},
    {98,0,0.5773468017578125},{100,0,0},{101,2,0},{102,1,0},
};

/* "Particle World (Stars)": os valores do preset do snow (lidos do .ffx) */
static const Par STARS[] = {
    {14,0,4},{15,0,1},{17,0,0},{18,0,0},{19,0,3},{20,0,3},{21,0,3},{22,0,3},
    {25,1,11},{26,0,1},{27,0,0},{28,0,0},{29,0,0},{30,0,0.5},{31,0,360},{33,0,0.2},
    {34,1,1},{35,1,1},{36,1,1},{42,0,0},{43,0,-1},{44,0,0},{47,0,0},{48,0,1},{49,0,0},
    {53,1,2},{56,0,0},{57,1,2},{58,2,0},{60,0,180},{61,0,360},{62,1,4},{63,0,0.25},{64,0,0.25},
    {65,0,50},{66,0,100},{69,1,2},{70,3,255,255,255},{71,3,255,255,255},{79,0,0},{80,1,1},
    {84,0,1},{88,0,45},{91,1,1},{101,2,0},{102,1,0},
};

static int32_t valor(const Par *p) {
    switch (p->tipo) {
    case 0: return pw_fixo(p->v);
    case 1: return (int32_t)p->v;
    case 2: return p->v != 0;
    default: return pw_cor((int)p->v, (int)p->v2, (int)p->v3);
    }
}

typedef struct { const Par *lista; int n; } Fonte;

static int32_t fonte(void *ctx, int32_t idx, int32_t t, int32_t passo, int32_t escala) {
    (void)t; (void)passo; (void)escala;
    const Fonte *f = (const Fonte *)ctx;
    for (int i = 0; i < f->n; i++) if (f->lista[i].idx == idx) return valor(&f->lista[i]);
    for (size_t i = 0; i < sizeof PADRAO / sizeof PADRAO[0]; i++) if (PADRAO[i].idx == idx) return valor(&PADRAO[i]);
    return 0;
}

static void gravar(const char *nome, const uint8_t *rgba, int w, int h) {
    FILE *f = fopen(nome, "wb");
    fprintf(f, "P6\n%d %d\n255\n", w, h);
    for (int i = 0; i < w * h; i++) {
        /* sobre fundo preto (o alfa ja vem multiplicado) */
        fputc(rgba[i * 4], f); fputc(rgba[i * 4 + 1], f); fputc(rgba[i * 4 + 2], f);
    }
    fclose(f);
}

int main(int argc, char **argv) {
    const char *pasta = argc > 1 ? argv[1] : ".";
    int w = 640, h = 360;
    uint8_t *in = calloc((size_t)w * h * 4, 1), *out = calloc((size_t)w * h * 4, 1);
    struct { const char *nome; Fonte f; } casos[] = {
        {"padrao", {PADRAO, 0}},
        {"stars", {STARS, (int)(sizeof STARS / sizeof STARS[0])}},
    };
    int quadros[] = {15, 30, 90};
    for (int c = 0; c < 2; c++) {
        for (int q = 0; q < 3; q++) {
            clock_t t0 = clock();
            int ok = pw_render(in, w, h, out, quadros[q] * 1000, 30000, 1000, fonte, &casos[c].f, NULL, 0, 0);
            double ms = (double)(clock() - t0) * 1000.0 / CLOCKS_PER_SEC;
            long soma = 0; int acesos = 0;
            for (int i = 0; i < w * h; i++) { soma += out[i * 4 + 3]; if (out[i * 4 + 3]) acesos++; }
            printf("%s quadro %d: ok=%d %.1f ms, pixels com alfa %d, alfa medio %.2f\n",
                   casos[c].nome, quadros[q], ok, ms, acesos, (double)soma / (w * h));
            char nome[512];
            snprintf(nome, sizeof nome, "%s/%s_%03d.ppm", pasta, casos[c].nome, quadros[q]);
            gravar(nome, out, w, h);
        }
    }
    return 0;
}
