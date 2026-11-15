/*
 * pw_runtime.h - o "Java" que o motor do CC Particle World do APK usa, em C.
 *
 * pw_gerado.c e gerado do smali do pacote com.novaeditor.model.ccparticleworld por
 * Tools/pwcore/pwsmali.py (instrucao por instrucao); aqui ficam os registradores, os arrays
 * com tamanho, o arena do quadro e as funcoes de java.* / kotlin que o pacote chama.
 */
#ifndef PW_RUNTIME_H
#define PW_RUNTIME_H

#pragma clang fp contract(off)

#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>

/* registrador do Dalvik: 32 bits (int/float), 64 bits (long/double) e objeto, separados */
typedef struct { union { int32_t i; float f; }; union { int64_t j; double d; }; void *o; } R;
#define ZV(x) ((x).o ? 1 : (x).i)
#define RV(x) ((x).o ? (intptr_t)(x).o : (intptr_t)(x).i)
#define PWOBJ(p) (p)
#define PWARR(p, i) (p)

/* arrays com tamanho (como os do Java); tudo vem do arena */
void *pw_arena(size_t esize, int64_t n);
void *pw_novo(size_t tam);
#define ARENA(T, n) ((T *)pw_arena(sizeof(T), (int64_t)(n)))
#define NEWOBJ(T) ((T *)pw_novo(sizeof(T)))
#define LEN(p) ((int32_t)(((int64_t *)(p))[-2]))
#define ESIZE(p) ((size_t)(((int64_t *)(p))[-1]))

void pw_falha(const char *motivo);

/* nomes proprios: o OFCore (Optical Flares) tem funcoes com os mesmos nomes no mesmo app */
#define J2I pw_J2I
#define J2L pw_J2L
#define JDIV32 pw_JDIV32
#define JREM32 pw_JREM32
#define JDIV64 pw_JDIV64
#define JREM64 pw_JREM64
int32_t J2I(double x);
int64_t J2L(double x);
int32_t JDIV32(int32_t a, int32_t b);
int32_t JREM32(int32_t a, int32_t b);
int64_t JDIV64(int64_t a, int64_t b);
int64_t JREM64(int64_t a, int64_t b);

/* objetos de fora do pacote */
typedef struct { void *f, *g; } C_h46;                 /* kotlin Pair */
typedef struct { int64_t i; double d; } PWCaixa;        /* Integer / Double / Boolean */
typedef struct { int8_t *a; int32_t pos; } PWByteBuffer;

/* interfaces do pacote: ponteiros para funcao */
typedef int32_t (*PWFonteFn)(void *ctx, int32_t idx, int32_t t, int32_t passo, int32_t escala);
typedef struct { PWFonteFn fn; void *ctx; } PWFonte;

extern void *S_Boolean_TRUE, *S_Boolean_FALSE, *S_ByteOrder_LITTLE_ENDIAN;

#include "pw_java.h"

#endif
