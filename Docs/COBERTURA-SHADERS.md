# Cobertura da tradução de shaders

Gerado por `Tools/glsl2msl.py` em 7 de novembro de 2026.

| estado | efeitos |
|---|---|
| traduzido limpo | 1235 |
| traduzido, pede revisão | 178 |
| sem shader (só parâmetros) | 49 |
| falhou | 28 |
| **total** | **1490** |

## Os 28 que falharam

Todos por **defeito no shader de origem**, não na tradução: chave ou
parêntese fica dentro de um comentário `//`, o que deixa o código
desequilibrado. O tradutor recusa esses em vez de emitir Metal que não
compila.

Por prefixo: `toji-` 28

| arquivo | motivo |
|---|---|
| `toji-3D_Particles_Beta.xml` | chaves desequilibradas dentro do main (7 x 6) no shader de origem |
| `toji-3D_Perception_BETA.xml` | main() sem fecho |
| `toji-skexnxxedgeline.xml` | main() sem fecho |
| `toji-skexnxxfeatherfalls2.xml` | chaves desequilibradas dentro do main (7 x 6) no shader de origem |
| `toji-skexnxxs2Dtunnelv2.xml` | chaves desequilibradas dentro do main (5 x 4) no shader de origem |
| `toji-skexnxxs2dclouds.xml` | chaves desequilibradas dentro do main (8 x 7) no shader de origem |
| `toji-skexnxxsbonfire.xml` | chaves desequilibradas dentro do main (6 x 5) no shader de origem |
| `toji-skexnxxscheapstars.xml` | chaves desequilibradas dentro do main (4 x 3) no shader de origem |
| `toji-skexnxxschrolens.xml` | chaves desequilibradas dentro do main (7 x 6) no shader de origem |
| `toji-skexnxxscirculartail.xml` | chaves desequilibradas dentro do main (4 x 3) no shader de origem |
| `toji-skexnxxscosmicycles.xml` | chaves desequilibradas dentro do main (9 x 8) no shader de origem |
| `toji-skexnxxsdna.xml` | chaves desequilibradas dentro do main (7 x 6) no shader de origem |
| `toji-skexnxxsdotsloader.xml` | chaves desequilibradas dentro do main (5 x 4) no shader de origem |
| `toji-skexnxxsfuji.xml` | main() sem fecho |
| `toji-skexnxxsglowtunnels.xml` | chaves desequilibradas dentro do main (8 x 7) no shader de origem |
| `toji-skexnxxsinstantgrass.xml` | chaves desequilibradas dentro do main (5 x 4) no shader de origem |
| `toji-skexnxxslightsaber.xml` | chaves desequilibradas dentro do main (5 x 4) no shader de origem |
| `toji-skexnxxsnewcolorgrid.xml` | chaves desequilibradas dentro do main (4 x 3) no shader de origem |
| `toji-skexnxxsnewtrails.xml` | chaves desequilibradas dentro do main (4 x 3) no shader de origem |
| `toji-skexnxxsnoisefade.xml` | chaves desequilibradas dentro do main (5 x 4) no shader de origem |
| `toji-skexnxxsopticcompesation.xml` | chaves desequilibradas dentro do main (7 x 6) no shader de origem |
| `toji-skexnxxsparticlev2.xml` | chaves desequilibradas dentro do main (10 x 9) no shader de origem |
| `toji-skexnxxspointunnel.xml` | chaves desequilibradas dentro do main (9 x 8) no shader de origem |
| `toji-skexnxxssmallringswater.xml` | chaves desequilibradas dentro do main (7 x 6) no shader de origem |
| `toji-skexnxxsstarstreak.xml` | chaves desequilibradas dentro do main (7 x 6) no shader de origem |
| `toji-skexnxxsvortextdust.xml` | chaves desequilibradas dentro do main (7 x 6) no shader de origem |
| `toji-skexnxxswingsline.xml` | chaves desequilibradas dentro do main (4 x 3) no shader de origem |
| `toji-skexnxxxfibersglow.xml` | chaves desequilibradas dentro do main (6 x 5) no shader de origem |

## Os 178 que pedem revisão

O verificador marcou identificadores que não soube resolver. A maioria é
falso positivo — variável local declarada num padrão que ele não reconhece.
**A primeira build no Xcode aponta os reais.** A coluna `nao_resolvidos` do
CSV lista o que ele viu em cada um.
