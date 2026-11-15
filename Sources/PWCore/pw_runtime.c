/*
 * pw_runtime.c - arena, java.* / kotlin e a API do motor do CC Particle World (PWCore.h).
 */
#include "pw_gerado.h"
#include "include/PWCore.h"
#include <setjmp.h>
#include <pthread.h>

/* ---------------- arena: blocos encadeados, com marca ---------------- */

typedef struct Bloco_ { struct Bloco_ *prox; size_t tam, usado; } BlocoA;
static BlocoA *pw_primeiro, *pw_atual;
static BlocoA *pw_marcaBloco; static size_t pw_marcaUsado;

static BlocoA *novo_bloco(size_t min) {
    size_t tam = min > (64u << 20) ? min : (64u << 20);
    BlocoA *b = (BlocoA *)malloc(sizeof(BlocoA) + tam);
    if (!b) return NULL;
    b->prox = NULL; b->tam = tam; b->usado = 0;
    return b;
}

static jmp_buf pw_salto;
static int pw_dentro = 0;

void pw_falha(const char *motivo) {
    (void)motivo;
    if (pw_dentro) longjmp(pw_salto, 1);
    abort();
}

static void *pw_bruto(size_t n) {
    n = (n + 15) & ~(size_t)15;
    if (!pw_atual) { pw_primeiro = pw_atual = novo_bloco(n); if (!pw_atual) pw_falha("memoria"); }
    while (pw_atual->usado + n > pw_atual->tam) {
        if (!pw_atual->prox) { pw_atual->prox = novo_bloco(n); if (!pw_atual->prox) pw_falha("memoria"); }
        pw_atual = pw_atual->prox;
        pw_atual->usado = 0;
    }
    void *p = (uint8_t *)(pw_atual + 1) + pw_atual->usado;
    pw_atual->usado += n;
    memset(p, 0, n);
    return p;
}

void *pw_arena(size_t esize, int64_t n) {
    if (n < 0) pw_falha("tamanho negativo");
    int64_t *h = (int64_t *)pw_bruto(16 + esize * (size_t)(n > 0 ? n : 1));
    h[0] = n; h[1] = (int64_t)esize;
    return h + 2;
}

void *pw_novo(size_t tam) { return pw_bruto(tam); }

static void pw_marcar(void) { pw_marcaBloco = pw_atual; pw_marcaUsado = pw_atual ? pw_atual->usado : 0; }
static void pw_voltar(void) {
    if (!pw_marcaBloco) { pw_atual = pw_primeiro; if (pw_atual) pw_atual->usado = 0; return; }
    pw_atual = pw_marcaBloco; pw_atual->usado = pw_marcaUsado;
    /* os blocos de depois ficam para o proximo quadro (zerados ao entrar) */
    for (BlocoA *b = pw_atual->prox; b; b = b->prox) b->usado = 0;
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
int32_t JDIV32(int32_t a, int32_t b) { if (b == 0) pw_falha("divisao por zero"); if (a == INT32_MIN && b == -1) return a; return a / b; }
int32_t JREM32(int32_t a, int32_t b) { if (b == 0) pw_falha("divisao por zero"); if (b == -1) return 0; return a % b; }
int64_t JDIV64(int64_t a, int64_t b) { if (b == 0) pw_falha("divisao por zero"); if (a == INT64_MIN && b == -1) return a; return a / b; }
int64_t JREM64(int64_t a, int64_t b) { if (b == 0) pw_falha("divisao por zero"); if (b == -1) return 0; return a % b; }

/* ---------------- java.* / kotlin ---------------- */

static PWCaixa caixaV = {1, 1}, caixaF = {0, 0};
void *S_Boolean_TRUE = &caixaV, *S_Boolean_FALSE = &caixaF, *S_ByteOrder_LITTLE_ENDIAN = &caixaV;

static void *copia(void *a, int32_t n) {
    if (!a) pw_falha("null");
    size_t es = ESIZE(a);
    void *b = pw_arena(es, n);
    int32_t m = LEN(a) < n ? LEN(a) : n;
    if (m > 0) memcpy(b, a, es * (size_t)m);
    return b;
}
void *J_Arrays_copyOf__AD_I(void *a, int32_t n) { return copia(a, n); }
void *J_Arrays_copyOf__AI_I(void *a, int32_t n) { return copia(a, n); }
void J_Arrays_fill__AB_B(void *a, int32_t v) { if (!a) pw_falha("null"); memset(a, (int8_t)v, (size_t)LEN(a)); }

void *J_Base64_getDecoder__(void) { return &caixaV; }
static int b64v(int c) {
    if (c >= 'A' && c <= 'Z') return c - 'A';
    if (c >= 'a' && c <= 'z') return c - 'a' + 26;
    if (c >= '0' && c <= '9') return c - '0' + 52;
    if (c == '+' || c == '-') return 62;
    if (c == '/' || c == '_') return 63;
    return -1;
}
void *J_Base64_Decoder_decode__String(void *dec, void *s) {
    (void)dec;
    const char *t = (const char *)s;
    size_t n = strlen(t);
    int8_t *out = ARENA(int8_t, (int64_t)(n / 4 * 3 + 3));
    int32_t k = 0; uint32_t acc = 0; int bits = 0;
    for (size_t i = 0; i < n; i++) {
        int v = b64v((unsigned char)t[i]);
        if (v < 0) continue;
        acc = (acc << 6) | (uint32_t)v; bits += 6;
        if (bits >= 8) { bits -= 8; out[k++] = (int8_t)((acc >> bits) & 0xff); }
    }
    ((int64_t *)out)[-2] = k;
    return out;
}

int32_t J_Boolean_booleanValue__(void *b) { return b ? ((PWCaixa *)b)->i != 0 : 0; }
void *J_Boolean_valueOf__Z(int32_t z) { return z ? S_Boolean_TRUE : S_Boolean_FALSE; }
void *J_Integer_valueOf__I(int32_t i) { PWCaixa *c = NEWOBJ(PWCaixa); c->i = i; c->d = i; return c; }
void *J_Double_valueOf__D(double d) { PWCaixa *c = NEWOBJ(PWCaixa); c->d = d; c->i = (int64_t)J2L(d); return c; }
double J_Double_doubleValue__(void *b) { if (!b) pw_falha("null"); return ((PWCaixa *)b)->d; }
double J_Number_doubleValue__(void *b) { if (!b) pw_falha("null"); return ((PWCaixa *)b)->d; }
int32_t J_Number_intValue__(void *b) { if (!b) pw_falha("null"); return (int32_t)((PWCaixa *)b)->i; }

void *J_ByteBuffer_allocate__I(int32_t n) { PWByteBuffer *b = NEWOBJ(PWByteBuffer); b->a = ARENA(int8_t, n); return b; }
void *J_ByteBuffer_array__(void *bb) { return ((PWByteBuffer *)bb)->a; }
void *J_ByteBuffer_clear__(void *bb) { ((PWByteBuffer *)bb)->pos = 0; return bb; }
static int8_t *em(void *bb, int32_t i, int32_t n) {
    PWByteBuffer *b = (PWByteBuffer *)bb;
    if (i < 0 || i + n > LEN(b->a)) pw_falha("ByteBuffer fora");
    return b->a + i;
}
double J_ByteBuffer_getDouble__I(void *bb, int32_t i) { double v; memcpy(&v, em(bb, i, 8), 8); return v; }
float J_ByteBuffer_getFloat__I(void *bb, int32_t i) { float v; memcpy(&v, em(bb, i, 4), 4); return v; }
int32_t J_ByteBuffer_getInt__I(void *bb, int32_t i) { int32_t v; memcpy(&v, em(bb, i, 4), 4); return v; }
int32_t J_ByteBuffer_get__I(void *bb, int32_t i) { return *em(bb, i, 1); }
void *J_ByteBuffer_order__ByteOrder(void *bb, void *o) { (void)o; return bb; }
void *J_ByteBuffer_putDouble__I_D(void *bb, int32_t i, double v) { memcpy(em(bb, i, 8), &v, 8); return bb; }
void *J_ByteBuffer_putFloat__I_F(void *bb, int32_t i, float v) { memcpy(em(bb, i, 4), &v, 4); return bb; }
void *J_ByteBuffer_putInt__I_I(void *bb, int32_t i, int32_t v) { memcpy(em(bb, i, 4), &v, 4); return bb; }
void *J_ByteBuffer_put__I_B(void *bb, int32_t i, int32_t v) { *em(bb, i, 1) = (int8_t)v; return bb; }
void *J_ByteBuffer_put__AB(void *bb, void *a) {
    PWByteBuffer *b = (PWByteBuffer *)bb;
    int32_t n = LEN(a);
    memcpy(em(bb, b->pos, n), a, (size_t)n);
    b->pos += n;
    return bb;
}

/* camera da comp: o Swift ainda nao passa (o Effect Camera do proprio efeito funciona) */
void *J_CameraDoPw_camera__I_I(void *cam, int32_t t, int32_t escala) { (void)cam; (void)t; (void)escala; return NULL; }

float J_Float_intBitsToFloat__I(int32_t i) { float f; memcpy(&f, &i, 4); return f; }
int32_t J_FonteDoPw_valor__I_I_I_I(void *f, int32_t idx, int32_t t, int32_t passo, int32_t escala) {
    PWFonte *ft = (PWFonte *)f;
    if (!ft || !ft->fn) pw_falha("sem fonte");
    return ft->fn(ft->ctx, idx, t, passo, escala);
}
int32_t J_Integer_compareUnsigned__I_I(int32_t a, int32_t b) {
    uint32_t x = (uint32_t)a, y = (uint32_t)b;
    return x < y ? -1 : (x == y ? 0 : 1);
}
double J_Math_abs__D(double a) { return fabs(a); }
double J_Math_atan2__D_D(double y, double x) { return atan2(y, x); }
double J_Math_cos__D(double a) { return cos(a); }
int32_t J_Math_min__I_I(int32_t a, int32_t b) { return a < b ? a : b; }
double J_Math_sin__D(double a) { return sin(a); }
double J_Math_sqrt__D(double a) { return sqrt(a); }
double J_Math_tan__D(double a) { return tan(a); }

void *J_NEW_h46(void) { return NEWOBJ(C_h46); }
void *J_NEW_iq7(void) { return NEWOBJ(PWCaixa); }
void *J_NEW_ju4(void) { return NEWOBJ(PWCaixa); }
void J_h46_init__Object_Object(void *p, void *f, void *g) { ((C_h46 *)p)->f = f; ((C_h46 *)p)->g = g; }
void J_iq7_init__fj3(void *o, void *f) { (void)o; (void)f; }
void J_ju4_init__I(void *o, int32_t i) { (void)o; (void)i; }
void J_Object_init__(void *o) { (void)o; }

void J_System_arraycopy__Object_I_Object_I_I(void *src, int32_t sp, void *dst, int32_t dp, int32_t n) {
    if (!src || !dst) pw_falha("null");
    if (n < 0 || sp < 0 || dp < 0 || sp + n > LEN(src) || dp + n > LEN(dst)) pw_falha("arraycopy fora");
    size_t es = ESIZE(src);
    memmove((uint8_t *)dst + es * (size_t)dp, (uint8_t *)src + es * (size_t)sp, es * (size_t)n);
}

/* o "by lazy" de SEQ_BYTES: decodifica uma vez (no arena permanente, antes da marca) */
static void *pw_seq = NULL;
void *J_bl4_getValue__(void *lazy) {
    (void)lazy;
    if (!pw_seq) pw_seq = pw_MotorDoPw_SEQ_BYTES_delegate_lambda_0__();
    return pw_seq;
}

double J_c10_a__D_D_D_D(double a, double b, double c, double d) { return ((a * b) + c) * d; }
double J_c10_b__Bloco_I_D_D(void *bloco, int32_t i, double a, double b) { return (pw_Bloco_d__I(bloco, i) * a) + b; }
double J_fx0_A__D_D_D_D(double a, double b, double c, double d) { return ((a - b) * c) + d; }
double J_n76_C__D_D_D_D(double a, double b, double c, double d) { return (a * b) + c + d; }
double J_n76_a__D_D_D_D(double a, double b, double c, double d) { return (a * b * c) + d; }
float J_n76_b__F_F_F_F(float a, float b, float c, float d) { return (c - (a * b)) * d; }
float J_ru5_A__F_F_F_F(float a, float b, float c, float d) { return ((a * b) + c) * d; }
float J_ru5_w__F_F_F_F(float a, float b, float c, float d) { return ((a - b) * c) + d; }
double J_t66_z0__I(int32_t i) {
    uint32_t u = (uint32_t)i;
    return ((double)(int32_t)((u >> 31) << 30)) * 2.0 + (double)(i & INT32_MAX);
}
void J_m84_h0__String(void *s) { (void)s; pw_falha("lateinit"); }
void *J_qj3_invoke__Object(void *l, void *a) { (void)l; (void)a; pw_falha("lambda"); return NULL; }
void *J_uj3_invoke__Object_Object(void *l, void *a, void *b) { (void)l; (void)a; (void)b; pw_falha("lambda"); return NULL; }
void *J_vj3_invoke__Object_Object_Object(void *l, void *a, void *b, void *c) { (void)l; (void)a; (void)b; (void)c; return NULL; }

/* ---------------- API ---------------- */

static pthread_mutex_t pw_trava = PTHREAD_MUTEX_INITIALIZER;
static int pw_iniciado = 0;

static void *mundo(int w, int h) {
    C_MundoPw *m = NEWOBJ(C_MundoPw);
    pw_MundoPw_init__I_I(m, w, h);
    return m;
}
/* RGBA (de cima para baixo) -> o ARGB do MundoPw */
static void para_mundo(const uint8_t *rgba, C_MundoPw *m) {
    int8_t *px = (int8_t *)m->px;
    size_t n = (size_t)m->w * (size_t)m->h;
    for (size_t i = 0; i < n; i++) {
        px[i * 4] = (int8_t)rgba[i * 4 + 3];
        px[i * 4 + 1] = (int8_t)rgba[i * 4];
        px[i * 4 + 2] = (int8_t)rgba[i * 4 + 1];
        px[i * 4 + 3] = (int8_t)rgba[i * 4 + 2];
    }
}

int pw_render(const uint8_t *rgbaIn, int w, int h, uint8_t *rgbaOut,
              int32_t t, int32_t escala, int32_t resolucao1000,
              PWFonteFn fonte, void *ctx,
              const uint8_t *texRgba, int tw, int th) {
    if (w < 1 || h < 1 || !rgbaOut || !fonte) return 0;
    pthread_mutex_lock(&pw_trava);
    int ok = 0;
    pw_dentro = 1;
    if (setjmp(pw_salto) == 0) {
        if (!pw_iniciado) {
            pw_clinits();
            (void)J_bl4_getValue__(NULL);
            pw_marcar();
            pw_iniciado = 1;
        }
        pw_voltar();
        C_MotorDoPw *motor = NEWOBJ(C_MotorDoPw);
        pw_MotorDoPw_init__(motor);
        PWFonte *f = NEWOBJ(PWFonte); f->fn = fonte; f->ctx = ctx;
        pw_MotorDoPw_setFonte__FonteDoPw(motor, f);
        C_MundoPw *ent = (C_MundoPw *)mundo(w, h);
        if (rgbaIn) para_mundo(rgbaIn, ent);
        pw_MotorDoPw_setEntrada__MundoPw(motor, ent);
        C_MundoPw *sai = (C_MundoPw *)mundo(w, h);
        pw_MotorDoPw_setSaida__MundoPw(motor, sai);
        if (texRgba && tw > 0 && th > 0) {
            C_MundoPw *tx = (C_MundoPw *)mundo(tw, th);
            para_mundo(texRgba, tx);
            pw_MotorDoPw_setTextura__MundoPw(motor, tx);
        } else {
            pw_MotorDoPw_setTextura__MundoPw(motor, NULL);
        }
        pw_MotorDoPw_setFornecerTextura__vj3(motor, NULL);
        pw_MotorDoPw_setCameraDaComp__CameraDoPw(motor, NULL);
        int32_t r = resolucao1000 < 50 ? 50 : (resolucao1000 > 1000 ? 1000 : resolucao1000);
        C_EntradaPw *e = NEWOBJ(C_EntradaPw);
        pw_EntradaPw_init__I_I_I_I_Z_I_I_I_I_I_I_I(e, t, 1000, 1000, escala, 1, 0, 1, 1, r, 1000, r, 1000);
        pw_MotorDoPw_render__EntradaPw(motor, e);
        C_MundoPw *s = (C_MundoPw *)motor->saida;
        const int8_t *px = (const int8_t *)s->px;
        size_t n = (size_t)w * (size_t)h;
        for (size_t i = 0; i < n; i++) {
            rgbaOut[i * 4] = (uint8_t)px[i * 4 + 1];
            rgbaOut[i * 4 + 1] = (uint8_t)px[i * 4 + 2];
            rgbaOut[i * 4 + 2] = (uint8_t)px[i * 4 + 3];
            rgbaOut[i * 4 + 3] = (uint8_t)px[i * 4];
        }
        ok = 1;
    }
    pw_dentro = 0;
    pthread_mutex_unlock(&pw_trava);
    return ok;
}

int32_t pw_fixo(double v) { return (int32_t)rint(v * 65536.0); }
int32_t pw_cor(int r, int g, int b) { return (int32_t)(((uint32_t)r << 8) | 255u | ((uint32_t)g << 16) | ((uint32_t)b << 24)); }
