<a id="languages"></a>

[English](README.md) · [Русский](README.ru.md) · [**Português (Brasil)**](README.pt-BR.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Italiano](README.it.md) · [Polski](README.pl.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

<h1 align="center">Metamorph: Creative Menu</h1>

<p align="center">Um menu criativo e conjunto de ferramentas sandbox para Noita: feitiços, varinhas, itens, materiais, perks, efeitos, criaturas, transformações, possessão, teleporte, clima, regras do mundo, integração multiplayer e ferramentas de recuperação.</p>

<p align="center"><strong>Criador e mantenedor: <a href="https://github.com/zerodancing">zerodancing</a></strong></p>

---

# Download

Para jogar normalmente, use a build pronta para instalar:

[**⬇️ Baixar a build mais recente**](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip)

[Página da build mais recente](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build) · [Changelog](metamorph_creative_menu/CHANGELOG.txt)

A release do GitHub é gerada automaticamente a partir da árvore completa de desenvolvimento. Testes, ferramentas de QA, diagnósticos, código-fonte nativo e ferramentas de build permanecem no repositório, mas são excluídos do arquivo para jogadores.

A build standalone do GitHub inclui NoitaPatcher e suporte nativo de recuperação, portanto **Unsafe Mods precisa estar permitido**.

# Instalação

1. Baixe `Metamorph-Creative-Menu.zip` pelo link acima.
2. Inicie Noita e abra **Mods** no menu principal.
3. Clique em **Open mods folder**.
4. Extraia ou mova a pasta `metamorph_creative_menu` para a pasta `mods`. O caminho final deve conter `metamorph_creative_menu/mod.xml` diretamente, sem uma pasta extra criada pelo arquivo compactado.
5. Se já houver uma cópia antiga, substitua a pasta `metamorph_creative_menu` inteira em vez de mesclar arquivos antigos e novos.
6. Volte ao Noita e atualize a lista de mods.
7. Permita **Unsafe Mods**.
8. Ative **Metamorph: Creative Menu** e inicie um jogo com os mods ativos.

Não ative a build standalone do GitHub e a versão da Steam Workshop ao mesmo tempo.

# Build standalone e Steam Workshop

A build distribuída por este repositório do GitHub é a build standalone completa. Ela inclui NoitaPatcher e recursos que precisam de acesso irrestrito à API de mods, incluindo operações de baixo nível com materiais e recuperação nativa após Game Over.

A [build da Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3785170245) é instalada separadamente. Ela não inclui os componentes nativos necessários para os recursos exclusivos da build standalone.

As duas builds usam a mesma identidade de mod. Instalar ambas ao mesmo tempo pode causar arquivos duplicados ou conflitantes e não é suportado.

# Sobre o mod

**Metamorph: Creative Menu (MCM)** é um menu criativo e toolkit sandbox para Noita.

Ele reúne ferramentas para:

- feitiços e inventário de feitiços;
- edição de varinhas e presets reutilizáveis;
- itens e recipientes com líquidos;
- catálogo completo de materiais e pintura de materiais;
- perks e remoção suportada de perks;
- efeitos de status e entidades GameEffect;
- criaturas, transformações e possessão;
- clima e horário;
- regras globais do mundo;
- teleporte;
- integração opcional com Entangled Worlds;
- recuperação após transformação, morte da forma e Game Over.

O MCM tenta operar sobre o estado real do Noita em vez de substituir tudo por cópias decorativas. Cartas de feitiço existentes são movidas como entidades, a entrega de itens respeita a estrutura do inventário, alterações de varinhas usam caminhos de commit/rollback, materiais continuam sendo materiais simulados de verdade e regras reversíveis preservam estado original suficiente para restaurar configurações suportadas depois.

Entangled Worlds é opcional. Sem ele, o MCM continua sendo um mod completo para single-player.

# Controles

Controles padrão:

| Ação | Entrada padrão |
| --- | --- |
| Abrir / fechar o menu criativo | **F4** |
| Voltar à forma humana durante uma transformação | **TAB** |
| Possuir uma criatura no mundo | **G** |
| Desenhar com o material selecionado | **Botão do meio do mouse** |

O painel criativo também fica disponível pela interface normal do inventário do Noita.

As teclas podem ser alteradas na seção **CONTROLS** do MCM e nas configurações de mod do Noita. São suportadas teclas, botões do mouse e combinações exatas de **CTRL / SHIFT / ALT**.

Durante a captura de uma tecla:

- **DELETE / BACKSPACE** limpa a associação;
- **ESC** cancela;
- **R** restaura o padrão daquela ação;
- **RESET ALL** restaura todas as associações padrão após confirmação.

Associações duplicadas continuam editáveis, mas o MCM mostra o conflito em vez de substituir silenciosamente outra ação.

Ações de navegação do menu, seções, retorno da forma, possessão, pintura de materiais, limpeza de efeitos, liberação do clima, reset de regras do mundo e ações multiplayer suportadas podem ser remapeadas.

# Janela do Creative Menu

O painel criativo direto é uma janela redimensionável e persistente, não um overlay de debug fixo.

Ela pode ser:

- movida pela barra de título;
- redimensionada pelas bordas e cantos;
- minimizada;
- fechada;
- restaurada para o layout padrão.

Posição, largura, altura e última seção aberta são lembradas entre execuções. Depois de mudanças de resolução, a geometria salva é ajustada para permanecer dentro da área visível da interface.

Listas e catálogos usam layouts medidos e contêineres de rolagem do Noita. Redimensionar a janela muda imediatamente quanto conteúdo cabe na tela, e textos traduzidos podem quebrar em mais linhas sem sobrepor controles vizinhos. Em layouts estreitos, os controles passam para novas linhas em vez de se desenharem uns sobre os outros.

Apenas abrir ou passar o mouse sobre o menu destacado não desativa permanentemente o gameplay. Quando um clique, arrasto ou campo de texto focado também poderia acionar o personagem, o MCM suprime temporariamente os controles relevantes e os restaura em seguida.

# Busca e localização

A busca está disponível nos principais catálogos, incluindo feitiços, itens, materiais, perks e criaturas.

Dependendo da entrada, ela pode encontrar:

- o nome no idioma atual da interface;
- o nome em inglês;
- chaves de localização;
- identificadores técnicos;
- caminhos XML.

A busca ignora maiúsculas/minúsculas, normaliza acentos e separadores comuns e tolera pequenos erros de digitação em consultas mais longas.

A interface própria do MCM é localizada em:

- inglês;
- russo;
- português brasileiro;
- espanhol;
- alemão;
- francês;
- italiano;
- polonês;
- chinês simplificado;
- japonês;
- coreano.

Para conteúdo comum do Noita, o mod reutiliza as chaves de localização do próprio jogo sempre que possível em vez de manter nomes duplicados.

# Feitiços

A seção de feitiços trabalha tanto com o catálogo quanto com entidades de feitiço que já pertencem ao jogador.

A área principal mostra:

- os slots normais da varinha ativa;
- as cartas **ALWAYS CAST**;
- o inventário de feitiços do jogador;
- o catálogo pesquisável de feitiços.

## Substituição rápida do slot selecionado

Um clique curto seleciona um slot da varinha. Depois disso, um clique curto com LMB em um feitiço do catálogo substitui o slot selecionado.

Esse é o caminho rápido para edição comum. Movimentos precisos usam drag-and-drop.

## Drag-and-drop transacional

Cartas existentes podem ser arrastadas:

- entre slots da varinha;
- de slots comuns para **ALWAYS CAST**;
- de **ALWAYS CAST** de volta para slots comuns;
- para um slot exato do inventário de feitiços;
- do inventário de volta para a varinha;
- para o mundo;
- para a lixeira quando suportado.

Para uma carta existente, o MCM move a entidade real sempre que possível. Assim, estado mutável, usos restantes e dados adicionados por outros mods não são perdidos apenas porque a carta mudou de lugar.

A origem permanece intacta até a transação de destino ser confirmada. Alvos inválidos ou desconhecidos cancelam a operação em vez de apagar a carta original. Uma soltura do mouse executa no máximo uma operação confirmada.

Cartas do catálogo são apenas templates e nunca são consumidas ao arrastar.

## Always Cast

Cartas Always Cast têm sua própria faixa. Promoção, remoção e troca levam em conta a capacidade efetiva dos slots comuns para evitar uma estrutura inválida de varinha.

## Desfazer e refazer

Mudanças internas da varinha têm um histórico limitado de **UNDO / REDO**.

Operações que entregam uma entidade real ao mundo ou a outro inventário nem sempre podem ser revertidas com segurança a partir de um snapshot da varinha, então essas transferências externas não são prometidas como universalmente reversíveis.

# Varinhas

A área de varinha edita a varinha atualmente segurada pelo jogador.

Estatísticas suportadas incluem:

- capacidade / slots;
- feitiços por disparo;
- tempo de recarga;
- atraso entre disparos;
- dispersão;
- multiplicador de velocidade de projétil;
- mana máxima;
- velocidade de recarga de mana;
- recuperação de recuo;
- nível da varinha;
- shuffle;
- comportamento sem recarga.

O MCM também edita apresentação e metadados relacionados:

- nome exibido;
- bloqueios da varinha e das cartas;
- caminho do sprite;
- offsets do sprite;
- posição de disparo.

Um catálogo visual de aparências segue dados de XML de varinhas quando disponíveis.

## Presets de varinha

Varinhas podem ser salvas como presets nomeados persistentes e reutilizadas em outros mundos ou futuras sessões de Noita.

Um preset pode guardar:

- estatísticas da varinha;
- valores de mana;
- metadados visuais;
- cartas comuns;
- cartas Always Cast;
- posições dos slots;
- usos restantes;
- estado congelado das cartas.

Cada preset tem duas operações diferentes:

- **APPLY** grava o blueprint salvo na varinha atualmente segurada;
- **GET COPY** constrói uma nova varinha com o mesmo blueprint.

A cópia vai para um slot livre de varinha no inventário rápido quando possível. Se não houver slot adequado, a varinha concluída é deixada no mundo perto do jogador.

Substituição de varinha e carregamento de preset usam caminhos de commit/rollback. Se a construção ou colocação falhar, o MCM tenta remover a árvore de entidade incompleta em vez de deixar uma varinha parcial quebrada.

# Itens e líquidos

## Itens

Um clique curto com **LMB** em uma entrada do catálogo cria um item suportado perto do jogador.

**RMB** tenta entregar o item à área adequada do inventário.

Entradas do catálogo também podem ser arrastadas:

- para um alvo compatível no inventário rápido;
- para fora do menu, em uma posição exata do mundo.

Soltar a carta dentro do menu sem um destino válido cancela a operação. A carta do catálogo é apenas um template e permanece disponível.

O MCM respeita a separação normal do inventário rápido do Noita entre slots de varinha e slots de item. Se houver falha ao carregar XML, preencher líquido, transferir para o inventário ou fazer uma transferência multiplayer opcional, a nova entidade é removida quando possível.

Alguns itens de inventário legítimos ficam em diretórios do jogo orientados a criaturas. O MCM classifica casos conhecidos pelo comportamento em vez de assumir que o nome da pasta sozinho define se algo é item ou criatura.

## Líquidos

Entradas de líquido criam recipientes reais do Noita já preenchidos, não objetos decorativos da interface.

O recipiente resultante pode ser carregado, jogado, quebrado e derramado, e seu conteúdo participa das reações normais de materiais.

# Materiais

A seção Materials é uma ferramenta de pintura do mundo baseada no registro real de materiais do Noita.

O catálogo é montado a partir de líquidos, areias / pós, gases, fogos, sólidos e materiais estáticos ou de efeitos registrados pelo engine. Materiais adicionados corretamente por outros mods ativos podem aparecer automaticamente.

Descoberta e validação cara de materiais são distribuídas em trabalho limitado, em vez de varrer todo o catálogo em um único frame da interface.

## Apresentação dos materiais

Líquidos usam a mesma apresentação de recipiente preenchido da seção de itens.

Para materiais não líquidos, o MCM prefere texturas e tint definidos em `materials.xml`, incluindo definições herdadas. Se não houver textura autoral, o fallback vem da cor real do material no engine e não de uma cor de preview arbitrária.

## Pintura

1. Escolha um material.
2. Escolha o tamanho do pincel.
3. Ative o modo de pintura.
4. Feche o inventário.
5. Segure a entrada configurada de desenho no mundo.

Abrir o inventário interrompe o modo de pintura ativo.

A pintura não emite apenas partículas decorativas. O MCM coloca células reais no mundo por um caminho apropriado ao engine. Materiais dinâmicos continuam seguindo a simulação do Noita: líquidos fluem, pós caem, gases se movem, fogo reage e substâncias instáveis podem se transformar por reações materiais.

Classes diferentes exigem estratégias diferentes de colocação. A build standalone pode usar acesso direto à grade do mundo por NoitaPatcher e um pequeno fallback de PixelScene para casos autorais que o Noita recusa construir diretamente em determinada coordenada da textura.

As filas são limitadas para que manter um pincel grande pressionado não execute deliberadamente trabalho ilimitado em um único frame.

# Perks

## Criar e receber perks

**LMB** cria um pickup normal do perk selecionado no mundo.

A ação de receber pode conceder o perk individualmente ou em lote. Operações em lote são processadas como jobs limitados, em vez de aplicar todas as cópias em um único frame de UI.

A interface mostra o progresso, e o trabalho ainda pendente pode ser cancelado. Cópias já confirmadas antes do cancelamento permanecem aplicadas.

Cada cópia concedida ainda passa pelo caminho normal de aplicação de perk em vez de falsificar diretamente o estado final.

## Remover perks

Remover um perk é muito mais difícil do que concedê-lo. Perks podem alterar globals, componentes, entidades, estatísticas do jogador e mecânicas de longa duração, e o Noita não fornece uma operação inversa universal.

Por isso o MCM só remove estado para o qual tenha uma inversão rastreada considerada suficientemente segura. O journal da transação tenta retirar apenas o estado pertencente àquela aplicação específica do perk, sem resetar estado não relacionado do jogador.

Se a limpeza ficar parcial ou não puder ser provada como completa, ela continua marcada como incompleta em vez de ser relatada silenciosamente como bem-sucedida.

Perks de terceiros podem ser concedidos sem necessariamente poderem ser removidos corretamente.

# Efeitos

A seção Effects aplica e remove status de materiais e entidades GameEffect suportadas.

A remoção considera propriedade quando possível. O MCM evita apagar indiscriminadamente efeitos ocultos semelhantes que pertencem a perks, ao jogo ou a outro sistema.

Efeitos persistentes criados pelo MCM usam limpeza / expiração limitada para que remover um efeito do MCM não resete estado alheio.

# Criaturas

O catálogo de criaturas preserva caminhos XML exatos em vez de juntar todas as entidades com nomes parecidos.

Interações suportadas:

- **LMB** — cria a entidade autoral selecionada perto do jogador;
- arrastar para fora do menu — cria na posição confirmada do cursor no mundo;
- **RMB** — transforma o jogador atual em uma forma suportada;
- entrada especial **PLAYER** — cria ou restaura estado de jogador como descrito abaixo.

Soltar uma carta arrastada de volta sobre o menu cancela a criação no mundo.

Regras de compatibilidade para formas perigosas ou incomuns usam caminhos exatos. Um nome de arquivo que apenas contenha uma palavra familiar não faz a entidade ser automaticamente tratada como outra forma equivalente.

# Transformações e retorno à forma humana

Formas jogáveis mantêm movimento nativo útil, ataques, aparência e física quando prático. Componentes que competem diretamente com o input do jogador podem ser desativados ou adaptados enquanto a forma estiver sob controle do jogador.

Algumas criaturas complexas exigem lógica adicional. Bosses, wrappers scriptados e entidades pesadas de física não são garantidos a se comportar exatamente como suas versões controladas pela IA quando usados como forma do jogador.

A ação configurada de retorno — **TAB por padrão** — primeiro usa o caminho normal de encerramento da transformação. Quando isso não basta, a build standalone possui caminhos adicionais de restauração via NoitaPatcher.

Em casos suportados de dano fatal, o MCM tenta:

- deixar a forma temporária morta ou cadáver no mundo quando apropriado;
- restaurar uma entidade humana do jogador;
- devolver authority e controles;
- preservar o inventário;
- restaurar estado relevante do jogador.

Isso é lógica de recuperação, não imortalidade absoluta. Um kill script de terceiro, estado incompatível do engine ou crash do processo pode ignorar esse handoff suportado.

# Possessão

Possessão controla uma criatura que já existe no mundo em vez de escolher uma forma pelo catálogo.

A tecla padrão é **G**.

Aponte para uma criatura adequada e use a ação de possessão. O MCM valida o alvo, prepara uma transição compatível e remove ou aposenta a entidade original do mundo apenas depois de confirmar o novo estado controlado pelo jogador.

Se a transição falhar, a criatura original não deve simplesmente desaparecer.

A possessão não se limita ao catálogo interno do MCM. Uma criatura compatível criada por outro mod pode funcionar, mas compatibilidade universal com toda entidade de terceiros não é garantida.

# Entrada Player

**PLAYER** é uma entrada especial do catálogo de criaturas, não um alvo comum de polymorph.

Sua ação de spawn cria um personagem separado semelhante ao jogador e tenta copiar apresentação apropriada e informação de vida máxima.

Usar a ação de transformação em **PLAYER** não transforma um jogador já humano em uma duplicata. Se o jogador estiver em outra forma, a ação serve como retorno à forma humana.

# Recuperação de Game Over em single-player

A build standalone para single-player inclui um caminho adicional de recuperação para a tela padrão de Game Over do Noita.

Quando a integração nativa consegue identificar com segurança as estruturas necessárias do jogo, o MCM adiciona a ação **“I didn't die”** à interface de Game Over.

Durante o jogo, o MCM mantém um backup rotativo do estado do jogador. Ativar a recuperação solicita a restauração pelo caminho normal de atualização do MCM, em vez de reconstruir o jogador inteiro diretamente no handler do clique da interface.

Uma recuperação suportada tenta:

- restaurar ou obter uma entidade viva do jogador;
- torná-la authoritative novamente;
- limpar o estado Game Over do engine;
- devolver controles e estado utilizável do jogador;
- fazer limpeza best-effort de áudio, música e interface do Game Over;
- fornecer uma curta janela de proteção após a restauração.

O helper nativo foi projetado para falhar de forma segura. Ele procura estruturas conhecidas no executável suportado do Noita em execução em vez de escrever para um único endereço fixo para sempre. Se as estruturas esperadas não puderem ser identificadas com segurança após uma atualização do jogo, a recuperação opcional não é usada em vez de escrever em um endereço incerto.

# Clima e horário

O MCM controla estado suportado de clima e horário, incluindo presets e parâmetros individuais expostos pela implementação atual.

Um estado forçado pode ser liberado de volta para o controle normal do jogo. Por exemplo, depois de fixar um horário específico, o MCM pode parar de possuir essa configuração para que o ciclo natural do Noita continue.

Mudanças climáticas são tratadas como estado controlado, não como comandos de console sem retorno.

# Regras do mundo

A seção **RULES** altera comportamento global suportado do jogo.

As regras abrangem áreas como:

- relações entre criaturas;
- comportamento do ouro;
- uso de feitiços;
- fog of war;
- recompensas específicas de morte;
- drops de cura;
- comportamento de sangue;
- gravidade;
- física;
- força do chute;
- juntas físicas;
- ciclo dia/noite;
- outros parâmetros globais suportados.

O objetivo principal é reversibilidade.

Para regras suportadas, o MCM registra ou deriva o estado original para poder restaurá-lo depois. Controles multiplicadores são aplicados em relação ao valor original em vez de multiplicar repetidamente um resultado já modificado.

Regras que precisam tocar muitas entidades ou objetos físicos usam trabalho limitado ao longo dos frames em vez de tentar reescrever o mundo inteiro de forma síncrona com um clique.

# Teleporte

A seção de teleporte oferece destinos preparados pelo mundo, incluindo pontos na rota principal, Holy Mountains, áreas laterais importantes e outros locais suportados.

Antes de mover o jogador, o MCM pode solicitar o carregamento da área e procura espaço utilizável próximo em vez de colocar o jogador diretamente dentro de terreno sólido.

O teleporte ainda depende de o mundo conseguir carregar e fornecer um destino válido. Mundos muito modificados podem exigir comportamento de fallback.

# Entangled Worlds

**Entangled Worlds / Noita Proxy é opcional.** O MCM funciona sem ele.

Quando EW está presente, o MCM habilita comportamento adicional consciente de multiplayer. Todos os peers devem usar builds compatíveis do MCM ao depender de estado sincronizado específico do MCM.

## Authority e formas

Formas do jogador exigem tratamento especial de ownership porque um jogador transformado não deve deixar acidentalmente uma segunda authority de rede.

O MCM coordena ownership, retirement e retorno à forma humana com EW onde suportado. Entidades de boss e do tipo Kolmi têm tratamento adicional de lifecycle destinado a impedir authorities duplicadas e cópias antigas controladas pela rede.

O caminho normal de morte do EW continua responsável por entidades que não são reconhecidas como estado de forma pertencente ao MCM.

## Itens, varinhas e feitiços

Quando possível, o MCM usa os mecanismos normais de item / inventário do EW em vez de inventar um sistema de transporte paralelo.

Mutações confirmadas de varinha e inventário de feitiços solicitam o refresh multiplayer apropriado quando a integração está disponível. Itens de mundo criados pelo MCM podem ser entregues ao caminho padrão de world items do EW.

## Perks

Pickups normais de perks podem usar a sincronização padrão de world items do EW. O tratamento de estado de perk do MCM coordena refresh e operações limitadas para que ações em lote não tentem emitir um refresh global caro para cada cópia.

## Materiais

Pintura de materiais tem um caminho especial de compatibilidade porque mudanças em células do mundo não são entidades de item comuns.

O MCM mantém o trabalho de pintura limitado, separa trabalho nas fronteiras de chunks e coordena etapas necessárias de world-frame / persistência do EW antes de liberar trabalho de conversão sincronizada. Um chunk de borda ainda não carregado é adiado em vez de bloquear todo o traço atual.

O objetivo é permitir que peers próximos vejam o estado pintado suportado sem reproduzir remotamente a ação normal da interface do MCM como uma chamada PixelScene baseada apenas em filename.

Isso ainda herda as suposições de material id do EW: um jogo receptor não pode criar corretamente um material inexistente ou cujo registro de materiais do engine seja incompatível.

## Clima, possessão e estado do mundo

Estado multiplayer suportado do MCM também inclui coordenação de clima, possessão e comportamento selecionado de regras / lifecycle. Verificações de authority evitam que dois peers tentem possuir o mesmo estado ao mesmo tempo.

O suporte a EW é deliberadamente conservador. Quando a integração não consegue provar um caminho sincronizado seguro, o MCM prefere o comportamento local suportado em vez de fingir que toda operação single-player é automaticamente segura em multiplayer.

# Compatibilidade e limitações

Noita expõe muitos sistemas por entidades fracamente acopladas, XML, componentes Lua e comportamento nativo do engine. Por isso o MCM não pode prometer compatibilidade universal com toda entidade modificada ou toda futura atualização do jogo.

Limitações importantes:

- uma criatura poder ser criada não significa que seja uma forma jogável segura;
- um perk poder ser concedido não significa que tenha inversão confiável;
- transferências externas de feitiços ou itens nem sempre podem ser desfeitas a partir de um snapshot interno;
- scripts de terceiros podem ignorar caminhos suportados de morte e recuperação;
- recursos nativos de recuperação dependem de comportamento suportado do executável do Noita e falham de forma segura se as estruturas necessárias não puderem ser identificadas;
- Entangled Worlds não consegue sincronizar um material ausente no registro do jogo receptor;
- inventários, entidades ou regras muito modificados podem exigir compatibilidade específica para aquele mod.

O MCM tenta preservar estado original e reverter mutações que falham, mas uma ferramenta sandbox que altera o estado vivo do jogo não pode tornar toda combinação de mods de terceiros totalmente transacional.

# Dados salvos

O MCM persiste estado de usuário que deve sobreviver entre execuções, incluindo configurações suportadas, teclas, layout do menu e presets de varinha.

A identidade do mod permanece estável para que atualizações normais preservem dados suportados. Ainda é recomendado substituir a pasta inteira do mod ao instalar uma nova build standalone, pois mesclar arquivos antigos e novos pode deixar runtime obsoleto para trás.

# Solução de problemas

## O mod não aparece

Confirme que a estrutura termina em:

`mods/metamorph_creative_menu/mod.xml`

Uma pasta extra acima de `metamorph_creative_menu` impede o Noita de encontrar o mod corretamente.

## Recursos nativos ou de materiais não funcionam

Confirme que **Unsafe Mods** está permitido e que você instalou a build standalone do GitHub, sem misturar arquivos da Workshop.

## O menu abre, mas uma ação do jogo também dispara

Verifique conflitos nas teclas personalizadas. O MCM mostra associações duplicadas, mas permite mantê-las se você realmente quiser.

## Uma criatura não pode ser transformada com segurança

Nem toda entidade XML que pode ser criada é uma forma de jogador suportada. Regras por caminho exato existem para criaturas que precisam de tratamento especial.

## Um perk não pode ser removido

A remoção só está disponível onde o MCM possui uma operação inversa suportada para o estado rastreado. Isso é intencional; tentar adivinhar uma limpeza pode danificar estado não relacionado do jogador.

## O multiplayer se comporta diferente entre peers

Use builds compatíveis do MCM em todos os participantes e mantenha Noita / Entangled Worlds compatíveis. O MCM não pode corrigir um registro de materiais incompatível nem alterações de rede arbitrárias de outros mods.

# Relatando bugs

Um bom relatório deve incluir:

- o que você estava tentando fazer;
- a seção e ação exatas do MCM;
- se ocorre em single-player, Entangled Worlds ou ambos;
- se a build standalone ou Workshop está instalada;
- se outros mods de gameplay estão ativos;
- passos confiáveis de reprodução;
- logs relevantes de Noita / EW quando disponíveis.

Para problemas de transformação, possessão, item ou material, inclua a entidade ou material exato quando possível. Identificadores técnicos normalmente são mais úteis que o nome traduzido exibido.

# Repositório e fonte de desenvolvimento

O repositório contém intencionalmente a **árvore completa de desenvolvimento**, e não o mesmo arquivo reduzido que os jogadores baixam.

`metamorph_creative_menu/` contém código runtime junto com:

- testes automatizados;
- ferramentas de QA;
- diagnósticos;
- código-fonte nativo;
- ferramentas de build;
- regras de limpeza de release;
- documentação de desenvolvimento.

Esses arquivos são úteis para desenvolvimento e testes de regressão, por isso permanecem no source do GitHub. O ZIP pronto para jogadores é gerado separadamente e exclui conteúdo exclusivo de desenvolvimento.

O pacote de jogador também recebe limpeza específica de release, incluindo o `README.txt` mínimo do pacote, enquanto a árvore source mantém sua documentação de desenvolvimento.

# Testes

A suíte automatizada fica em `metamorph_creative_menu/tests/` e combina verificações de contrato em Python com mocks em Lua.

A partir da raiz do repositório, o workflow de release executa a suíte contra o source completo importado antes de publicar a build de jogador. `texlua` é necessário para a parte dos mocks Lua.

Verificações de source hygiene também protegem arquivos voltados à produção e documentação contra restos de histórico de desenvolvimento, interfaces antigas de debug e artefatos acidentais do processo.

# Importação do source e processo de release

O source completo de desenvolvimento pode ser importado de um arquivo da família `Metamorph-Creative-Menu-v...zip`.

O workflow de importação verifica a estrutura, exige os componentes completos de desenvolvimento, executa source hygiene e a suíte de regressão antes de commitar a árvore importada.

Um arquivo ModWorkshop / player-style não é tratado como source de desenvolvimento.

A release pública `latest-build` é então produzida a partir do source completo por um builder separado. Ele remove QA, testes, diagnósticos, código-fonte nativo e outro payload exclusivo de desenvolvimento, aplica regras de limpeza, valida o arquivo final e só então atualiza o asset estável de download.

Essa separação permite que o repositório continue útil para desenvolvimento enquanto o download normal do jogador permanece pequeno e sem instrumentação de desenvolvimento.

# Componentes de terceiros

Componentes de terceiros, dependências incluídas e projetos upstream são documentados em [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
