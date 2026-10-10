<a id="languages"></a>

[English](README.md) · [Русский](README.ru.md) · [Português (Brasil)](README.pt-BR.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [**Italiano**](README.it.md) · [Polski](README.pl.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

<h1 align="center">Metamorph: Creative Menu</h1>

<p align="center">Un menu creativo e toolkit sandbox per Noita: incantesimi, bacchette, oggetti, materiali, perk, effetti, creature, trasformazioni, possessione, teletrasporto, meteo, regole del mondo, integrazione multiplayer e strumenti di recupero.</p>

<p align="center"><strong>Creatore e maintainer: <a href="https://github.com/zerodancing">zerodancing</a></strong></p>

---

# Download

Per giocare normalmente, usa la build pronta da installare:

[**⬇️ Scarica la build più recente**](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip)

[Pagina della build più recente](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build) · [Changelog](metamorph_creative_menu/CHANGELOG.txt)

La release GitHub viene generata automaticamente dall'albero completo di sviluppo. Test, strumenti QA, diagnostica, sorgenti native e strumenti di build restano nel repository ma vengono esclusi dall'archivio per i giocatori.

La build standalone GitHub include NoitaPatcher e supporto nativo di recupero, quindi **Unsafe Mods deve essere consentito**.

# Installazione

1. Scarica `Metamorph-Creative-Menu.zip` dal link qui sopra.
2. Avvia Noita e apri **Mods** dal menu principale.
3. Fai clic su **Open mods folder**.
4. Estrai o sposta la cartella `metamorph_creative_menu` nella cartella `mods`. Il percorso finale deve contenere direttamente `metamorph_creative_menu/mod.xml`, senza una cartella extra creata dall'archivio.
5. Se è già presente una copia vecchia, sostituisci l'intera cartella `metamorph_creative_menu` invece di unire file vecchi e nuovi.
6. Torna in Noita e aggiorna la lista dei mod.
7. Consenti **Unsafe Mods**.
8. Attiva **Metamorph: Creative Menu** e avvia una partita con i mod attivi.

Non attivare contemporaneamente la build standalone GitHub e la versione Steam Workshop.

# Build standalone e Steam Workshop

La build distribuita tramite questo repository GitHub è la build standalone completa. Include NoitaPatcher e funzioni che richiedono accesso non limitato alla mod API, comprese operazioni a basso livello sui materiali e recupero nativo dopo Game Over.

La [build Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3785170245) viene installata separatamente. Non include i componenti nativi necessari alle funzioni disponibili solo nella build standalone.

Le due build usano la stessa identità del mod. Installarle entrambe può quindi causare file duplicati o in conflitto e non è supportato.

# Informazioni sul mod

**Metamorph: Creative Menu (MCM)** è un menu creativo e toolkit sandbox per Noita.

Riunisce strumenti per:

- incantesimi e inventario degli incantesimi;
- modifica delle bacchette e preset riutilizzabili;
- oggetti e contenitori di liquidi;
- catalogo completo dei materiali e pittura con materiali;
- perk e rimozione supportata dei perk;
- status ed entità GameEffect;
- creature, trasformazioni e possessione;
- meteo e tempo;
- regole globali del mondo;
- teletrasporto;
- integrazione opzionale con Entangled Worlds;
- percorsi di recupero dopo trasformazioni, morte della forma e Game Over.

MCM prova a lavorare sullo stato reale di Noita invece di sostituire tutto con copie decorative. Le carte di incantesimo esistenti vengono spostate come entità, la consegna degli oggetti rispetta la struttura dell'inventario, le modifiche alle bacchette usano percorsi di commit/rollback, i materiali restano materiali realmente simulati e le regole reversibili conservano abbastanza stato originale da ripristinare in seguito le impostazioni supportate.

Entangled Worlds è opzionale. Senza EW, MCM rimane un mod single-player completo.

# Controlli

Controlli predefiniti:

| Azione | Input predefinito |
| --- | --- |
| Apri / chiudi il menu creativo | **F4** |
| Torna alla forma umana durante una trasformazione | **TAB** |
| Possiedi una creatura nel mondo | **G** |
| Dipingi con il materiale selezionato | **Tasto centrale del mouse** |

Il pannello creativo è disponibile anche tramite la normale interfaccia inventario di Noita.

Le associazioni possono essere modificate nella sezione **CONTROLS** di MCM e nelle impostazioni mod di Noita. Sono supportati tasti, pulsanti del mouse e combinazioni esatte con **CTRL / SHIFT / ALT**.

Durante l'assegnazione:

- **DELETE / BACKSPACE** cancella l'associazione;
- **ESC** annulla;
- **R** ripristina il default per quell'azione;
- **RESET ALL** ripristina tutte le associazioni predefinite dopo conferma.

Le associazioni duplicate restano modificabili, ma MCM mostra il conflitto invece di sostituire silenziosamente un'altra azione.

Navigazione del menu, sezioni, ritorno dalla forma, possessione, pittura dei materiali, pulizia degli effetti, rilascio del meteo, reset delle regole del mondo e azioni multiplayer supportate possono essere riassegnati.

# Finestra Creative Menu

Il pannello creativo diretto è una finestra persistente e ridimensionabile, non un overlay di debug fisso.

Può essere:

- spostata tramite la barra del titolo;
- ridimensionata da bordi e angoli;
- minimizzata;
- chiusa;
- ripristinata al layout predefinito.

Posizione, larghezza, altezza e ultima sezione aperta vengono ricordate tra le sessioni. Dopo un cambio di risoluzione, la geometria salvata viene riportata nell'area visibile della GUI.

Liste e cataloghi usano layout misurati e contenitori di scorrimento di Noita. Ridimensionare la finestra cambia immediatamente la quantità di contenuto visibile, mentre le etichette tradotte possono andare a capo senza sovrapporsi ai controlli vicini. Nei layout stretti i controlli passano su righe aggiuntive invece di essere disegnati uno sopra l'altro.

Aprire o semplicemente passare il mouse sopra il menu separato non disabilita permanentemente il gameplay. Quando un clic, un drag o un campo di testo attivo potrebbe anche azionare il giocatore, MCM sopprime temporaneamente i controlli rilevanti e li ripristina subito dopo.

# Ricerca e localizzazione

La ricerca è disponibile nei cataloghi principali, inclusi incantesimi, oggetti, materiali, perk e creature.

A seconda della voce può corrispondere a:

- nome nella lingua corrente dell'interfaccia;
- nome inglese;
- chiavi di localizzazione;
- identificatori tecnici;
- percorsi XML.

La ricerca non distingue maiuscole/minuscole, normalizza accenti e separatori comuni e tollera piccoli errori di battitura nelle query più lunghe.

L'interfaccia propria di MCM è localizzata in:

- inglese;
- russo;
- portoghese brasiliano;
- spagnolo;
- tedesco;
- francese;
- italiano;
- polacco;
- cinese semplificato;
- giapponese;
- coreano.

Per il contenuto normale di Noita, il mod riusa quando possibile le chiavi di localizzazione del gioco invece di mantenere nomi duplicati.

# Incantesimi

La sezione degli incantesimi lavora sia con il catalogo sia con le entità incantesimo già possedute dal giocatore.

L'area principale contiene:

- slot normali della bacchetta attiva;
- carte **ALWAYS CAST**;
- inventario degli incantesimi del giocatore;
- catalogo ricercabile degli incantesimi.

## Sostituzione rapida dello slot selezionato

Un clic breve seleziona uno slot della bacchetta. Poi un clic LMB breve su un incantesimo del catalogo sostituisce quello slot.

È il percorso rapido per la modifica normale. Per gli spostamenti precisi si usa il drag-and-drop.

## Drag-and-drop transazionale

Le carte esistenti possono essere trascinate:

- tra gli slot della bacchetta;
- dagli slot normali a **ALWAYS CAST**;
- da **ALWAYS CAST** agli slot normali;
- in uno slot preciso dell'inventario incantesimi;
- dall'inventario alla bacchetta;
- nel mondo;
- nel cestino quando supportato.

Per una carta esistente, MCM sposta l'entità reale quando possibile. Stato mutabile, usi rimanenti e dati aggiunti da altri mod non vengono quindi persi solo perché la carta cambia posizione.

La sorgente resta intatta finché la transazione di destinazione non viene confermata. Destinazioni non valide o sconosciute annullano l'operazione invece di cancellare la carta originale. Un rilascio del mouse esegue al massimo una singola operazione confermata.

Le carte del catalogo sono template e non vengono mai consumate trascinandole.

## Always Cast

Le carte Always Cast hanno una fascia dedicata. Promozione, retrocessione e scambio tengono conto della capacità effettiva degli slot normali per evitare una struttura di bacchetta non valida.

## Annulla e ripeti

Le mutazioni interne della bacchetta dispongono di una cronologia limitata **UNDO / REDO**.

Le operazioni che consegnano una vera entità al mondo esterno o a un altro inventario non possono sempre essere invertite in sicurezza da uno snapshot della bacchetta, quindi questi trasferimenti esterni non sono garantiti come sempre annullabili.

# Bacchette

L'area bacchetta modifica la bacchetta attualmente impugnata dal giocatore.

Le statistiche supportate includono:

- capacità / slot;
- incantesimi per cast;
- tempo di ricarica;
- ritardo tra i cast;
- dispersione;
- moltiplicatore velocità proiettili;
- mana massimo;
- velocità di ricarica mana;
- recupero rinculo;
- livello della bacchetta;
- shuffle;
- comportamento senza ricarica.

MCM modifica anche presentazione e metadati correlati:

- nome mostrato;
- blocchi della bacchetta e delle carte;
- percorso sprite;
- offset dello sprite;
- posizione di sparo.

Un catalogo visivo di aspetto segue i dati XML delle bacchette quando disponibili.

## Preset delle bacchette

Le bacchette possono essere salvate come preset persistenti con nome e riutilizzate in altri mondi o sessioni future di Noita.

Un preset può conservare:

- statistiche della bacchetta;
- valori di mana;
- metadati visivi;
- carte normali;
- carte Always Cast;
- posizioni degli slot;
- usi rimanenti;
- stato congelato delle carte.

Ogni preset ha due operazioni separate:

- **APPLY** scrive il blueprint salvato sulla bacchetta attualmente impugnata;
- **GET COPY** costruisce una nuova bacchetta dallo stesso blueprint.

La copia viene inserita in uno slot libero per bacchette dell'inventario rapido quando possibile. Se non c'è uno slot adatto, la bacchetta completa viene lasciata nel mondo vicino al giocatore.

Sostituzione della bacchetta e caricamento dei preset usano percorsi di commit/rollback. Se costruzione o posizionamento non possono essere completati, MCM prova a rimuovere l'albero entità incompleto invece di lasciare una bacchetta parziale danneggiata.

# Oggetti e liquidi

## Oggetti

Un clic breve **LMB** su una voce del catalogo crea un oggetto supportato vicino al giocatore.

**RMB** tenta di consegnarlo alla zona corretta dell'inventario.

Le voci del catalogo possono anche essere trascinate:

- verso una destinazione compatibile dell'inventario rapido;
- fuori dal menu verso una posizione esatta del mondo.

Rilasciare la carta dentro il menu senza una destinazione valida annulla l'operazione. La carta del catalogo è solo un template e resta disponibile.

MCM rispetta la normale separazione dell'inventario rapido di Noita tra slot per bacchette e slot per oggetti. Un errore nel caricamento XML, riempimento di liquidi, consegna all'inventario o handoff multiplayer opzionale rimuove la nuova entità quando possibile.

Alcuni veri oggetti da inventario si trovano in directory del gioco orientate alle creature. MCM classifica i casi noti in base al comportamento invece di assumere che il nome della cartella da solo determini se qualcosa sia un oggetto o una creatura.

## Liquidi

Le voci dei liquidi creano veri contenitori Noita già riempiti, non oggetti decorativi dell'interfaccia.

Il contenitore può essere portato, lasciato cadere, rotto e versato, e il contenuto partecipa alle normali reazioni dei materiali.

# Materiali

La sezione Materials è uno strumento di pittura del mondo basato sul vero registro dei materiali di Noita.

Il catalogo viene costruito da liquidi, sabbie / polveri, gas, fuochi, solidi e materiali statici o di effetti registrati dal motore. I materiali aggiunti correttamente da altri mod attivi possono quindi comparire automaticamente.

La scoperta e la validazione costosa dei materiali sono distribuite come lavoro limitato invece di analizzare l'intero catalogo in un singolo frame UI.

## Presentazione dei materiali

I liquidi usano la stessa presentazione con contenitore pieno della sezione Oggetti.

Per i materiali non liquidi, MCM preferisce texture e dati tint definiti in `materials.xml`, incluse le definizioni ereditate. Se non esiste una texture definita, il fallback deriva dal vero colore del materiale nel motore e non da un colore preview arbitrario.

## Pittura

1. Seleziona un materiale.
2. Seleziona la dimensione del pennello.
3. Attiva la modalità pittura.
4. Chiudi l'inventario.
5. Tieni premuto l'input di disegno configurato nel mondo.

Aprire l'inventario interrompe la modalità pittura attiva.

La pittura non emette semplicemente particelle decorative. MCM inserisce celle reali nel mondo tramite un percorso appropriato al motore. I materiali dinamici continuano a seguire la simulazione di Noita: i liquidi scorrono, le polveri cadono, i gas si muovono, il fuoco reagisce e le sostanze instabili possono trasformarsi tramite reazioni materiali.

Classi diverse richiedono strategie di posizionamento diverse. La build standalone può usare l'accesso diretto di NoitaPatcher alla griglia del mondo e un piccolo fallback PixelScene per casi definiti che Noita rifiuta di costruire direttamente in una determinata coordinata della texture.

Le code di lavoro sono limitate, così mantenere un pennello grande non esegue intenzionalmente una quantità illimitata di lavoro in un singolo frame.

# Perk

## Creare e ricevere perk

**LMB** crea un pickup normale del perk selezionato nel mondo.

L'azione di ricezione può concedere il perk singolarmente o in blocco. Le operazioni in blocco vengono processate come job limitati invece di applicare tutte le copie in un solo frame UI.

L'interfaccia mostra l'avanzamento e il lavoro ancora in attesa può essere annullato. Le copie già confermate prima dell'annullamento restano applicate.

Ogni copia concessa continua a usare il normale percorso di applicazione del perk invece di simulare direttamente lo stato finale.

## Rimuovere perk

Rimuovere un perk è molto più complesso che concederlo. I perk possono modificare globals, componenti, entità, statistiche del giocatore e meccaniche persistenti, e Noita non offre un'operazione inversa universale.

Per questo MCM rimuove soltanto lo stato per cui dispone di un'inversione tracciata sufficientemente sicura. Il journal della transazione prova a rimuovere solo lo stato appartenente a quella specifica applicazione del perk, senza resettare stato non correlato del giocatore.

Se una pulizia è parziale o non può essere dimostrata completa, resta trattata come incompleta invece di essere riportata silenziosamente come riuscita.

Un perk di terze parti può essere concedibile senza essere correttamente rimovibile.

# Effetti

La sezione Effects applica e rimuove status dei materiali ed entità GameEffect supportate.

La rimozione tiene conto della proprietà quando possibile. MCM evita di cancellare indiscriminatamente effetti nascosti simili appartenenti a perk, al gioco o a un altro sistema.

Gli effetti persistenti creati da MCM usano pulizia / scadenza limitata, in modo che rimuovere un effetto MCM non resetti stato altrui.

# Creature

Il catalogo delle creature conserva percorsi XML esatti invece di unire tutte le entità con nomi simili.

Interazioni supportate:

- **LMB** — crea l'entità definita selezionata vicino al giocatore;
- trascina fuori dal menu — crea alla posizione confermata del cursore nel mondo;
- **RMB** — trasforma il giocatore attuale in una forma supportata;
- voce speciale **PLAYER** — crea o ripristina stato del giocatore come descritto sotto.

Rilasciare una carta trascinata di nuovo sopra il menu annulla lo spawn nel mondo.

Le regole di compatibilità per forme pericolose o insolite usano percorsi esatti. Un nome file che contiene semplicemente una parola familiare non rende automaticamente l'entità equivalente a un'altra forma.

# Trasformazioni e ritorno alla forma umana

Le forme giocabili conservano movimento nativo utile, attacchi, presentazione e fisica quando pratico. I componenti che competono direttamente con l'input del giocatore possono essere disabilitati o adattati mentre la forma è controllata dal giocatore.

Alcune creature complesse richiedono logica aggiuntiva. Boss, wrapper scriptati ed entità fortemente dipendenti dalla fisica non sono garantiti a comportarsi esattamente come le versioni controllate dall'IA quando usati come forma del giocatore.

L'azione di ritorno configurata — **TAB** per default — usa prima il normale percorso di fine trasformazione. Quando non basta, la build standalone dispone di percorsi aggiuntivi di ripristino tramite NoitaPatcher.

Nei casi supportati di danno letale, MCM prova a:

- lasciare la forma temporanea morta o il cadavere nel mondo quando appropriato;
- ripristinare un'entità umana del giocatore;
- restituire authority e controlli;
- preservare l'inventario;
- ripristinare stato rilevante del giocatore.

Questa è logica di recupero, non immortalità assoluta. Un kill script di terze parti, stato incompatibile del motore o crash del processo può aggirare l'handoff supportato.

# Possessione

La possessione controlla una creatura che esiste già nel mondo invece di scegliere una forma dal catalogo.

Il tasto predefinito è **G**.

Punta una creatura adatta e usa l'azione di possessione. MCM valida il bersaglio, prepara una transizione compatibile e rimuove o ritira l'entità originale dal mondo solo dopo aver confermato il nuovo stato controllato dal giocatore.

Se la transizione fallisce, la creatura originale non dovrebbe semplicemente sparire.

La possessione non è limitata al catalogo interno di MCM. Una creatura compatibile creata da un altro mod può funzionare, ma non è garantita compatibilità universale con ogni entità di terze parti.

# Voce Player

**PLAYER** è una voce speciale del catalogo creature, non un normale bersaglio polymorph.

La sua azione di spawn crea un personaggio separato simile al giocatore e prova a copiare presentazione appropriata e informazioni sulla salute massima.

Usare l'azione di trasformazione su **PLAYER** non trasforma un giocatore già umano in un duplicato. Se il giocatore è in un'altra forma, l'azione viene usata per tornare alla forma umana.

# Recupero Game Over in single-player

La build standalone single-player include un percorso aggiuntivo di recupero per la schermata Game Over standard di Noita.

Quando l'integrazione nativa riesce a identificare in sicurezza le strutture necessarie del gioco, MCM aggiunge l'azione **“I didn't die”** all'interfaccia Game Over.

MCM mantiene un backup aggiornato dello stato del giocatore durante la partita. Attivare il recupero richiede il ripristino tramite il normale percorso di aggiornamento di MCM invece di ricostruire tutto il giocatore direttamente nel gestore del clic UI.

Un recupero supportato prova a:

- ripristinare o ottenere un'entità giocatore viva;
- renderla di nuovo authoritative;
- cancellare lo stato Game Over del motore;
- restituire controlli e stato utilizzabile;
- eseguire pulizia best-effort di audio, musica e interfaccia Game Over;
- fornire una breve finestra di protezione dopo il ripristino.

L'helper nativo è progettato in fail-closed. Analizza l'eseguibile Noita supportato in esecuzione alla ricerca di strutture note invece di scrivere a un singolo indirizzo codificato per sempre. Se le strutture attese non possono essere identificate in sicurezza dopo un aggiornamento, il recupero opzionale non viene usato invece di scrivere in una posizione incerta.

# Meteo e tempo

MCM può controllare stato meteo e temporale supportato, inclusi preset e singoli parametri esposti dall'implementazione corrente.

Uno stato forzato può essere poi rilasciato al normale controllo del gioco. Per esempio, dopo aver fissato un'ora precisa, MCM può smettere di possedere quell'impostazione in modo che il flusso naturale del tempo di Noita riprenda.

Le modifiche meteo vengono trattate come stato controllato, non come comandi console a senso unico.

# Regole del mondo

La sezione **RULES** modifica il comportamento globale supportato del gioco.

Le regole coprono aree come:

- relazioni tra creature;
- comportamento dell'oro;
- uso degli incantesimi;
- fog of war;
- ricompense selezionate per uccisioni;
- drop di cura;
- comportamento legato al sangue;
- gravità;
- fisica;
- forza del calcio;
- giunti fisici;
- ciclo giorno/notte;
- altri parametri globali supportati.

L'obiettivo principale è la reversibilità.

Per le regole supportate, MCM registra o deriva lo stato originale per poter ripristinare l'impostazione in seguito. I controlli moltiplicatori vengono applicati rispetto al valore originale invece di moltiplicare ripetutamente un risultato già modificato.

Le regole che devono toccare molte entità o oggetti fisici usano lavoro limitato distribuito sui frame invece di riscrivere sincronicamente l'intero mondo con un clic.

# Teletrasporto

La sezione teletrasporto offre destinazioni preparate nel mondo, inclusi punti lungo il percorso principale, Holy Mountains, grandi aree laterali e altri luoghi supportati.

Prima di spostare il giocatore, MCM può richiedere il caricamento dell'area di destinazione e cerca spazio libero utilizzabile nelle vicinanze invece di posizionare intenzionalmente il giocatore dentro terreno solido.

Il teletrasporto dipende comunque dalla capacità del mondo di caricarsi e fornire una destinazione valida. Mondi fortemente modificati possono richiedere comportamento di fallback.

# Entangled Worlds

**Entangled Worlds / Noita Proxy è opzionale.** MCM funziona senza EW.

Quando EW è presente, MCM abilita comportamenti aggiuntivi consapevoli del multiplayer. Tutti i peer dovrebbero usare build MCM compatibili quando dipendono da stato sincronizzato specifico di MCM.

## Authority e forme

Le forme del giocatore richiedono gestione speciale dell'ownership perché un giocatore trasformato non deve lasciare accidentalmente una seconda authority di rete.

MCM coordina ownership, retirement e ritorno alla forma umana con EW dove supportato. Entità di boss e tipo Kolmi dispongono di trattamento lifecycle aggiuntivo pensato per evitare authority duplicate e vecchie copie controllate dalla rete.

Il normale percorso di morte di EW resta responsabile delle entità non riconosciute come stato di forma appartenente a MCM.

## Oggetti, bacchette e incantesimi

Quando possibile, MCM usa i normali meccanismi di item / inventario di EW invece di inventare un sistema di trasporto parallelo.

Le modifiche confermate a bacchette e inventario incantesimi richiedono l'aggiornamento multiplayer appropriato quando l'integrazione è disponibile. Gli oggetti del mondo creati da MCM possono essere consegnati al normale percorso world-item di EW.

## Perk

I pickup normali dei perk possono usare la sincronizzazione world-item standard di EW. La gestione dello stato dei perk da parte di MCM coordina refresh e operazioni limitate, così le azioni in blocco non tentano un costoso refresh globale per ogni copia.

## Materiali

La pittura dei materiali ha un percorso dedicato di compatibilità perché le modifiche alle celle del mondo non sono normali entità oggetto.

MCM mantiene il lavoro di pittura limitato, separa il lavoro ai confini dei chunk e coordina i passaggi world-frame / persistenza richiesti da EW prima di rilasciare lavoro di conversione sincronizzato. Un chunk di bordo non ancora caricato viene rimandato invece di bloccare l'intero tratto attivo.

L'obiettivo è permettere ai peer EW vicini di vedere lo stato dipinto supportato senza dover riprodurre a distanza la normale azione UI di MCM come chiamata PixelScene basata solo sul filename.

Restano comunque le assunzioni di EW sugli ID dei materiali: un gioco ricevente non può creare correttamente un materiale che non esiste lì o il cui registro materiali del motore è incompatibile.

## Meteo, possessione e stato del mondo

Lo stato multiplayer supportato di MCM include anche coordinamento per meteo, possessione e alcuni comportamenti di regole / lifecycle. I controlli di authority evitano che due peer provino a possedere lo stesso stato contemporaneamente.

Il supporto EW è intenzionalmente conservativo. Quando l'integrazione non può dimostrare un percorso di sincronizzazione sicuro, MCM preferisce il comportamento locale supportato invece di fingere che ogni operazione single-player sia automaticamente sicura in multiplayer.

# Compatibilità e limitazioni

Noita espone molti sistemi tramite entità debolmente accoppiate, XML, componenti Lua e comportamento nativo del motore. MCM non può quindi promettere compatibilità universale con ogni entità modificata o ogni futuro aggiornamento del gioco.

Limitazioni importanti:

- una creatura può essere spawnabile senza essere una forma giocatore sicura;
- un perk può essere concedibile senza avere un'inversione affidabile;
- trasferimenti esterni di incantesimi o oggetti non possono sempre essere annullati da uno snapshot interno;
- script di terze parti possono aggirare percorsi supportati di morte e recupero;
- le funzioni native di recupero dipendono da comportamento supportato dell'eseguibile Noita e falliscono in sicurezza se le strutture richieste non possono essere identificate;
- Entangled Worlds non può sincronizzare un materiale assente dal registro del gioco ricevente;
- inventari, entità o regole fortemente modificati possono richiedere compatibilità specifica per quel mod.

MCM prova a preservare lo stato originale e fare rollback delle mutazioni fallite, ma uno strumento sandbox che modifica stato vivo del gioco non può rendere completamente transazionale ogni combinazione di mod di terze parti.

# Dati salvati

MCM persiste lo stato utente che deve sopravvivere tra le sessioni, comprese impostazioni supportate, associazioni, layout del menu e preset delle bacchette.

L'identità del mod rimane stabile così gli aggiornamenti normali possono conservare i dati supportati. È comunque consigliato sostituire l'intera cartella del mod quando si installa una nuova build standalone, perché unire file vecchi e nuovi può lasciare runtime obsoleto.

# Risoluzione dei problemi

## Il mod non compare

Verifica che il percorso termini con:

`mods/metamorph_creative_menu/mod.xml`

Una cartella extra sopra `metamorph_creative_menu` impedisce a Noita di vedere correttamente il mod.

## Le funzioni native o dei materiali non funzionano

Verifica che **Unsafe Mods** sia consentito e che sia installata la build standalone GitHub senza mescolare file della Workshop.

## Il menu si apre ma si attiva anche un'azione di gioco

Controlla i conflitti nelle associazioni personalizzate. MCM mostra i duplicati ma permette intenzionalmente di mantenerli se desiderato.

## Una creatura non può essere trasformata in sicurezza

Non ogni entità XML spawnabile è una forma giocatore supportata. Esistono regole per percorso esatto per le creature che richiedono gestione speciale.

## Un perk non può essere rimosso

La rimozione è disponibile solo dove MCM possiede un'operazione inversa supportata per lo stato tracciato. È intenzionale: indovinare la pulizia può danneggiare stato non correlato del giocatore.

## Il multiplayer si comporta diversamente tra i peer

Usa build MCM compatibili su tutti i partecipanti e un ambiente Noita / Entangled Worlds compatibile. MCM non può correggere un registro materiali incompatibile o modifiche di rete arbitrarie di altri mod.

# Segnalare bug

Una segnalazione utile dovrebbe includere:

- cosa stavi cercando di fare;
- sezione e azione esatte di MCM;
- se il problema avviene in single-player, Entangled Worlds o entrambi;
- se è installata la build standalone o Workshop;
- se sono attivi altri gameplay mod;
- passaggi affidabili per riprodurre il problema;
- log rilevanti di Noita / EW quando disponibili.

Per problemi di trasformazione, possessione, oggetti o materiali, indica se possibile l'entità o il materiale esatto. Gli identificatori tecnici sono spesso più utili di un nome visualizzato tradotto.

# Repository e sorgente di sviluppo

Il repository contiene intenzionalmente **l'albero completo di sviluppo**, non lo stesso archivio ridotto scaricato dai giocatori.

`metamorph_creative_menu/` contiene codice runtime insieme a:

- test automatizzati;
- strumenti QA;
- diagnostica;
- sorgenti native;
- strumenti di build;
- regole di pulizia della release;
- documentazione di sviluppo.

Questi file sono utili per sviluppo e test di regressione, quindi restano nel source GitHub. Lo ZIP pronto per i giocatori viene generato separatamente ed esclude il contenuto solo sviluppo.

Il pacchetto giocatore riceve inoltre pulizia specifica della release, incluso il `README.txt` minimo del pacchetto, mentre l'albero source mantiene la documentazione di sviluppo.

# Test

La suite automatizzata si trova in `metamorph_creative_menu/tests/` e combina controlli di contratto Python con mock test Lua.

Dalla root del repository, il workflow di release esegue la suite sul source completo importato prima di pubblicare la build per i giocatori. `texlua` è necessario per la parte di mock Lua.

I controlli di source hygiene proteggono inoltre file orientati alla produzione e documentazione da residui della cronologia di sviluppo, vecchie superfici di debug e artefatti accidentali del processo.

# Importazione del source e processo di release

Il source completo di sviluppo può essere importato da un archivio della famiglia `Metamorph-Creative-Menu-v...zip`.

Il workflow di importazione verifica la struttura, richiede tutti i componenti di sviluppo, esegue source hygiene e la suite di regressione prima di committare l'albero importato.

Un archivio ModWorkshop / player-style non viene trattato come source di sviluppo.

La release pubblica `latest-build` viene poi prodotta dal source completo tramite un player-builder separato. Il builder rimuove QA, test, diagnostica, sorgenti native e altro payload solo sviluppo, applica le regole di pulizia, valida l'archivio risultante e solo allora aggiorna l'asset di download stabile.

Questa separazione mantiene il repository utile per lo sviluppo lasciando il download normale dei giocatori piccolo e privo di strumentazione di sviluppo.

# Componenti di terze parti

Componenti di terze parti, dipendenze incluse e progetti upstream sono documentati in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
