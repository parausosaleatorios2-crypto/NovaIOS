# Compilar no Mac

## Requisitos

- macOS 14 (Sonoma) ou mais novo
- Xcode 15.4 ou mais novo
- Para instalar no aparelho: conta de desenvolvedor Apple

## Caminho com XcodeGen (recomendado)

```bash
brew install xcodegen
cd NovaEditor-iOS
xcodegen generate
open NovaEditor.xcodeproj
```

No Xcode, alvo `NovaEditor` → **Signing & Capabilities** → escolha o **Team**.

## Caminho sem XcodeGen

1. Xcode → File → New → Project → iOS → App
   - Product Name: `NovaEditor`
   - Organization Identifier: `com.novavision`
   - Interface: SwiftUI · Language: Swift
2. Apague o `ContentView.swift` e o `NovaEditorApp.swift` que o Xcode criou.
3. Arraste para o projeto, marcando **Create groups** e o alvo `NovaEditor`:
   - `Sources/` (os três módulos como grupos, não como frameworks separados)
   - `Shaders/` (os `.metal` vão para **Compile Sources**, os `.h` ficam de fora)
   - `Resources/` como **folder reference** (pasta azul), para preservar a árvore
4. Copie as chaves do `project.yml` para o `Info.plist`.
5. Build Settings → `MTL_LANGUAGE_REVISION` = Metal 3.0.

## A primeira build demora

1.438 arquivos `.metal` numa metallib: de 10 a 25 minutos. Depois é incremental.

Se a build da metallib estourar memória:

```
Build Settings → Metal Compiler → Optimization Level → None (debug)
```

## Gerar o IPA

Crie `ExportOptions.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>          <string>development</string>
  <key>teamID</key>          <string>SEU_TEAM_ID</string>
  <key>signingStyle</key>    <string>automatic</string>
  <key>stripSwiftSymbols</key><true/>
  <key>compileBitcode</key>  <false/>
</dict>
</plist>
```

Depois:

```bash
xcodebuild -project NovaEditor.xcodeproj -scheme NovaEditor \
  -configuration Release -sdk iphoneos \
  -archivePath build/NovaEditor.xcarchive archive

xcodebuild -exportArchive \
  -archivePath build/NovaEditor.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath build/
```

O IPA sai em `build/NovaEditor.ipa`.

Para TestFlight, troque `method` para `app-store-connect`.

## Problemas conhecidos

**«Use of undeclared identifier» num `fx_*.metal`**
É um dos 179 marcados como `revisar` em `Docs/relatorio-shaders.csv`. Abra o XML
correspondente em `Resources/effects/` e corrija o `.metal` à mão, ou ajuste o
tradutor em `Tools/glsl2msl.py` e regere.

**App grande demais**
`Resources/` são 169 MB, com `ransom-letters` (74 MB) e `vhs` (27 MB) na frente.
O limite de download por rede celular da App Store é 200 MB. Considere baixar
esses dois pacotes sob demanda em vez de embutir.

**Metal não roda no simulador antigo**
Simulador de Mac Intel tem suporte parcial. Teste em aparelho ou em Mac Apple Silicon.
