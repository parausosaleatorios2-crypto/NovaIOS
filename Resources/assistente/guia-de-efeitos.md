# Como escrever um efeito do Nova (para `criar_efeito`)

Um efeito é UM arquivo XML: cabeçalho, controles e um shader de fragmento em GLSL ES 3.00 que roda uma vez por
pixel, na GPU do celular, a cada quadro. O `criar_efeito` compila na placa de vídeo do aparelho, aplica na camada e
devolve os quadros e as conferências automáticas; repita até ficar bom.

## Esqueleto

```xml
<effect id="meu_efeito" name="Nome em português" name-en="English name"
        desc="Uma frase sobre o que se vê." desc-en="One sentence about what you see.">
  <params>
    <texture id="inputImg" src="content" />
    <slider id="forca" label="Força" label-en="Strength" default="0.7" min="0" max="1" step="0.01" snap="0" />
    <color id="tom" label="Cor" label-en="Color" default="#FFFFC24B" />
    <point id="centro" label="Centro" label-en="Center" defaultX="0.5" defaultY="0.5" />
    <switch id="animar" label="Animar" label-en="Animate" default="true" />
    <selector id="modo" label="Modo" label-en="Mode" default="0" options="Somar|Tela|Multiplicar" />
    <slider id="velocidade" group="Movimento" label="Velocidade" label-en="Speed" default="1" min="0" max="5" />
  </params>
  <shader><![CDATA[
void main() {
    vec4 cor = texture(inputImg, acScreenNorm);
    // ... a conta ...
    fragColor = cor;
}
  ]]></shader>
</effect>
```

- `id`: curto, minúsculas e `_` (o app troca por um id próprio). `name`/`desc` em português e `name-en`/`desc-en`
  em inglês; `label` e `label-en` em todo controle (o app é bilíngue).
- Cada controle vira um `uniform` com o MESMO nome do `id` — não declare uniform nenhum. Todo controle declarado
  tem que ser usado no shader, e todo nome usado tem que existir.
- Tipos: `slider` → `float` (`type="integer"`, `type="angle"`, `snap="0"` no valor neutro); `color` → `vec4`
  (`#AARRGGBB` ou `#RRGGBB`; use `.rgb`); `point` → `vec2` de 0 a 1 na camada, Y para baixo (alça arrastável na
  prévia; para sair do quadro, `min="-1" max="2"`); `switch` → `bool`; `selector` → `int` (o índice da opção);
  `xyz` → `vec3` (`defaultX/Y/Z`). `group="Título"` junta controles numa seção fechável (só para efeito com muitos).
- 3 a 7 controles úteis, com faixa boa e o padrão já mostrando o efeito com clareza.

## O contrato do shader

| nome | tipo | o que é |
|---|---|---|
| `acScreenNorm` | `vec2` | a coordenada 0..1 do pixel na camada (Y para baixo) |
| `fragColor` | `vec4` | onde escrever o resultado |
| `texture(img, uv)` | | lê uma textura (`texture2D` não: isto é GLSL ES 3.00) |
| `acTime` | `float` | segundos desde o começo da camada (animar: `acTime * velocidade`) |
| `acProgress` | `float` | 0..1 ao longo da duração da camada |
| `acResolution` | `vec2` | o tamanho do alvo em px; `acTexelSize` = 1/acResolution |
| `acAspect` | `float` | largura ÷ altura (círculo redondo: `(uv - 0.5) * vec2(acAspect, 1.0)`) |
| `acEscalaDePixel` | `float` | px do buffer por px da composição: medida em pixel × isto antes de virar UV |
| `acRascunho` | `int` | 1 = prévia em movimento: pode cortar AMOSTRAS de um borrão; 0 = a conta inteira |
| `acPass` | `int` | o passe atual (efeito de vários passes) |

**A cor NÃO é pré-multiplicada**: `texture(inputImg, uv)` devolve a cor reta e o alfa; devolva a cor reta e o alfa
da camada (`fragColor = vec4(rgb, cor.a)`). Nada de dividir ou multiplicar pelo alfa. Luz por cima do transparente
precisa de alfa: `fragColor = vec4(rgb, max(cor.a, intensidadeDaLuz))`.

## Texturas além da camada

- `<texture id="fundo" src="backdrop" />` — o que está ATRÁS da camada, na tela: leia com
  `texture(fundo, acTela(acScreenNorm))`.
- `<texture id="mapa" src="layer" label="Camada do mapa" label-en="Map layer" />` — outra camada escolhida no painel.
- `<texture id="eco" src="history" offset="2" />` — a camada 2 quadros atrás (rastro, eco).
- `<texture id="memoria" src="state" />` + um `<pass target="memoria" />` — o que o próprio efeito escreveu no
  quadro anterior (realimentação); `acStateFresh == 1` quando não há quadro anterior.
- `<texture id="som" src="audio" />` — o espectro do som, `texture(som, vec2(faixa, 0.5)).r` de 0 a 1.

## Vários passes (borrão, brilho)

```xml
<params>
  <texture id="inputImg" src="content" />
  <texture id="meio" src="buffer" scale="0.5" />
</params>
<passes>
  <pass target="meio" />
  <pass />
</passes>
```

No shader, `if (acPass == 0) { ... ler inputImg, escrever o meio ... } else { ... ler meio e inputImg ... }`. O
último passe não tem `target`. `scale="0.5"` trabalha em meia resolução (bem mais barato).

## Celular primeiro

- Laço com limite CONSTANTE (`for (int i = 0; i < 12; i++)`); module a força pelo controle, não a contagem.
- Poucas leituras por pixel: 8–16 num borrão de um passe; para mais, buffer em meia resolução.
- Guarde todo denominador (`max(x, 1e-4)`): NaN vira pixel preto.
- Palavras reservadas que não podem ser nome: `sample`, `input`, `output`, `filter`, `active`; nem nome de função
  nativa (`mix`, `step`, `length`, `distance`…) como variável.
- Funções auxiliares antes do `main`.

## Como trabalhar

1. Para partir de algo parecido do catálogo, peça o XML dele com `guia_de_efeitos` e `exemplo` (o id do
   `listar_efeitos`).
2. `criar_efeito` com o XML inteiro. Se voltar erro de compilação, ele vem com a linha do SEU código: corrija e mande
   de novo.
3. Olhe os quadros que voltam (antes × depois) e as conferências (efeito invisível, preto, controle que não muda
   nada, pesado). Ajuste e mande de novo até ficar como a pessoa pediu.
4. Diga à pessoa o que o efeito faz e quais controles ele tem. `salvar_efeito` só quando ela pedir para guardar (ou
   já tiver pedido): ele vai para "Meus efeitos".
