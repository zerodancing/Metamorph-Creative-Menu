# Metamorph: Creative Menu — Português (Brasil)

[English](README.en.md) · [Русский](README.ru.md) · [Português (Brasil)](README.pt-BR.md) · [Español](README.es-ES.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Italiano](README.it.md) · [Polski](README.pl.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

## Sobre o mod

**Metamorph: Creative Menu (MCM)** é um menu criativo/de desenvolvimento para **Noita**. Ele foi feito para funcionar de forma independente no modo solo e também oferece compatibilidade experimental opcional com **Entangled Worlds / Noita Proxy**.

O MCM permite editar varinhas, gerar ou receber itens, aplicar e remover vantagens e efeitos, transformar-se em criaturas, possuir uma criatura existente sob o cursor, controlar clima e regras do mundo e gerar um companheiro semelhante ao jogador.

## Requisitos e instalação

- Noita instalado.
- A pasta `metamorph_creative_menu` dentro de `Noita/mods/`.
- Ative **Unsafe mods / unrestricted API** no menu de mods. O NoitaPatcher incluído precisa dessa permissão.
- Entangled Worlds é **opcional**.

Instalação:
1. Baixe uma versão em [Releases](https://github.com/zerodancing/Metamorph-Creative-Menu/releases) ou baixe/clone o repositório.
2. Copie `metamorph_creative_menu` para `Noita/mods/`.
3. Confirme que existe `Noita/mods/metamorph_creative_menu/mod.xml`.
4. Ative Unsafe mods e depois Metamorph: Creative Menu.

Não renomeie a pasta interna do mod.

## Controles

- **TAB** — abre/fecha o menu.
- **TAB transformado** — volta para a forma humana.
- **G** por padrão — possui/transforma no alvo compatível sob o cursor; a tecla pode ser alterada nas configurações.
- LMB/RMB têm ações diferentes conforme a aba e são mostradas na interface.

## Recursos

### Feitiços
Com uma varinha na mão, selecione um slot e escolha um feitiço no catálogo pesquisável. É possível substituir, excluir ou soltar feitiços. A substituição só remove o feitiço antigo depois que o novo foi anexado e verificado.

### Itens
Categorias incluem recipientes, líquidos, pedras, ovos, varinhas, livros, bônus, orbes, itens de missão e outros.
- **LMB:** gera perto do jogador.
- **RMB:** tenta colocar diretamente no inventário.
- Se o inventário estiver cheio ou o pickup falhar, o item permanece no mundo.
- Há frascos e recipientes preenchidos com líquidos compatíveis.

### Vantagens
- **ADD:** LMB gera o pickup; RMB aplica diretamente.
- **REMOVE:** LMB remove uma unidade; RMB tenta remover todas.
O MCM registra muitas alterações de vantagens para reverter entidades, componentes e valores pertencentes à vantagem sem sobrescrever deliberadamente alterações de outros sistemas. Quando não há inversão segura, o mod prefere recusar uma remoção perigosa.

### Busca
Catálogos grandes possuem busca por nome traduzido, ID e/ou descrição.

### Criaturas, objetos e formas
- **LMB:** gera a entidade.
- **RMB:** transforma o jogador.
- **TAB:** volta ao humano.

A segurança de transformação é armazenada por caminho XML exato. Alguns wrappers conhecidos por serem perigosos usam um alvo canônico seguro somente para transformação. Formas controladas pelo jogador preservam, quando possível, ataques, movimento, aparência e física úteis, enquanto desativam IA conflitante. Criaturas muito complexas podem usar adaptadores aproximados.

### Retorno humano e morte da forma
O retorno normal por TAB usa primeiro o ciclo nativo de polymorph de Noita. O MCM também mantém um backup serializado do humano por meio do NoitaPatcher.

Em dano fatal, o MCM tenta fazer **death handoff**: a forma atual morre, mas a autoridade do jogador é transferida de volta para o humano restaurado, evitando que a morte do corpo transformado termine automaticamente a partida.

### Possessão
Aponte para uma criatura compatível e pressione **G** (padrão). O MCM usa a forma compatível do alvo e retira o alvo original do mundo para evitar uma simples duplicação.

### Companheiro PLAYER
A entrada `PLAYER` pode criar um aliado semelhante ao jogador. Quando as capacidades necessárias do NoitaPatcher estão disponíveis, o companheiro pode usar a varinha copiada de forma mais próxima do jogador real.

### Efeitos
Aplique efeitos de status/temporários, escolha duração quando suportada e remova efeitos pelo editor, preservando quando possível efeitos internos/perks que não pertencem ao editor.

### Clima
Predefinições de horário: manhã, dia, tarde/noite inicial e noite. Predefinições de clima: limpo, nublado, neblina e tempestade. O modo avançado controla valores suportados de horário, nuvens, neblina, vento, velocidade do vento, chuva e relâmpagos. **RELEASE** para de manter o override ativo.

### Regras do mundo
As regras são **overrides reversíveis**. `NATIVE`/RESET restaura o baseline que o MCM capturou para os valores que controla. Há recuperação persistente para regras críticas.

Regras atuais:

- RELAÇÕES DAS CRIATURAS
- OURO NÃO DESAPARECE
- USOS ILIMITADOS
- REVELAR MAPA
- DINHEIRO DE SANGUE POR TRUQUES
- CHANCE DE CURA
- RATOS AMIGÁVEIS
- QUANTIDADE DE SANGUE
- OURO POR TRUQUES
- FLASH DE DANO
- PERDA DE MANCHAS
- GRAVIDADE DO MUNDO
- AMORTECIMENTO FÍSICO
- VOLUME DE SANGUE
- FORÇA DO CHUTE
- FORÇA DAS JUNTAS
- VELOCIDADE DO DIA

Regras de física atuam sobre corpos/entidades carregados ou próximos, não sobre todas as entidades descarregadas do mundo infinito de uma só vez.

## Solo e Entangled Worlds

**Entangled Worlds não é necessário para jogar solo.** O MCM inclui sua própria cópia do NoitaPatcher e codec Base64 local.

Com `quant.ew` ativo, o MCM habilita integração experimental para itens do mundo, perks, clima, regras, formas/possessão, companions e patches de compatibilidade. Se o EW já publicou uma API NoitaPatcher compatível, o MCM pode reutilizá-la.

A compatibilidade multiplayer é **experimental/parcial**. Host e cliente devem ter os mesmos direitos de uso do menu, mas nem todo caso extremo de Noita/EW pode ser garantido. Todos os peers devem usar a mesma versão do MCM.

## Solução de problemas

- Menu não abre: confira `Noita/mods/metamorph_creative_menu/` e se o mod está habilitado.
- Recursos avançados ausentes: ative Unsafe mods e confira `NoitaPatcher/noitapatcher.dll`.
- Problema em uma forma: informe o XML/nome exato e se falhou TAB ou retorno após morte.
- EW: informe versões de MCM e Entangled Worlds.

Relate bugs em [GitHub Issues](https://github.com/zerodancing/Metamorph-Creative-Menu/issues) com versão, passos e logs quando disponíveis.

## Dependências e créditos

O MCM inclui **NoitaPatcher** (dextercd) e **lbase64** (Ilya Kolbin) e integra opcionalmente com **Noita Entangled Worlds** (IntQuant e contribuidores). Detalhes completos: [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md).

## Links

- MCM: https://github.com/zerodancing/Metamorph-Creative-Menu
- Releases: https://github.com/zerodancing/Metamorph-Creative-Menu/releases
- Issues: https://github.com/zerodancing/Metamorph-Creative-Menu/issues
- Noita: https://noitagame.com/
- NoitaPatcher: https://github.com/dextercd/NoitaPatcher
- NoitaPatcher docs: https://dexter.döpping.eu/NoitaPatcher/
- Entangled Worlds: https://github.com/IntQuant/noita_entangled_worlds
- lbase64: https://github.com/iskolbin/lbase64

## Desenvolvimento

O mod jogável está em `metamorph_creative_menu/`; testes e contratos ficam em `metamorph_creative_menu/tests/`. Ainda não foi escolhida uma licença geral para o código original do MCM; componentes de terceiros mantêm seus próprios termos.
