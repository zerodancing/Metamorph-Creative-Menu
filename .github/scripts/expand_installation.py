from pathlib import Path
import re

README = Path("README.md")
text = README.read_text(encoding="utf-8")

blocks = {
"en": r'''### Installation — step by step

1. Open the [Releases page](https://github.com/zerodancing/Metamorph-Creative-Menu/releases). Open the newest release and download the MCM `.zip` file from **Assets**. If a packaged release is not available yet, use **Code → Download ZIP** and find the `metamorph_creative_menu` folder inside the downloaded archive.
2. **Close Noita completely** before installing or updating the mod.
3. Find your Noita installation folder. On Steam: **Library → right-click Noita → Manage → Browse local files**. If you use another installation, open the folder that contains the Noita executable.
4. Open the `mods` folder inside the Noita folder. If `mods` does not exist, create it.
5. Extract the download. Copy the whole folder named **`metamorph_creative_menu`** into `Noita/mods/`. Do not rename that folder.
6. Check the final path. This file must exist directly here:

   `Noita/mods/metamorph_creative_menu/mod.xml`

   Correct: `Noita/mods/metamorph_creative_menu/mod.xml`  
   Wrong: `Noita/mods/metamorph_creative_menu/metamorph_creative_menu/mod.xml`
7. Start Noita and open **Mods**. Enable **Unsafe mods / unrestricted API**. MCM bundles NoitaPatcher, and the full recovery, entity-serialization, player-authority and MagicNumbers functionality needs this permission.
8. Enable **Metamorph: Creative Menu**. If Noita offers **Restart with enabled mods active**, use it; otherwise restart the game after enabling the mod.
9. Start or continue a run and press **TAB**. If the Creative Menu opens, installation is complete. While transformed, TAB is also the normal return-to-human control. The default possession key is **G** and can be changed in the mod settings.
10. If TAB does nothing, check these three things first: the `mod.xml` path from step 6, **Unsafe mods** is enabled, and Noita was restarted after enabling MCM.

**Updating MCM:** close Noita, remove the old `metamorph_creative_menu` folder, then copy the new folder into `mods`. Replacing the whole folder avoids stale files from older versions.

**Entangled Worlds is optional.** Single-player MCM does not require it. For multiplayer, use the same MCM version on every peer and enable the compatible Entangled Worlds setup separately.''',
"ru": r'''### Установка — по шагам

1. Откройте [страницу Releases](https://github.com/zerodancing/Metamorph-Creative-Menu/releases). Откройте самый новый релиз и в разделе **Assets** скачайте `.zip` с MCM. Если готового релиза пока нет, используйте **Code → Download ZIP** и найдите внутри архива папку `metamorph_creative_menu`.
2. **Полностью закройте Noita** перед первой установкой или обновлением мода.
3. Найдите папку игры. В Steam: **Библиотека → ПКМ по Noita → Управление → Просмотреть локальные файлы**. Для другой установки просто откройте папку, в которой находится исполняемый файл Noita.
4. В папке Noita откройте папку `mods`. Если её нет — создайте её.
5. Распакуйте скачанный архив. Скопируйте целиком папку **`metamorph_creative_menu`** в `Noita/mods/`. Не переименовывайте эту папку.
6. Обязательно проверьте итоговый путь. Файл должен находиться прямо здесь:

   `Noita/mods/metamorph_creative_menu/mod.xml`

   Правильно: `Noita/mods/metamorph_creative_menu/mod.xml`  
   Неправильно: `Noita/mods/metamorph_creative_menu/metamorph_creative_menu/mod.xml`
7. Запустите Noita и откройте **Mods / Моды**. Включите **Unsafe mods / unrestricted API**. MCM поставляется со своей копией NoitaPatcher, и полный набор функций восстановления, сериализации сущностей, переключения игрока и MagicNumbers требует этого разрешения.
8. Включите **Metamorph: Creative Menu**. Если Noita показывает кнопку **Restart with enabled mods active**, нажмите её; иначе перезапустите игру после включения мода.
9. Начните или продолжите забег и нажмите **TAB**. Если открылось Creative Menu — установка завершена. Во время превращения TAB также используется для обычного возврата в человеческое тело. Клавиша possession по умолчанию — **G**, её можно изменить в настройках мода.
10. Если TAB ничего не делает, сначала проверьте три вещи: путь к `mod.xml` из шага 6, включён ли **Unsafe mods**, и перезапускалась ли Noita после включения MCM.

**Обновление MCM:** закройте Noita, удалите старую папку `metamorph_creative_menu`, затем скопируйте новую папку в `mods`. Полная замена папки не оставляет старые файлы от предыдущих версий.

**Entangled Worlds не обязателен.** Для одиночной игры MCM работает без него. Для сетевой игры используйте одинаковую версию MCM у всех участников и отдельно установите совместимую версию Entangled Worlds.''',
"pt-br": r'''### Instalação — passo a passo

1. Abra a [página de Releases](https://github.com/zerodancing/Metamorph-Creative-Menu/releases). Abra a versão mais recente e baixe o `.zip` do MCM em **Assets**. Se ainda não houver um pacote de release, use **Code → Download ZIP** e localize a pasta `metamorph_creative_menu` dentro do arquivo baixado.
2. **Feche completamente o Noita** antes de instalar ou atualizar o mod.
3. Localize a pasta de instalação do Noita. No Steam: **Biblioteca → clique com o botão direito em Noita → Gerenciar → Explorar arquivos locais**. Em outra instalação, abra a pasta que contém o executável do Noita.
4. Abra a pasta `mods` dentro da pasta do Noita. Se ela não existir, crie-a.
5. Extraia o download. Copie a pasta inteira **`metamorph_creative_menu`** para `Noita/mods/`. Não renomeie essa pasta.
6. Confira o caminho final. Este arquivo precisa existir exatamente aqui:

   `Noita/mods/metamorph_creative_menu/mod.xml`

   Correto: `Noita/mods/metamorph_creative_menu/mod.xml`  
   Errado: `Noita/mods/metamorph_creative_menu/metamorph_creative_menu/mod.xml`
7. Inicie o Noita e abra **Mods**. Ative **Unsafe mods / unrestricted API**. O MCM inclui o NoitaPatcher e os recursos completos de recuperação, serialização de entidades, autoridade do jogador e MagicNumbers precisam dessa permissão.
8. Ative **Metamorph: Creative Menu**. Se o Noita mostrar **Restart with enabled mods active**, use essa opção; caso contrário, reinicie o jogo depois de ativar o mod.
9. Inicie ou continue uma partida e pressione **TAB**. Se o Creative Menu abrir, a instalação terminou. Enquanto transformado, TAB também é o comando normal para voltar à forma humana. A tecla padrão de possessão é **G** e pode ser alterada nas configurações do mod.
10. Se TAB não fizer nada, confira primeiro: o caminho do `mod.xml` no passo 6, se **Unsafe mods** está ativado e se o Noita foi reiniciado depois de ativar o MCM.

**Para atualizar:** feche o Noita, remova a pasta antiga `metamorph_creative_menu` e copie a nova pasta para `mods`. Substituir a pasta inteira evita arquivos antigos sobrando.

**Entangled Worlds é opcional.** O MCM funciona sozinho no modo single-player. Para multiplayer, use a mesma versão do MCM em todos os jogadores e configure separadamente uma versão compatível do Entangled Worlds.''',
"es": r'''### Instalación — paso a paso

1. Abre la [página de Releases](https://github.com/zerodancing/Metamorph-Creative-Menu/releases). Abre la versión más reciente y descarga el `.zip` de MCM desde **Assets**. Si todavía no hay un paquete de release, usa **Code → Download ZIP** y busca la carpeta `metamorph_creative_menu` dentro del archivo descargado.
2. **Cierra Noita por completo** antes de instalar o actualizar el mod.
3. Localiza la carpeta de instalación de Noita. En Steam: **Biblioteca → clic derecho en Noita → Administrar → Ver archivos locales**. En otra instalación, abre la carpeta que contiene el ejecutable de Noita.
4. Abre la carpeta `mods` dentro de Noita. Si no existe, créala.
5. Extrae la descarga. Copia la carpeta completa **`metamorph_creative_menu`** a `Noita/mods/`. No cambies el nombre de esa carpeta.
6. Comprueba la ruta final. Este archivo debe existir exactamente aquí:

   `Noita/mods/metamorph_creative_menu/mod.xml`

   Correcto: `Noita/mods/metamorph_creative_menu/mod.xml`  
   Incorrecto: `Noita/mods/metamorph_creative_menu/metamorph_creative_menu/mod.xml`
7. Inicia Noita y abre **Mods**. Activa **Unsafe mods / unrestricted API**. MCM incluye NoitaPatcher y las funciones completas de recuperación, serialización de entidades, autoridad del jugador y MagicNumbers necesitan este permiso.
8. Activa **Metamorph: Creative Menu**. Si Noita muestra **Restart with enabled mods active**, úsalo; si no, reinicia el juego después de activar el mod.
9. Inicia o continúa una partida y pulsa **TAB**. Si se abre Creative Menu, la instalación está terminada. Mientras estás transformado, TAB también sirve para volver normalmente a la forma humana. La tecla de posesión predeterminada es **G** y puede cambiarse en los ajustes del mod.
10. Si TAB no hace nada, revisa primero estas tres cosas: la ruta de `mod.xml` del paso 6, que **Unsafe mods** esté activado y que Noita se haya reiniciado después de activar MCM.

**Para actualizar MCM:** cierra Noita, elimina la carpeta antigua `metamorph_creative_menu` y copia la nueva carpeta en `mods`. Reemplazar la carpeta completa evita archivos obsoletos.

**Entangled Worlds es opcional.** MCM funciona solo en un jugador. Para multijugador, usa la misma versión de MCM en todos los jugadores e instala por separado una versión compatible de Entangled Worlds.''',
"de": r'''### Installation — Schritt für Schritt

1. Öffne die [Releases-Seite](https://github.com/zerodancing/Metamorph-Creative-Menu/releases). Öffne das neueste Release und lade die MCM-`.zip` unter **Assets** herunter. Falls noch kein fertiges Release-Paket vorhanden ist, nutze **Code → Download ZIP** und suche darin den Ordner `metamorph_creative_menu`.
2. **Beende Noita vollständig**, bevor du den Mod installierst oder aktualisierst.
3. Finde deinen Noita-Installationsordner. In Steam: **Bibliothek → Rechtsklick auf Noita → Verwalten → Lokale Dateien durchsuchen**. Bei einer anderen Installation öffne den Ordner mit der Noita-Programmdatei.
4. Öffne im Noita-Ordner den Ordner `mods`. Falls er nicht existiert, erstelle ihn.
5. Entpacke den Download. Kopiere den vollständigen Ordner **`metamorph_creative_menu`** nach `Noita/mods/`. Benenne diesen Ordner nicht um.
6. Prüfe den endgültigen Pfad. Diese Datei muss genau hier liegen:

   `Noita/mods/metamorph_creative_menu/mod.xml`

   Richtig: `Noita/mods/metamorph_creative_menu/mod.xml`  
   Falsch: `Noita/mods/metamorph_creative_menu/metamorph_creative_menu/mod.xml`
7. Starte Noita und öffne **Mods**. Aktiviere **Unsafe mods / unrestricted API**. MCM bringt NoitaPatcher mit; die vollständigen Recovery-, Entity-Serialisierungs-, Player-Authority- und MagicNumbers-Funktionen benötigen diese Berechtigung.
8. Aktiviere **Metamorph: Creative Menu**. Falls Noita **Restart with enabled mods active** anbietet, nutze diese Option; andernfalls starte das Spiel nach dem Aktivieren neu.
9. Starte oder lade einen Run und drücke **TAB**. Wenn das Creative Menu erscheint, ist die Installation abgeschlossen. Während einer Verwandlung ist TAB auch die normale Rückkehr zur menschlichen Form. Die Standardtaste für Possession ist **G** und kann in den Mod-Einstellungen geändert werden.
10. Falls TAB nichts tut, prüfe zuerst: den `mod.xml`-Pfad aus Schritt 6, ob **Unsafe mods** aktiviert ist und ob Noita nach dem Aktivieren von MCM neu gestartet wurde.

**MCM aktualisieren:** Noita schließen, den alten Ordner `metamorph_creative_menu` entfernen und danach den neuen Ordner nach `mods` kopieren. So bleiben keine veralteten Dateien zurück.

**Entangled Worlds ist optional.** Im Einzelspieler benötigt MCM EW nicht. Für Multiplayer sollte auf allen Peers dieselbe MCM-Version laufen; eine kompatible Entangled-Worlds-Version wird separat eingerichtet.''',
"fr": r'''### Installation — étape par étape

1. Ouvrez la [page Releases](https://github.com/zerodancing/Metamorph-Creative-Menu/releases). Ouvrez la version la plus récente et téléchargez le `.zip` de MCM dans **Assets**. Si aucun paquet de release n’est encore disponible, utilisez **Code → Download ZIP** puis trouvez le dossier `metamorph_creative_menu` dans l’archive téléchargée.
2. **Fermez complètement Noita** avant d’installer ou de mettre à jour le mod.
3. Trouvez le dossier d’installation de Noita. Dans Steam : **Bibliothèque → clic droit sur Noita → Gérer → Parcourir les fichiers locaux**. Pour une autre installation, ouvrez le dossier contenant l’exécutable de Noita.
4. Ouvrez le dossier `mods` dans le dossier de Noita. S’il n’existe pas, créez-le.
5. Extrayez l’archive. Copiez le dossier complet **`metamorph_creative_menu`** dans `Noita/mods/`. Ne renommez pas ce dossier.
6. Vérifiez le chemin final. Ce fichier doit se trouver exactement ici :

   `Noita/mods/metamorph_creative_menu/mod.xml`

   Correct : `Noita/mods/metamorph_creative_menu/mod.xml`  
   Incorrect : `Noita/mods/metamorph_creative_menu/metamorph_creative_menu/mod.xml`
7. Lancez Noita et ouvrez **Mods**. Activez **Unsafe mods / unrestricted API**. MCM inclut NoitaPatcher et les fonctions complètes de récupération, sérialisation des entités, autorité du joueur et MagicNumbers ont besoin de cette permission.
8. Activez **Metamorph: Creative Menu**. Si Noita propose **Restart with enabled mods active**, utilisez cette option ; sinon redémarrez le jeu après avoir activé le mod.
9. Lancez ou continuez une partie et appuyez sur **TAB**. Si le Creative Menu s’ouvre, l’installation est terminée. Pendant une transformation, TAB sert aussi à revenir normalement à la forme humaine. La touche de possession par défaut est **G** et peut être modifiée dans les paramètres du mod.
10. Si TAB ne fait rien, vérifiez d’abord : le chemin de `mod.xml` de l’étape 6, que **Unsafe mods** est activé et que Noita a été redémarré après l’activation de MCM.

**Mise à jour de MCM :** fermez Noita, supprimez l’ancien dossier `metamorph_creative_menu`, puis copiez le nouveau dossier dans `mods`. Remplacer entièrement le dossier évite de conserver des fichiers obsolètes.

**Entangled Worlds est facultatif.** MCM fonctionne seul en solo. En multijoueur, utilisez la même version de MCM sur tous les joueurs et installez séparément une version compatible d’Entangled Worlds.''',
"it": r'''### Installazione — passo per passo

1. Apri la [pagina Releases](https://github.com/zerodancing/Metamorph-Creative-Menu/releases). Apri la versione più recente e scarica il `.zip` di MCM da **Assets**. Se non è ancora disponibile un pacchetto release, usa **Code → Download ZIP** e trova la cartella `metamorph_creative_menu` nell’archivio scaricato.
2. **Chiudi completamente Noita** prima di installare o aggiornare il mod.
3. Trova la cartella di installazione di Noita. Su Steam: **Libreria → clic destro su Noita → Gestisci → Sfoglia file locali**. Per un’altra installazione, apri la cartella che contiene l’eseguibile di Noita.
4. Apri la cartella `mods` nella cartella di Noita. Se non esiste, creala.
5. Estrai il download. Copia l’intera cartella **`metamorph_creative_menu`** in `Noita/mods/`. Non rinominare questa cartella.
6. Controlla il percorso finale. Questo file deve esistere esattamente qui:

   `Noita/mods/metamorph_creative_menu/mod.xml`

   Corretto: `Noita/mods/metamorph_creative_menu/mod.xml`  
   Errato: `Noita/mods/metamorph_creative_menu/metamorph_creative_menu/mod.xml`
7. Avvia Noita e apri **Mods**. Abilita **Unsafe mods / unrestricted API**. MCM include NoitaPatcher e le funzioni complete di recovery, serializzazione delle entità, player authority e MagicNumbers richiedono questo permesso.
8. Abilita **Metamorph: Creative Menu**. Se Noita mostra **Restart with enabled mods active**, usa quell’opzione; altrimenti riavvia il gioco dopo aver abilitato il mod.
9. Avvia o continua una partita e premi **TAB**. Se si apre il Creative Menu, l’installazione è completata. Durante una trasformazione, TAB serve anche per tornare normalmente alla forma umana. Il tasto predefinito per la possessione è **G** e può essere modificato nelle impostazioni del mod.
10. Se TAB non fa nulla, controlla prima: il percorso di `mod.xml` del punto 6, che **Unsafe mods** sia abilitato e che Noita sia stato riavviato dopo aver attivato MCM.

**Aggiornamento di MCM:** chiudi Noita, elimina la vecchia cartella `metamorph_creative_menu`, quindi copia la nuova cartella in `mods`. Sostituire l’intera cartella evita di lasciare file obsoleti.

**Entangled Worlds è opzionale.** MCM funziona autonomamente in single-player. Per il multiplayer, usa la stessa versione di MCM su tutti i giocatori e configura separatamente una versione compatibile di Entangled Worlds.''',
"pl": r'''### Instalacja — krok po kroku

1. Otwórz [stronę Releases](https://github.com/zerodancing/Metamorph-Creative-Menu/releases). Otwórz najnowsze wydanie i pobierz plik `.zip` MCM z sekcji **Assets**. Jeżeli nie ma jeszcze gotowego pakietu wydania, użyj **Code → Download ZIP** i znajdź folder `metamorph_creative_menu` wewnątrz pobranego archiwum.
2. **Całkowicie zamknij Noitę** przed instalacją lub aktualizacją moda.
3. Znajdź folder instalacyjny Noity. W Steam: **Biblioteka → prawy przycisk na Noita → Zarządzaj → Przeglądaj pliki lokalne**. Przy innej instalacji otwórz folder zawierający plik wykonywalny Noity.
4. Otwórz folder `mods` w katalogu Noity. Jeśli go nie ma, utwórz go.
5. Rozpakuj pobrany plik. Skopiuj cały folder **`metamorph_creative_menu`** do `Noita/mods/`. Nie zmieniaj nazwy tego folderu.
6. Sprawdź końcową ścieżkę. Ten plik musi znajdować się dokładnie tutaj:

   `Noita/mods/metamorph_creative_menu/mod.xml`

   Poprawnie: `Noita/mods/metamorph_creative_menu/mod.xml`  
   Błędnie: `Noita/mods/metamorph_creative_menu/metamorph_creative_menu/mod.xml`
7. Uruchom Noitę i otwórz **Mods**. Włącz **Unsafe mods / unrestricted API**. MCM zawiera NoitaPatcher, a pełne funkcje odzyskiwania, serializacji encji, kontroli gracza i MagicNumbers wymagają tego uprawnienia.
8. Włącz **Metamorph: Creative Menu**. Jeśli Noita pokaże **Restart with enabled mods active**, użyj tej opcji; w przeciwnym razie uruchom grę ponownie po włączeniu moda.
9. Rozpocznij lub kontynuuj rozgrywkę i naciśnij **TAB**. Jeśli otworzy się Creative Menu, instalacja jest zakończona. Podczas transformacji TAB służy również do normalnego powrotu do ludzkiej formy. Domyślny klawisz przejęcia to **G** i można go zmienić w ustawieniach moda.
10. Jeśli TAB nic nie robi, najpierw sprawdź: ścieżkę `mod.xml` z kroku 6, czy **Unsafe mods** jest włączone i czy Noita została ponownie uruchomiona po aktywowaniu MCM.

**Aktualizacja MCM:** zamknij Noitę, usuń stary folder `metamorph_creative_menu`, a następnie skopiuj nowy folder do `mods`. Pełna wymiana folderu zapobiega pozostawieniu starych plików.

**Entangled Worlds jest opcjonalny.** MCM działa samodzielnie w trybie single-player. W multiplayerze wszyscy gracze powinni używać tej samej wersji MCM, a zgodną wersję Entangled Worlds należy skonfigurować osobno.''',
"zh-cn": r'''### 安装 — 逐步说明

1. 打开 [Releases 页面](https://github.com/zerodancing/Metamorph-Creative-Menu/releases)。进入最新版本，在 **Assets** 中下载 MCM 的 `.zip` 文件。如果暂时没有打包好的 Release，请使用 **Code → Download ZIP**，然后在下载的压缩包中找到 `metamorph_creative_menu` 文件夹。
2. 安装或更新模组前，**请完全关闭 Noita**。
3. 找到 Noita 的安装目录。Steam：**库 → 右键 Noita → 管理 → 浏览本地文件**。如果使用其他安装方式，请打开包含 Noita 可执行文件的目录。
4. 在 Noita 目录中打开 `mods` 文件夹。如果没有该文件夹，请创建它。
5. 解压下载文件。将完整的 **`metamorph_creative_menu`** 文件夹复制到 `Noita/mods/`。不要重命名这个文件夹。
6. 检查最终路径。下面这个文件必须直接存在：

   `Noita/mods/metamorph_creative_menu/mod.xml`

   正确：`Noita/mods/metamorph_creative_menu/mod.xml`  
   错误：`Noita/mods/metamorph_creative_menu/metamorph_creative_menu/mod.xml`
7. 启动 Noita 并打开 **Mods**。启用 **Unsafe mods / unrestricted API**。MCM 自带 NoitaPatcher，完整的恢复、实体序列化、玩家控制权切换和 MagicNumbers 功能需要此权限。
8. 启用 **Metamorph: Creative Menu**。如果 Noita 显示 **Restart with enabled mods active**，请选择它；否则在启用模组后重新启动游戏。
9. 开始或继续一次游戏并按 **TAB**。如果 Creative Menu 打开，说明安装成功。变形状态下，TAB 也用于正常返回人类形态。默认的附身按键是 **G**，可在模组设置中修改。
10. 如果按 TAB 没有反应，请先检查三项：第 6 步中的 `mod.xml` 路径、是否启用了 **Unsafe mods**、以及启用 MCM 后是否重启了 Noita。

**更新 MCM：**关闭 Noita，删除旧的 `metamorph_creative_menu` 文件夹，然后把新文件夹复制到 `mods`。完整替换可以避免残留旧版本文件。

**Entangled Worlds 是可选的。** 单人游戏不需要 EW。多人游戏时，请确保所有玩家使用相同版本的 MCM，并单独安装兼容版本的 Entangled Worlds。''',
"ja": r'''### インストール — 手順

1. [Releases ページ](https://github.com/zerodancing/Metamorph-Creative-Menu/releases)を開きます。最新リリースを開き、**Assets** から MCM の `.zip` をダウンロードしてください。まだパッケージ済みリリースがない場合は **Code → Download ZIP** を使い、ダウンロードしたアーカイブ内の `metamorph_creative_menu` フォルダーを探します。
2. インストールまたは更新の前に、**Noita を完全に終了**してください。
3. Noita のインストールフォルダーを開きます。Steam では **ライブラリ → Noita を右クリック → 管理 → ローカルファイルを閲覧**。それ以外のインストールでは Noita の実行ファイルがあるフォルダーを開きます。
4. Noita フォルダー内の `mods` を開きます。存在しない場合は作成してください。
5. ダウンロードしたファイルを展開し、**`metamorph_creative_menu`** フォルダー全体を `Noita/mods/` にコピーします。このフォルダー名は変更しないでください。
6. 最終パスを確認します。次のファイルが直接存在している必要があります：

   `Noita/mods/metamorph_creative_menu/mod.xml`

   正しい例：`Noita/mods/metamorph_creative_menu/mod.xml`  
   間違い：`Noita/mods/metamorph_creative_menu/metamorph_creative_menu/mod.xml`
7. Noita を起動して **Mods** を開き、**Unsafe mods / unrestricted API** を有効にします。MCM には NoitaPatcher が同梱されており、完全な復旧、エンティティのシリアライズ、プレイヤー権限切り替え、MagicNumbers 機能にこの許可が必要です。
8. **Metamorph: Creative Menu** を有効にします。Noita に **Restart with enabled mods active** が表示された場合はそれを使用し、表示されない場合も有効化後にゲームを再起動してください。
9. ランを開始または再開して **TAB** を押します。Creative Menu が開けばインストール成功です。変身中の TAB は通常の人間形態への復帰にも使います。Possession の初期キーは **G** で、Mod 設定から変更できます。
10. TAB を押しても何も起きない場合は、まず第 6 手順の `mod.xml` パス、**Unsafe mods** が有効か、MCM 有効化後に Noita を再起動したかを確認してください。

**MCM の更新：**Noita を終了し、古い `metamorph_creative_menu` フォルダーを削除してから、新しいフォルダーを `mods` にコピーしてください。フォルダー全体を置き換えることで古いファイルの残留を防げます。

**Entangled Worlds は任意です。** シングルプレイでは EW は不要です。マルチプレイでは全プレイヤーが同じ MCM バージョンを使用し、対応する Entangled Worlds を別途導入してください。''',
"ko": r'''### 설치 — 단계별 안내

1. [Releases 페이지](https://github.com/zerodancing/Metamorph-Creative-Menu/releases)를 엽니다. 가장 최신 릴리스를 열고 **Assets**에서 MCM `.zip` 파일을 다운로드하세요. 아직 패키지 릴리스가 없다면 **Code → Download ZIP**을 사용한 뒤 압축 파일 안에서 `metamorph_creative_menu` 폴더를 찾으세요.
2. 모드를 설치하거나 업데이트하기 전에 **Noita를 완전히 종료**하세요.
3. Noita 설치 폴더를 찾습니다. Steam에서는 **라이브러리 → Noita 우클릭 → 관리 → 로컬 파일 보기**를 사용하세요. 다른 설치 방식이라면 Noita 실행 파일이 있는 폴더를 여세요.
4. Noita 폴더 안의 `mods` 폴더를 엽니다. 없다면 새로 만드세요.
5. 다운로드한 파일의 압축을 풉니다. **`metamorph_creative_menu`** 폴더 전체를 `Noita/mods/` 안에 복사하세요. 이 폴더 이름을 바꾸지 마세요.
6. 최종 경로를 확인하세요. 아래 파일이 정확히 이 위치에 있어야 합니다:

   `Noita/mods/metamorph_creative_menu/mod.xml`

   올바름: `Noita/mods/metamorph_creative_menu/mod.xml`  
   잘못됨: `Noita/mods/metamorph_creative_menu/metamorph_creative_menu/mod.xml`
7. Noita를 실행하고 **Mods**를 엽니다. **Unsafe mods / unrestricted API**를 활성화하세요. MCM에는 NoitaPatcher가 포함되어 있으며 전체 복구, 엔티티 직렬화, 플레이어 권한 전환 및 MagicNumbers 기능에 이 권한이 필요합니다.
8. **Metamorph: Creative Menu**를 활성화하세요. Noita에 **Restart with enabled mods active**가 표시되면 사용하고, 그렇지 않더라도 모드를 활성화한 뒤 게임을 다시 시작하세요.
9. 게임을 시작하거나 이어서 **TAB**을 누르세요. Creative Menu가 열리면 설치가 완료된 것입니다. 변신 중 TAB은 정상적으로 인간 형태로 돌아가는 키이기도 합니다. 기본 possession 키는 **G**이며 모드 설정에서 변경할 수 있습니다.
10. TAB을 눌러도 아무 반응이 없다면 먼저 세 가지를 확인하세요: 6단계의 `mod.xml` 경로, **Unsafe mods** 활성화 여부, MCM 활성화 후 Noita를 재시작했는지 여부입니다.

**MCM 업데이트:** Noita를 종료하고 기존 `metamorph_creative_menu` 폴더를 삭제한 뒤 새 폴더를 `mods`에 복사하세요. 폴더 전체를 교체하면 이전 버전 파일이 남는 것을 방지할 수 있습니다.

**Entangled Worlds는 선택 사항입니다.** 싱글플레이에서는 EW가 필요하지 않습니다. 멀티플레이에서는 모든 플레이어가 같은 MCM 버전을 사용하고 호환되는 Entangled Worlds를 별도로 설치하세요.''',
}

for code, block in blocks.items():
    anchor = re.escape(f'<a id="{code}"></a>')
    pattern = rf'({anchor}\n\n## [^\n]+\n\n)### [^\n]+\n\n.*?(?=\n\n### )'
    text, count = re.subn(pattern, lambda match: match.group(1) + block, text, count=1, flags=re.S)
    if count != 1:
        raise RuntimeError(f"Could not replace installation section for {code}")

README.write_text(text, encoding="utf-8")
print("Expanded installation instructions for", len(blocks), "languages")
