# O que falta

Lista honesta. Cada item diz o porquê e o que é preciso para fechar.

---

## 1. Bloqueios absolutos (nada a fazer em código)

### 1.1 Mac com Xcode
Compilar iOS exige o toolchain da Apple, só disponível no macOS. Não há
alternativa em Linux, Docker, nuvem genérica ou conversor. **Sem Mac, não há IPA.**

### 1.2 Conta de desenvolvedor Apple
Para instalar num aparelho é preciso: certificado (desenvolvimento ou
distribuição), provisioning profile com o App ID `com.novavision.editor` e,
se for perfil ad-hoc, o UDID de cada aparelho.

---

## 2. Decisões do dono do projeto

### 2.1 Os 639 efeitos do Alight Motion
Portam como os outros. O problema é distribuição. **Com eles:** só sideload com
certificado. **Sem eles:** 851 efeitos e caminho aberto para a App Store.

### 2.2 Quais layouts entram
O app Android tem quatro — Nova, CapCut, Motion, After Effects — e cada um muda
o *jeito de editar*, não só a aparência. Aqui só o Nova está esboçado. O layout
After Effects é um app de desktop dentro do aparelho: menu, painéis arrastáveis,
áreas de trabalho, atalhos de teclado. Na prática ele pede iPad.

### 2.3 iPhone só, ou iPhone e iPad
`project.yml` está em `TARGETED_DEVICE_FAMILY: "1,2"` (os dois). Se for só
iPhone, mude para `"1"` e o layout AE sai de cena.

---

## 3. Informação que falta do app original

### 3.1 Telas sem captura
O APK traz capturas só de duas telas: o layout After Effects
(`assets/extensoes/prints/layout/*.webp`, 1600×900) e a folha de baixar por link.
**Início, Projetos, Marketplace, Perfil e o editor no layout Nova foram
reconstruídos a partir das 6.872 strings de UI.** A estrutura está certa; o
arranjo visual é leitura. Com prints dessas telas, dá para copiar fiel.

### 3.2 Ordem e ícones da barra de baixo
Sabe-se *quais* botões existem (Biblioteca, Legendas, IA, Link, Drive, Layout) e
que os três primeiros ficam nessa ordem. O resto é suposição.

### 3.3 Fonte da interface
Os 5,3 MB em `Resources/fonts/` são fontes de **conteúdo** (galeria e
«nota de resgate»), não a fonte da UI. Qual fonte a interface usa?

### 3.4 Esquema interno do `.nova`
O manifesto confirma que é um ZIP (MIME `application/x-nova`, `application/zip`).
O **esquema do JSON interno está no bytecode** e não foi decodificado.
`NovaProjectIO` grava e lê o formato *deste* app iOS, compatível na estrutura
(ZIP + JSON + `media/`), mas **não abre `.nova` feito no Android**. Para isso é
preciso um `.nova` de exemplo e a confirmação do esquema.

### 3.5 Para que serve o CPython embutido
`libpython.zip.so` tem 14 MB dentro do APK e não se descobriu o que ele roda.
Isso importa: **a Apple proíbe interpretar código baixado**. Se for script
interno embutido, passa. Se baixa script do servidor, não passa na revisão.

### 3.6 Contratos da API
`novavisionhub-3.onrender.com` serve auth, biblioteca, marketplace, IA e créditos.
Nenhum endpoint foi documentado — só as URLs base, extraídas dos pools de string.

---

## 4. Código por escrever

### 4.1 Provedor de conteúdo das camadas — **feito (2026-11-07)**
`Sources/NovaEngine/LayerContent.swift` (`MediaContentProvider`) entrega ao
`Compositor` a textura de cada camada: vídeo (`VideoDecoder`), imagem (com a
orientação EXIF), texto renderizado (UIKit), sólido. Mídia que falta entra como
barras coloridas, como no Android. O `PreviewSurface` desenha o quadro do
`Compositor`; o editor importa fotos e vídeos da galeria (`MediaImport.swift`,
cópia para `media/`) e exporta (`ExportView.swift` + `AudioMux.swift`: vídeo
H.264/HEVC, HEVC com alfa em .mov, som das camadas de vídeo, salvar na galeria e
compartilhar).

Conferido no APK com o REA (JADX): `com.novaeditor.model.LayerContent` tem os
tipos Media (MediaKind IMAGE/VIDEO, uri, sourceInPointUs, sourceDurationUs,
speed, muted, gain, reversed, emLaco), Text, Solid, Shape, Audio, Camera, Luz,
Nulo, Group, Model3D, Midi, Osso e Adjustment; o export roda em
`com.novaeditor.export.ServicoDeExportacao` (ações CANCELAR e TERMINAR).

Falta: forma vetorial (hoje desenha como sólido), mídia invertida/em laço/
remapeamento de tempo, ganho de áudio, decodificação sequencial na exportação
(hoje busca quadro a quadro: mais lento).

### 4.2 Renderização de texto
Texto com os animadores do AE (seletores de faixa, oscilante, expressão) —
774 classes de modelo no Android cuidam disso. Nada escrito aqui.

### 4.3 Os 179 shaders a revisar
`Docs/relatorio-shaders.csv` lista quais. Na maioria são falsos positivos do
verificador (variáveis locais em padrões que ele não reconhece), mas cada um
precisa compilar de verdade no Xcode para confirmar. **A primeira build vai
apontar os reais.**

### 4.4 Mescla com o fundo
`NovaBlend.metal` tem os 28 modos do AE, mas os que precisam ler o *destino*
(multiply, overlay, soft light...) hoje operam sobre preto. Para ficar correto é
preciso ou `[[color(0)]]` com framebuffer fetch, ou um pass extra que amostra o
backdrop. **Normal, Add e Screen já saem certos.**

### 4.5 3D
Element 3D (97 classes), Optical Flares (31), câmera de um e dois nós, luzes,
sombras projetadas, HDRI. Nada escrito.

### 4.6 IA
RIFE v4.6 está em `Resources/ia/` (21 MB). MODNet, EdgeTAM, Depth-Anything-v2 e
UVR-MDX-NET são baixados sob demanda no Android. É preciso decidir entre
ONNX Runtime iOS e conversão para Core ML.

### 4.7 Expressões
O Android usa QuickJS (`libqjs.so`). QuickJS compila para iOS; `JavaScriptCore`
é alternativa. Nada escrito.

### 4.8 Importador de projeto do After Effects
`.aep` e presets `.ffx`. 12 classes no Android (`com.novaeditor.aeimport`).

### 4.9 Nuvem, conta, marketplace, extensões, colaboração
Depende de 3.6. A colaboração, aliás, o próprio app Android declara como
**ainda não ligada**.

---

## 5. Ordem sugerida

1. Abrir no Xcode e fazer a primeira build — ela revela os shaders que falham de verdade
2. Escrever o `LayerContentProvider` (4.1) → o preview acende
3. Ligar o `Compositor` ao `PreviewSurface`
4. Exercitar a exportação com uma composição simples
5. Corrigir a mescla com fundo (4.4)
6. Texto (4.2)
7. Daí em diante, por prioridade do produto
