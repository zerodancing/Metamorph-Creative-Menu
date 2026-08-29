<h1 align="center">Metamorph: Creative Menu</h1>

<p align="center">
  Une boîte à outils créative pour Noita : sorts, baguettes, objets, matériaux, atouts, créatures, effets, téléportation, météo et règles du monde.
</p>

<a id="languages"></a>

[English](README.md) · [Русский](README.ru.md) · [Português (Brasil)](README.pt-BR.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [**Français**](README.fr.md) · [Italiano](README.it.md) · [Polski](README.pl.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

## Télécharger

Version actuelle : **2.0.0**

| Paquet | Téléchargement |
|---|---|
| **Dernière version prête à installer** | **[⬇️ Télécharger Metamorph-Creative-Menu.zip](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip)** |
| Page de la version | [Dernière version prête à installer](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build) |

> Le ZIP contient déjà le dossier complet `metamorph_creative_menu`, y compris NoitaPatcher. Extrayez ce dossier directement dans `Noita/mods/`.

Chemin final correct :

```text
Noita/mods/metamorph_creative_menu/mod.xml
```

Si vous obtenez `metamorph_creative_menu/metamorph_creative_menu/mod.xml`, l'archive a été extraite un niveau de dossier trop bas.

---

## Français

### Installation

1. [Téléchargez le dernier ZIP prêt à installer](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip).
2. Fermez complètement Noita avant d'installer ou de mettre à jour le mod.
3. Dans Steam, ouvrez **Bibliothèque → clic droit sur Noita → Gérer → Parcourir les fichiers locaux**.
4. Ouvrez le dossier `mods` du jeu et copiez-y le dossier complet **`metamorph_creative_menu`**.
5. Vérifiez que `Noita/mods/metamorph_creative_menu/mod.xml` existe. Ne renommez pas le dossier du mod.
6. Lancez Noita, activez **Metamorph: Creative Menu**, autorisez **Unsafe mods / unrestricted API** si nécessaire, puis redémarrez Noita après l'activation du mod.
7. Lancez une partie et appuyez sur **TAB**. Si le menu s'ouvre, l'installation est terminée.

**Mise à jour :** fermez Noita, supprimez l'ancien dossier `metamorph_creative_menu`, puis copiez le nouveau dans `mods`. Remplacer le dossier entier évite de conserver des fichiers obsolètes d'anciennes versions.

### Commandes

- **F4 ou TAB** : ouvrir ou fermer le Creative Menu.
- **TAB pendant une transformation** : revenir à la forme humaine.
- **G** par défaut : prendre le contrôle d'une créature compatible sous le curseur.
- **Bouton central de la souris** : dessiner avec le matériau sélectionné.
- Les raccourcis peuvent être modifiés dans la section COMMANDES ou dans les paramètres du mod. Les actions disponibles au clic gauche et au clic droit sont indiquées dans l'interface.

### Ce que MCM permet de faire

- Obtenir et placer des sorts, puis les déplacer entre les baguettes, les emplacements Toujours lancé, l'inventaire et le monde.
- Modifier les caractéristiques, l'apparence et les verrouillages des baguettes ; enregistrer des préréglages et créer des copies.
- Faire apparaître des objets près du joueur ou à une position choisie dans le monde, et placer les objets compatibles directement dans l'inventaire.
- Créer des flacons avec les liquides sélectionnés.
- Choisir des matériaux et les dessiner dans le monde.
- Faire apparaître, ajouter et retirer des atouts.
- Faire apparaître des créatures près du joueur ou à une position choisie dans le monde.
- Se transformer en créature, prendre le contrôle de créatures existantes et revenir à la forme humaine.
- Faire apparaître une entité PLAYER distincte.
- Appliquer et retirer des effets du jeu.
- Modifier la météo, l'heure de la journée, la gravité et d'autres règles du monde.
- Se téléporter vers des lieux du jeu.
- Avec Entangled Worlds, se téléporter vers d'autres joueurs ou les faire venir jusqu'à vous.
- Modifier les raccourcis et rechercher dans les catalogues de sorts, objets, matériaux, atouts et créatures.
- Déplacer et redimensionner la fenêtre du menu ; sa position et sa taille sont conservées entre les lancements du jeu.

<details>
<summary><strong>Transformations, compatibilité et récupération</strong></summary>

MCM utilise des données de compatibilité basées sur les chemins XML exacts ainsi que des exceptions de routage sûr très limitées pour les entités connues comme dangereuses ou inadaptées à une transformation native directe. Les formes contrôlées par le joueur essaient de conserver les mouvements, attaques, éléments visuels et comportements physiques natifs utiles, tout en désactivant les éléments d'intelligence artificielle qui entreraient en conflit avec les commandes du joueur. Les boss complexes, les entités fortement scriptées et les objets physiques peuvent nécessiter des adaptateurs dédiés et ne reproduisent pas toujours exactement chaque comportement de leur intelligence artificielle d'origine.

NoitaPatcher est utilisé pour les mécanismes de récupération renforcée, notamment la sérialisation et la désérialisation des entités, le transfert de l'entité contrôlée par le joueur et d'autres fonctions avancées pendant l'exécution. C'est pourquoi la version complète et autonome demande un accès de mod sans restrictions.

</details>

<details>
<summary><strong>Intégration multijoueur avec Entangled Worlds</strong></summary>

**Entangled Worlds est facultatif.** MCM est conçu pour fonctionner comme un mod complet en solo sans EW.

Lorsque `quant.ew` est actif, MCM active une intégration expérimentale pour les objets partagés, les atouts, la météo, les règles du monde, les formes et la prise de contrôle de créatures, les demandes de compagnon ainsi que les comportements liés à l'autorité et à la synchronisation. Tous les participants doivent utiliser la même version de MCM. Le multijoueur est volontairement considéré comme expérimental, car toutes les situations particulières de Noita et EW ne peuvent pas être garanties comme parfaitement synchronisées.

</details>

### Prérequis et composants tiers

- **Noita** — jeu requis, par Nolla Games.
- **NoitaPatcher** par dextercd — inclus avec MCM et utilisé pour les fonctions avancées et de récupération.
- **lbase64** par Ilya Kolbin — implémentation locale de Base64 incluse.
- **Entangled Worlds / Noita Proxy** par IntQuant et les contributeurs — intégration multijoueur facultative ; non requise en solo.

Les liens exacts vers les projets d'origine, les chemins des composants inclus et les informations de licence ou d'état se trouvent dans [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

### Dépannage

- **TAB ne fait rien :** vérifiez le chemin exact de `mod.xml`, assurez-vous que MCM est activé, autorisez Unsafe mods/unrestricted API, puis redémarrez Noita.
- **La récupération avancée ou une partie des règles du monde manque :** vérifiez que `metamorph_creative_menu/NoitaPatcher/noitapatcher.dll` est présent et que l'accès unrestricted API est autorisé.
- **Une forme ne revient pas correctement :** indiquez le nom ou le XML exact de la créature et précisez si l'échec concerne le retour normal avec TAB ou le retour après des dégâts mortels.
- **Désynchronisation avec EW :** vérifiez que tous les participants utilisent la même version de MCM et une version compatible d'EW.

### Liens

- [Dernière version](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build)
- [Signaler un problème](https://github.com/zerodancing/Metamorph-Creative-Menu/issues)
- [Composants tiers](THIRD_PARTY_NOTICES.md)
- [Noita](https://noitagame.com/)
- [NoitaPatcher](https://github.com/dextercd/NoitaPatcher)
- [Documentation de NoitaPatcher](https://dexter.döpping.eu/NoitaPatcher/)
- [Entangled Worlds](https://github.com/IntQuant/noita_entangled_worlds)
- [lbase64](https://github.com/iskolbin/lbase64)

[↑ Retour au choix de langue](#languages)

---

## Pour les développeurs

Le mod jouable se trouve dans `metamorph_creative_menu/`.

- Notes d'architecture et de développement : `metamorph_creative_menu/README.txt`
- Suite de tests de régression : `metamorph_creative_menu/tests/`
- Instructions de test : `metamorph_creative_menu/tests/TESTING.txt`
- Informations sur les composants tiers : [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)

Le workflow automatique `latest-build` du dépôt regroupe le dossier jouable `metamorph_creative_menu` dans un ZIP prêt à installer et met à jour l'adresse de téléchargement stable indiquée plus haut.