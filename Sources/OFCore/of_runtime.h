/*
 * of_runtime.h - o "Java" que o motor do Optical Flares do APK usa, em C.
 *
 * of_motor.c e of_mdo.c sao gerados do smali de MotorDoOf e MatematicaDoOf
 * (instrucao por instrucao); aqui ficam os objetos (S, ParamsOf, Cor, Arestas,
 * as lambdas Frag), as listas, os arrays com tamanho e o arena do quadro.
 */
#ifndef OF_RUNTIME_H
#define OF_RUNTIME_H

#pragma clang fp contract(off)

#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <limits.h>
#include <float.h>

/* registrador do Dalvik: 32 bits (int/float), 64 bits (long/double) e objeto, separados */
typedef struct { union { int32_t i; float f; }; union { int64_t j; double d; }; void *o; } R;
#define ZV(x) ((x).o ? 1 : (x).i)

/* arrays com tamanho (como os do Java); tudo vem do arena do quadro */
void *of_arena(size_t esize, int64_t n);
#define ARENA(T, n) ((T *)of_arena(sizeof(T), (int64_t)(n)))
#define LEN(p) ((int32_t)(((int64_t *)(p))[-2]))
#define ESIZE(p) ((size_t)(((int64_t *)(p))[-1]))

int32_t J2I(double x);
int64_t J2L(double x);
int32_t JDIV32(int32_t a, int32_t b);
int32_t JREM32(int32_t a, int32_t b);
int64_t JDIV64(int64_t a, int64_t b);
int64_t JREM64(int64_t a, int64_t b);

/* ---------------- objetos ---------------- */

typedef struct { int kind; float a, b; int32_t inteiro, flag; char texto[96]; int tem; } ValorOf;
typedef struct { int kind; int32_t a, b; float min, max; int32_t flag; int tem; } DefOf;

#define OF_NPARAM 256

typedef struct { int tipo; DefOf *defs; ValorOf v[OF_NPARAM]; } C_ParamsOf;
typedef C_ParamsOf P;

typedef struct { int tipo; char nome[64]; int oculto, solo; ValorOf params[OF_NPARAM]; } C_ElementoOf;

typedef struct { void **itens; int32_t n, cap; } OFLista;
typedef struct { OFLista *l; int32_t i; } OFIter;

typedef struct { int versao; ValorOf globais[OF_NPARAM]; OFLista elementos; } C_FlareOf;

typedef struct {
    float posX, posY, centroX, centroY, brilho, escala;
    double rotacao;
    int32_t corR, corG, corB, modoCor, render;
    float evolucao, tempo;
    int32_t semente;
} C_MotorDoOf_Controles;

typedef struct C_MotorDoOf {
    int32_t w, h;
    void *acum, *cf, *ci;
    C_MotorDoOf_Controles *controles;
    OFLista *faltou;
    C_FlareOf *flare;
    P *g;
    void *linF, *linV, *linX0, *linX1, *linY;
    int32_t nLinhas;
    int64_t sementeDosOrbs;
    int32_t sementeGlobal, threadsDoQuadro;
    void *trabalho;
} C_MotorDoOf;
typedef C_MotorDoOf M;

typedef struct { void *arr, *esps, *f, *n; P *p; void *raios; } C_MotorDoOf_S;
typedef struct { void *c1, *c2; int32_t inv, modo; float s38, s3c; } C_MotorDoOf_Cor;
typedef struct { void *xs, *dx, *va, *inc; } C_MotorDoOf_Arestas;
typedef struct { int32_t f; } C_iw6;
typedef struct { float f; } C_hw6;
typedef struct { double r; int32_t n; int64_t rcx; } C_MatematicaDoOf_Reduzido;
typedef struct { void *rgba; } C_MotorDoOf_Resultado;

/* lambdas (Frag) e referencias de metodo (qj3) */
typedef struct { int cls; R c[16]; } OFObj;

/* ---------------- estaticos ---------------- */
extern int32_t S_MotorDoOf_MAX_LINHAS;
extern void *S_MatematicaDoOf_log2, *S_MatematicaDoOf_exp2, *S_MatematicaDoOf_rsq;
extern const float S_MatematicaDoOf_K255, S_MatematicaDoOf_E_FLOAT;
extern void *S_Libm_TAB_ATAN, *S_Libm_LOGF_REC, *S_Libm_LOGF_CAUDA, *S_Libm_LOGF_CABECA;
extern const int64_t S_Libm_PIO4;
extern const char *DEFS_DO_OF;
#include "of_consts.h"

/* ---------------- java.lang / util ---------------- */
float J_Math_abs_F(float a);
double J_Math_abs_D(double a);
int32_t J_Math_min_II(int32_t a, int32_t b);
float J_Math_min_FF(float a, float b);
float J_Math_max_FF(float a, float b);
double J_Math_rint_D(double a);
double J_StrictMath_log(double a);
double J_StrictMath_pow(double a, double b);
float J_Float_intBitsToFloat(int32_t i);
int32_t J_Float_floatToRawIntBits(float f);
int32_t J_Float_isNaN(float f);
int32_t J_Float_isInfinite(float f);
int64_t J_Double_doubleToRawLongBits(double d);
void J_System_arraycopy(void *src, int32_t sp, void *dst, int32_t dp, int32_t n);
void *J_Arrays_copyOf_F(void *a, int32_t n);
void *J_Arrays_copyOf_B(void *a, int32_t n);
void *J_Arrays_copyOf_I(void *a, int32_t n);
void *J_Arrays_copyOf_LjavalangObject(void *a, int32_t n);
void J_Arrays_fill_B(void *a, int32_t v);
void J_Arrays_fill_F(void *a, float v);
int32_t J_Collection_add(void *c, void *x);
int32_t J_Collection_isEmpty(void *c);
void *J_Iterable_iterator(void *c);
void *J_List_iterator(void *c);
void *J_ArrayList_iterator(void *c);
int32_t J_ArrayList_size(void *c);
int32_t J_ArrayList_add(void *c, void *x);
int32_t J_Iterator_hasNext(void *it);
void *J_Iterator_next(void *it);
void *NEW_ArrayList(void);
void INIT_ArrayList(void *o, ...);
void *NEW_StringBuilder(void);
void INIT_StringBuilder(void *o, ...);
void *J_StringBuilder_append(void *sb, ...);
void *J_StringBuilder_toString(void *sb);
void *J_Integer_valueOf(int32_t i);
void *J_LinkedHashMap_get(void *m, void *k);
int32_t J_CharSequence_length(void *s);
int32_t J_m84_J(void *a, void *b);
void INIT_Object(void *o);

/* ajudantes do Kotlin que o R8 juntou */
int32_t J_c10_e(int32_t a, int32_t b, int32_t c, int32_t d);
float J_c10_c(float a, float b, float c, float d);
float J_fx0_b(float a, float b, float c, float d);
float J_n76_b(float a, float b, float c, float d);
int32_t J_n76_f(int32_t a, int32_t b, int32_t c, int32_t d);
float J_ru5_A(float a, float b, float c, float d);
float J_ru5_a(float a, float b, float c, float d);
float J_ru5_w(float a, float b, float c, float d);
int32_t J_bh4_d(int32_t a, int32_t b, int32_t c, int32_t d);
float J_bh4_a(float a, float b, int32_t i);
int32_t J_wf6_r(int32_t v, int32_t a, int32_t b);
int64_t J_wf6_s(int64_t v, int64_t a, int64_t b);

/* ---------------- classes do Optical Flares ---------------- */
float J_MotorDoOf_S_get(void *s, int32_t i);
void J_MotorDoOf_S_set(void *s, int32_t i, float f);
int32_t J_MotorDoOf_S_i1(void *s, int32_t i);
void J_MotorDoOf_S_i2(void *s, int32_t i, int32_t v);
int32_t J_MotorDoOf_S_b(void *s, int32_t i);
void *J_MotorDoOf_S_getP(void *s);
void *J_MotorDoOf_S_getRaios(void *s);
void J_MotorDoOf_S_setRaios(void *s, void *v);
void *J_MotorDoOf_S_getEsps(void *s);
void J_MotorDoOf_S_setEsps(void *s, void *v);
void *J_MotorDoOf_S_getArr(void *s);
void J_MotorDoOf_S_setArr(void *s, void *v);
void *NEW_MotorDoOf_S(void);
void INIT_MotorDoOf_S(void *o, void *p);

float J_ParamsOf_f1(void *p, int32_t i);
float J_ParamsOf_f2(void *p, int32_t i, int32_t k);
int32_t J_ParamsOf_i(void *p, int32_t i);
int32_t J_ParamsOf_tem(void *p, int32_t i);
int32_t J_ParamsOf_flag(void *p, int32_t i);
int32_t J_ParamsOf_corInt(void *p, int32_t i);
void *J_ParamsOf_texto(void *p, int32_t i);
int32_t J_ParamsOf_getTipo(void *p);
void J_ParamsOf_cor_default(void *p, int32_t i, void *arr, int32_t k, int32_t mask, void *obj);
void *NEW_ParamsOf(void);
void INIT_ParamsOf(void *o, int32_t tipo, void *mapa);

int32_t J_ElementoOf_getTipo(void *e);
int32_t J_ElementoOf_getSolo(void *e);
int32_t J_ElementoOf_getOculto(void *e);
void *J_ElementoOf_getParams(void *e);
void *J_FlareOf_getElementos(void *f);
void *J_FlareOf_Companion_getTIPOS(void *c);

void *NEW_MotorDoOf_Cor(void);
void INIT_MotorDoOf_Cor(void *o, void *s);
void J_MotorDoOf_Cor_em(void *c, float f, void *arr);
float J_MotorDoOf_Cor_getS38(void *c);
float J_MotorDoOf_Cor_getS3c(void *c);

void *NEW_MotorDoOf_Arestas(void);
void INIT_MotorDoOf_Arestas(void *o);
void *J_MotorDoOf_Arestas_getXs(void *a);
void *J_MotorDoOf_Arestas_getDx(void *a);
void *J_MotorDoOf_Arestas_getVa(void *a);
void *J_MotorDoOf_Arestas_getInc(void *a);

void *NEW_MotorDoOf_Resultado(void);
void INIT_MotorDoOf_Resultado(void *o, void *rgba, void *faltou);
void *J_MotorDoOf_Trabalho_copiaDe_app(void *t, int32_t n);
void *J_MotorDoOf_Trabalho_saidaDe_app(void *t, int32_t n);

float J_MotorDoOf_Controles_getPosX(void *c);
float J_MotorDoOf_Controles_getPosY(void *c);
float J_MotorDoOf_Controles_getCentroX(void *c);
float J_MotorDoOf_Controles_getCentroY(void *c);
float J_MotorDoOf_Controles_getBrilho(void *c);
float J_MotorDoOf_Controles_getEscala(void *c);
double J_MotorDoOf_Controles_getRotacao(void *c);
int32_t J_MotorDoOf_Controles_getCorR(void *c);
int32_t J_MotorDoOf_Controles_getCorG(void *c);
int32_t J_MotorDoOf_Controles_getCorB(void *c);
int32_t J_MotorDoOf_Controles_getModoCor(void *c);
int32_t J_MotorDoOf_Controles_getRender(void *c);
float J_MotorDoOf_Controles_getEvolucao(void *c);
float J_MotorDoOf_Controles_getTempo(void *c);
int32_t J_MotorDoOf_Controles_getSemente(void *c);
float J_Companion_rotacaoAe(double d);

void *NEW_iw6(void);
void *NEW_hw6(void);
void INIT_iw6(void *o);
void INIT_hw6(void *o);
void *NEW_MatematicaDoOf_Reduzido(void);
void INIT_MatematicaDoOf_Reduzido(void *o, double r, int32_t n, int64_t rcx);

/* lambdas */
void *NEW_a(void); void INIT_a(void *o, float, float, float, float, void *);
void *NEW_b(void); void INIT_b(void *o, float, int32_t, float, void *, float, void *, int32_t);
void *NEW_c(void); void INIT_c(void *o, float, float, int32_t, float, float, float, int32_t, float, void *, float, void *);
void *NEW_d(void); void INIT_d(void *o, float, float, float, int32_t, float, float, float, float, int32_t, float, float, float, void *, float, float, void *);
void *NEW_e(void); void INIT_e(void *o, float, void *, int32_t);
void *NEW_f(void); void INIT_f(void *o, void *, float, void *, float);
void *NEW_g(void); void INIT_g(void *o, int32_t, float, int32_t, void *, float, float, float, float);
void *NEW_MotorDoOf_forma_1(void); void INIT_MotorDoOf_forma_1(void *o, void *m);
void *NEW_MotorDoOf_forma_2(void); void INIT_MotorDoOf_forma_2(void *o, void *m);
int32_t J_MotorDoOf_Frag_pixel(void *fr, float a, float b, float c, float d, void *arr);
void *J_qj3_invoke(void *fn, void *s);

/* metodos gerados que o runtime chama */
#include "of_motor_protos.h"
#include "of_mdo_protos.h"

#endif
