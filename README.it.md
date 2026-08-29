<h1 align="center">Metamorph: Creative Menu</h1>

<p align="center">
  Uno strumento creativo per Noita: incantesimi, bacchette, oggetti, materiali, vantaggi, creature, effetti, teletrasporto, meteo e regole del mondo.
</p>

<a id="languages"></a>

[English](README.md) · [Русский](README.ru.md) · [Português (Brasil)](README.pt-BR.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [**Italiano**](README.it.md) · [Polski](README.pl.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

## Scaricare

Versione attuale: **2.0.0**

| Pacchetto | Download |
|---|---|
| **Ultima versione pronta da installare** | **[⬇️ Scarica Metamorph-Creative-Menu.zip](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip)** |
| Pagina della versione | [Ultima versione pronta da installare](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build) |

> Lo ZIP contiene già la cartella completa `metamorph_creative_menu`, incluso NoitaPatcher. Estrai quella cartella direttamente in `Noita/mods/`.

Percorso finale corretto:

```text
Noita/mods/metamorph_creative_menu/mod.xml
```

Se ottieni `metamorph_creative_menu/metamorph_creative_menu/mod.xml`, l'archivio è stato estratto un livello di cartella troppo in profondità.

---

## Italiano

### Installazione

1. [Scarica l'ultimo ZIP pronto all'installazione](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip).
2. Chiudi completamente Noita prima di installare o aggiornare il mod.
3. In Steam apri **Libreria → clic destro su Noita → Gestisci → Sfoglia file locali**.
4. Apri la cartella `mods` del gioco e copia al suo interno l'intera cartella **`metamorph_creative_menu`**.
5. Verifica che esista `Noita/mods/metamorph_creative_menu/mod.xml`. Non rinominare la cartella del mod.
6. Avvia Noita, attiva **Metamorph: Creative Menu**, consenti **Unsafe mods / unrestricted API** se richiesto e riavvia Noita dopo aver attivato il mod.
7. Avvia una partita e premi **TAB**. Se il menu si apre, l'installazione è completa.

**Aggiornamento:** chiudi Noita, elimina la vecchia cartella `metamorph_creative_menu` e copia quella nuova in `mods`. Sostituire l'intera cartella evita di lasciare file obsoleti di versioni precedenti.

### Controlli

- **F4 o TAB**: aprire o chiudere il Creative Menu.
- **TAB durante una trasformazione**: tornare alla forma umana.
- **G** per impostazione predefinita: prendere il controllo di una creatura supportata sotto il cursore.
- **Pulsante centrale del mouse**: disegnare con il materiale selezionato.
- Le assegnazioni possono essere modificate nella sezione COMANDI o nelle impostazioni del mod. Le azioni disponibili con clic sinistro e destro sono indicate nell'interfaccia.

### Cosa può fare MCM

- Ottenere e posizionare incantesimi e spostarli tra bacchette, spazi Sempre attivo, inventario e mondo.
- Modificare statistiche, aspetto e blocchi delle bacchette; salvare preimpostazioni e creare copie.
- Generare oggetti vicino al giocatore o in una posizione scelta del mondo e inserire gli oggetti supportati direttamente nell'inventario.
- Creare fiaschette con i liquidi selezionati.
- Selezionare materiali e disegnarli nel mondo.
- Generare, aggiungere e rimuovere vantaggi.
- Generare creature vicino al giocatore o in una posizione scelta del mondo.
- Trasformarsi in creature, prendere il controllo di creature esistenti e tornare alla forma umana.
- Generare un'entità PLAYER separata.
- Applicare e rimuovere effetti di gioco.
- Modificare meteo, ora del giorno, gravità e altre regole del mondo.
- Teletrasportarsi in luoghi del gioco.
- Con Entangled Worlds, teletrasportarsi da altri giocatori o portarli da te.
- Modificare le assegnazioni dei tasti e cercare nei cataloghi di incantesimi, oggetti, materiali, vantaggi e creature.
- Spostare e ridimensionare la finestra del menu; posizione e dimensioni vengono mantenute tra gli avvii del gioco.

<details>
<summary><strong>Trasformazioni, compatibilità e recupero</strong></summary>

MCM usa dati di compatibilità basati sui percorsi XML esatti e limitate eccezioni di instradamento sicuro per le entità note come pericolose o inadatte a una trasformazione nativa diretta. Le forme controllate dal giocatore cercano di mantenere movimento, attacchi, aspetto e fisica nativi utili, disattivando al tempo stesso l'intelligenza artificiale che entrerebbe in conflitto con i comandi del giocatore. Boss complessi, entità fortemente gestite da script e oggetti fisici possono richiedere adattatori dedicati e non sempre riproducono esattamente ogni comportamento dell'intelligenza artificiale originale.

NoitaPatcher viene usato per i meccanismi di recupero più robusti, tra cui serializzazione e deserializzazione delle entità, trasferimento del controllo dell'entità del giocatore e altre funzioni avanzate durante l'esecuzione. Per questo motivo la versione completa e autonoma richiede l'accesso senza restrizioni alle API del mod.

</details>

<details>
<summary><strong>Integrazione multigiocatore con Entangled Worlds</strong></summary>

**Entangled Worlds è facoltativo.** MCM è progettato per funzionare come mod completo in modalità giocatore singolo senza EW.

Quando `quant.ew` è attivo, MCM abilita un'integrazione sperimentale per oggetti condivisi, vantaggi, meteo, regole del mondo, forme e controllo delle creature, richieste del compagno e comportamenti collegati ad autorità e sincronizzazione. Tutti i partecipanti devono usare la stessa versione di MCM. Il supporto multigiocatore è considerato intenzionalmente sperimentale perché non tutte le situazioni limite di Noita ed EW possono essere sincronizzate con garanzia perfetta.

</details>

### Requisiti e componenti di terze parti

- **Noita** — gioco richiesto, di Nolla Games.
- **NoitaPatcher** di dextercd — incluso in MCM e usato per funzioni avanzate e recupero.
- **lbase64** di Ilya Kolbin — implementazione locale di Base64 inclusa.
- **Entangled Worlds / Noita Proxy** di IntQuant e collaboratori — integrazione multigiocatore facoltativa; non necessaria in modalità giocatore singolo.

I collegamenti esatti ai progetti originali, i percorsi dei componenti inclusi e le informazioni su licenze o stato sono in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

### Risoluzione dei problemi

- **TAB non fa nulla:** controlla il percorso esatto di `mod.xml`, assicurati che MCM sia attivo, consenti Unsafe mods/unrestricted API e riavvia Noita.
- **Mancano il recupero avanzato o parte delle regole del mondo:** controlla che `metamorph_creative_menu/NoitaPatcher/noitapatcher.dll` sia presente e che l'accesso unrestricted API sia consentito.
- **Una forma non torna correttamente:** indica il nome o XML esatto della creatura e specifica se è fallito il ritorno normale con TAB o il ritorno dopo un danno letale.
- **Desincronizzazione con EW:** verifica che tutti usino la stessa versione di MCM e una versione compatibile di EW.

### Collegamenti

- [Ultima versione](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build)
- [Segnala un problema](https://github.com/zerodancing/Metamorph-Creative-Menu/issues)
- [Componenti di terze parti](THIRD_PARTY_NOTICES.md)
- [Noita](https://noitagame.com/)
- [NoitaPatcher](https://github.com/dextercd/NoitaPatcher)
- [Documentazione di NoitaPatcher](https://dexter.döpping.eu/NoitaPatcher/)
- [Entangled Worlds](https://github.com/IntQuant/noita_entangled_worlds)
- [lbase64](https://github.com/iskolbin/lbase64)

[↑ Torna alla scelta della lingua](#languages)

---

## Per sviluppatori

Il mod giocabile si trova in `metamorph_creative_menu/`.

- Note su architettura e sviluppo: `metamorph_creative_menu/README.txt`
- Suite di test di regressione: `metamorph_creative_menu/tests/`
- Istruzioni per i test: `metamorph_creative_menu/tests/TESTING.txt`
- Informazioni sui componenti di terze parti: [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)

Il flusso automatico `latest-build` del repository impacchetta la cartella giocabile `metamorph_creative_menu` in uno ZIP pronto da installare e aggiorna l'indirizzo stabile di download indicato sopra.