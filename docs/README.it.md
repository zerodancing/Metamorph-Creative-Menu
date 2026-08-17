# Metamorph: Creative Menu — Italiano

[English](README.en.md) · [Русский](README.ru.md) · [Português (Brasil)](README.pt-BR.md) · [Español](README.es-ES.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Italiano](README.it.md) · [Polski](README.pl.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

## Informazioni

**Metamorph: Creative Menu (MCM)** è un menu creativo/di sviluppo per **Noita**. Funziona autonomamente in giocatore singolo e offre compatibilità sperimentale opzionale con **Entangled Worlds / Noita Proxy**.

Permette di modificare bacchette, generare o prendere oggetti, applicare/rimuovere vantaggi ed effetti, trasformarsi in creature, possedere una creatura esistente sotto il cursore, cambiare meteo e regole del mondo e creare un compagno simile al giocatore.

## Requisiti e installazione

- Noita installato.
- `metamorph_creative_menu` dentro `Noita/mods/`.
- Attivare **Unsafe mods / unrestricted API**: il NoitaPatcher nativo incluso lo richiede.
- Entangled Worlds è **opzionale**.

1. Scarica una build da [Releases](https://github.com/zerodancing/Metamorph-Creative-Menu/releases) oppure scarica/clona il repository.
2. Copia `metamorph_creative_menu` in `Noita/mods/`.
3. Verifica `Noita/mods/metamorph_creative_menu/mod.xml`.
4. Attiva Unsafe mods e poi Metamorph: Creative Menu.

Non rinominare la cartella interna.

## Comandi

- **TAB** — apre/chiude il menu.
- **TAB trasformato** — ritorna alla forma umana.
- **G** predefinito — possiede/trasforma nella creatura compatibile sotto il cursore; configurabile.
- LMB/RMB cambiano azione in base alla scheda e sono indicati nell'interfaccia.

## Funzioni

### Incantesimi
Impugna una bacchetta, scegli uno slot e un incantesimo dal catalogo con ricerca/categorie. Puoi sostituire, eliminare o lasciare cadere incantesimi. La sostituzione verifica il nuovo incantesimo prima di eliminare quello vecchio.

### Oggetti
Contenitori, liquidi, pietre, uova, bacchette, libri, bonus, sfere, oggetti quest e altro.
- **LMB:** genera vicino.
- **RMB:** prova ad aggiungere direttamente all'inventario.
- Se non c'è spazio o il pickup fallisce, l'oggetto resta nel mondo.
- Sono supportate fiaschette/contenitori riempiti.

### Vantaggi
- **ADD:** LMB genera il pickup; RMB applica direttamente.
- **REMOVE:** LMB rimuove uno stack; RMB tenta di rimuoverli tutti.
MCM registra molte modifiche appartenenti ai perk per ripristinare entità, componenti e valori senza sovrascrivere volutamente stato esterno. Se non esiste un inverse sicuro, può rifiutare una rimozione rischiosa.

### Ricerca
I cataloghi grandi possono cercare nome tradotto, ID e/o descrizione.

### Creature, oggetti e forme
- **LMB:** genera.
- **RMB:** trasforma.
- **TAB:** umano.

La compatibilità è registrata per percorso XML esatto. Alcuni wrapper noti come pericolosi usano un target canonico sicuro solo durante la trasformazione. Le forme tentano di mantenere attacchi, movimento, presentazione e fisica utili disattivando l'IA che competerebbe col giocatore. Entità complesse possono essere approssimate da adapter speciali.

### Ritorno umano e morte della forma
TAB usa prima il lifecycle polymorph nativo di Noita. MCM conserva anche un backup umano serializzato tramite NoitaPatcher.

Con danno fatale, **death handoff** prova a lasciare morire la forma-creatura trasferendo l'autorità del giocatore al corpo umano ripristinato, evitando che la morte della forma termini automaticamente la run.

### Possessione
Punta una creatura compatibile e premi **G**. MCM adotta una forma compatibile con il target e ritira l'entità originale per evitare un semplice duplicato.

### Compagno PLAYER
La voce `PLAYER` può generare un alleato simile al giocatore. Con le capacità NoitaPatcher necessarie può usare la bacchetta copiata in modo più simile a un giocatore reale.

### Effetti
Applica effetti status/temporanei, scegli durata quando supportata e rimuovi effetti cercando di conservare stati interni/perk non appartenenti all'editor.

### Meteo
Preset orario: mattino, giorno, sera, notte. Preset meteo: sereno, nuvoloso, nebbia, tempesta. Advanced controlla valori supportati di ora, nuvole, nebbia, vento, velocità vento, pioggia e fulmini. **RELEASE** smette di mantenere l'override.

### Regole del mondo
Sono **override reversibili**. `NATIVE`/RESET ripristina il baseline catturato da MCM; le regole critiche usano recovery persistente.

Regole attuali:

- RELAZIONI CREATURE
- ORO PERMANENTE
- USI ILLIMITATI
- RIVELA MAPPA
- DENARO DI SANGUE DAI TRICK KILL
- PROBABILITÀ CURA
- RATTI AMICHEVOLI
- QUANTITÀ DI SANGUE
- ORO DA TRICK KILL
- LAMPO DANNO
- PERDITA MACCHIE
- GRAVITÀ DEL MONDO
- SMORZAMENTO FISICO
- VOLUME DEL SANGUE
- FORZA DEL CALCIO
- FORZA DEI GIUNTI
- VELOCITÀ DEL GIORNO

Le regole fisiche agiscono su entità/corpi caricati o vicini, non istantaneamente su tutto il mondo non caricato.

## Singolo ed Entangled Worlds

**EW non è richiesto in giocatore singolo.** MCM include NoitaPatcher e un codec Base64 locale.

Con `quant.ew` attivo viene abilitata l'integrazione sperimentale per oggetti, perk, meteo, regole, forme/possessione, compagni e compatibility patch. Se EW pubblica già un'API NoitaPatcher compatibile, MCM può riutilizzarla.

Il multiplayer è **sperimentale/parziale**. Host e client dovrebbero avere gli stessi diritti MCM, ma non ogni edge case Noita/EW è garantito. Tutti i peer dovrebbero usare la stessa versione MCM.

## Problemi e segnalazioni

- Menu assente: verifica percorso e mod attivo.
- Funzioni avanzate mancanti: abilita Unsafe mods e controlla `NoitaPatcher/noitapatcher.dll`.
- Forma problematica: indica nome/XML e se fallisce TAB o ritorno dopo morte.
- EW: indica versioni MCM ed EW.

Segnala su [GitHub Issues](https://github.com/zerodancing/Metamorph-Creative-Menu/issues).

## Dipendenze e crediti

MCM include **NoitaPatcher** (dextercd) e **lbase64** (Ilya Kolbin) e integra opzionalmente **Noita Entangled Worlds** (IntQuant e contributor). Dettagli: [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md).

## Link

- MCM: https://github.com/zerodancing/Metamorph-Creative-Menu
- Releases: https://github.com/zerodancing/Metamorph-Creative-Menu/releases
- Issues: https://github.com/zerodancing/Metamorph-Creative-Menu/issues
- Noita: https://noitagame.com/
- NoitaPatcher: https://github.com/dextercd/NoitaPatcher
- NoitaPatcher docs: https://dexter.döpping.eu/NoitaPatcher/
- Entangled Worlds: https://github.com/IntQuant/noita_entangled_worlds
- lbase64: https://github.com/iskolbin/lbase64

## Sviluppo

Mod giocabile: `metamorph_creative_menu/`. Test e contratti: `metamorph_creative_menu/tests/`. Non è ancora stata scelta una licenza generale per il codice originale MCM.
