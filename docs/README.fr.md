# Metamorph: Creative Menu — Français

[English](README.en.md) · [Русский](README.ru.md) · [Português (Brasil)](README.pt-BR.md) · [Español](README.es-ES.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Italiano](README.it.md) · [Polski](README.pl.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

## À propos

**Metamorph: Creative Menu (MCM)** est un menu créatif/de développement pour **Noita**. Il fonctionne de façon autonome en solo et propose une compatibilité expérimentale optionnelle avec **Entangled Worlds / Noita Proxy**.

Il permet de modifier les baguettes, créer ou prendre des objets, appliquer/retirer des atouts et effets, se transformer en créatures, posséder une créature existante sous le curseur, modifier la météo et les règles du monde et créer un compagnon ressemblant au joueur.

## Prérequis et installation

- Noita installé.
- Le dossier `metamorph_creative_menu` dans `Noita/mods/`.
- Activez **Unsafe mods / unrestricted API** : le NoitaPatcher natif inclus en a besoin.
- Entangled Worlds est **optionnel**.

1. Téléchargez une build via [Releases](https://github.com/zerodancing/Metamorph-Creative-Menu/releases) ou clonez/téléchargez le dépôt.
2. Copiez `metamorph_creative_menu` dans `Noita/mods/`.
3. Vérifiez `Noita/mods/metamorph_creative_menu/mod.xml`.
4. Activez Unsafe mods puis Metamorph: Creative Menu.

Ne renommez pas le dossier interne.

## Commandes

- **TAB** — ouvrir/fermer le menu.
- **TAB transformé** — revenir au corps humain.
- **G** par défaut — posséder/se transformer en la créature compatible sous le curseur; configurable.
- Les actions LMB/RMB sont indiquées dans chaque onglet.

## Fonctionnalités

### Sorts
Tenez une baguette, choisissez un emplacement et un sort dans le catalogue avec recherche/catégories. Vous pouvez remplacer, supprimer ou jeter un sort. Le remplacement vérifie d'abord le nouveau sort avant de supprimer l'ancien.

### Objets
Conteneurs, liquides, pierres, œufs, baguettes, livres, bonus, orbes, objets de quête, etc.
- **LMB:** créer à proximité.
- **RMB:** essayer de placer directement dans l'inventaire.
- Si le pickup échoue ou si l'inventaire est plein, l'objet reste dans le monde.
- Les flacons/conteneurs remplis sont pris en charge.

### Atouts
- **ADD:** LMB crée le pickup, RMB applique directement.
- **REMOVE:** LMB retire une pile, RMB tente de tout retirer.
MCM suit de nombreuses modifications appartenant aux perks pour restaurer entités, composants et valeurs sans écraser volontairement les changements externes. Sans inverse sûre, une suppression dangereuse peut être refusée.

### Recherche
Les grands catalogues peuvent rechercher le nom traduit, l'ID et/ou la description.

### Créatures, objets et formes
- **LMB:** créer.
- **RMB:** transformer.
- **TAB:** humain.

La compatibilité est enregistrée par chemin XML exact. Quelques wrappers connus comme dangereux utilisent uniquement pour la transformation une cible canonique sûre. Les formes joueur essaient de conserver attaques, déplacement, apparence et physique utiles tout en désactivant l'IA concurrente. Les entités complexes peuvent utiliser des adaptateurs approximatifs.

### Retour humain et mort de la forme
TAB utilise d'abord le cycle polymorph natif de Noita. MCM conserve aussi une sauvegarde humaine sérialisée grâce à NoitaPatcher.

En cas de dégâts mortels, **death handoff** tente de laisser mourir le corps de créature tout en transférant l'autorité du joueur vers le corps humain restauré, afin que la mort de la forme ne termine pas automatiquement la partie.

### Possession
Visez une créature compatible et appuyez sur **G**. MCM adopte une forme compatible de la cible puis retire la cible originale pour éviter un simple doublon.

### Compagnon PLAYER
L'entrée `PLAYER` crée un allié semblable au joueur. Avec les capacités NoitaPatcher nécessaires, il peut utiliser la baguette copiée d'une façon plus proche d'un vrai joueur.

### Effets
Appliquez des effets de statut/temporaires, choisissez la durée quand possible et retirez-les tout en essayant de préserver les états internes/perks qui n'appartiennent pas à l'éditeur.

### Météo
Heures: matin, jour, soir, nuit. Presets: clair, nuageux, brumeux, tempête. Le mode avancé modifie les valeurs prises en charge de l'heure, nuages, brouillard, vent, vitesse du vent, pluie et éclairs. **RELEASE** cesse de maintenir l'override.

### Règles du monde
Ce sont des **overrides réversibles**. `NATIVE`/RESET restaure le baseline capturé par MCM; les règles critiques disposent de recovery persistant.

Règles actuelles:

- RELATIONS DES CRÉATURES
- OR PERMANENT
- SORTS ILLIMITÉS
- RÉVÉLER LA CARTE
- ARGENT DE SANG DES TRICK KILLS
- CHANCE DE SOIN
- RATS AMICAUX
- QUANTITÉ DE SANG
- OR DES TRICK KILLS
- FLASH DE DÉGÂTS
- PERTE DES TACHES
- GRAVITÉ DU MONDE
- AMORTISSEMENT PHYSIQUE
- VOLUME DE SANG
- FORCE DU COUP DE PIED
- SOLIDITÉ DES JOINTS
- VITESSE DU CYCLE JOUR

Les règles de physique visent les entités/corps chargés ou proches, pas instantanément tout le monde déchargé.

## Solo et Entangled Worlds

**Entangled Worlds n'est pas requis en solo.** MCM inclut NoitaPatcher et un codec Base64 local.

Avec `quant.ew`, MCM active une intégration expérimentale pour objets, perks, météo, règles, formes/possession, compagnons et patches de compatibilité. Si EW publie déjà une API NoitaPatcher compatible, MCM peut la réutiliser.

Le multijoueur reste **expérimental/partiel**. Hôte et client doivent avoir les mêmes droits utilisateur MCM, mais tous les cas limites Noita/EW ne peuvent pas être garantis. Utilisez la même version MCM sur tous les pairs.

## Dépannage et rapports

- Menu absent: vérifiez le chemin et l'activation du mod.
- Fonctions avancées absentes: activez Unsafe mods et vérifiez `NoitaPatcher/noitapatcher.dll`.
- Forme problématique: indiquez le nom/XML exact et si TAB ou le retour après mort a échoué.
- EW: indiquez les versions MCM et EW.

Rapports: [GitHub Issues](https://github.com/zerodancing/Metamorph-Creative-Menu/issues).

## Dépendances et crédits

MCM inclut **NoitaPatcher** (dextercd) et **lbase64** (Ilya Kolbin), avec intégration optionnelle de **Noita Entangled Worlds** (IntQuant et contributeurs). Voir [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md).

## Liens

- MCM: https://github.com/zerodancing/Metamorph-Creative-Menu
- Releases: https://github.com/zerodancing/Metamorph-Creative-Menu/releases
- Issues: https://github.com/zerodancing/Metamorph-Creative-Menu/issues
- Noita: https://noitagame.com/
- NoitaPatcher: https://github.com/dextercd/NoitaPatcher
- NoitaPatcher docs: https://dexter.döpping.eu/NoitaPatcher/
- Entangled Worlds: https://github.com/IntQuant/noita_entangled_worlds
- lbase64: https://github.com/iskolbin/lbase64

## Développement

Mod jouable: `metamorph_creative_menu/`. Tests et contrats: `metamorph_creative_menu/tests/`. Aucune licence globale n'a encore été choisie pour le code original MCM.
