<h1 align="center">Metamorph: Creative Menu</h1>

<p align="center">
  Um conjunto criativo para Noita: feitiços, varinhas, itens, materiais, vantagens, criaturas, efeitos, teletransporte, clima e regras do mundo.
</p>

<a id="languages"></a>

[English](README.md) · [Русский](README.ru.md) · [**Português (Brasil)**](README.pt-BR.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Italiano](README.it.md) · [Polski](README.pl.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

## Download

Versão atual: **2.0.0**

| Pacote | Download |
|---|---|
| **Versão mais recente pronta para instalar** | **[⬇️ Baixar Metamorph-Creative-Menu.zip](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip)** |
| Página da versão | [Versão mais recente pronta para instalar](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build) |

> O ZIP já contém a pasta completa `metamorph_creative_menu`, incluindo o NoitaPatcher integrado. Extraia essa pasta diretamente em `Noita/mods/`.

Caminho final correto:

```text
Noita/mods/metamorph_creative_menu/mod.xml
```

Se o caminho terminar como `metamorph_creative_menu/metamorph_creative_menu/mod.xml`, o arquivo foi extraído uma pasta abaixo do nível correto.

---

## Português (Brasil)

### Instalação

1. [Baixe o ZIP mais recente pronto para instalar](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip).
2. Feche completamente o Noita antes de instalar ou atualizar o mod.
3. No Steam, abra **Biblioteca → clique com o botão direito em Noita → Gerenciar → Explorar arquivos locais**.
4. Abra a pasta `mods` do jogo e copie para ela a pasta completa **`metamorph_creative_menu`**.
5. Confirme que `Noita/mods/metamorph_creative_menu/mod.xml` existe. Não renomeie a pasta do mod.
6. Inicie o Noita, ative **Metamorph: Creative Menu**, permita **Unsafe mods / unrestricted API** quando necessário e reinicie o jogo depois de ativar o mod.
7. Inicie uma partida e pressione **TAB**. Se o menu abrir, a instalação foi concluída.

**Atualização:** feche o Noita, remova a pasta antiga `metamorph_creative_menu` e copie a nova para `mods`. Substituir a pasta inteira evita arquivos antigos de versões anteriores.

### Controles

- **F4 ou TAB**: abrir ou fechar o Creative Menu.
- **TAB durante uma transformação**: voltar à forma humana.
- **G** por padrão: assumir o controle de uma criatura compatível sob o cursor.
- **Botão do meio do mouse**: desenhar com o material selecionado.
- As teclas podem ser alteradas na seção CONTROLES ou nas configurações do mod. As ações disponíveis para o botão esquerdo e o botão direito são mostradas na interface.

### O que o MCM pode fazer

- Obter e posicionar feitiços, além de movê-los entre varinhas, espaços de Sempre Lançar, inventário e mundo.
- Editar atributos, aparência e bloqueios de varinhas; salvar predefinições e criar cópias.
- Criar itens perto do jogador ou em uma posição escolhida do mundo e colocar itens compatíveis diretamente no inventário.
- Criar frascos com líquidos selecionados.
- Selecionar materiais e desenhá-los no mundo.
- Criar, adicionar e remover vantagens.
- Criar criaturas perto do jogador ou em uma posição escolhida do mundo.
- Transformar-se em criaturas, assumir o controle de criaturas existentes e voltar à forma humana.
- Criar uma entidade PLAYER separada.
- Aplicar e remover efeitos do jogo.
- Alterar clima, horário, gravidade e outras regras do mundo.
- Teletransportar-se para locais do jogo.
- Com Entangled Worlds, teletransportar-se até outros jogadores ou trazê-los até você.
- Alterar atalhos e pesquisar nos catálogos de feitiços, itens, materiais, vantagens e criaturas.
- Mover e redimensionar a janela do menu; sua posição e tamanho são mantidos entre execuções do jogo.

<details>
<summary><strong>Transformações, compatibilidade e recuperação</strong></summary>

O MCM usa dados de compatibilidade por caminho XML exato e exceções restritas de encaminhamento seguro para entidades que são sabidamente perigosas ou inadequadas para uma transformação nativa direta. As formas controladas pelo jogador tentam preservar movimento, ataques, aparência e física nativos úteis, ao mesmo tempo em que desativam inteligências artificiais que entrariam em conflito com os comandos do jogador. Chefes complexos, entidades com scripts próprios e objetos físicos podem exigir adaptadores dedicados e nem sempre reproduzem exatamente todo o comportamento da inteligência artificial original.

O NoitaPatcher é usado em mecanismos fortes de recuperação, como serialização e desserialização de entidades, transferência do controle da entidade do jogador e outras funções avançadas durante a execução. Por isso, a versão completa e independente solicita acesso de mod sem restrições.

</details>

<details>
<summary><strong>Integração multijogador com Entangled Worlds</strong></summary>

**Entangled Worlds é opcional.** O MCM foi projetado para funcionar como um mod completo de um jogador sem EW.

Quando `quant.ew` está ativo, o MCM habilita integração experimental para itens compartilhados, vantagens, clima, regras do mundo, formas e controle de criaturas, solicitações de companheiro e comportamentos relacionados a autoridade e sincronização. Use a mesma versão do MCM em todos os participantes. O suporte multijogador é considerado experimental porque nem todas as situações-limite de Noita e EW podem ser sincronizadas com garantia perfeita.

</details>

### Requisitos e componentes de terceiros

- **Noita** — jogo obrigatório, da Nolla Games.
- **NoitaPatcher** por dextercd — incluído no MCM e usado para funções avançadas e recuperação.
- **lbase64** por Ilya Kolbin — implementação local de Base64 incluída.
- **Entangled Worlds / Noita Proxy** por IntQuant e colaboradores — integração multijogador opcional; não é necessária no modo de um jogador.

Links exatos dos projetos originais, caminhos dos componentes incluídos e informações de licença ou estado estão em [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

### Solução de problemas

- **TAB não faz nada:** confirme o caminho exato de `mod.xml`, verifique se o MCM está ativado, permita Unsafe mods/unrestricted API e reinicie o Noita.
- **A recuperação avançada ou parte das regras do mundo está ausente:** confirme que `metamorph_creative_menu/NoitaPatcher/noitapatcher.dll` existe e que o acesso unrestricted API está permitido.
- **Uma forma não volta corretamente:** informe o nome ou XML exato da criatura e diga se a falha ocorreu no retorno normal com TAB ou no retorno após dano fatal.
- **Dessincronização com EW:** confirme que todos usam a mesma versão do MCM e uma versão compatível do EW.

### Links

- [Versão mais recente](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build)
- [Relatar um erro](https://github.com/zerodancing/Metamorph-Creative-Menu/issues)
- [Componentes de terceiros](THIRD_PARTY_NOTICES.md)
- [Noita](https://noitagame.com/)
- [NoitaPatcher](https://github.com/dextercd/NoitaPatcher)
- [Documentação do NoitaPatcher](https://dexter.döpping.eu/NoitaPatcher/)
- [Entangled Worlds](https://github.com/IntQuant/noita_entangled_worlds)
- [lbase64](https://github.com/iskolbin/lbase64)

[↑ Voltar à seleção de idioma](#languages)

---

## Para desenvolvedores

O mod jogável fica em `metamorph_creative_menu/`.

- Notas de arquitetura e desenvolvimento: `metamorph_creative_menu/README.txt`
- Conjunto de testes de regressão: `metamorph_creative_menu/tests/`
- Instruções de teste: `metamorph_creative_menu/tests/TESTING.txt`
- Avisos sobre componentes de terceiros: [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)

O fluxo automático `latest-build` do repositório empacota a pasta jogável `metamorph_creative_menu` em um ZIP pronto para instalar e atualiza o endereço estável de download acima.