/*
 * of_runtime.c - objetos e servicos que o motor gerado do Optical Flares chama.
 * Portado das classes do APK (ParamsOf, FlareOf, MotorDoOf.S/Cor/Arestas, as lambdas).
 */
#include "of_runtime.h"
#include "OFCore.h"
#include <stdarg.h>
#include <stdio.h>
#ifdef __APPLE__
#include <dispatch/dispatch.h>
#endif

/* ---------------- arena do quadro ---------------- */

typedef struct Bloco { struct Bloco *prox; } Bloco;
static _Thread_local Bloco *arena_lista = NULL;

void *of_arena(size_t esize, int64_t n) {
    if (n < 0) n = 0;
    size_t bytes = 16 + sizeof(Bloco) + (size_t)n * esize;
    Bloco *b = (Bloco *)calloc(1, bytes + 16);
    if (!b) abort();
    b->prox = arena_lista; arena_lista = b;
    int64_t *h = (int64_t *)((char *)b + ((sizeof(Bloco) + 15) & ~(size_t)15));
    h[0] = n; h[1] = (int64_t)esize;
    return h + 2;
}

static void arena_liberar(void) {
    while (arena_lista) { Bloco *b = arena_lista; arena_lista = b->prox; free(b); }
}

/* ---------------- conversoes do Java ---------------- */

int32_t J2I(double x) {
    if (x != x) return 0;
    if (x >= 2147483647.0) return INT32_MAX;
    if (x <= -2147483648.0) return INT32_MIN;
    return (int32_t)x;
}
int64_t J2L(double x) {
    if (x != x) return 0;
    if (x >= 9223372036854775807.0) return INT64_MAX;
    if (x <= -9223372036854775808.0) return INT64_MIN;
    return (int64_t)x;
}
int32_t JDIV32(int32_t a, int32_t b) { if (b == 0) return 0; if (a == INT32_MIN && b == -1) return a; return a / b; }
int32_t JREM32(int32_t a, int32_t b) { if (b == 0) return 0; if (b == -1) return 0; return a % b; }
int64_t JDIV64(int64_t a, int64_t b) { if (b == 0) return 0; if (a == INT64_MIN && b == -1) return a; return a / b; }
int64_t JREM64(int64_t a, int64_t b) { if (b == 0) return 0; if (b == -1) return 0; return a % b; }

static float ibf(int32_t i) { float f; memcpy(&f, &i, 4); return f; }
static int32_t fbi(float f) { int32_t i; memcpy(&i, &f, 4); return i; }

/* ---------------- java.lang ---------------- */

float J_Math_abs_F(float a) { return ibf(fbi(a) & 0x7fffffff); }
double J_Math_abs_D(double a) { return fabs(a); }
int32_t J_Math_min_II(int32_t a, int32_t b) { return a <= b ? a : b; }
float J_Math_min_FF(float a, float b) {
    if (a != a) return a;
    if (a == 0.0f && b == 0.0f && fbi(b) == (int32_t)0x80000000) return b;
    return a <= b ? a : b;
}
float J_Math_max_FF(float a, float b) {
    if (a != a) return a;
    if (a == 0.0f && b == 0.0f && fbi(a) == (int32_t)0x80000000) return b;
    return a >= b ? a : b;
}
double J_Math_rint_D(double a) { return rint(a); }
double J_StrictMath_log(double a) { return log(a); }
double J_StrictMath_pow(double a, double b) { return pow(a, b); }
float J_Float_intBitsToFloat(int32_t i) { return ibf(i); }
int32_t J_Float_floatToRawIntBits(float f) { return fbi(f); }
int32_t J_Float_isNaN(float f) { return f != f; }
int32_t J_Float_isInfinite(float f) { return isinf(f) ? 1 : 0; }
int64_t J_Double_doubleToRawLongBits(double d) { int64_t i; memcpy(&i, &d, 8); return i; }

void J_System_arraycopy(void *src, int32_t sp, void *dst, int32_t dp, int32_t n) {
    if (!src || !dst || n <= 0) return;
    size_t es = ESIZE(src);
    memmove((char *)dst + (size_t)dp * es, (char *)src + (size_t)sp * es, (size_t)n * es);
}
static void *copia(void *a, int32_t n) {
    size_t es = ESIZE(a);
    void *b = of_arena(es, n);
    int32_t m = LEN(a) < n ? LEN(a) : n;
    if (m > 0) memcpy(b, a, (size_t)m * es);
    return b;
}
void *J_Arrays_copyOf_F(void *a, int32_t n) { return copia(a, n); }
void *J_Arrays_copyOf_B(void *a, int32_t n) { return copia(a, n); }
void *J_Arrays_copyOf_I(void *a, int32_t n) { return copia(a, n); }
void *J_Arrays_copyOf_LjavalangObject(void *a, int32_t n) { return copia(a, n); }
void J_Arrays_fill_B(void *a, int32_t v) { if (a) memset(a, (int8_t)v, (size_t)LEN(a)); }
void J_Arrays_fill_F(void *a, float v) { if (a) { float *f = (float *)a; for (int32_t i = 0; i < LEN(a); i++) f[i] = v; } }

/* listas: ArrayList, List dos elementos, o LinkedHashSet de "faltou" */
static OFLista *lista_nova(void) { return ARENA(OFLista, 1); }
static void lista_por(OFLista *l, void *x) {
    if (l->n == l->cap) {
        int32_t nc = l->cap ? l->cap * 2 : 16;
        void **novo = ARENA(void *, nc);
        if (l->n) memcpy(novo, l->itens, sizeof(void *) * (size_t)l->n);
        l->itens = novo; l->cap = nc;
    }
    l->itens[l->n++] = x;
}
int32_t J_Collection_add(void *c, void *x) { if (c) lista_por((OFLista *)c, x); return 1; }
int32_t J_Collection_isEmpty(void *c) { return c ? ((OFLista *)c)->n == 0 : 1; }
void *J_Iterable_iterator(void *c) { OFIter *it = ARENA(OFIter, 1); it->l = (OFLista *)c; return it; }
void *J_List_iterator(void *c) { return J_Iterable_iterator(c); }
void *J_ArrayList_iterator(void *c) { return J_Iterable_iterator(c); }
int32_t J_ArrayList_size(void *c) { return c ? ((OFLista *)c)->n : 0; }
int32_t J_ArrayList_add(void *c, void *x) { return J_Collection_add(c, x); }
int32_t J_Iterator_hasNext(void *it) { OFIter *i = (OFIter *)it; return i->l && i->i < i->l->n; }
void *J_Iterator_next(void *it) { OFIter *i = (OFIter *)it; return i->l->itens[i->i++]; }
void *NEW_ArrayList(void) { return lista_nova(); }
void INIT_ArrayList(void *o, ...) { (void)o; }
void *NEW_StringBuilder(void) { return NULL; }
void INIT_StringBuilder(void *o, ...) { (void)o; }
void *J_StringBuilder_append(void *sb, ...) { return sb; }
void *J_StringBuilder_toString(void *sb) { (void)sb; return (void *)"?"; }
void *J_Integer_valueOf(int32_t i) { (void)i; return NULL; }
void *J_LinkedHashMap_get(void *m, void *k) { (void)m; (void)k; return NULL; }
int32_t J_CharSequence_length(void *s) { return s ? (int32_t)strlen((const char *)s) : 0; }
int32_t J_m84_J(void *a, void *b) {
    if (a == b) return 1;
    if (!a || !b) return 0;
    return strcmp((const char *)a, (const char *)b) == 0;
}
void INIT_Object(void *o) { (void)o; }

/* ---------------- ajudantes do Kotlin ---------------- */

int32_t J_c10_e(int32_t a, int32_t b, int32_t c, int32_t d) {
    return (int32_t)(((uint32_t)((int32_t)((uint32_t)a * (uint32_t)b)) + (uint32_t)c) * (uint32_t)d);
}
float J_c10_c(float a, float b, float c, float d) { float t = a * b; t = t * c; return t + d; }
float J_fx0_b(float a, float b, float c, float d) { float t = a * b; t = t + c; return t + d; }
float J_n76_b(float a, float b, float c, float d) { float t = a * b; t = c - t; return t * d; }
int32_t J_n76_f(int32_t a, int32_t b, int32_t c, int32_t d) { return JDIV32((int32_t)((uint32_t)a + (uint32_t)b - (uint32_t)c), d); }
float J_ru5_A(float a, float b, float c, float d) { float t = a * b; t = t + c; return t * d; }
float J_ru5_a(float a, float b, float c, float d) { float t = a * b; t = t * c; return d - t; }
float J_ru5_w(float a, float b, float c, float d) { float t = a - b; t = t * c; return t + d; }
int32_t J_bh4_d(int32_t a, int32_t b, int32_t c, int32_t d) {
    return (int32_t)((uint32_t)((int32_t)((uint32_t)a - (uint32_t)b)) * (uint32_t)c + (uint32_t)d);
}
float J_bh4_a(float a, float b, int32_t i) { float t = ibf(i) * a; return t + b; }
int32_t J_wf6_r(int32_t v, int32_t a, int32_t b) { return v < a ? a : (v > b ? b : v); }
int64_t J_wf6_s(int64_t v, int64_t a, int64_t b) { return v < a ? a : (v > b ? b : v); }

/* ---------------- ParamsOf (com a tabela DefsDoOf) ---------------- */

static DefOf DEFS[16][OF_NPARAM];
static int defs_prontos = 0;

static void carregar_defs(void) {
    if (defs_prontos) return;
    const char *p = DEFS_DO_OF;
    while (*p) {
        while (*p == '\n') p++;
        if (!*p) break;
        char linha[160]; int n = 0;
        while (*p && *p != '\n' && n < 159) linha[n++] = *p++;
        linha[n] = 0;
        char *campos[8]; int k = 0; char *s = linha;
        campos[k++] = s;
        while (*s && k < 8) { if (*s == '|') { *s = 0; campos[k++] = s + 1; } s++; }
        if (k < 8) continue;
        int tipo = atoi(campos[0]), id = atoi(campos[1]);
        if (tipo < 0 || tipo >= 16 || id < 0 || id >= OF_NPARAM) continue;
        DefOf *d = &DEFS[tipo][id];
        d->kind = atoi(campos[2]);
        d->a = (int32_t)strtoll(campos[3], NULL, 16);
        d->b = (int32_t)strtoll(campos[4], NULL, 16);
        d->min = ibf((int32_t)strtoll(campos[5], NULL, 16));
        d->max = ibf((int32_t)strtoll(campos[6], NULL, 16));
        d->flag = atoi(campos[7]);
        d->tem = 1;
    }
    defs_prontos = 1;
}

void *NEW_ParamsOf(void) { return ARENA(C_ParamsOf, 1); }

void INIT_ParamsOf(void *o, int32_t tipo, void *mapa) {
    carregar_defs();
    P *p = (P *)o;
    p->tipo = tipo;
    p->defs = (tipo >= 0 && tipo < 16) ? DEFS[tipo] : DEFS[15];
    ValorOf *m = (ValorOf *)mapa;
    for (int id = 0; id < OF_NPARAM; id++) {
        if (!m || !m[id].tem) continue;
        int alvo = id == 91 ? 7 : id;
        DefOf *d = &p->defs[alvo];
        if (!d->tem) continue;
        ValorOf v = m[id];
        if (d->kind == 0 && d->min < d->max) {
            float a = v.a;
            if (a < d->min) a = d->min; else if (d->max < a) a = d->max;
            memset(&v, 0, sizeof v); v.kind = 0; v.a = a; v.tem = 1;
        }
        p->v[alvo] = v;
    }
}

static ValorOf *val(P *p, int32_t i) { return (i >= 0 && i < OF_NPARAM && p->v[i].tem) ? &p->v[i] : NULL; }
static DefOf *def(P *p, int32_t i) { return (i >= 0 && i < OF_NPARAM && p->defs[i].tem) ? &p->defs[i] : NULL; }

float J_ParamsOf_f1(void *pp, int32_t i) {
    P *p = (P *)pp; ValorOf *v = val(p, i);
    if (v) { if (v->kind == 0) return v->a; if (v->kind == 3 || v->kind == 4) return (float)v->inteiro; return 0.0f; }
    DefOf *d = def(p, i); if (!d) return 0.0f;
    if (d->kind == 0) return ibf(d->a);
    if (d->kind == 3 || d->kind == 4) return (float)d->a;
    return 0.0f;
}
float J_ParamsOf_f2(void *pp, int32_t i, int32_t k) {
    P *p = (P *)pp; ValorOf *v = val(p, i); int32_t a;
    if (v) {
        if (v->kind == 1) return k == 0 ? v->a : v->b;
        if (v->kind != 2) return 0.0f;
        a = v->inteiro;
    } else {
        DefOf *d = def(p, i); if (!d) return 0.0f;
        if (d->kind == 1) return ibf(k == 0 ? d->a : d->b);
        if (d->kind != 2) return 0.0f;
        a = d->a;
    }
    return (float)((a >> ((k * 8) & 31)) & 255);
}
int32_t J_ParamsOf_i(void *pp, int32_t i) {
    P *p = (P *)pp; ValorOf *v = val(p, i); float f;
    if (v) { if (v->kind != 0) return (v->kind == 3 || v->kind == 4) ? v->inteiro : 0; f = v->a; }
    else {
        DefOf *d = def(p, i); if (!d) return 0;
        if (d->kind != 0) return (d->kind == 3 || d->kind == 4) ? d->a : 0;
        f = ibf(d->a);
    }
    return J2I(f);
}
int32_t J_ParamsOf_tem(void *pp, int32_t i) { return def((P *)pp, i) != NULL; }
int32_t J_ParamsOf_flag(void *pp, int32_t i) {
    P *p = (P *)pp; ValorOf *v = val(p, i);
    if (v) return v->kind == 2 ? v->flag : 0;
    DefOf *d = def(p, i); return d ? d->flag : 0;
}
int32_t J_ParamsOf_corInt(void *pp, int32_t i) {
    P *p = (P *)pp; ValorOf *v = val(p, i);
    if (v && v->kind == 2) return v->inteiro;
    DefOf *d = def(p, i);
    return (d && d->kind == 2) ? d->a : 0;
}
void *J_ParamsOf_texto(void *pp, int32_t i) { ValorOf *v = val((P *)pp, i); return v ? (void *)v->texto : (void *)""; }
int32_t J_ParamsOf_getTipo(void *pp) { return ((P *)pp)->tipo; }
void J_ParamsOf_cor_default(void *pp, int32_t i, void *arr, int32_t k, int32_t mask, void *obj) {
    (void)obj;
    if (mask & 4) k = 0;
    int32_t c = J_ParamsOf_corInt(pp, i);
    float f = K_x18014F27C;
    float *a = (float *)arr;
    a[k] = (float)(c & 255) * f;
    a[k + 1] = (float)((c >> 8) & 255) * f;
    a[k + 2] = (float)((c >> 16) & 255) * f;
}

/* ---------------- FlareOf (o bloco .ofp) ---------------- */

int32_t J_ElementoOf_getTipo(void *e) { return ((C_ElementoOf *)e)->tipo; }
int32_t J_ElementoOf_getSolo(void *e) { return ((C_ElementoOf *)e)->solo; }
int32_t J_ElementoOf_getOculto(void *e) { return ((C_ElementoOf *)e)->oculto; }
void *J_ElementoOf_getParams(void *e) { return ((C_ElementoOf *)e)->params; }
void *J_FlareOf_getElementos(void *f) { return &((C_FlareOf *)f)->elementos; }
void *J_FlareOf_Companion_getTIPOS(void *c) { (void)c; return NULL; }

static uint16_t le16(const uint8_t *b) { return (uint16_t)(b[0] | (b[1] << 8)); }
static int32_t le32(const uint8_t *b) { return (int32_t)((uint32_t)b[0] | ((uint32_t)b[1] << 8) | ((uint32_t)b[2] << 16) | ((uint32_t)b[3] << 24)); }

static int valor(ValorOf *out, const uint8_t *b, int i, int n, int kind) {
    memset(out, 0, sizeof *out);
    out->kind = kind;
    switch (kind) {
    case 0: if (n < 4) return 0; out->a = ibf(le32(b + i)); break;
    case 1: if (n < 8) return 0; out->a = ibf(le32(b + i)); out->b = ibf(le32(b + i + 4)); break;
    case 2: if (n < 8) return 0; out->inteiro = b[i] | (b[i + 1] << 8) | (b[i + 2] << 16); out->flag = le32(b + i + 4); break;
    case 3: if (n < 4) return 0; out->inteiro = le32(b + i); break;
    case 4: if (n < 1) return 0; out->inteiro = b[i]; break;
    case 5: {
        if (n <= 4) return 0;
        int m = n - 4; if (m > 95) m = 95;
        memcpy(out->texto, b + i + 4, (size_t)m); out->texto[m] = 0;
        break;
    }
    default: return 0;
    }
    out->tem = 1;
    return 1;
}

/* FlareOf.ler: "OFP"+versao, depois [u16 tag][u16 tam][dados] em little endian */
static C_FlareOf *flare_ler(const uint8_t *b, int len) {
    if (len < 4 || b[0] != 'O' || b[1] != 'F' || b[2] != 'P') return NULL;
    C_FlareOf *f = ARENA(C_FlareOf, 1);
    f->versao = b[3];
    ValorOf *params = f->globais;
    C_ElementoOf *el = NULL;
    int tipoTem = 0;
    int o = 4, kind = 0, id = 0;
    while (o + 4 <= len) {
        int tag = le16(b + o), n = le16(b + o + 2), d = o + 4;
        if (d + n > len) break;
        if (tag == 1) {
            if (el) { if (n >= 4) { el->tipo = le32(b + d); tipoTem = 1; } else el->tipo = -1; }
        } else if (tag == 2) {
            if (el) { int m = n < 63 ? n : 63; memcpy(el->nome, b + d, (size_t)m); el->nome[m] = 0; }
        } else if (tag == 3) {
            if (el) { int z = 0; for (int k = 0; k < n; k++) if (b[d + k]) z = 1; el->oculto = z; }
        } else if (tag == 4) {
            if (el) { int z = 0; for (int k = 0; k < n; k++) if (b[d + k]) z = 1; el->solo = z; }
        } else if (tag == 1000 || tag == 4000) {
            el = ARENA(C_ElementoOf, 1);
            el->tipo = -1;
            lista_por(&f->elementos, el);
            params = el->params;
        } else if (tag == 50) {
            if (n >= 4) id = le32(b + d);
        } else if (tag == 51) {
            if (n >= 4) kind = le32(b + d);
        } else if (tag == 52) {
            ValorOf v;
            if (kind != 6 && id >= 0 && id < OF_NPARAM && valor(&v, b, d, n, kind)) params[id] = v;
        }
        o = d + n;
    }
    (void)tipoTem;
    /* so os elementos com tipo */
    OFLista l = {0};
    for (int k = 0; k < f->elementos.n; k++) {
        C_ElementoOf *e = (C_ElementoOf *)f->elementos.itens[k];
        if (e->tipo >= 0) lista_por(&l, e);
    }
    f->elementos = l;
    return f;
}

/* ---------------- MotorDoOf.S ---------------- */

void *NEW_MotorDoOf_S(void) { return ARENA(C_MotorDoOf_S, 1); }
void INIT_MotorDoOf_S(void *o, void *p) {
    C_MotorDoOf_S *s = (C_MotorDoOf_S *)o;
    s->p = (P *)p;
    s->f = ARENA(float, 72);
    s->n = ARENA(int32_t, 288);
    s->raios = ARENA(void *, 0);
    s->esps = ARENA(float, 0);
    s->arr = ARENA(float, 0);
}
float J_MotorDoOf_S_get(void *s, int32_t i) { return ((float *)((C_MotorDoOf_S *)s)->f)[i >> 2]; }
void J_MotorDoOf_S_set(void *s, int32_t i, float f) { ((float *)((C_MotorDoOf_S *)s)->f)[i >> 2] = f; }
int32_t J_MotorDoOf_S_i1(void *s, int32_t i) { return ((int32_t *)((C_MotorDoOf_S *)s)->n)[i]; }
void J_MotorDoOf_S_i2(void *s, int32_t i, int32_t v) { ((int32_t *)((C_MotorDoOf_S *)s)->n)[i] = v; }
int32_t J_MotorDoOf_S_b(void *s, int32_t i) { return ((int32_t *)((C_MotorDoOf_S *)s)->n)[i] != 0; }
void *J_MotorDoOf_S_getP(void *s) { return ((C_MotorDoOf_S *)s)->p; }
void *J_MotorDoOf_S_getRaios(void *s) { return ((C_MotorDoOf_S *)s)->raios; }
void J_MotorDoOf_S_setRaios(void *s, void *v) { ((C_MotorDoOf_S *)s)->raios = v; }
void *J_MotorDoOf_S_getEsps(void *s) { return ((C_MotorDoOf_S *)s)->esps; }
void J_MotorDoOf_S_setEsps(void *s, void *v) { ((C_MotorDoOf_S *)s)->esps = v; }
void *J_MotorDoOf_S_getArr(void *s) { return ((C_MotorDoOf_S *)s)->arr; }
void J_MotorDoOf_S_setArr(void *s, void *v) { ((C_MotorDoOf_S *)s)->arr = v; }

/* ---------------- MotorDoOf.Cor ---------------- */

void *NEW_MotorDoOf_Cor(void) { return ARENA(C_MotorDoOf_Cor, 1); }
void INIT_MotorDoOf_Cor(void *o, void *s) {
    C_MotorDoOf_Cor *c = (C_MotorDoOf_Cor *)o;
    c->modo = J_MotorDoOf_S_i1(s, 96);
    c->inv = J_MotorDoOf_S_b(s, 100);
    float *c1 = ARENA(float, 4), *c2 = ARENA(float, 4);
    c1[0] = J_MotorDoOf_S_get(s, 64); c1[1] = J_MotorDoOf_S_get(s, 68); c1[2] = J_MotorDoOf_S_get(s, 72); c1[3] = J_MotorDoOf_S_get(s, 76);
    c2[0] = J_MotorDoOf_S_get(s, 80); c2[1] = J_MotorDoOf_S_get(s, 84); c2[2] = J_MotorDoOf_S_get(s, 88); c2[3] = J_MotorDoOf_S_get(s, 92);
    c->c1 = c1; c->c2 = c2;
    c->s38 = J_MotorDoOf_S_get(s, 56);
    c->s3c = J_MotorDoOf_S_get(s, 60);
}
void J_MotorDoOf_Cor_em(void *co, float f, void *arr) {
    C_MotorDoOf_Cor *c = (C_MotorDoOf_Cor *)co;
    float *a = (float *)arr, *c1 = (float *)c->c1, *c2 = (float *)c->c2;
    if (c->modo == 0) { a[0] = c1[0]; a[1] = c1[1]; a[2] = c1[2]; a[3] = c1[3]; return; }
    if (c->modo != 2) {
        float f2 = fmodf(f, 1.0f);
        if (c->inv) f2 = 1.0f - f2;
        float f3 = K_x18014F258;
        float f4 = f2 + f3;
        float f5 = f2 - f3;
        float fl = f4 - (float)floor((double)f4);
        float t = f5 - (float)floor((double)f5);
        float fl2 = (t * 2.5f) - 1.0f;
        float f6 = (f2 * 2.5f) - 1.0f;
        float f7 = (fl * 2.5f) - 1.0f;
        a[0] = J_Math_max_FF(0.0f, 1.0f - (fl2 * fl2));
        a[1] = J_Math_max_FF(0.0f, 1.0f - (f6 * f6));
        a[2] = J_Math_max_FF(0.0f, 1.0f - (f7 * f7));
        a[3] = J_Math_max_FF(0.0f, 0.0f);
        return;
    }
    float t = f * 2.0f; t = t * K_x18014F25C;
    float s = (MDO_sinf(t) + 1.0f) * 0.5f;
    if (c->inv) s = 1.0f - s;
    float f8 = 1.0f - s;
    float f9 = c1[0] * f8;
    a[0] = (c2[0] * s) + f9;
    a[1] = (c2[1] * s) + (c1[1] * f8);
    a[2] = (c2[2] * s) + (c1[2] * f8);
    a[3] = (s * c2[3]) + (f8 * c1[3]);
}
float J_MotorDoOf_Cor_getS38(void *c) { return ((C_MotorDoOf_Cor *)c)->s38; }
float J_MotorDoOf_Cor_getS3c(void *c) { return ((C_MotorDoOf_Cor *)c)->s3c; }

/* ---------------- Arestas, Resultado, Trabalho ---------------- */

void *NEW_MotorDoOf_Arestas(void) { return ARENA(C_MotorDoOf_Arestas, 1); }
void INIT_MotorDoOf_Arestas(void *o) {
    C_MotorDoOf_Arestas *a = (C_MotorDoOf_Arestas *)o;
    a->xs = ARENA(float, 2); a->dx = ARENA(float, 2); a->va = ARENA(float, 8); a->inc = ARENA(float, 8);
}
void *J_MotorDoOf_Arestas_getXs(void *a) { return ((C_MotorDoOf_Arestas *)a)->xs; }
void *J_MotorDoOf_Arestas_getDx(void *a) { return ((C_MotorDoOf_Arestas *)a)->dx; }
void *J_MotorDoOf_Arestas_getVa(void *a) { return ((C_MotorDoOf_Arestas *)a)->va; }
void *J_MotorDoOf_Arestas_getInc(void *a) { return ((C_MotorDoOf_Arestas *)a)->inc; }

void *NEW_MotorDoOf_Resultado(void) { return ARENA(C_MotorDoOf_Resultado, 1); }
void INIT_MotorDoOf_Resultado(void *o, void *rgba, void *faltou) { (void)faltou; ((C_MotorDoOf_Resultado *)o)->rgba = rgba; }
void *J_MotorDoOf_Trabalho_copiaDe_app(void *t, int32_t n) { (void)t; return ARENA(float, n); }
void *J_MotorDoOf_Trabalho_saidaDe_app(void *t, int32_t n) { (void)t; return ARENA(int8_t, n); }

/* ---------------- Controles ---------------- */
#define CT(c) ((C_MotorDoOf_Controles *)(c))
float J_MotorDoOf_Controles_getPosX(void *c) { return CT(c)->posX; }
float J_MotorDoOf_Controles_getPosY(void *c) { return CT(c)->posY; }
float J_MotorDoOf_Controles_getCentroX(void *c) { return CT(c)->centroX; }
float J_MotorDoOf_Controles_getCentroY(void *c) { return CT(c)->centroY; }
float J_MotorDoOf_Controles_getBrilho(void *c) { return CT(c)->brilho; }
float J_MotorDoOf_Controles_getEscala(void *c) { return CT(c)->escala; }
double J_MotorDoOf_Controles_getRotacao(void *c) { return CT(c)->rotacao; }
int32_t J_MotorDoOf_Controles_getCorR(void *c) { return CT(c)->corR; }
int32_t J_MotorDoOf_Controles_getCorG(void *c) { return CT(c)->corG; }
int32_t J_MotorDoOf_Controles_getCorB(void *c) { return CT(c)->corB; }
int32_t J_MotorDoOf_Controles_getModoCor(void *c) { return CT(c)->modoCor; }
int32_t J_MotorDoOf_Controles_getRender(void *c) { return CT(c)->render; }
float J_MotorDoOf_Controles_getEvolucao(void *c) { return CT(c)->evolucao; }
float J_MotorDoOf_Controles_getTempo(void *c) { return CT(c)->tempo; }
int32_t J_MotorDoOf_Controles_getSemente(void *c) { return CT(c)->semente; }

/* MotorDoOf.Companion.rotacaoAe: (long) rint(d * 65536) % 23592960, em float */
float J_Companion_rotacaoAe(double d) {
    int64_t l = J2L(rint(d * 65536.0)) % 23592960LL;
    float f = (float)l;
    f = f * K_x18014F270;
    return f * K_x18014FD2C;
}

void *NEW_iw6(void) { return ARENA(C_iw6, 1); }
void *NEW_hw6(void) { return ARENA(C_hw6, 1); }
void INIT_iw6(void *o) { (void)o; }
void INIT_hw6(void *o) { (void)o; }
void *NEW_MatematicaDoOf_Reduzido(void) { return ARENA(C_MatematicaDoOf_Reduzido, 1); }
void INIT_MatematicaDoOf_Reduzido(void *o, double r, int32_t n, int64_t rcx) {
    C_MatematicaDoOf_Reduzido *z = (C_MatematicaDoOf_Reduzido *)o; z->r = r; z->n = n; z->rcx = rcx;
}

/* ---------------- lambdas ---------------- */

enum { L_A = 1, L_B, L_C, L_D, L_E, L_F, L_G, Q_IRIS = 100, Q_CIRCULO };
static OFObj *obj(int cls) { OFObj *o = ARENA(OFObj, 1); o->cls = cls; return o; }
void *NEW_a(void) { return obj(L_A); }
void *NEW_b(void) { return obj(L_B); }
void *NEW_c(void) { return obj(L_C); }
void *NEW_d(void) { return obj(L_D); }
void *NEW_e(void) { return obj(L_E); }
void *NEW_f(void) { return obj(L_F); }
void *NEW_g(void) { return obj(L_G); }
#define OC(o) (((OFObj *)(o))->c)
void INIT_a(void *o, float a, float b, float c, float d, void *cor) { R *r = OC(o); r[0].f = a; r[1].f = b; r[2].f = c; r[3].f = d; r[4].o = cor; }
void INIT_b(void *o, float a, int32_t b, float c, void *m, float d, void *cor, int32_t q) {
    R *r = OC(o); r[0].f = a; r[1].i = b; r[2].f = c; r[3].o = m; r[4].f = d; r[5].o = cor; r[6].i = q;
}
void INIT_c(void *o, float a0, float a1, int32_t a2, float a3, float a4, float a5, int32_t a6, float a7, void *m, float a9, void *cor) {
    R *r = OC(o); r[0].f = a0; r[1].f = a1; r[2].i = a2; r[3].f = a3; r[4].f = a4; r[5].f = a5; r[6].i = a6; r[7].f = a7;
    r[8].o = m; r[9].f = a9; r[10].o = cor;
}
void INIT_d(void *o, float a0, float a1, float a2, int32_t a3, float a4, float a5, float a6, float a7, int32_t a8,
            float a9, float a10, float a11, void *m, float a13, float a14, void *cor) {
    R *r = OC(o); r[0].f = a0; r[1].f = a1; r[2].f = a2; r[3].i = a3; r[4].f = a4; r[5].f = a5; r[6].f = a6; r[7].f = a7;
    r[8].i = a8; r[9].f = a9; r[10].f = a10; r[11].f = a11; r[12].o = m; r[13].f = a13; r[14].f = a14; r[15].o = cor;
}
void INIT_e(void *o, float a, void *cor, int32_t q) { R *r = OC(o); r[0].f = a; r[1].o = cor; r[2].i = q; }
void INIT_f(void *o, void *h, float a, void *cor, float b) { R *r = OC(o); r[0].o = h; r[1].f = a; r[2].o = cor; r[3].f = b; }
void INIT_g(void *o, int32_t a, float b, int32_t c, void *cor, float d, float e, float f, float g) {
    R *r = OC(o); r[0].i = a; r[1].f = b; r[2].i = c; r[3].o = cor; r[4].f = d; r[5].f = e; r[6].f = f; r[7].f = g;
}
void *NEW_MotorDoOf_forma_1(void) { return obj(Q_IRIS); }
void *NEW_MotorDoOf_forma_2(void) { return obj(Q_CIRCULO); }
void INIT_MotorDoOf_forma_1(void *o, void *m) { OC(o)[0].o = m; }
void INIT_MotorDoOf_forma_2(void *o, void *m) { OC(o)[0].o = m; }

int32_t J_MotorDoOf_Frag_pixel(void *fr, float x, float y, float u, float v, void *arr) {
    R *r = OC(fr);
    switch (((OFObj *)fr)->cls) {
    case L_A: return mo_glowRender_lambda_4(r[0].f, r[1].f, r[2].f, r[3].f, r[4].o, x, y, u, v, arr);
    case L_B:
        if (r[6].i == 0) return mo_shimmerRender_lambda_0(r[0].f, r[1].i, r[2].f, r[3].o, r[4].f, r[5].o, x, y, u, v, arr);
        return mo_shimmerRender_lambda_1(r[0].f, r[1].i, r[2].f, r[3].o, r[4].f, r[5].o, x, y, u, v, arr);
    case L_C: return mo_irisRender_lambda_0(r[0].f, r[1].f, r[2].i, r[3].f, r[4].f, r[5].f, r[6].i, r[7].f, r[8].o, r[9].f, r[10].o, x, y, u, v, arr);
    case L_D: return mo_circuloRender_lambda_0(r[0].f, r[1].f, r[2].f, r[3].i, r[4].f, r[5].f, r[6].f, r[7].f, r[8].i,
                                              r[9].f, r[10].f, r[11].f, r[12].o, r[13].f, r[14].f, r[15].o, x, y, u, v, arr);
    case L_E:
        if (r[2].i == 0) return mo_sparkleRender_lambda_0(r[0].f, r[1].o, x, y, u, v, arr);
        return mo_spikeBallRender_lambda_0(r[0].f, r[1].o, x, y, u, v, arr);
    case L_F: return mo_streakRender_lambda_0(r[0].o, r[1].f, r[2].o, r[3].f, x, y, u, v, arr);
    case L_G: return mo_hoopRender_lambda_0(r[0].i, r[1].f, r[2].i, r[3].o, r[4].f, r[5].f, r[6].f, r[7].f, x, y, u, v, arr);
    }
    return 0;
}

void *J_qj3_invoke(void *fn, void *s) {
    OFObj *o = (OFObj *)fn;
    if (o->cls == Q_IRIS) mo_irisRender((M *)o->c[0].o, s);
    else if (o->cls == Q_CIRCULO) mo_circuloRender((M *)o->c[0].o, s);
    return NULL;
}

/* ---------------- novaLinha e pintar (o rasterizador junta as linhas e pinta por faixa) ---------------- */

int32_t S_MotorDoOf_MAX_LINHAS = 131072;

void mo_novaLinha(M *m, int32_t y, int32_t x0, int32_t x1, void *a, void *b, void *frag) {
    if (m->nLinhas == S_MotorDoOf_MAX_LINHAS) {
        mo_pintar(m, m->threadsDoQuadro);
        m->nLinhas = 0;
    }
    int32_t n = m->nLinhas;
    if (n == LEN(m->linY)) {
        int32_t n2 = n * 2;
        m->linY = copia(m->linY, n2);
        m->linX0 = copia(m->linX0, n2);
        m->linX1 = copia(m->linX1, n2);
        m->linV = copia(m->linV, n * 16);
        m->linF = copia(m->linF, n2);
    }
    int32_t i6 = m->nLinhas;
    m->nLinhas = i6 + 1;
    ((int32_t *)m->linY)[i6] = y;
    ((int32_t *)m->linX0)[i6] = x0;
    ((int32_t *)m->linX1)[i6] = x1;
    ((void **)m->linF)[i6] = frag;
    float *v = (float *)m->linV, *fa = (float *)a, *fb = (float *)b;
    int32_t k = i6 * 8;
    v[k] = fa[0]; v[k + 1] = fa[1]; v[k + 2] = fa[2]; v[k + 3] = fa[3];
    v[k + 4] = fb[0]; v[k + 5] = fb[1]; v[k + 6] = fb[2]; v[k + 7] = fb[3];
}

typedef struct { int32_t *ini, *ord; M *m; int32_t passo; } Faixa;
static void faixa(void *ctx, size_t k) {
    Faixa *f = (Faixa *)ctx;
    int32_t a = (int32_t)k * f->passo, b = ((int32_t)k + 1) * f->passo;
    if (b > f->m->h) b = f->m->h;
    if (a < b) mo_pintar_faixa(f->ini, f->ord, f->m, a, b);
}

void mo_pintar(M *m, int32_t threads) {
    int32_t n = m->nLinhas;
    if (n == 0) return;
    int32_t h = m->h;
    int32_t *ini = ARENA(int32_t, h + 1);
    int32_t *linY = (int32_t *)m->linY;
    for (int32_t i = 0; i < n; i++) ini[linY[i] + 1]++;
    for (int32_t i = 0; i < h; i++) ini[i + 1] += ini[i];
    int32_t *ord = ARENA(int32_t, n);
    int32_t *pos = copia(ini, h + 1);
    for (int32_t i = 0; i < n; i++) ord[pos[linY[i]]++] = i;
    int32_t t = J_wf6_r(threads, 1, 16);
    if (t > h) t = h;
    if (t <= 1) { mo_pintar_faixa(ini, ord, m, 0, h); return; }
    Faixa f = { ini, ord, m, J_n76_f(h, t, 1, t) };
#ifdef __APPLE__
    dispatch_apply_f((size_t)t, dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), &f, faixa);
#else
    for (int32_t k = 0; k < t; k++) faixa(&f, (size_t)k);
#endif
}

/* ---------------- tabelas (opticalflares/tabelas.bin) ---------------- */

void *S_MatematicaDoOf_log2 = NULL, *S_MatematicaDoOf_exp2 = NULL, *S_MatematicaDoOf_rsq = NULL;

static void *estatico(size_t es, int64_t n) {
    int64_t *h = (int64_t *)calloc(1, 16 + (size_t)n * es);
    h[0] = n; h[1] = (int64_t)es;
    return h + 2;
}

int of_carregar_tabelas(const uint8_t *b, size_t len) {
    if (S_MatematicaDoOf_log2) return 1;
    size_t need = 16384 * 4 + 4 + 262143 + 8192 * 4;
    if (len < need) return 0;
    float *lg = estatico(4, 16384);
    int32_t *ex = estatico(4, 262144);
    int32_t *rs = estatico(4, 8192);
    size_t o = 0;
    for (int i = 0; i < 16384; i++, o += 4) lg[i] = ibf(le32(b + o));
    ex[0] = le32(b + o); o += 4;
    for (int i = 1; i < 262144; i++) ex[i] = (int32_t)((uint32_t)ex[i - 1] + b[o++]);
    for (int i = 0; i < 8192; i++, o += 4) rs[i] = le32(b + o);
    S_MatematicaDoOf_exp2 = ex; S_MatematicaDoOf_rsq = rs; S_MatematicaDoOf_log2 = lg;
    return 1;
}

/* ---------------- entrada ---------------- */

int of_render(const uint8_t *ofp, int ofpLen, const OFControles *c, int w, int h, int threads,
              const uint8_t *rgbaIn, uint8_t *rgbaOut) {
    if (!S_MatematicaDoOf_log2 || w <= 0 || h <= 0) return 0;
    C_FlareOf *fl = flare_ler(ofp, ofpLen);
    if (!fl) { arena_liberar(); return 0; }
    M *m = ARENA(M, 1);
    m->w = w; m->h = h;
    m->flare = fl;
    C_MotorDoOf_Controles *ct = ARENA(C_MotorDoOf_Controles, 1);
    ct->posX = c->posX; ct->posY = c->posY; ct->centroX = c->centroX; ct->centroY = c->centroY;
    ct->brilho = c->brilho; ct->escala = c->escala; ct->rotacao = c->rotacao;
    ct->corR = c->corR; ct->corG = c->corG; ct->corB = c->corB;
    ct->modoCor = c->modoCor; ct->render = c->render;
    ct->evolucao = c->evolucao; ct->tempo = c->tempo; ct->semente = c->semente;
    m->controles = ct;
    m->trabalho = NULL;
    m->faltou = lista_nova();
    m->cf = ARENA(float, 208);
    m->ci = ARENA(int32_t, 208);
    P *g = NEW_ParamsOf(); INIT_ParamsOf(g, 0, fl->globais); m->g = g;
    m->sementeDosOrbs = -1;
    float *acum = ARENA(float, (int64_t)w * h * 4);
    for (int64_t i = 3; i < (int64_t)w * h * 4; i += 4) acum[i] = 1.0f;
    m->acum = acum;
    m->threadsDoQuadro = 1;
    m->linY = ARENA(int32_t, 1024);
    m->linX0 = ARENA(int32_t, 1024);
    m->linX1 = ARENA(int32_t, 1024);
    m->linV = ARENA(float, 8192);
    m->linF = ARENA(void *, 1024);
    int8_t *in = ARENA(int8_t, (int64_t)w * h * 4);
    if (rgbaIn) memcpy(in, rgbaIn, (size_t)w * h * 4);
    void *res = mo_quadro(m, in, threads < 1 ? 1 : threads);
    int ok = 0;
    if (res && ((C_MotorDoOf_Resultado *)res)->rgba) {
        void *out = ((C_MotorDoOf_Resultado *)res)->rgba;
        if (LEN(out) == w * h * 4) { memcpy(rgbaOut, out, (size_t)w * h * 4); ok = 1; }
    }
    arena_liberar();
    return ok;
}
