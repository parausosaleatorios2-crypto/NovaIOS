# Mapa Android → iOS

| Android (0.918.0) | iOS (este projeto) | Estado |
|---|---|---|
| Jetpack Compose | SwiftUI | esboço |
| OpenGL ES 3.0 | Metal | motor pronto |
| Shaders GLSL ES 3.0 | MSL via `Tools/glsl2msl.py` | 1.438 traduzidos |
| MediaCodec + SurfaceTexture | VideoToolbox + `AVAssetImageGenerator` | escrito |
| MediaMuxer | `AVAssetWriter` | escrito |
| Room | JSON em `project.json` | pronto |
| WorkManager | `BGProcessingTaskRequest` | não escrito |
| Foreground Service (export) | `beginBackgroundTask` | não escrito |
| FileProvider | `UIDocumentPickerViewController` | não escrito |
| Intent filters `.nova` | `CFBundleDocumentTypes` + UTI | declarado |
| `novaeditor://` | `CFBundleURLTypes` | declarado |
| App Links do hub | `com.apple.developer.associated-domains` | declarado |
| ONNX Runtime (JNI) | ONNX Runtime iOS ou Core ML | não escrito |
| QuickJS (`libqjs.so`) | QuickJS ou JavaScriptCore | não escrito |
| CPython (`libpython.zip.so`) | **sem caminho limpo** | ver PENDENCIAS 3.5 |
| Discord Social SDK (JNI) | SDK iOS, se existir | não escrito |
| WebRTC (colaboração) | — | o Android também não ligou |
| Google Sign-In + Firebase | mesmos SDKs, versão iOS | não escrito |

## Permissões

| Android | iOS |
|---|---|
| `READ_MEDIA_IMAGES` / `READ_MEDIA_VIDEO` | `NSPhotoLibraryUsageDescription` |
| `RECORD_AUDIO` | `NSMicrophoneUsageDescription` |
| `INTERNET` | implícita |
| `POST_NOTIFICATIONS` | `UNUserNotificationCenter` |
| `WAKE_LOCK` | `UIApplication.isIdleTimerDisabled` |
| `FOREGROUND_SERVICE_MEDIA_PROCESSING` | **sem equivalente** — export longo fica em foreground |

## Diferença que mais dói

No Android o export roda em foreground service: o usuário sai do app e a
renderização continua. **No iOS não existe isso.** `beginBackgroundTask` dá cerca
de 30 segundos. Um export de 2 minutos em 4K precisa do app aberto e na tela.

As saídas são: manter o app em primeiro plano com a tela acesa; ou export na
nuvem, que o app Android já oferece como recurso do plano PRO.
