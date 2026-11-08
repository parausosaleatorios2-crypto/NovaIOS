# Mapa: app Android (APK 0.918.0) × porte iOS

Levantado com o REA (JADX 0.7.1) no APK `NovaEditor-0.918.0.apk`
(sha256 `b9b0507f…5971`, 10.493 classes). Os pacotes `com.novaeditor.*` têm nomes
legíveis; o resto (render, UI) está ofuscado. Atualizado em 2026-11-08.

Legenda: ✅ feito · 🟡 parcial · ❌ falta

## Núcleo do editor

| Área no APK | Classes | iOS |
|---|---|---|
| `model.Transform` (âncora, posição+Z, escala, rotação X/Y/Z, opacidade, skew) | `Transform`, `Mat4` | ✅ matriz igual a `buildMatrix`; gizmo e painel com keyframes |
| `model.Animated` / `Keyframe` / `Easing` | `Animated`, `Keyframe`, `Easing`, `AjustesDeInterpolacao`, `CurvaAvancada` | 🟡 keyframes e easing básicos; falta editor de curva (gráfico) e alças de Bézier |
| `model.LayerContent` (Media, Text, Solid, Shape, Audio, Camera, Luz, Nulo, Group, Model3D, Midi, Osso, Adjustment) | 13 tipos | 🟡 Media (foto/vídeo), Text, Solid; Shape desenha como sólido; Audio/Camera/Luz/Group/3D/Midi/Osso/Adjustment ❌ |
| Mídia: `remap`, `reversed`, `emLaco`, `speed` animado, `gain`, `matte` | `LayerContent.Media`, `MatteDeVideo`, `MapaDeTempo`, `SpeedRamp` | 🟡 velocidade fixa e mudo; invertido, laço, remapeamento, rampa e matte ❌ |
| `model.BlendMode` | 30 modos | ✅ todos no shader, lendo o fundo real |
| Máscaras | `LayerMask`, `MaskShape`, `MaskMode`, `MascaraDeAlfa` | ❌ |
| Pais / grupos | `parentID`, `Reparentar`, `MolduraDoGrupo` | 🟡 pai funciona no cálculo; sem interface |
| Desfazer | `UndoHistory` | ✅ desfazer/refazer (60 passos) |
| Marcadores | `Marker`, `Markers` | ❌ |

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
| Animadores do AE | `AnimadorDeTexto`, `SeletorDeFaixa`, `SeletorOscilante`, `SeletorDeExpressao`, `TransformacaoDeGlifo`, `LetraAnimada` | ❌ |
| Fontes | `fontes.CatalogoDeFontes`, 47 fontes em `assets/fonts` | ❌ seletor de fonte |
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
| Exportar | `export.ServicoDeExportacao` | ✅ vídeo H.264/HEVC/alfa + áudio; GIF/PNG/PSD ❌ |
| Projeto `.nova` | `persistence.*Dto` | 🟡 formato próprio; não abre `.nova` do Android |
| Importar After Effects | `aeimport.*` | ❌ |
| Nuvem, conta, biblioteca, IA, marketplace | `cloud.*`, `biblioteca.*` | ❌ (API não documentada) |
| Layouts Nova/CapCut/Motion/AE | `layout.*` | 🟡 só Nova |
| Templates | `templates.*` | ❌ |

## Próximos, por impacto

1. Máscaras (uso diário).
2. Seletor de fonte + animadores de texto.
3. Vídeo invertido/laço/remapeamento.
4. Shapes vetoriais.
5. Editor de curva de keyframes.
