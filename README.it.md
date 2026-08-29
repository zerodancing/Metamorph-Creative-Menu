<a id="languages"></a>

[English](README.md) · [Русский](README.ru.md) · [Português (Brasil)](README.pt-BR.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [**Italiano**](README.it.md) · [Polski](README.pl.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

<h1 align="center">Metamorph: Creative Menu</h1>

<p align="center">Un menu creativo e una raccolta di strumenti per Noita: incantesimi, bacchette, oggetti, materiali, vantaggi, creature, trasformazioni, effetti, teletrasporto, meteo, regole del mondo e molto altro.</p>

<p align="center"><strong>Versione 2.0.0</strong></p>

---

# Scarica

[**⬇️ Scarica l'ultima versione della mod**](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip)

Versione attuale: **2.0.0**

**Per usare la versione completa è necessario consentire le mod non sicure.**

[Pagina dell'ultima build](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build)

[Elenco delle modifiche della versione 2.0.0](metamorph_creative_menu/CHANGELOG.txt)

# Indice

- [Installazione](#installazione)
- [Versione completa e versione del Workshop di Steam](#versione-completa-e-versione-del-workshop-di-steam)
- [Informazioni sulla mod](#informazioni-sulla-mod)
- [Comandi e interfaccia](#comandi-e-interfaccia)
- [Incantesimi](#incantesimi)
- [Bacchette](#bacchette)
- [Oggetti e liquidi](#oggetti-e-liquidi)
- [Materiali](#materiali)
- [Vantaggi](#vantaggi)
- [Effetti](#effetti)
- [Creature e trasformazioni](#creature-e-trasformazioni)
- [Ritorno dopo una trasformazione e morte della forma](#ritorno-dopo-una-trasformazione-e-morte-della-forma)
- [Controllare una creatura](#controllare-una-creatura)
- [Giocatore](#giocatore)
- [Meteo e ora](#meteo-e-ora)
- [Regole del mondo](#regole-del-mondo)
- [Teletrasporto](#teletrasporto)
- [Entangled Worlds](#entangled-worlds)
- [NoitaPatcher e mod non sicure](#noitapatcher-e-mod-non-sicure)
- [Se qualcosa non funziona](#se-qualcosa-non-funziona)
- [Segnalare un errore](#segnalare-un-errore)

# Installazione

1. [Scarica l'ultima versione della mod](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip).
2. Avvia Noita e apri **Mod** dal menu principale.
3. Fai clic su **Apri cartella mod**.
4. Sposta la cartella `metamorph_creative_menu` dall'archivio scaricato nella cartella `mods` che si è aperta. Se `metamorph_creative_menu` è già presente, elimina la vecchia cartella e sostituiscila con quella nuova.
5. Chiudi la cartella delle mod.
6. Nel menu delle mod, fai clic su **Aggiorna**. **Metamorph: Creative Menu** dovrebbe comparire nell'elenco.
7. Fai clic su **Mod non sicure** finché il testo non diventa rosso e mostra **Mod non sicure: Consentite**.
8. Fai clic sul nome della mod in modo che venga evidenziato e compaia **[x]** davanti. Questo indica che la mod è attiva.
9. Fai clic su **Avvia una nuova partita con le mod attive**.
10. Scegli una modalità di gioco e gioca.

# Versione completa e versione del Workshop di Steam

La build disponibile su questa pagina GitHub è la versione completa di MCM. Include NoitaPatcher e funzioni che richiedono l'autorizzazione per le mod non sicure.

La [versione del Workshop di Steam](https://steamcommunity.com/sharedfiles/filedetails/?id=3785170245) si installa separatamente. Non include NoitaPatcher né le funzioni della versione completa che richiedono l'accesso delle mod non sicure.

Non installare né attivare entrambe le versioni contemporaneamente.

# Informazioni sulla mod

**Metamorph: Creative Menu (MCM)** è un menu creativo e una raccolta di strumenti per Noita.

Riunisce in un'unica interfaccia strumenti per incantesimi, bacchette, oggetti, materiali, vantaggi, effetti, creature, trasformazioni, meteo, regole globali del mondo e teletrasporto.

MCM è adatto sia al gioco libero in modalità creativa sia agli esperimenti con le meccaniche di Noita. Molte operazioni non si limitano alla semplice creazione di una nuova entità, ma tengono conto dello stato già esistente della bacchetta, dell'oggetto, della forma, del vantaggio o del mondo.

**Entangled Worlds non è necessario.** Senza di esso, MCM funziona come una mod completa per giocatore singolo. Se Entangled Worlds è installato, diventano disponibili ulteriori funzioni multigiocatore sperimentali.

# Comandi e interfaccia

| Azione | Tasto |
| --- | --- |
| Apri / chiudi il menu creativo | **F4 o TAB** |
| Torna alla forma umana | **TAB durante una trasformazione** |
| Prendi il controllo di una creatura | **G** |
| Disegna con il materiale selezionato | **Pulsante centrale del mouse** |

Il pannello MCM è disponibile anche tramite la normale interfaccia dell'inventario.

I tasti possono essere modificati nella sezione **COMANDI** o nelle impostazioni della mod.

Durante l'assegnazione di un tasto:

- **DELETE / BACKSPACE** — cancella l'assegnazione;
- **ESC** — annulla;
- **R** — ripristina l'assegnazione predefinita;
- **RIPRISTINA TUTTO** — ripristina tutte le assegnazioni predefinite dopo la conferma.

Se la stessa combinazione viene assegnata a più azioni, MCM segnala un conflitto.

## Finestra del menu creativo

La finestra può essere:

- spostata;
- ridimensionata in larghezza e altezza;
- ridimensionata dai bordi e dagli angoli;
- ridotta a icona;
- chiusa;
- riportata alla disposizione predefinita.

Dimensioni, posizione e ultima sezione aperta vengono conservate tra un avvio del gioco e l'altro.

I cataloghi più grandi usano lo scorrimento e si adattano automaticamente alle dimensioni attuali della finestra.

## Ricerca

La ricerca è disponibile nei cataloghi di:

- incantesimi;
- oggetti;
- materiali;
- vantaggi;
- creature.

Può prendere in considerazione non solo il nome visualizzato, ma anche il nome inglese, la chiave di localizzazione, l'identificatore tecnico o il percorso XML.

La ricerca non distingue tra maiuscole e minuscole e tollera piccoli errori di battitura nelle parole sufficientemente lunghe.

L'interfaccia di MCM è localizzata in 11 lingue. Per i normali contenuti di gioco vengono riutilizzate, quando possibile, le traduzioni di Noita.

# Incantesimi

La sezione degli incantesimi permette di lavorare non solo con il catalogo, ma anche con i veri incantesimi del giocatore attuale.

Sono disponibili contemporaneamente:

- gli slot della bacchetta attiva;
- **SEMPRE ATTIVO**;
- l'inventario degli incantesimi;
- il catalogo degli incantesimi.

## Sostituzione rapida

Puoi selezionare uno slot preciso della bacchetta e fare clic sinistro sull'incantesimo desiderato nel catalogo. L'incantesimo verrà inserito nello slot selezionato.

## Trascinamento

Gli incantesimi esistenti possono essere spostati:

- tra gli slot della bacchetta;
- in **SEMPRE ATTIVO**;
- da **SEMPRE ATTIVO** di nuovo negli slot normali;
- in uno slot preciso dell'inventario degli incantesimi;
- dall'inventario alla bacchetta;
- nel mondo di gioco;
- nel cestino.

Per le carte incantesimo già esistenti, MCM cerca di spostare la vera entità di gioco invece di crearne una nuova copia. In questo modo può conservare lo stato modificato della carta, compreso quello aggiunto da altre mod.

L'incantesimo di origine rimane al suo posto finché la nuova destinazione non viene confermata. Un'operazione non riuscita o non consentita non dovrebbe distruggere la carta originale.

## Sempre attivo

Gli incantesimi permanenti hanno una propria area.

Quando si spostano incantesimi tra gli slot normali e **SEMPRE ATTIVO**, MCM tiene conto della capacità della bacchetta in modo che la struttura degli slot normali rimanga corretta.

## Annulla / Ripeti

Per le modifiche interne della bacchetta è disponibile una cronologia limitata **ANNULLA / RIPETI**.

Si applica alle operazioni che possono essere ripristinate in modo sicuro a partire dallo stato della bacchetta stessa.

Il trasferimento di un vero incantesimo nel mondo esterno o nel normale inventario di gioco non può sempre essere annullato correttamente ripristinando soltanto lo stato della bacchetta. Per questo motivo tali azioni non sono sempre annullabili.

# Bacchette

MCM include un editor completo della bacchetta attiva.

È possibile modificare:

- il numero di slot;
- gli incantesimi per lancio;
- il tempo di ricarica;
- il ritardo tra i lanci;
- la dispersione;
- il moltiplicatore della velocità dei proiettili;
- il mana massimo;
- la ricarica del mana;
- il recupero del rinculo;
- il livello della bacchetta;
- la mescola;
- la modalità senza ricarica.

È inoltre possibile modificare l'aspetto e i parametri correlati:

- il nome visualizzato;
- i blocchi;
- l'immagine della bacchetta;
- lo spostamento dell'immagine;
- il punto di sparo.

È disponibile un catalogo visivo degli aspetti delle bacchette.

## Bacchette salvate

Una bacchetta può essere salvata per riutilizzarne in seguito lo stato memorizzato.

Vengono salvati:

- le caratteristiche;
- il mana;
- l'aspetto;
- gli incantesimi normali;
- **SEMPRE ATTIVO**;
- la disposizione delle carte;
- gli utilizzi rimanenti;
- lo stato congelato delle carte.

Le bacchette salvate restano disponibili tra mondi diversi e nei successivi avvii di Noita.

### Applica

**APPLICA** applica lo stato salvato alla bacchetta che il giocatore possiede in quel momento.

### Copia

**COPIA** crea una copia separata della bacchetta salvata.

Se nell'inventario rapido c'è uno slot adatto libero, la nuova bacchetta viene inserita lì. In caso contrario viene creata nel mondo di gioco accanto al giocatore.

Se la creazione non può essere completata correttamente, MCM cerca di rimuovere l'entità incompleta.

# Oggetti e liquidi

## Oggetti

**Clic sinistro** su una voce del catalogo crea un oggetto accanto al giocatore.

**Clic destro** prova a inserire l'oggetto direttamente nell'inventario.

Un oggetto può anche essere trascinato:

- in un'area compatibile dell'inventario rapido;
- fuori dal menu, nel punto scelto del mondo di gioco.

Se la carta viene rilasciata all'interno del menu senza una destinazione valida, l'operazione viene annullata.

Il catalogo contiene modelli, quindi la voce non scompare dopo la creazione di un oggetto.

MCM rispetta la normale suddivisione dell'inventario rapido di Noita tra slot per bacchette e slot per oggetti e non dovrebbe sostituire senza motivo un oggetto già presente.

## Liquidi

MCM può creare veri contenitori di gioco riempiti con il liquido selezionato.

Il contenitore creato si comporta come un normale oggetto di Noita:

- può essere conservato nell'inventario;
- lanciato nel mondo;
- rotto;
- può versare il proprio contenuto;
- partecipa alle normali reazioni tra materiali.

# Materiali

Il catalogo dei materiali viene costruito a partire dalle sostanze registrate nell'istanza corrente di Noita.

Comprende diversi tipi di materiali, tra cui:

- liquidi;
- polveri;
- gas;
- fuoco;
- materiali solidi;
- materiali statici;
- materiali con una visualizzazione speciale.

Se un'altra mod attiva aggiunge correttamente un proprio materiale a Noita, quel materiale può comparire anche in MCM.

## Disegnare con i materiali

1. Scegli un materiale.
2. Scegli la dimensione del pennello.
3. Fai clic su **INIZIA A DIPINGERE**.
4. Chiudi l'inventario.
5. Tieni premuto nel mondo di gioco il tasto assegnato al disegno.

Per impostazione predefinita viene usato il **pulsante centrale del mouse**.

Aprire l'inventario interrompe la modalità di disegno.

## Comportamento dei materiali

MCM crea veri materiali del mondo di gioco, non particelle decorative.

Dopo essere stati posizionati, continuano a seguire la normale simulazione di Noita:

- i liquidi scorrono;
- le polveri cadono;
- i gas si diffondono;
- il fuoco interagisce con l'ambiente;
- le sostanze reagiscono tra loro;
- i materiali instabili possono trasformarsi in altri materiali.

Per i diversi tipi di materiale, MCM utilizza metodi di posizionamento adatti, comprese funzioni aggiuntive di NoitaPatcher nei casi che non possono essere gestiti correttamente con i normali strumenti delle mod.

# Vantaggi

## Creare un vantaggio

**Clic sinistro** crea il vantaggio selezionato nel mondo di gioco.

Può essere raccolto come un normale vantaggio di Noita.

## Ottenere vantaggi

MCM permette di ottenere:

- 1 copia;
- 10 copie;
- 100 copie.

L'ottenimento in massa viene elaborato gradualmente per evitare di eseguire molte operazioni pesanti in un singolo fotogramma.

L'interfaccia mostra l'avanzamento e permette di annullare le operazioni ancora da eseguire. Le copie già ottenute con successo rimangono al giocatore dopo l'annullamento.

## Rimuovere vantaggi

Rimuovere un vantaggio in sicurezza è molto più difficile che ottenerlo.

Alcuni vantaggi modificano contemporaneamente più sistemi di gioco, creano entità o avviano effetti per i quali non esiste un unico metodo universale di annullamento.

Per questo MCM rimuove soltanto le modifiche supportate per le quali può eseguire un'operazione inversa con sufficiente affidabilità.

La mod cerca di annullare soltanto lo stato creato dalla specifica applicazione del vantaggio, senza azzerare inutilmente altri effetti o parametri del giocatore.

# Effetti

MCM permette di applicare e rimuovere elementi supportati, tra cui:

- effetti di gioco;
- stati legati ai materiali.

Durante la rimozione, la mod cerca di non toccare stati estranei appartenenti ai vantaggi o ad altri sistemi di gioco.

In questo modo è possibile rimuovere gli effetti propri di MCM senza cancellare indiscriminatamente tutti gli stati simili del giocatore.

# Creature e trasformazioni

## Creare creature

**Clic sinistro** crea la creatura selezionata accanto al giocatore.

La carta di una creatura può anche essere trascinata fuori dal menu per crearla nel punto scelto del mondo di gioco.

**Clic destro** su una voce supportata tenta di trasformare il giocatore attuale nella forma corrispondente.

## Compatibilità delle forme

Le creature di Noita sono molto diverse tra loro nella struttura interna.

Per questo MCM distingue gli obiettivi di trasformazione in base a percorsi XML esatti e non considera automaticamente intercambiabili tutte le creature simili.

Durante una trasformazione, MCM utilizza le capacità della forma scelta e, se necessario, applica regole di compatibilità specifiche per determinate creature.

# Ritorno dopo una trasformazione e morte della forma

Puoi tornare alla forma umana con l'azione assegnata, **TAB per impostazione predefinita**.

MCM usa prima i normali meccanismi di Noita per terminare una trasformazione. Per i casi più complessi è disponibile un recupero aggiuntivo tramite NoitaPatcher.

La mod gestisce inoltre le situazioni supportate in cui una forma temporanea subisce danni letali.

In questi casi MCM cerca di:

- conservare il cadavere della forma morta;
- ripristinare il giocatore umano;
- restituire il controllo;
- conservare l'inventario;
- ripristinare lo stato legato al giocatore.

Non si tratta di immortalità assoluta. Modi di morire insoliti causati da altre mod, mod incompatibili o un errore interno di Noita possono aggirare il normale meccanismo di recupero.

# Controllare una creatura

Oltre a scegliere una forma dal catalogo, MCM può prendere il controllo di **una creatura già presente nel mondo di gioco**.

Il tasto predefinito è **G**.

Posiziona il cursore su un bersaglio compatibile e usa l'azione assegnata.

MCM controlla la creatura, esegue la trasformazione in una forma compatibile e rimuove l'entità originale dal mondo soltanto dopo aver confermato che la trasformazione è riuscita.

Se la trasformazione non viene completata, la creatura originale non dovrebbe semplicemente scomparire.

Questa funzione non è limitata al catalogo statico di MCM. Anche una creatura compatibile aggiunta da un'altra mod può superare il controllo, anche se non è garantita la compatibilità universale con qualsiasi entità di terze parti.

# Giocatore

**GIOCATORE** è una voce speciale del catalogo delle creature.

Non è una normale forma in cui trasformarsi.

**Clic sinistro** crea un personaggio separato per il quale MCM tenta di copiare:

- l'aspetto del giocatore;
- la salute massima.

**Clic destro** sulla voce **GIOCATORE** non trasforma il giocatore normale in questa entità.

Se il giocatore è già in forma umana, l'azione non fa nulla. Se il giocatore è trasformato in un'altra creatura, viene usato il ritorno alla forma umana.

# Meteo e ora

MCM permette di modificare:

- l'ora del giorno;
- configurazioni meteo predefinite;
- singoli parametri meteo supportati.

È possibile imporre lo stato desiderato e poi liberare il parametro corrispondente dal controllo di MCM.

Per esempio, dopo aver imposto un'ora specifica è possibile restituire a Noita il normale scorrere del tempo.

# Regole del mondo

La sezione **REGOLE** permette di modificare più a fondo il comportamento del mondo di gioco.

A seconda della regola, è possibile controllare parametri come:

- i rapporti tra creature;
- l'oro;
- l'uso degli incantesimi;
- la nebbia di guerra;
- le ricompense per determinati tipi di uccisione;
- le ricompense curative;
- il sangue;
- la gravità;
- il comportamento fisico;
- la forza del calcio;
- i giunti fisici;
- il ciclo giorno-notte;
- altri parametri globali supportati.

La caratteristica principale è che le regole di MCM sono progettate come **modifiche reversibili**.

Per le impostazioni supportate, la mod conserva lo stato originale e permette di riportare i parametri al loro valore normale.

Quando viene usato un moltiplicatore, il nuovo valore viene calcolato rispetto allo stato di base invece di continuare a moltiplicare un risultato già modificato.

Le operazioni che devono modificare molte entità o oggetti fisici vengono elaborate gradualmente, invece di tentare di modificare tutto il mondo nel momento stesso in cui si preme il pulsante.

# Teletrasporto

MCM permette di spostarsi rapidamente verso destinazioni predefinite del gioco, tra cui punti:

- lungo il percorso principale;
- nelle Montagne Sacre;
- in grandi aree laterali;
- in altre località supportate.

Prima del teletrasporto, la mod può caricare l'area di destinazione e cerca di trovare uno spazio libero nelle vicinanze per evitare di collocare il giocatore direttamente dentro una parete solida o un altro ostacolo.

# Entangled Worlds

**Entangled Worlds / Noita Proxy è facoltativo.**

MCM funziona completamente in giocatore singolo anche senza di esso.

Quando Entangled Worlds è installato, vengono attivate ulteriori funzioni multigiocatore sperimentali.

Per una migliore compatibilità, è consigliabile che tutti i partecipanti utilizzino la stessa versione di MCM.

## Oggetti, bacchette e incantesimi

Quando possibile, gli oggetti presenti nel mondo e gli incantesimi lasciati a terra utilizzano i normali meccanismi di Entangled Worlds.

Anche le modifiche all'inventario possono essere trasmesse tramite Entangled Worlds.

## Vantaggi

Un vantaggio creato da MCM rimane una vera entità di gioco e, quando possibile, viene trasmesso tramite il normale sistema degli oggetti nel mondo di Entangled Worlds.

## Materiali

Il disegno con i materiali dispone di un supporto multigiocatore sperimentale.

MCM sincronizza le aree del mondo interessate in modo che il risultato possa comparire anche agli altri partecipanti.

Per funzionare correttamente, il materiale corrispondente deve esistere anche per l'altro giocatore. Se gli insiemi di mod sono diversi, non è possibile garantire una visualizzazione identica di tutti i materiali.

## Meteo e regole del mondo

Le modifiche supportate al meteo e alle regole globali possono essere sincronizzate tramite Entangled Worlds.

## Trasformazioni e controllo delle creature

Le trasformazioni ricevono supporto aggiuntivo quando si utilizza Entangled Worlds.

Quando si prende il controllo di una creatura già esistente, la mod tiene conto anche del suo stato di rete. Se MCM non può stabilire con sufficiente sicurezza che l'entità originale può essere rimossa, preferisce lasciarla al suo posto.

## Giocatore

La creazione dell'entità speciale **GIOCATORE** è supportata anche con Entangled Worlds. In questo caso copia i colori dell'aspetto della persona che l'ha creata.

## Teletrasporto tra giocatori

Quando Entangled Worlds è attivo, la sezione di teletrasporto mostra i giocatori disponibili.

**VAI DA** ti teletrasporta vicino al giocatore selezionato.

**PORTA QUI** invia al giocatore selezionato una richiesta di teletrasportarsi da te.

In entrambi i casi, MCM cerca di utilizzare uno spazio libero vicino alla destinazione.

## Limitazioni

Il supporto a Entangled Worlds rimane sperimentale.

**In multigiocatore, trasformarsi in boss grandi o composti da molte articolazioni può causare un calo critico delle prestazioni e rendere di fatto inutilizzabile la sessione di gioco corrente.**

Noita è estremamente difficile da sincronizzare completamente, soprattutto quando cambiano contemporaneamente:

- il mondo a pixel;
- i materiali;
- gli oggetti fisici;
- creature e boss complessi;
- i contenuti di altre mod.

Per questo MCM non garantisce una sincronizzazione perfetta di ogni possibile stato.

# NoitaPatcher e mod non sicure

La versione completa di MCM include **NoitaPatcher**.

Viene usato per funzioni che non possono essere realizzate in modo sufficiente con i normali strumenti di modifica di Noita, in particolare per parte dei meccanismi di:

- recupero dopo trasformazioni complesse;
- gestione delle entità di gioco;
- interazione con il mondo di gioco;
- posizionamento di alcuni materiali;
- compatibilità estesa.

Per questo, nella versione completa è necessario consentire le **mod non sicure**.

NoitaPatcher è già incluso nella build pronta di MCM e non deve essere installato separatamente.

# Se qualcosa non funziona

## MCM non si carica

Verifica che, dopo l'estrazione, esista:

```text
Noita/mods/metamorph_creative_menu/mod.xml
```

Verifica che:

- MCM sia attivo nel menu **Mod**;
- accanto compaia **[x]**;
- le **mod non sicure siano consentite**;
- il gioco sia stato avviato con le mod attive.

## Le funzioni che usano NoitaPatcher non funzionano

Verifica che esista:

```text
metamorph_creative_menu/NoitaPatcher/noitapatcher.dll
```

e assicurati che le **mod non sicure** siano consentite.

## Non riesci a tornare da una forma

Prova l'azione di ritorno assegnata, **TAB per impostazione predefinita**.

Se il problema si ripresenta, nella segnalazione è utile indicare:

- il nome esatto della creatura;
- il percorso XML, se conosciuto;
- come è stata ottenuta la forma;
- se il normale ritorno funziona;
- se il problema compare soltanto dopo danni letali;
- se viene usato Entangled Worlds.

## Problemi con Entangled Worlds

Verifica:

- che tutti i partecipanti usino la stessa versione di MCM;
- che le versioni di Entangled Worlds siano compatibili;
- che venga usato lo stesso insieme di mod se il problema riguarda materiali o creature provenienti da altre mod.

# Segnalare un errore

[Crea una Issue](https://github.com/zerodancing/Metamorph-Creative-Menu/issues)

Per una segnalazione utile è consigliabile indicare:

- la versione di MCM;
- che cosa stavi facendo esattamente;
- il risultato previsto;
- il risultato effettivo;
- il nome della creatura, dell'oggetto, del vantaggio o del materiale interessato;
- se viene usato Entangled Worlds;
- altre mod che potrebbero essere collegate al problema;
- il testo dell'errore o il relativo estratto del registro;
- uno screenshot o un video, se aiuta a mostrare il problema.

# Componenti di terze parti

- **Noita** — Nolla Games.
- **NoitaPatcher** — dextercd, incluso nella versione completa.
- **lbase64** — Ilya Kolbin, incluso in MCM.
- **Entangled Worlds / Noita Proxy** — IntQuant e collaboratori del progetto; si installa separatamente ed è facoltativo.

Informazioni dettagliate sui progetti originali e sulle relative licenze si trovano in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

---

**Metamorph: Creative Menu** è una mod non ufficiale creata dagli utenti per Noita. Il progetto non è affiliato a Nolla Games e non è una parte ufficialmente supportata del gioco.

[↑ Torna alla selezione della lingua](#languages)