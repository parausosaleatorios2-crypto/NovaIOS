/*
 * OFCore.h - o motor do Optical Flares do APK (MotorDoOf), em C.
 * Swift chama of_carregar_tabelas uma vez (opticalflares/tabelas.bin) e
 * of_render por quadro.
 */
#ifndef OFCORE_H
#define OFCORE_H

#include <stdint.h>
#include <stddef.h>

typedef struct {
    float posX, posY, centroX, centroY;   /* px da camada */
    float brilho, escala;                 /* % */
    double rotacao;                       /* graus */
    int32_t corR, corG, corB;             /* 0..255 */
    int32_t modoCor;                      /* 1 Tint, 2 Multiply */
    int32_t render;                       /* 1 On Black, 2 On Transparent, 3 Over Original */
    float evolucao;                       /* graus */
    float tempo;                          /* s */
    int32_t semente;
} OFControles;

/* tabelas.bin do APK; devolve 1 quando carregou */
int of_carregar_tabelas(const uint8_t *bin, size_t len);

/* Desenha o flare (bloco .ofp) sobre rgbaIn (RGBA 8 bits, de cima para baixo) em rgbaOut.
 * Devolve 1 quando desenhou. */
int of_render(const uint8_t *ofp, int ofpLen, const OFControles *c, int w, int h, int threads,
              const uint8_t *rgbaIn, uint8_t *rgbaOut);

#endif
