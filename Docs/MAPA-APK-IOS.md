# Mapa: app Android (APK 0.918.0) × porte iOS

Levantado com o REA (JADX 0.7.1) no APK `NovaEditor-0.918.0.apk`
(sha256 `b9b0507f…5971`, 10.493 classes). Os pacotes `com.novaeditor.*` têm nomes
legíveis; o resto (render, UI) está ofuscado. Atualizado em 2026-11-08.

Legenda: ✅ feito · 🟡 parcial · ❌ falta

Três sessões trabalham em paralelo: editor/motor (esta), efeitos (shaders) e
perfil/conta/marketplace/templates.

## Núcleo do editor

| Área no APK | Classes | iOS |
|---|---|---|
| `model.Transform` (âncora, posição+Z, escala, rotação X/Y/Z, opacidade, skew) | `Transform`, `Mat4` | ✅ matriz igual a `buildMatrix`; gizmo e painel com keyframes |
| `model.Animated` / `Keyframe` / `Easing` | `Animated`, `Keyframe`, `Easing`, `AjustesDeInterpolacao`, `CurvaAvancada` | 🟡 keyframes + 11 interpolações por chave (linear, segurar, suave, entrada/saída, cúbica, expo, recuo, elástico, quicar); falta gráfico de curva com alças |
| `model.LayerContent` (Media, Text, Solid, Shape, Audio, Camera, Luz, Nulo, Group, Model3D, Midi, Osso, Adjustment) | 13 tipos | 🟡 Media, Text, Solid, Shape (vetorial), Audio, Nulo, Adjustment ✅; Camera/Luz/Group/3D/Midi/Osso ❌ |
| Mídia: `remap`, `reversed`, `emLaco`, `speed` animado, `gain`, `matte` | `LayerContent.Media`, `MatteDeVideo`, `MapaDeTempo`, `SpeedRamp` | 🟡 velocidade, mudo, invertido, laço e corte de início ✅; remapeamento, rampa e matte ❌ |
| `model.BlendMode` | 30 modos | ✅ todos no shader, lendo o fundo real |
| Máscaras | `LayerMask`, `MaskShape`, `MaskMode`, `MascaraDeAlfa` | ✅ retângulo, elipse, polígono, estrela; adicionar/subtrair/interseção/diferença; inverter, suavizar, expandir, animáveis |
| Pais / grupos | `parentID`, `Reparentar`, `MolduraDoGrupo` | ✅ escolher pai no painel (sem ciclos); grupos ❌ |
| Desfazer | `UndoHistory` | ✅ desfazer/refazer (60 passos) |
| Marcadores | `Marker`, `Markers` | ✅ marcadores da composição na régua |

## Efeitos

| Área | iOS |
|---|---|
| 1.490 XMLs (`assets/effects`) | ✅ idênticos ao APK (verificado com `verify_reconstruction`: PASS) |
| Shaders GLSL → Metal | 🟡 ~945 compilam; a sonda do CI mede quais renderizam certo |
| Parâmetros (slider, switch, seletor, cor, ponto) | ✅ no painel de propriedades, animáveis |
| Parâmetros curva, gradação, LUT, malha, flare | ❌ |
| Texturas de outra camada (`src="layer"`), áudio, espectro | ❌ entram transparentes |
| Presets de efeito (`PredefinicaoDoEfeito`, `ui.presets`) | ❌ |

## Texto

| Área | Classes | iOS |
|---|---|---|
| Texto básico | `SourceText` | ✅ texto, tamanho, cor |
| Animadores do AE | `AnimadorDeTexto`, `SeletorDeFaixa`, `SeletorOscilante`, `SeletorDeExpressao`, `TransformacaoDeGlifo`, `LetraAnimada` | 🟡 6 animações de entrada por letra/palavra; seletores completos do AE ❌ |
| Fontes | `fontes.CatalogoDeFontes`, 47 fontes em `assets/fonts` | ✅ fontes do APK + do sistema; alinhamento, contorno, sombra, espaçamento |
| Legendas automáticas | `MontadorDeLegendas`, `EstilosDeLegenda`, `cloud.LegendasResposta` | ❌ (depende da nuvem) |

## Motores grandes

| Área | Classes | iOS |
|---|---|---|
| Element 3D | `model.element3d.*` (~40) | ❌ |
| Optical Flares | `model.opticalflares.*` | ❌ |
| Partículas (CC Particle World) | `model.ccparticleworld.*` | ❌ |
| CC Ball Action | `model.ccballaction.*` | ❌ |
| Puppet | `PuppetArap`, `PuppetPin`, `MotorDoPuppet` | ❌ |
| Rastreamento / câmera (SfM) | `model.sfm.*`, `MotionTrack`, `TrackedBlob` | ❌ |
| Física / estilhaço | `SimulacaoDaFisica`, `FisicaDoEstilhaco` | ❌ |
| MIDI | `LeitorDeMidi`, `VisualizadorDeMidi` | ❌ |

## App

| Área | Pacote | iOS |
|---|---|---|
| Importar mídia | — | ✅ galeria, várias de uma vez |
| Exportar | `export.ServicoDeExportacao` | ✅ vídeo H.264/HEVC/alfa + áudio, GIF, PNG; PSD ❌ |
| Projeto `.nova` | `persistence.*Dto` | ✅ importa `.nova` do Android (ConversorAndroid); duplicar/exportar/apagar projeto |
| Importar After Effects | `aeimport.*` | ❌ |
| Nuvem, conta, biblioteca, IA, marketplace | `cloud.*`, `biblioteca.*` | 🟡 Perfil, conta (Firebase) e Marketplace (comunidade e biblioteca); IA, legendas e export na nuvem ❌ |
| Layouts Nova/CapCut/Motion/AE | `layout.*` | 🟡 só Nova; cores do tema iguais às do APK (#00ff89, cartões #141625); disposição das telas sem captura de referência |
| Templates | `templates.*` | ✅ templates do APK (`Resources/templates`) |

## Próximos, por impacto

1. Remapeamento de tempo e rampa de velocidade.
2. Gráfico de curva com alças de Bézier.
3. Grupos / pré-composições.
4. Seletores de texto do AE (faixa, oscilante, expressão).
5. Presets de efeito e templates.
6. Motores grandes, um por vez: Partículas, Optical Flares, Element 3D, Puppet, rastreamento.
