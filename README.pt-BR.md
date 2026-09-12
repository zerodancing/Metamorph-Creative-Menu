<a id="languages"></a>

[English](README.md) · [Русский](README.ru.md) · [**Português (Brasil)**](README.pt-BR.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Italiano](README.it.md) · [Polski](README.pl.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

<h1 align="center">Metamorph: Creative Menu</h1>

<p align="center">Um menu criativo e conjunto de ferramentas para Noita: feitiços, varinhas, itens, materiais, vantagens, criaturas, transformações, efeitos, teletransporte, clima, regras do mundo e muito mais.</p>

<p align="center"><strong>Versão 2.0.0</strong></p>

---

# Baixar

[**⬇️ Baixar a versão mais recente do mod**](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip)

Versão atual: **2.0.0**

**Para usar a versão completa, é necessário permitir mods inseguros.**

[Página da compilação mais recente](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build)

[Lista de alterações da versão 2.0.0](metamorph_creative_menu/CHANGELOG.txt)

# Conteúdo

- [Instalação](#instalação)
- [Versão completa e versão da Oficina Steam](#versão-completa-e-versão-da-oficina-steam)
- [Sobre o mod](#sobre-o-mod)
- [Controles e interface](#controles-e-interface)
- [Feitiços](#feitiços)
- [Varinhas](#varinhas)
- [Itens e líquidos](#itens-e-líquidos)
- [Materiais](#materiais)
- [Vantagens](#vantagens)
- [Efeitos](#efeitos)
- [Criaturas e transformações](#criaturas-e-transformações)
- [Retorno após uma transformação e morte da forma](#retorno-após-uma-transformação-e-morte-da-forma)
- [Possessão de criatura](#possessão-de-criatura)
- [Jogador](#jogador)
- [Clima e horário](#clima-e-horário)
- [Regras do mundo](#regras-do-mundo)
- [Teletransporte](#teletransporte)
- [Entangled Worlds](#entangled-worlds)
- [NoitaPatcher e mods inseguros](#noitapatcher-e-mods-inseguros)
- [Se algo não funcionar](#se-algo-não-funcionar)
- [Relatar um erro](#relatar-um-erro)

# Instalação

1. [Baixe a versão mais recente do mod](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip).
2. Inicie o Noita e abra **Mods** no menu principal.
3. Clique em **Abrir pasta de mods**.
4. Mova a pasta `metamorph_creative_menu` do arquivo baixado para a pasta `mods` que foi aberta. Se `metamorph_creative_menu` já estiver lá, exclua a pasta antiga e coloque a nova no lugar.
5. Feche a pasta de mods.
6. No menu de mods, clique em **Atualizar**. **Metamorph: Creative Menu** deve aparecer na lista.
7. Clique em **Mods inseguros** até o texto ficar vermelho e mostrar **Mods inseguros: Permitidos**.
8. Clique no nome do mod para que ele fique destacado e apareça **[x]** antes dele. Isso significa que o mod está ativado.
9. Clique em **Iniciar um novo jogo com mods ativos**.
10. Escolha um modo de jogo e jogue.

# Versão completa e versão da Oficina Steam

A compilação disponível nesta página do GitHub é a versão completa do MCM. Ela inclui o NoitaPatcher e funções que exigem permissão para mods inseguros.

A [versão da Oficina Steam](https://steamcommunity.com/sharedfiles/filedetails/?id=3785170245) é instalada separadamente. Ela não inclui o NoitaPatcher nem as funções da versão completa que exigem acesso de mods inseguros.

Não instale nem ative as duas versões ao mesmo tempo.

# Sobre o mod

**Metamorph: Creative Menu (MCM)** é um menu criativo e conjunto de ferramentas para Noita.

Ele reúne em uma só interface ferramentas para feitiços, varinhas, itens, materiais, vantagens, efeitos, criaturas, transformações, clima, regras globais do mundo e teletransporte.

O MCM serve tanto para jogar livremente em modo criativo quanto para experimentar as mecânicas de Noita. Muitas operações não são tratadas como simples criação de uma nova entidade: elas levam em conta o estado já existente da varinha, do item, da forma, da vantagem ou do mundo.

**Entangled Worlds não é necessário.** Sem ele, o MCM funciona como um mod completo para um jogador. Com o Entangled Worlds instalado, recursos multijogador experimentais adicionais ficam disponíveis.

# Controles e interface

| Ação | Tecla |
| --- | --- |
| Abrir / fechar o menu criativo | **F4 ou TAB** |
| Voltar à forma humana | **TAB durante uma transformação** |
| Possuir uma criatura | **G** |
| Desenhar com o material selecionado | **Botão do meio do mouse** |

O painel do MCM também fica disponível pela interface normal do inventário.

As teclas podem ser alteradas na seção **CONTROLES** ou nas configurações do mod.

Ao atribuir uma tecla:

- **DELETE / BACKSPACE** — limpar a atribuição;
- **ESC** — cancelar;
- **R** — restaurar a atribuição padrão;
- **REDEFINIR TUDO** — restaurar todas as atribuições padrão após confirmação.

Se a mesma combinação for atribuída a mais de uma ação, o MCM mostra um conflito.

## Janela do menu criativo

A janela pode ser:

- movida;
- redimensionada na largura e na altura;
- redimensionada pelas bordas e pelos cantos;
- minimizada;
- fechada;
- restaurada para a disposição padrão.

O tamanho, a posição e a última seção aberta são salvos entre as execuções do jogo.

Catálogos grandes usam rolagem e se adaptam automaticamente ao tamanho atual da janela.

## Pesquisa

A pesquisa está disponível nos catálogos de:

- feitiços;
- itens;
- materiais;
- vantagens;
- criaturas.

Ela pode considerar não apenas o nome exibido, mas também o nome em inglês, a chave de localização, o identificador técnico ou o caminho XML.

A pesquisa não diferencia maiúsculas de minúsculas e tolera pequenos erros de digitação em palavras suficientemente longas.

A interface do MCM está localizada em 11 idiomas. Para o conteúdo normal do jogo, as traduções do próprio Noita são reutilizadas sempre que possível.

# Feitiços

A seção de feitiços permite trabalhar não apenas com o catálogo, mas também com os feitiços reais do jogador atual.

Ao mesmo tempo, ficam disponíveis:

- os espaços da varinha ativa;
- **SEMPRE LANÇAR**;
- o inventário de feitiços;
- o catálogo de feitiços.

## Substituição rápida

É possível selecionar um espaço específico da varinha e clicar com LMB no feitiço desejado no catálogo. Ele será colocado no espaço selecionado.

## Arrastar

Feitiços existentes podem ser movidos:

- entre os espaços da varinha;
- para **SEMPRE LANÇAR**;
- de **SEMPRE LANÇAR** de volta para os espaços normais;
- para espaços específicos do inventário de feitiços;
- do inventário de volta para a varinha;
- para o mundo do jogo;
- para a lixeira.

Para cartas já existentes, o MCM procura mover a própria entidade do jogo em vez de criar uma cópia nova. Isso permite preservar o estado alterado da carta, inclusive quando ele foi modificado por outro mod.

O feitiço de origem permanece no lugar até que o novo destino seja confirmado. Uma operação inválida ou malsucedida não deve destruir a carta original.

## Sempre Lançar

Os feitiços de **SEMPRE LANÇAR** têm uma área própria.

Ao mover feitiços entre os espaços normais e **SEMPRE LANÇAR**, a capacidade da varinha é levada em conta para que a estrutura dos espaços normais continue correta.

## Desfazer / Refazer

Para alterações internas da varinha, há um histórico limitado de **DESFAZER / REFAZER**.

Ele se aplica às operações que podem ser restauradas com segurança a partir do estado da própria varinha.

Nem sempre é possível reverter corretamente, com uma simples restauração de estado, a transferência de um feitiço real para o mundo ou para o inventário normal do jogo. Por isso, essas ações nem sempre podem ser desfeitas.

# Varinhas

O MCM inclui um editor completo da varinha ativa.

É possível alterar:

- espaços;
- feitiços por disparo;
- recarga;
- atraso de disparo;
- dispersão;
- velocidade;
- mana máxima;
- recarga de mana;
- recuperação de recuo;
- nível;
- embaralhar;
- modo sem recarga.

Também é possível alterar o visual e parâmetros relacionados:

- nome exibido;
- bloqueios;
- imagem da varinha;
- deslocamento da imagem;
- ponto de disparo.

Há um catálogo para escolher o visual da varinha.

## Varinhas salvas

É possível salvar uma varinha e usar seu estado salvo mais tarde.

São salvos:

- atributos;
- mana;
- visual;
- feitiços normais;
- **SEMPRE LANÇAR**;
- disposição das cartas;
- usos restantes;
- estado congelado das cartas.

As varinhas salvas continuam disponíveis entre mundos diferentes e em execuções posteriores do Noita.

### Aplicar

**APLICAR** aplica o estado salvo à varinha que o jogador está usando no momento.

### Cópia

**CÓPIA** cria uma cópia separada da varinha salva.

Se houver um espaço livre adequado no inventário rápido, a nova varinha é colocada nele. Caso contrário, ela é criada no mundo, perto do jogador.

Se a criação não puder ser concluída corretamente, o MCM procura remover a entidade incompleta.

# Itens e líquidos

## Itens

**LMB** em uma entrada do catálogo cria um item perto do jogador.

**RMB** tenta colocar o item diretamente no inventário.

O item também pode ser arrastado:

- para uma área adequada do inventário rápido;
- para fora do menu, até um ponto escolhido no mundo do jogo.

Se a carta for solta dentro do menu sem um destino válido, a operação é cancelada.

As entradas do catálogo são modelos, portanto a própria entrada não desaparece depois que um item é criado.

O MCM leva em conta a divisão normal do inventário rápido do Noita entre espaços para varinhas e itens e não deve substituir sem motivo um item que já esteja lá.

## Líquidos

O MCM pode criar recipientes reais do jogo com o líquido selecionado.

O recipiente criado se comporta como um item normal do Noita:

- pode ficar no inventário;
- pode ser jogado no mundo;
- pode quebrar;
- derrama seu conteúdo;
- participa das reações normais entre materiais.

# Materiais

O catálogo de materiais é montado a partir das substâncias registradas na instância atual do Noita.

Ele inclui diferentes tipos de materiais, entre eles:

- líquidos;
- pós;
- gases;
- fogo;
- sólidos;
- materiais estáticos;
- materiais com exibição especial.

Se outro mod ativo adicionar corretamente seu próprio material ao Noita, ele também poderá aparecer no MCM.

## Pintura com materiais

1. Escolha um material.
2. Escolha o tamanho do pincel.
3. Clique em **COMEÇAR A PINTAR**.
4. Feche o inventário.
5. Mantenha pressionado o botão atribuído para desenhar no mundo do jogo.

Por padrão, é usado o **botão do meio do mouse**.

Abrir o inventário encerra o modo de pintura.

## Comportamento dos materiais

O MCM cria materiais reais do mundo do jogo, não partículas decorativas.

Depois de colocados, eles continuam seguindo a simulação normal do Noita:

- líquidos fluem;
- pós caem;
- gases se espalham;
- fogo interage com o ambiente;
- substâncias participam de reações;
- materiais instáveis podem se transformar em outros.

Para diferentes tipos de material, o MCM usa métodos de colocação apropriados, incluindo recursos adicionais do NoitaPatcher nos casos que não podem ser tratados corretamente pelos meios comuns do mod.

# Vantagens

## Criação de vantagem

**LMB** cria a vantagem selecionada no mundo do jogo.

Ela pode ser coletada como uma vantagem normal do Noita.

## Obter vantagens

O MCM permite obter:

- 1 cópia;
- 10 cópias;
- 100 cópias.

A obtenção em massa é processada gradualmente para evitar que um grande número de operações pesadas seja executado em um único quadro.

A interface mostra o progresso da tarefa, e a execução restante pode ser cancelada. As cópias já obtidas com sucesso permanecem com o jogador após o cancelamento.

## Remoção de vantagens

Remover uma vantagem com segurança é muito mais difícil do que obtê-la.

Algumas vantagens alteram vários sistemas do jogo ao mesmo tempo, criam entidades ou iniciam efeitos para os quais não existe uma única forma universal de reversão.

Por isso, o MCM remove apenas alterações compatíveis para as quais consegue executar uma operação inversa com segurança suficiente.

O mod procura desfazer especificamente o estado criado pela aplicação correspondente da vantagem, sem redefinir desnecessariamente outros efeitos e parâmetros do jogador.

# Efeitos

O MCM permite aplicar e remover:

- efeitos do jogo compatíveis;
- estados relacionados a materiais.

Ao remover, o mod procura não afetar estados externos pertencentes a vantagens ou a outros sistemas do jogo.

Isso permite limpar os próprios efeitos do MCM sem remover indiscriminadamente todo estado semelhante do jogador.

# Criaturas e transformações

## Criação de criaturas

**LMB** cria a criatura selecionada perto do jogador.

A carta da criatura também pode ser arrastada para fora do menu para criá-la em um ponto escolhido do mundo do jogo.

**RMB** em uma entrada compatível tenta transformar o jogador atual na forma correspondente.

## Compatibilidade das formas

As criaturas do Noita podem ter estruturas internas muito diferentes.

Por isso, o MCM distingue os alvos de transformação pelos caminhos XML exatos e não considera automaticamente intercambiáveis todas as criaturas com nomes semelhantes.

Durante a transformação, o MCM usa as capacidades da forma escolhida e, quando necessário, aplica regras específicas de compatibilidade para determinadas criaturas.

# Retorno após uma transformação e morte da forma

É possível voltar à forma humana usando a ação atribuída — **TAB por padrão**.

Primeiro, o MCM usa os mecanismos normais do Noita para encerrar a transformação. Em casos mais complexos, há uma recuperação adicional com o NoitaPatcher.

O mod também trata situações compatíveis em que a forma temporária recebe dano fatal.

Nesses casos, o MCM tenta:

- manter o cadáver da forma morta;
- restaurar o jogador humano;
- devolver o controle;
- preservar o inventário;
- restaurar o estado relacionado ao jogador.

Isso não é imortalidade absoluta. Formas incomuns de morte causadas por outros mods, mods incompatíveis ou uma falha interna do Noita podem contornar o mecanismo normal de recuperação.

# Possessão de criatura

Além de escolher uma forma pelo catálogo, o MCM pode possuir **uma criatura que já existe no mundo do jogo**.

Por padrão, é usada a tecla **G**.

Aponte o cursor para um alvo adequado e use a ação atribuída.

O MCM verifica a criatura, realiza a transformação em uma forma compatível e só retira a entidade original do mundo depois que a transformação é confirmada como bem-sucedida.

Se a transformação não acontecer, a criatura original não deve simplesmente desaparecer.

Esse recurso não se limita ao catálogo estático do MCM. Uma criatura adequada adicionada por outro mod também pode passar pela verificação, embora não haja garantia de compatibilidade universal com qualquer criatura de terceiros.

# Jogador

**JOGADOR** é uma entrada especial do catálogo de criaturas.

Não é uma forma normal para transformação.

**LMB** cria um personagem separado, e o MCM tenta copiar:

- o visual do jogador;
- a vida máxima.

**RMB** na entrada **JOGADOR** não transforma um jogador humano nessa entidade.

Se o jogador já estiver na forma humana, a ação não faz nada. Se estiver transformado em outra criatura, a ação retorna à forma humana.

# Clima e horário

O MCM permite alterar:

- o horário;
- predefinições de clima;
- parâmetros específicos de clima compatíveis.

É possível definir o estado desejado e depois liberar o parâmetro correspondente do controle do MCM.

Por exemplo, depois de forçar um horário específico, é possível devolver ao Noita o fluxo natural do tempo.

# Regras do mundo

A seção **REGRAS** serve para alterações mais profundas no comportamento do mundo do jogo.

Dependendo da regra, é possível controlar parâmetros como:

- relações entre criaturas;
- ouro;
- uso de feitiços;
- névoa de guerra;
- recompensas por determinados tipos de morte;
- itens de cura derrubados;
- sangue;
- gravidade;
- comportamento físico;
- força do chute;
- juntas físicas;
- ciclo de dia e noite;
- outros parâmetros globais compatíveis.

A principal característica é que as regras do MCM são tratadas como **alterações reversíveis**.

Para configurações compatíveis, o mod preserva o estado original e permite restaurar os parâmetros aos valores normais.

Quando uma regra usa um multiplicador, o novo valor é calculado em relação ao estado de base, em vez de multiplicar repetidamente um resultado que já foi alterado.

Operações que precisam modificar um grande número de entidades ou objetos físicos são processadas gradualmente, para não tentar processar o mundo inteiro no momento exato em que o botão é pressionado.

# Teletransporte

O MCM permite viajar rapidamente para destinos preparados do jogo, incluindo pontos:

- da rota principal;
- das Montanhas Sagradas;
- de grandes áreas laterais;
- de outros locais compatíveis.

Antes do teletransporte, o mod pode carregar a área de destino e tenta encontrar um espaço livre por perto para não colocar o jogador diretamente dentro de uma parede sólida ou de outro obstáculo.

# Entangled Worlds

**Entangled Worlds / Noita Proxy é opcional.**

O MCM funciona completamente no modo de um jogador sem ele.

Com o Entangled Worlds instalado, recursos multijogador experimentais adicionais são ativados.

Para obter a melhor compatibilidade, recomenda-se usar a mesma versão do MCM com todos os participantes.

## Itens, varinhas e feitiços

Sempre que possível, itens no mundo e feitiços descartados usam os mecanismos padrão do Entangled Worlds.

Alterações no inventário também podem ser transmitidas pelo Entangled Worlds.

## Vantagens

Uma vantagem criada pelo MCM continua sendo uma entidade real do jogo e, sempre que possível, é transmitida pelo sistema normal de itens do mundo do Entangled Worlds.

## Materiais

A pintura com materiais tem suporte multijogador experimental.

O MCM sincroniza as áreas afetadas do mundo para que o resultado possa aparecer para os outros participantes.

Para funcionar corretamente, o material correspondente também precisa existir para o outro jogador. Se os conjuntos de mods forem diferentes, não é possível garantir a mesma aparência de todos os materiais.

## Clima e regras do mundo

Alterações compatíveis de clima e regras globais podem ser sincronizadas pelo Entangled Worlds.

## Transformações e possessão de criaturas

As transformações têm suporte adicional ao usar Entangled Worlds.

Ao possuir uma criatura que já existe, o mod também leva em conta seu estado de rede. Se o MCM não puder determinar com segurança suficiente que a entidade original pode ser removida, ele prefere deixá-la no mundo.

## Jogador

A criação da entidade especial **JOGADOR** também é compatível com o Entangled Worlds. Nesse caso, ela copia as cores do visual de quem a criou.

## Teletransporte entre jogadores

Quando Entangled Worlds está ativo, os jogadores disponíveis são exibidos na seção de teletransporte.

**IR ATÉ** move você até o jogador selecionado.

**TRAZER AQUI** envia ao jogador selecionado uma solicitação para se mover até você.

Nos dois casos, o MCM procura usar um espaço livre próximo ao ponto de destino.

## Limitações

O suporte ao Entangled Worlds continua experimental.

**Em uma partida multijogador, transformar-se em chefes grandes ou com várias articulações pode causar uma queda crítica de desempenho e, na prática, inutilizar a sessão atual.**

É extremamente difícil sincronizar completamente o Noita, especialmente quando várias destas coisas mudam ao mesmo tempo:

- o mundo de pixels;
- materiais;
- objetos físicos;
- criaturas e chefes complexos;
- conteúdo de outros mods.

Por isso, o MCM não promete sincronização perfeita de todo estado possível.

# NoitaPatcher e mods inseguros

A versão completa do MCM inclui o **NoitaPatcher**.

Ele é usado para recursos que não podem ser implementados apenas com os meios comuns de modificação do Noita, incluindo parte dos mecanismos de:

- recuperação após transformações complexas;
- trabalho com entidades do jogo;
- trabalho com o mundo do jogo;
- colocação de alguns materiais;
- compatibilidade ampliada.

Por isso, é necessário permitir **Mods inseguros** para usar a versão completa.

O NoitaPatcher já vem incluído na compilação pronta do MCM. Não é necessário instalá-lo separadamente.

# Se algo não funcionar

## O MCM não carrega

Confira se, depois da extração, existe:

```text
Noita/mods/metamorph_creative_menu/mod.xml

```

Verifique se:

- o MCM está ativado no menu **Mods**;
- há **[x]** ao lado dele;
- **Mods inseguros: Permitidos**;
- o jogo foi iniciado com mods ativos.

## Recursos que usam NoitaPatcher não funcionam

Confira se existe:

```text
metamorph_creative_menu/NoitaPatcher/noitapatcher.dll

```

e verifique se **Mods inseguros** estão permitidos.

## Não é possível voltar da forma atual

Tente a ação de retorno atribuída — **TAB por padrão**.

Se o problema continuar, ao criar um relatório é recomendável informar:

- o nome exato da criatura;
- o caminho XML, se conhecido;
- como a forma foi obtida;
- se o retorno normal funciona;
- se o problema acontece apenas após dano fatal;
- se Entangled Worlds está sendo usado.

## Problemas com Entangled Worlds

Verifique:

- se todos usam a mesma versão do MCM;
- se as versões do Entangled Worlds são compatíveis;
- se todos usam o mesmo conjunto de mods quando o problema envolve materiais ou criaturas de outros mods.

# Relatar um erro

[Criar uma Issue](https://github.com/zerodancing/Metamorph-Creative-Menu/issues)

Para um relatório útil, é recomendável informar:

- a versão do MCM;
- o que você estava fazendo;
- o resultado esperado;
- o resultado obtido;
- o nome da criatura, item, vantagem ou material;
- se Entangled Worlds está sendo usado;
- outros mods que possam estar relacionados ao problema;
- o texto do erro ou o trecho correspondente do registro;
- uma captura de tela ou vídeo, se ajudarem a mostrar o problema.

# Componentes de terceiros

- **Noita** — Nolla Games.
- **NoitaPatcher** — dextercd, incluído na versão completa.
- **lbase64** — Ilya Kolbin, incluído no MCM.
- **Entangled Worlds / Noita Proxy** — IntQuant e colaboradores do projeto, instalado separadamente e opcional.

Informações detalhadas sobre os projetos originais e as licenças estão em [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

---

**Metamorph: Creative Menu** é um mod não oficial criado por usuários para Noita. O projeto não é afiliado à Nolla Games e não faz parte oficial do jogo.

[↑ Voltar à seleção de idioma](#languages)
