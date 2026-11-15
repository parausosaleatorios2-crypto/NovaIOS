/* pw_java.h - as funcoes de java.* e kotlin que o pacote do Particle World chama (pw_runtime.c). */
#ifndef PW_JAVA_H
#define PW_JAVA_H
#include <stdint.h>

void *J_Arrays_copyOf__AD_I(void *a, int32_t n);
void *J_Arrays_copyOf__AI_I(void *a, int32_t n);
void J_Arrays_fill__AB_B(void *a, int32_t v);
void *J_Base64_getDecoder__(void);
void *J_Base64_Decoder_decode__String(void *dec, void *s);
int32_t J_Boolean_booleanValue__(void *b);
void *J_Boolean_valueOf__Z(int32_t z);
void *J_ByteBuffer_allocate__I(int32_t n);
void *J_ByteBuffer_array__(void *bb);
void *J_ByteBuffer_clear__(void *bb);
double J_ByteBuffer_getDouble__I(void *bb, int32_t i);
float J_ByteBuffer_getFloat__I(void *bb, int32_t i);
int32_t J_ByteBuffer_getInt__I(void *bb, int32_t i);
int32_t J_ByteBuffer_get__I(void *bb, int32_t i);
void *J_ByteBuffer_order__ByteOrder(void *bb, void *ordem);
void *J_ByteBuffer_putDouble__I_D(void *bb, int32_t i, double v);
void *J_ByteBuffer_putFloat__I_F(void *bb, int32_t i, float v);
void *J_ByteBuffer_putInt__I_I(void *bb, int32_t i, int32_t v);
void *J_ByteBuffer_put__AB(void *bb, void *a);
void *J_ByteBuffer_put__I_B(void *bb, int32_t i, int32_t v);
void *J_CameraDoPw_camera__I_I(void *cam, int32_t t, int32_t escala);
double J_Double_doubleValue__(void *b);
void *J_Double_valueOf__D(double d);
float J_Float_intBitsToFloat__I(int32_t i);
int32_t J_FonteDoPw_valor__I_I_I_I(void *f, int32_t idx, int32_t t, int32_t passo, int32_t escala);
int32_t J_Integer_compareUnsigned__I_I(int32_t a, int32_t b);
void *J_Integer_valueOf__I(int32_t i);
double J_Math_abs__D(double a);
double J_Math_atan2__D_D(double y, double x);
double J_Math_cos__D(double a);
int32_t J_Math_min__I_I(int32_t a, int32_t b);
double J_Math_sin__D(double a);
double J_Math_sqrt__D(double a);
double J_Math_tan__D(double a);
void *J_NEW_h46(void);
void *J_NEW_iq7(void);
void *J_NEW_ju4(void);
double J_Number_doubleValue__(void *b);
int32_t J_Number_intValue__(void *b);
void J_Object_init__(void *o);
void J_System_arraycopy__Object_I_Object_I_I(void *src, int32_t sp, void *dst, int32_t dp, int32_t n);
void *J_bl4_getValue__(void *lazy);
double J_c10_a__D_D_D_D(double a, double b, double c, double d);
double J_c10_b__Bloco_I_D_D(void *bloco, int32_t i, double a, double b);
double J_fx0_A__D_D_D_D(double a, double b, double c, double d);
void J_h46_init__Object_Object(void *p, void *f, void *g);
void J_iq7_init__fj3(void *o, void *f);
void J_ju4_init__I(void *o, int32_t i);
void J_m84_h0__String(void *s);
double J_n76_C__D_D_D_D(double a, double b, double c, double d);
double J_n76_a__D_D_D_D(double a, double b, double c, double d);
float J_n76_b__F_F_F_F(float a, float b, float c, float d);
float J_ru5_A__F_F_F_F(float a, float b, float c, float d);
float J_ru5_w__F_F_F_F(float a, float b, float c, float d);
void *J_qj3_invoke__Object(void *l, void *a);
double J_t66_z0__I(int32_t i);
void *J_uj3_invoke__Object_Object(void *l, void *a, void *b);
void *J_vj3_invoke__Object_Object_Object(void *l, void *a, void *b, void *c);

#endif
