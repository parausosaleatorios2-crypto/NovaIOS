/*
 * PWCore.h - o motor do CC Particle World do APK (pacote ccparticleworld), em C.
 *
 * O Swift chama pw_render por quadro. Os parametros vem pela funcao `fonte`, que devolve o
 * valor "bruto" do parametro `idx` (o indice do plugin, ex. 14 = Birth Rate) no instante
 * t / escala segundos — como ParametrosDoPw.bruto do APK: numero em ponto fixo 16.16
 * (pw_fixo), menu e caixa como inteiro (menus comecam em 1, como no AE) e cor por pw_cor.
 */
#ifndef PWCORE_H
#define PWCORE_H

#include <stdint.h>

typedef int32_t (*PWFonteFn)(void *ctx, int32_t idx, int32_t t, int32_t passo, int32_t escala);

/* rgbaIn/rgbaOut: RGBA 8 bits, de cima para baixo, w x h. t/escala = instante (escala =
 * fps x 1000; um quadro = 1000). resolucao1000 = 1000 na resolucao cheia. texRgba (opcional)
 * e a camada de textura. Devolve 1 quando desenhou. */
int pw_render(const uint8_t *rgbaIn, int w, int h, uint8_t *rgbaOut,
              int32_t t, int32_t escala, int32_t resolucao1000,
              PWFonteFn fonte, void *ctx,
              const uint8_t *texRgba, int tw, int th);

int32_t pw_fixo(double v);
int32_t pw_cor(int r, int g, int b);

#endif
