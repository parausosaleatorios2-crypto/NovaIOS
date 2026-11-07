# Nova Editor para iOS

Porte do app Android **Nova Editor 0.918.0** (`com.novavision.editor.apk`) para iPhone e iPad.

APK de origem — SHA-256 `b9b0507f63ce841b5d85cad59c960ca504562b2bb7a35f9fe491c5d745125971`

---

## ⚠️ Leia isto primeiro

**Este pacote não contém um IPA, e nenhum IPA pode ser gerado a partir dele sem um Mac.**

Compilar para iOS exige o toolchain da Apple, que só existe no macOS. Não há como
contornar: nem com Linux, nem com Docker, nem com conversor. O que está aqui é o
projeto-fonte, pronto para abrir no Xcode.

**Este pacote também não é o app completo.** O app Android tem 1.327 classes de
domínio compiladas em bytecode — código-fonte que não existe em lugar nenhum
recuperável. O que foi reconstruído em Swift está listado abaixo, e o que falta
está em `Docs/PENDENCIAS.md`. Leia os dois antes de planejar prazo.

---

## O que está pronto e funciona

| Peça | Arquivo | Estado |
|---|---|---|
| Tradutor GLSL ES 3.0 → Metal | `Tools/glsl2msl.py` | **completo** |
| 1.438 shaders traduzidos | `Shaders/fx_*.metal` | 1.259 limpos, 179 a revisar |
| Parser dos XMLs de efeito | `Sources/NovaEngine/EffectManifest.swift` | completo |
| Catálogo dos 1.490 efeitos | `Sources/NovaEngine/EffectRegistry.swift` | completo |
| Motor de efeitos em Metal | `Sources/NovaEngine/EffectRenderer.swift` | completo |
| Keyframes, easing, curvas do Flow | `Sources/NovaEngine/Animated.swift` | completo |
| Modelo de projeto e camadas | `Sources/NovaEngine/ProjectModel.swift` | completo |
| Formato `.nova` (ZIP + JSON) | `Sources/NovaEngine/NovaProjectIO.swift` | grava e lê |
| Compositor de quadro | `Sources/NovaEngine/Compositor.swift` | escrito, sem provedor de mídia |
| Decode e export de vídeo | `Sources/NovaEngine/VideoPipeline.swift` | escrito, não exercitado |
| Tela Início, 4 abas | `Sources/NovaUI/HomeView.swift` | estrutura pronta |
| Editor, timeline, barra de baixo | `Sources/NovaUI/EditorView.swift` | estrutura pronta |
| Navegador de efeitos | `Sources/NovaUI/EffectBrowserView.swift` | funciona |
| 169 MB de assets do APK | `Resources/` | cópia integral |
| 6.872 strings PT→EN | `Resources/i18n/en.json` | o arquivo original |
| Testes do motor | `Tests/NovaEngineTests/` | 25 testes |

---

## Compilar

Precisa de: **Mac com macOS 14+**, **Xcode 15.4+** e, para instalar no aparelho,
uma **conta de desenvolvedor Apple**.

```bash
brew install xcodegen
cd NovaEditor-iOS
xcodegen generate
open NovaEditor.xcodeproj
```

No Xcode: selecione o alvo `NovaEditor`, aba **Signing & Capabilities**, escolha
o seu **Team**. Depois ⌘R para rodar no simulador ou no aparelho.

Para gerar o IPA:

```bash
xcodebuild -project NovaEditor.xcodeproj -scheme NovaEditor \
  -configuration Release -sdk iphoneos \
  -archivePath build/NovaEditor.xcarchive archive

xcodebuild -exportArchive -archivePath build/NovaEditor.xcarchive \
  -exportOptionsPlist ExportOptions.plist -exportPath build/
```

Detalhes e problemas conhecidos em `Docs/COMPILAR.md`.

### Primeira compilação demora

São 1.438 arquivos `.metal`. A primeira build da metallib leva de 10 a 25 minutos
dependendo do Mac. As seguintes são incrementais.

---

## Regenerar os shaders

Os `.metal` são **gerados**, não escritos à mão. Para mudar um efeito, mude o XML
em `Resources/effects/` e rode:

```bash
python3 -I Tools/glsl2msl.py Resources/effects -o Shaders \
        --relatorio Docs/relatorio-shaders.csv
```

O relatório diz, efeito por efeito, se a tradução saiu limpa ou precisa de olho.

---

## Como o motor de efeitos funciona

Igual ao Android: o efeito **não é código**, é dado.

```
Resources/effects/nv-blurrr-box.xml      ← parâmetros, passes, GLSL
          ↓ glsl2msl.py (em build)
Shaders/fx_nv_blurrr_box.metal           ← fragment em MSL
          ↓ em tempo de execução
EffectManifest  lê o XML  → parâmetros e passes
EffectRenderer  monta uniforms, resolve texturas, roda os passes
```

Por isso os 1.490 XMLs vieram **inalterados** do APK. Trocar um efeito não exige
recompilar Swift — só regerar o `.metal`.

### Os dois dialetos

O app carrega efeitos de duas origens, com dialetos de shader diferentes:

- **NovaEditor** (868 arquivos): `fragColor`, `texture(sampler, uv)`
- **Alight Motion** (664 arquivos): `gl_FragColor`, `texture2DCv(tex.texture, uv)`,
  texturas como struct com `.texture`, `.size`, `.transform`

O tradutor cobre os dois. 90 arquivos misturam os dois e também passam.

---

## Aviso sobre os efeitos de terceiros

**639 dos 1.490 efeitos trazem `id="com.alightcreative.effect.*"`** — o pacote do
Alight Motion. Outros 31 são portes de plugins do After Effects, 21 do Sapphire
(Boris FX) e 10 do Boris Continuum. Um XML traz, no próprio texto, a marca
«MODDED BY TOJI X ES8N» e um convite de Telegram.

Tecnicamente eles portam como qualquer outro. **Distribuir isso é outra questão** —
e a App Store rejeita. Essa decisão é do dono do projeto e precisa ser tomada antes
de montar o pacote de efeitos para publicação.

---

## Estrutura

```
NovaEditor-iOS/
├── LEIA-ME.md                 este arquivo
├── project.yml                XcodeGen
├── Package.swift              SwiftPM, para testar o motor sem o app
├── Sources/
│   ├── NovaEngine/            motor: efeitos, keyframes, projeto, vídeo
│   ├── NovaUI/                SwiftUI: início, editor, timeline, efeitos
│   └── NovaApp/               ponto de entrada
├── Shaders/
│   ├── fx_*.metal             1.438 efeitos traduzidos
│   ├── NovaFullscreen.metal   vertex compartilhado
│   ├── NovaBlend.metal        modos de mesclagem do AE
│   ├── NovaEngineUniforms.h   gerado
│   └── NovaShaderHelpers.h    gerado
├── Resources/                 169 MB — os assets do APK, sem alteração
├── Tools/glsl2msl.py          o tradutor
├── Tests/NovaEngineTests/     testes do motor
└── Docs/
    ├── PENDENCIAS.md          o que falta, item por item
    ├── COMPILAR.md            passo a passo no Mac
    ├── ARQUITETURA.md         mapa Android → iOS
    └── relatorio-shaders.csv  estado de cada um dos 1.490
```
