#!/usr/bin/env python3
"""
glsl2msl.py - Tradutor de shaders do NovaEditor: GLSL ES 3.0 -> Metal Shading Language.

Le os XMLs de efeito do NovaEditor (assets/effects/*.xml), extrai os parametros e o
corpo do shader, e emite um arquivo .metal por efeito com:
  - struct de uniforms (do <params>)
  - argumentos de textura (dos <texture>)
  - a funcao fragment traduzida

Nao depende de nada alem da biblioteca padrao. Projetado para o dialeto especifico
deste app: o corpo do shader nao tem #version nem declaracoes de uniform; o motor
injeta tudo. Os uniforms do motor (acScreenNorm, acPass, ...) viram campos de um
struct comum, EngineUniforms.

Uso:
  python3 -I glsl2msl.py ENTRADA_DIR -o SAIDA_DIR [--relatorio rel.csv] [-v]
  python3 -I glsl2msl.py ENTRADA_DIR --so-relatorio
"""

import os, re, sys, csv, json, argparse, logging, collections
import xml.etree.ElementTree as ET

log = logging.getLogger("glsl2msl")

# --------------------------------------------------------------------------- tipos
TIPOS = {
    "vec2":"float2","vec3":"float3","vec4":"float4",
    "ivec2":"int2","ivec3":"int3","ivec4":"int4",
    "uvec2":"uint2","uvec3":"uint3","uvec4":"uint4",
    "bvec2":"bool2","bvec3":"bool3","bvec4":"bool4",
    "mat2":"float2x2","mat3":"float3x3","mat4":"float4x4",
    "mat2x2":"float2x2","mat3x3":"float3x3","mat4x4":"float4x4",
    "mat2x3":"float3x2","mat3x2":"float2x3",
    "mat2x4":"float4x2","mat4x2":"float2x4",
    "mat3x4":"float4x3","mat4x3":"float3x4",
}

# funcoes com nome diferente em MSL
FUNCS = {
    "inversesqrt":"rsqrt",
    "dFdx":"dfdx", "dFdy":"dfdy",
    "fract":"fract", "mix":"mix", "clamp":"clamp",
    "smoothstep":"smoothstep", "step":"step",
    "matrixCompMult":"__nv_matCompMult",
    "roundEven":"rint",
    "floatBitsToInt":"as_type<int>",
    "floatBitsToUint":"as_type<uint>",
    "intBitsToFloat":"as_type<float>",
    "uintBitsToFloat":"as_type<float>",
}

# funcoes que existem igual nos dois (nao mexer)
IGUAIS = {
 "abs","sign","floor","ceil","round","trunc","min","max","pow","exp","exp2","log","log2",
 "sqrt","sin","cos","tan","asin","acos","sinh","cosh","tanh","radians","degrees",
 "dot","cross","normalize","length","distance","reflect","refract","faceforward",
 "transpose","determinant","fwidth","isnan","isinf","modf","frexp","ldexp",
 "any","all","not","equal","notEqual","lessThan","greaterThan",
 "lessThanEqual","greaterThanEqual","select",
}

PALAVRAS_RESERVADAS = {
 "if","else","for","while","do","return","break","continue","discard","switch","case",
 "default","struct","const","in","out","inout","void","bool","int","uint","float",
 "true","false","lowp","mediump","highp","precision","uniform","varying","attribute",
 "layout","flat","smooth","noperspective","centroid","sample","patch","invariant",
 "sampler2D","sampler3D","samplerCube","texture2D","textureCube",
}

# uniforms injetados pelo motor
ENGINE_UNIFORMS = {
    # --- float2 (tamanhos, pontos, normalizados) -----------------------------
    "acScreenSize":"float2", "acTela":"float2",
    "acTamanhoDaTela":"float2", "acResolution":"float2", "acPreviewSize":"float2",
    "acTexelSize":"float2", "acLayerSize":"float2", "acTamanhoDaCamada":"float2",
    "acCamada":"float2", "acLayerCenter":"float2",
    "acLayerCenterNorm":"float2", "acEntradaDePe":"float2", "acLayerNormAm":"float2",
    "acPivoDoAm":"float2", "acLayerPivot":"float2", "acCentroDaCamadaPx":"float2",
    "acCentroDaCamada":"float2", "acCentroDaCamadaNorm":"float2",
    "acCaixaDoTexto":"float2", "acProjectSize":"float2", "acLayerSizeNorm":"float2",
    "acVelocidadeDoAm":"float2", "acVelocity":"float2", "acPontoNoBuffer":"float2",
    "acBufferNoPonto":"float2", "acTamanhoDoTexto":"float2", "acFolgaDaCamada":"float2",
    "acEscalaPorQuadroDoAm":"float2", "acProporcaoDoNode":"float2",
    # --- float3 --------------------------------------------------------------
    "acCameraOlho":"float3", "acCameraOlhoNova":"float3",
    # --- float4x4 (matrizes) -------------------------------------------------
    "acLayerToScreen":"float4x4", "acCamadaParaTela":"float4x4", "acParaTela":"float4x4",
    "acLTS":"float4x4", "acScreenToLayer":"float4x4", "acCameraInvVP":"float4x4",
    "acCamera3D":"float4x4", "acCamadaNaTela":"float4x4", "acCamadaPropria":"float4x4",
    # --- int -----------------------------------------------------------------
    "acPass":"int", "acIteration":"int", "acIterationCount":"int", "acAmostras":"int",
    "acShowGuides":"int", "acStateFresh":"int",
    # --- float ---------------------------------------------------------------
    "acTime":"float", "acAspect":"float", "acEscalaDePixel":"float",
    "acFrameDuration":"float", "acRascunho":"float", "acDeltaNivel":"float",
    "acAngularVelocity":"float", "acGiroPorQuadroDoAm":"float", "acProgress":"float",
    # acDeltaNivel e acDirParaUv NAO entram: sao funcoes definidas dentro dos shaders.
}

# varyings vindos do vertex (efeitos convertidos do NodeVideo)
VARYINGS = {
    # coordenadas por pixel — vem do vertex, nao do buffer de uniforms
    "acScreenNorm":"float2", "acLayerNorm":"float2", "acLayerNormAm":"float2",
    "vs_TEXCOORD0":"float2", "vs_TEXCOORD1":"float2", "vs_TEXCOORD2":"float2",
    "vs_TEXCOORD3":"float2", "vs_TEXCOORD4":"float2", "vs_TEXCOORD5":"float2",
    "vs_COLOR0":"float4",
}

# tipo MSL de cada tipo de parametro do XML
PARAM_MSL = {
    "slider":"float", "spinner":"float", "float":"float", "hue-disc":"float",
    "switch":"int", "checkbox":"int", "selector":"int", "cycle":"int",
    "color":"float4", "point":"float2", "xyz":"float3", "orient":"float4",
    "curve":"float4", "flare":"float4", "gradacao":"float4",
    "node-grading":"float4", "lut":"float4", "malha":"float4",
}

# builtins do dialeto Alight Motion
AM_BUILTINS = {
    "getTexSize":      "__nv_getTexSize",
    "vertShaderInit":  "__nv_vertShaderInit",
    "acTela":          "__nv_acTela",
    "acPontoNoBuffer": "__nv_acPontoNoBuffer",
}

HELPERS = r"""
// ---------------------------------------------------------------- helpers
// Gerado por glsl2msl.py. GLSL mod() nao e fmod(): difere para negativos.
inline float  __nv_mod(float x, float y)   { return x - y * floor(x / y); }
inline float2 __nv_mod(float2 x, float2 y) { return x - y * floor(x / y); }
inline float3 __nv_mod(float3 x, float3 y) { return x - y * floor(x / y); }
inline float4 __nv_mod(float4 x, float4 y) { return x - y * floor(x / y); }
inline float2 __nv_mod(float2 x, float y)  { return x - y * floor(x / y); }
inline float3 __nv_mod(float3 x, float y)  { return x - y * floor(x / y); }
inline float4 __nv_mod(float4 x, float y)  { return x - y * floor(x / y); }

// atan(y,x) do GLSL -> atan2; atan(x) continua atan.
inline float  __nv_atan(float y, float x)  { return atan2(y, x); }
inline float2 __nv_atan(float2 y, float2 x){ return float2(atan2(y.x,x.x), atan2(y.y,x.y)); }
inline float3 __nv_atan(float3 y, float3 x){ return float3(atan2(y.x,x.x), atan2(y.y,x.y), atan2(y.z,x.z)); }
inline float  __nv_atan(float x)           { return atan(x); }
inline float2 __nv_atan(float2 x)          { return atan(x); }
inline float3 __nv_atan(float3 x)          { return atan(x); }

// MSL nao tem inverse() de matriz.
inline float2x2 __nv_inverse(float2x2 m) {
    float d = m[0][0]*m[1][1] - m[0][1]*m[1][0];
    float i = (abs(d) < 1e-20f) ? 0.0f : 1.0f / d;
    return float2x2(float2( m[1][1]*i, -m[0][1]*i), float2(-m[1][0]*i,  m[0][0]*i));
}
inline float3x3 __nv_inverse(float3x3 m) {
    float3 a = m[0], b = m[1], c = m[2];
    float3 r0 = cross(b, c), r1 = cross(c, a), r2 = cross(a, b);
    float d = dot(a, r0);
    float i = (abs(d) < 1e-20f) ? 0.0f : 1.0f / d;
    return float3x3(float3(r0.x,r1.x,r2.x)*i, float3(r0.y,r1.y,r2.y)*i, float3(r0.z,r1.z,r2.z)*i);
}
inline float4x4 __nv_inverse(float4x4 m) {
    float a00=m[0][0],a01=m[0][1],a02=m[0][2],a03=m[0][3];
    float a10=m[1][0],a11=m[1][1],a12=m[1][2],a13=m[1][3];
    float a20=m[2][0],a21=m[2][1],a22=m[2][2],a23=m[2][3];
    float a30=m[3][0],a31=m[3][1],a32=m[3][2],a33=m[3][3];
    float b00=a00*a11-a01*a10, b01=a00*a12-a02*a10, b02=a00*a13-a03*a10;
    float b03=a01*a12-a02*a11, b04=a01*a13-a03*a11, b05=a02*a13-a03*a12;
    float b06=a20*a31-a21*a30, b07=a20*a32-a22*a30, b08=a20*a33-a23*a30;
    float b09=a21*a32-a22*a31, b10=a21*a33-a23*a31, b11=a22*a33-a23*a32;
    float det=b00*b11-b01*b10+b02*b09+b03*b08-b04*b07+b05*b06;
    float i=(abs(det)<1e-20f)?0.0f:1.0f/det;
    return float4x4(
      float4(( a11*b11-a12*b10+a13*b09)*i, (-a01*b11+a02*b10-a03*b09)*i,
             ( a31*b05-a32*b04+a33*b03)*i, (-a21*b05+a22*b04-a23*b03)*i),
      float4((-a10*b11+a12*b08-a13*b07)*i, ( a00*b11-a02*b08+a03*b07)*i,
             (-a30*b05+a32*b02-a33*b01)*i, ( a20*b05-a22*b02+a23*b01)*i),
      float4(( a10*b10-a11*b08+a13*b06)*i, (-a00*b10+a01*b08-a03*b06)*i,
             ( a30*b04-a31*b02+a33*b00)*i, (-a20*b04+a21*b02-a23*b00)*i),
      float4((-a10*b09+a11*b07-a12*b06)*i, ( a00*b09-a01*b07+a02*b06)*i,
             (-a30*b03+a31*b01-a32*b00)*i, ( a20*b03-a21*b01+a22*b00)*i));
}

// Dialeto Alight Motion.
inline float2 __nv_getTexSize(float2 s) { return s; }
inline void   __nv_vertShaderInit() { }
// No AM a UV da tela tem t = 0 EMBAIXO; no Metal tem t = 0 EM CIMA.
inline float2 __nv_acTela(float2 uv) { return float2(uv.x, 1.0f - uv.y); }
inline float2 __nv_acPontoNoBuffer(float2 p) { return p; }

inline float2x2 __nv_matCompMult(float2x2 a, float2x2 b){ return float2x2(a[0]*b[0], a[1]*b[1]); }
inline float3x3 __nv_matCompMult(float3x3 a, float3x3 b){ return float3x3(a[0]*b[0], a[1]*b[1], a[2]*b[2]); }
inline float4x4 __nv_matCompMult(float4x4 a, float4x4 b){ return float4x4(a[0]*b[0], a[1]*b[1], a[2]*b[2], a[3]*b[3]); }
"""


def tirar_comentarios(src):
    """Remove // e /* */ sem tocar no conteudo de strings."""
    out = []; i = 0; n = len(src)
    while i < n:
        c = src[i]
        if c == '"':
            j = i + 1
            while j < n and src[j] != '"':
                j += 2 if src[j] == "\\" else 1
            out.append(src[i:j+1]); i = j + 1
        elif c == "/" and i + 1 < n and src[i+1] == "/":
            j = src.find("\n", i)
            j = n if j < 0 else j
            out.append(" " * (j - i)); i = j
        elif c == "/" and i + 1 < n and src[i+1] == "*":
            j = src.find("*/", i + 2)
            j = n if j < 0 else j + 2
            out.append(" " if "\n" not in src[i:j] else "\n" * src[i:j].count("\n"))
            i = j
        else:
            out.append(c); i += 1
    return "".join(out)


class Efeito:
    """Um efeito lido do XML."""
    def __init__(self, path):
        self.path = path
        self.arquivo = os.path.basename(path)
        self.slug = re.sub(r"[^a-zA-Z0-9]", "_", os.path.splitext(self.arquivo)[0])
        self.id = None; self.nome = None; self.categoria = None
        self.params = []      # (tipo_xml, id)
        self.texturas = []    # id
        self.passes = 0
        self.iterativo = False
        self.shader = None
        self.erro = None
        self._ler()

    def _ler(self):
        try:
            raw = open(self.path, "rb").read().decode("utf-8", "replace")
            raw = re.sub(r"<\?xml[\s\S]*?\?>", "", raw, count=1).strip()
            root = ET.fromstring(raw)
        except Exception as e:
            self.erro = "xml: %s" % str(e)[:120]; return
        a = root.attrib
        self.id = a.get("id"); self.nome = a.get("name"); self.categoria = a.get("category")
        vistos = set()
        for ps in root.findall("params"):
            for p in ps.iter():
                if p is ps: continue
                pid = p.attrib.get("id")
                if not pid or pid in vistos: continue
                if p.tag == "texture":
                    vistos.add(pid); self.texturas.append(pid)
                elif p.tag in PARAM_MSL:
                    vistos.add(pid); self.params.append((p.tag, pid))
        pz = root.find("passes")
        self.passes = len(list(pz)) if pz is not None else 1
        self.iterativo = root.find("iterations") is not None
        sh = root.find("shader")
        if sh is not None and sh.text and sh.text.strip():
            self.shader = sh.text
        else:
            self.erro = self.erro or "sem shader"


class Tradutor:
    def __init__(self, efeito):
        self.e = efeito
        self.avisos = []
        self.nao_resolvidos = set()
        self.usa_am = False
        self.sombreados = []

    # -------------------------------------------------- utilidades
    @staticmethod
    def _split_args(s):
        """Divide os argumentos de uma chamada respeitando parenteses e colchetes."""
        out = []; d = 0; cur = ""
        for ch in s:
            if ch in "([{": d += 1
            elif ch in ")]}": d -= 1
            if ch == "," and d == 0:
                out.append(cur); cur = ""
            else:
                cur += ch
        if cur.strip() or out: out.append(cur)
        return [x.strip() for x in out]

    @staticmethod
    def _find_call(src, name, start=0):
        """Acha name( ... ) e devolve (ini, abre, fecha) ou None."""
        pat = re.compile(r"\b%s\s*\(" % re.escape(name))
        m = pat.search(src, start)
        if not m: return None
        abre = m.end() - 1
        d = 0
        for i in range(abre, len(src)):
            if src[i] == "(": d += 1
            elif src[i] == ")":
                d -= 1
                if d == 0:
                    return (m.start(), abre, i)
        return None

    def _rewrite_calls(self, src, name, fn):
        """Reescreve todas as chamadas de `name` usando fn(args)->str."""
        pos = 0
        while True:
            loc = self._find_call(src, name, pos)
            if not loc: break
            ini, abre, fecha = loc
            args = self._split_args(src[abre+1:fecha])
            novo = fn(args)
            if novo is None:
                pos = fecha + 1; continue
            src = src[:ini] + novo + src[fecha+1:]
            pos = ini + len(novo)
        return src

    # -------------------------------------------------- passos
    def _proteger_strings(self, s):
        self._str_store = []
        def rep(m):
            self._str_store.append(m.group(0))
            return "\x00S%d\x00" % (len(self._str_store)-1)
        return re.sub(r'"(?:[^"\\]|\\.)*"', rep, s)

    def _restaurar_strings(self, s):
        for i, v in enumerate(self._str_store):
            s = s.replace("\x00S%d\x00" % i, v)
        return s

    def _tipos(self, s):
        for g, m in TIPOS.items():
            s = re.sub(r"\b%s\b" % g, m, s)
        # precisao do GLSL nao existe em MSL
        s = re.sub(r"\b(lowp|mediump|highp)\s+", "", s)
        s = re.sub(r"^\s*precision\s+\w+\s+\w+\s*;\s*$", "", s, flags=re.M)
        return s

    def _texturas(self, s):
        tex = set(self.e.texturas)
        # texture(sampler, uv [, bias]) -> sampler.sample(smp, uv)
        def f_texture(args):
            if len(args) < 2: return None
            t = args[0].strip()
            if t not in tex:
                self.avisos.append("texture() em '%s' que nao e <texture> declarada" % t)
            if len(args) >= 3:
                return "%s.sample(__nv_smp, %s, bias(%s))" % (t, args[1], args[2])
            return "%s.sample(__nv_smp, %s)" % (t, args[1])
        s = self._rewrite_calls(s, "texture", f_texture)

        def f_textureLod(args):
            if len(args) < 3: return None
            return "%s.sample(__nv_smp, %s, level(%s))" % (args[0], args[1], args[2])
        s = self._rewrite_calls(s, "textureLod", f_textureLod)

        def f_texelFetch(args):
            if len(args) < 2: return None
            lod = args[2] if len(args) >= 3 else "0"
            return "%s.read(uint2(%s), uint(%s))" % (args[0], args[1], lod)
        s = self._rewrite_calls(s, "texelFetch", f_texelFetch)

        def f_textureSize(args):
            if not args: return None
            t = args[0]
            return "int2(int(%s.get_width()), int(%s.get_height()))" % (t, t)
        s = self._rewrite_calls(s, "textureSize", f_textureSize)

        # texture2D legado
        def f_texture2D(args):
            if len(args) < 2: return None
            return "%s.sample(__nv_smp, %s)" % (args[0], args[1])
        s = self._rewrite_calls(s, "texture2D", f_texture2D)
        return s

    def _dialeto_am(self, s):
        """Dialeto do Alight Motion: texturas sao structs com .texture/.size/.transform,
        e a amostragem e texture2DCv(). Usado por 664 dos 1.490 efeitos."""
        tex = list(self.e.texturas)
        usou = False
        for t in tex:
            esc = re.escape(t)
            if re.search(r"\b%s\s*\.\s*(texture|size|transform|matrix)\b" % esc, s):
                usou = True
            # X.texture -> X   (a propria texture2d)
            s = re.sub(r"\b%s\s*\.\s*texture\b" % esc, t, s)
            # X.size -> info.size ; X.transform -> info.transform
            s = re.sub(r"\b%s\s*\.\s*size\b" % esc, "%s_info.size" % t, s)
            s = re.sub(r"\b%s\s*\.\s*(transform|matrix)\b" % esc, "%s_info.transform" % t, s)
        self.usa_am = usou
        # texture2DCv / texture2DCvCv -> sample
        def f_cv(args):
            if len(args) < 2: return None
            return "%s.sample(__nv_smp, %s)" % (args[0].strip(), args[1])
        s = self._rewrite_calls(s, "texture2DCvCv", f_cv)
        s = self._rewrite_calls(s, "texture2DCv", f_cv)
        return s

    def _funcoes(self, s):
        # mod -> __nv_mod (semantica do GLSL)
        s = self._rewrite_calls(s, "mod", lambda a: "__nv_mod(%s)" % ", ".join(a) if len(a) == 2 else None)
        # atan 1 ou 2 argumentos
        s = self._rewrite_calls(s, "atan", lambda a: "__nv_atan(%s)" % ", ".join(a) if 1 <= len(a) <= 2 else None)
        # inverse
        s = self._rewrite_calls(s, "inverse", lambda a: "__nv_inverse(%s)" % a[0] if len(a) == 1 else None)
        for g, m in FUNCS.items():
            if g in ("mod","atan","inverse"): continue
            s = re.sub(r"\b%s\s*\(" % re.escape(g), m + "(", s)
        for g, m in AM_BUILTINS.items():
            s = re.sub(r"\b%s\s*\(" % re.escape(g), m + "(", s)
        return s

    def _builtins(self, s):
        s = re.sub(r"\bgl_FragCoord\b", "__nv_fragCoord", s)
        s = re.sub(r"\bgl_FragColor\b", "__nv_out", s)
        s = re.sub(r"\bfragColor\b", "__nv_out", s)
        s = re.sub(r"\bgl_PointCoord\b", "__nv_pointCoord", s)
        s = re.sub(r"\bdiscard\b(?!\s*_)", "discard_fragment()", s)
        return s

    def _locais(self, src):
        """Identificadores que o proprio shader declara (funcoes, variaveis, #define).
        Esses NUNCA sao prefixados: um `float acScreenSize = ...` local vence o uniform."""
        src = tirar_comentarios(src)
        nomes = set()
        tipos = "|".join(re.escape(t) for t in (set(TIPOS.values()) |
                 {"float","int","uint","bool","void","half","vec2","vec3","vec4",
                  "mat2","mat3","mat4","ivec2","ivec3","ivec4"}))
        for m in re.finditer(r"\b(?:%s)\s+([A-Za-z_]\w*)\s*\(" % tipos, src):
            nomes.add(m.group(1))                       # funcoes locais
        for m in re.finditer(r"\b(?:const\s+)?(?:%s)\s+([^;{}()]+?);" % tipos, src):
            for parte in m.group(1).split(","):
                w = re.match(r"\s*([A-Za-z_]\w*)", parte)
                if w: nomes.add(w.group(1))             # variaveis locais
        for m in re.finditer(r"^\s*#\s*define\s+([A-Za-z_]\w*)", src, re.M):
            nomes.add(m.group(1))                       # macros
        return nomes

    def _uniformes(self, s):
        """Prefixa params do XML com u. e uniforms do motor com eng.
        Pula tudo que o shader declara por conta propria."""
        locais = self._locais(s)
        self.sombreados = sorted(locais & (set(ENGINE_UNIFORMS) | set(VARYINGS)
                                           | {p for _, p in self.e.params}))
        for _, pid in self.e.params:
            if pid in locais: continue
            s = re.sub(r"(?<![\w.])%s\b" % re.escape(pid), "u.%s" % pid, s)
        for name in ENGINE_UNIFORMS:
            if name in locais: continue
            s = re.sub(r"(?<![\w.])%s\b" % re.escape(name), "eng.%s" % name, s)
        for name in VARYINGS:
            if name in locais: continue
            s = re.sub(r"(?<![\w.])%s\b" % re.escape(name), "in.%s" % name, s)
        return s

    def _identificadores_soltos(self, corpo):
        """Procura identificadores que nao foram resolvidos (sinal de traducao incompleta)."""
        corpo = tirar_comentarios(corpo)
        declarados = set()
        # nomes definidos por #define (com ou sem argumentos)
        for m in re.finditer(r"^\s*#\s*define\s+([A-Za-z_]\w*)", corpo, re.M):
            declarados.add(m.group(1))
        for m in re.finditer(r"^\s*#\s*define\s+[A-Za-z_]\w*\s*\(([^)]*)\)", corpo, re.M):
            for a in m.group(1).split(","):
                if a.strip(): declarados.add(a.strip())
        # linhas de preprocessador nao sao codigo
        corpo = re.sub(r"^\s*#.*$", "", corpo, flags=re.M)
        # variaveis declaradas: tipo nome
        tipos_msl = set(TIPOS.values()) | {"float","int","uint","bool","void","half"}
        rx_tipos = "|".join(re.escape(t) for t in tipos_msl)
        # "float a, b[3], c = 1.0;" -> a, b, c
        for m in re.finditer(r"\b(?:const\s+)?(?:%s)\s+([^;{}()]+?);" % rx_tipos, corpo):
            for parte in m.group(1).split(","):
                w = re.match(r"\s*([A-Za-z_]\w*)", parte)
                if w: declarados.add(w.group(1))
        for m in re.finditer(r"\b(?:%s)\s+([A-Za-z_]\w*)" % rx_tipos, corpo):
            declarados.add(m.group(1))
        # for (int i = 0; ...)
        for m in re.finditer(r"for\s*\(\s*(?:const\s+)?(?:%s)\s+([A-Za-z_]\w*)" % rx_tipos, corpo):
            declarados.add(m.group(1))
        # parametros de funcoes locais
        for m in re.finditer(r"\b[A-Za-z_]\w*\s*\(([^)]*)\)\s*\{", corpo):
            for a in m.group(1).split(","):
                w = a.strip().split()
                if len(w) >= 2: declarados.add(w[-1].strip("[]"))
        # nomes de funcoes locais
        for m in re.finditer(r"\b(?:%s)\s+([A-Za-z_]\w*)\s*\(" % "|".join(re.escape(t) for t in tipos_msl), corpo):
            declarados.add(m.group(1))
        conhecidos = (declarados | PALAVRAS_RESERVADAS | IGUAIS | set(TIPOS.values())
                      | set(FUNCS.values()) | set(self.e.texturas)
                      | {"u","eng","__nv_out","__nv_fragCoord","__nv_pointCoord","__nv_smp",
                         "bias","level","sample","read","get_width","get_height",
                         "discard_fragment","float","int","uint","bool","half",
                         "as_type","main","xyz","xy","rgb","rgba","xyzw","rg","st","uv"}
                      | {"__nv_mod","__nv_atan","__nv_inverse","__nv_matCompMult",
                         "__nv_getTexSize","__nv_vertShaderInit","size","transform",
                         "NovaTexInfo","EngineUniforms","NovaVertexOut","position","in"}
                      | set(VARYINGS)
                      | {"%s_info" % t for t in self.e.texturas})
        soltos = set()
        for m in re.finditer(r"(?<![\w.])([A-Za-z_]\w*)", corpo):
            w = m.group(1)
            if w in conhecidos: continue
            if w.startswith("__nv_"): continue
            if re.match(r"^(float|int|uint|bool)\d?x?\d?$", w): continue
            soltos.add(w)
        return soltos

    # -------------------------------------------------- saida
    def traduzir(self):
        e = self.e
        if e.shader is None:
            return None, ["sem shader"]
        s = e.shader
        s = self._proteger_strings(s)
        s = self._tipos(s)
        s = self._dialeto_am(s)
        s = self._texturas(s)
        s = self._funcoes(s)
        s = self._builtins(s)
        s = self._uniformes(s)
        s = self._restaurar_strings(s)

        # main() do GLSL vira corpo da funcao fragment
        m = re.search(r"\bvoid\s+main\s*\(\s*(?:void)?\s*\)\s*\{", s)
        if not m:
            return None, ["sem void main()"]
        ini = m.end() - 1
        d = 0; fim = None
        for i in range(ini, len(s)):
            if s[i] == "{": d += 1
            elif s[i] == "}":
                d -= 1
                if d == 0: fim = i; break
        if fim is None:
            return None, ["main() sem fecho"]
        pre = s[:m.start()].strip()      # funcoes auxiliares antes do main
        corpo = s[ini+1:fim]

        # Validacao: o MSL gerado tem de ter delimitadores equilibrados.
        # Alguns XMLs de origem tem chave dentro de comentario e ficam quebrados;
        # emitir isso so faria a build do Xcode falhar sem explicacao.
        for texto, nome in ((pre, "antes do main"), (corpo, "dentro do main")):
            limpo = tirar_comentarios(texto)
            for ab, fe, rotulo in (("{", "}", "chaves"), ("(", ")", "parenteses")):
                if limpo.count(ab) != limpo.count(fe):
                    return None, ["%s desequilibradas %s (%d x %d) no shader de origem"
                                  % (rotulo, nome, limpo.count(ab), limpo.count(fe))]

        # `return;` do GLSL (void main) tem de devolver a cor no MSL.
        corpo = re.sub(r"\breturn\s*;", "return __nv_out;", corpo)

        self.nao_resolvidos = self._identificadores_soltos(pre + "\n" + corpo)

        # struct de uniforms do efeito
        campos = []
        for tipo, pid in e.params:
            campos.append("    %s %s;" % (PARAM_MSL[tipo], pid))
        struct_u = ("struct %sParams {\n%s\n};" % (e.slug, "\n".join(campos))) if campos \
                   else ("struct %sParams { int __vazio; };" % e.slug)

        # argumentos de textura
        texargs = ""
        for i, t in enumerate(e.texturas):
            texargs += ",\n    texture2d<float> %s [[texture(%d)]]" % (t, i)
        if getattr(self, "usa_am", False):
            for i, t in enumerate(e.texturas):
                texargs += ",\n    constant NovaTexInfo& %s_info [[buffer(%d)]]" % (t, 2 + i)

        cab = []
        cab.append("// ---------------------------------------------------------------------------")
        cab.append("// %s" % (e.nome or e.arquivo))
        cab.append("// origem : assets/effects/%s" % e.arquivo)
        cab.append("// id     : %s" % (e.id or "-"))
        cab.append("// passes : %d%s" % (e.passes, "  (iterativo)" if e.iterativo else ""))
        cab.append("// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo")
        cab.append("// ---------------------------------------------------------------------------")

        out = []
        out.append("\n".join(cab))
        out.append('#include <metal_stdlib>')
        out.append('#include "NovaEngineUniforms.h"')
        out.append('#include "NovaShaderHelpers.h"')
        out.append("using namespace metal;")
        out.append("")
        out.append(struct_u)
        out.append("")
        if pre:
            out.append("// --- funcoes auxiliares do efeito")
            out.append(pre)
            out.append("")
        out.append("fragment float4 fx_%s(" % e.slug)
        out.append("    NovaVertexOut       in   [[stage_in]],")
        out.append("    constant EngineUniforms& eng [[buffer(0)]],")
        out.append("    constant %sParams&  u    [[buffer(1)]]," % e.slug)
        out.append("    sampler             __nv_smp [[sampler(0)]]%s)" % texargs)
        out.append("{")
        out.append("    float4 __nv_fragCoord = in.position;")
        out.append("    float2 __nv_pointCoord = in.uv;")
        out.append("    float4 __nv_out = float4(0.0);")
        out.append(corpo.rstrip())
        out.append("    return __nv_out;")
        out.append("}")
        return "\n".join(out) + "\n", self.avisos


def main():
    ap = argparse.ArgumentParser(description="Traduz os shaders do NovaEditor de GLSL ES 3.0 para MSL")
    ap.add_argument("entrada", help="pasta com os XMLs de efeito")
    ap.add_argument("-o","--saida", default=None, help="pasta de saida dos .metal")
    ap.add_argument("--relatorio", default=None, help="CSV com o resultado por efeito")
    ap.add_argument("--so-relatorio", action="store_true", help="nao escreve .metal")
    ap.add_argument("--limite", type=int, default=0)
    ap.add_argument("-v","--verbose", action="store_true")
    a = ap.parse_args()
    logging.basicConfig(level=logging.DEBUG if a.verbose else logging.WARNING,
                        format="%(levelname)s %(message)s")

    if not os.path.isdir(a.entrada):
        print("ERRO: pasta inexistente: %s" % a.entrada, file=sys.stderr); return 2
    if a.saida and not a.so_relatorio:
        os.makedirs(a.saida, exist_ok=True)

    arquivos = sorted(f for f in os.listdir(a.entrada) if f.endswith(".xml"))
    if a.limite: arquivos = arquivos[:a.limite]

    linhas = []
    n_ok = n_sem = n_erro = 0
    total_soltos = collections.Counter()
    registry = []

    for f in arquivos:
        e = Efeito(os.path.join(a.entrada, f))
        if e.erro and e.shader is None:
            if e.erro == "sem shader":
                n_sem += 1
                linhas.append([f, e.id or "", e.nome or "", "sem-shader", 0, 0, 0, ""])
            else:
                n_erro += 1
                linhas.append([f, "", "", "erro-xml", 0, 0, 0, e.erro])
            continue
        t = Tradutor(e)
        try:
            msl, avisos = t.traduzir()
        except Exception as ex:
            n_erro += 1
            linhas.append([f, e.id or "", e.nome or "", "erro-traducao", 0, 0, 0, str(ex)[:120]])
            log.debug("falha em %s: %s", f, ex)
            continue
        if msl is None:
            n_erro += 1
            linhas.append([f, e.id or "", e.nome or "", "erro-traducao", 0, 0, 0, ";".join(avisos)])
            continue
        soltos = sorted(t.nao_resolvidos)
        for s_ in soltos: total_soltos[s_] += 1
        estado = "ok" if not soltos else "revisar"
        n_ok += 1
        if a.saida and not a.so_relatorio:
            open(os.path.join(a.saida, "fx_%s.metal" % e.slug), "w", encoding="utf-8").write(msl)
        registry.append({"arquivo": f, "slug": e.slug, "id": e.id, "nome": e.nome,
                         "categoria": e.categoria, "funcao": "fx_%s" % e.slug,
                         "passes": e.passes, "iterativo": e.iterativo,
                         "texturas": e.texturas,
                         "params": [{"tipo": tp, "id": pid} for tp, pid in e.params],
                         "estado": estado, "nao_resolvidos": soltos,
                         "dialeto": "alight-motion" if t.usa_am else "novaeditor",
                         "sombreados": t.sombreados})
        linhas.append([f, e.id or "", e.nome or "", estado, len(e.params), len(e.texturas),
                       e.passes, ",".join(soltos[:8])])

    if a.saida and not a.so_relatorio:
        open(os.path.join(a.saida, "NovaShaderHelpers.h"), "w", encoding="utf-8").write(
            "#pragma once\n#include <metal_stdlib>\nusing namespace metal;\n" + HELPERS)
        campos = "\n".join("    %s %s;" % (t_, n_) for n_, t_ in sorted(ENGINE_UNIFORMS.items()))
        open(os.path.join(a.saida, "NovaEngineUniforms.h"), "w", encoding="utf-8").write(
            "#pragma once\n#include <metal_stdlib>\nusing namespace metal;\n\n"
            "// Uniforms injetados pelo motor em todo shader de efeito.\n"
            "struct EngineUniforms {\n%s\n};\n\n"
            "struct NovaVertexOut {\n    float4 position [[position]];\n    float2 uv;\n};\n"
            % campos)
        json.dump(registry, open(os.path.join(a.saida, "registro.json"), "w", encoding="utf-8"),
                  ensure_ascii=False, indent=1)

    if a.relatorio:
        with open(a.relatorio, "w", newline="", encoding="utf-8") as fh:
            w = csv.writer(fh)
            w.writerow(["arquivo","id","nome","estado","params","texturas","passes","nao_resolvidos"])
            w.writerows(linhas)

    rev = sum(1 for l in linhas if l[3] == "revisar")
    lim = sum(1 for l in linhas if l[3] == "ok")
    print("arquivos .................. %d" % len(arquivos))
    print("traduzidos limpos ......... %d" % lim)
    print("traduzidos p/ revisar ..... %d" % rev)
    print("sem shader (so params) .... %d" % n_sem)
    print("falhas .................... %d" % n_erro)
    if total_soltos:
        print("\nidentificadores nao resolvidos mais comuns:")
        for k, v in total_soltos.most_common(25):
            print("  %5d  %s" % (v, k))
    return 0

if __name__ == "__main__":
    sys.exit(main())
