<a id="languages"></a>

[English](README.md) · [Русский](README.ru.md) · [Português (Brasil)](README.pt-BR.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [**Français**](README.fr.md) · [Italiano](README.it.md) · [Polski](README.pl.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

<h1 align="center">Metamorph: Creative Menu</h1>

<p align="center">Un menu créatif et une boîte à outils pour Noita : sorts, baguettes, objets, matériaux, atouts, créatures, transformations, effets, téléportation, météo, règles du monde et bien plus encore.</p>

<p align="center"><strong>Version 2.0.0</strong></p>

---

# Télécharger

[**⬇️ Télécharger la dernière version du mod**](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip)

Version actuelle : **2.0.0**

**La version complète nécessite d'autoriser les mods non sécurisés.**

[Page de la dernière compilation](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build)

[Liste des changements de la version 2.0.0](metamorph_creative_menu/CHANGELOG.txt)

# Sommaire

- [Installation](#installation)
- [Version complète et version du Workshop Steam](#version-complète-et-version-du-workshop-steam)
- [À propos du mod](#à-propos-du-mod)
- [Commandes et interface](#commandes-et-interface)
- [Sorts](#sorts)
- [Baguettes](#baguettes)
- [Objets et liquides](#objets-et-liquides)
- [Matériaux](#matériaux)
- [Atouts](#atouts)
- [Effets](#effets)
- [Créatures et transformations](#créatures-et-transformations)
- [Retour après une transformation et mort de la forme](#retour-après-une-transformation-et-mort-de-la-forme)
- [Prendre le contrôle d'une créature](#prendre-le-contrôle-dune-créature)
- [Joueur](#joueur)
- [Météo et heure](#météo-et-heure)
- [Règles du monde](#règles-du-monde)
- [Téléportation](#téléportation)
- [Entangled Worlds](#entangled-worlds)
- [NoitaPatcher et mods non sécurisés](#noitapatcher-et-mods-non-sécurisés)
- [Si quelque chose ne fonctionne pas](#si-quelque-chose-ne-fonctionne-pas)
- [Signaler un problème](#signaler-un-problème)

# Installation

1. [Téléchargez la dernière version du mod](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip).
2. Lancez Noita et ouvrez **Mods** depuis le menu principal.
3. Cliquez sur **Ouvrir le dossier des mods**.
4. Déplacez le dossier `metamorph_creative_menu` de l'archive téléchargée vers le dossier `mods` qui vient de s'ouvrir. Si `metamorph_creative_menu` y existe déjà, supprimez l'ancien dossier et remplacez-le par le nouveau.
5. Fermez le dossier des mods.
6. Dans le menu des mods, cliquez sur **Actualiser**. **Metamorph: Creative Menu** devrait apparaître dans la liste.
7. Cliquez sur **Mods non sécurisés** jusqu'à ce que le texte devienne rouge et indique **Mods non sécurisés : autorisés**.
8. Cliquez sur le nom du mod pour qu'il soit mis en évidence et que **[x]** apparaisse devant. Cela signifie que le mod est activé.
9. Cliquez sur **Démarrer une nouvelle partie avec les mods actifs**.
10. Choisissez un mode de jeu et jouez.

# Version complète et version du Workshop Steam

La compilation disponible sur cette page GitHub est la version complète de MCM. Elle inclut NoitaPatcher ainsi que des fonctions qui nécessitent l'autorisation des mods non sécurisés.

La [version du Workshop Steam](https://steamcommunity.com/sharedfiles/filedetails/?id=3785170245) s'installe séparément. Elle n'inclut ni NoitaPatcher ni les fonctions de la version complète qui nécessitent l'accès accordé aux mods non sécurisés.

N'installez et n'activez pas les deux versions en même temps.

# À propos du mod

**Metamorph: Creative Menu (MCM)** est un menu créatif et une boîte à outils pour Noita.

Il réunit dans une même interface des outils pour les sorts, baguettes, objets, matériaux, atouts, effets, créatures, transformations, la météo, les règles globales du monde et la téléportation.

MCM convient aussi bien au jeu libre en mode créatif qu'aux expériences sur les mécaniques de Noita. De nombreuses opérations ne se limitent pas à créer une nouvelle entité : elles tiennent compte de l'état déjà existant de la baguette, de l'objet, de la forme, de l'atout ou du monde.

**Entangled Worlds n'est pas requis.** Sans lui, MCM fonctionne comme un mod complet en solo. Lorsque Entangled Worlds est installé, des fonctions multijoueur expérimentales supplémentaires deviennent disponibles.

# Commandes et interface

| Action | Touche |
| --- | --- |
| Ouvrir / fermer le menu créatif | **F4 ou TAB** |
| Revenir à la forme humaine | **TAB pendant une transformation** |
| Prendre le contrôle d'une créature | **G** |
| Peindre avec le matériau sélectionné | **Bouton central de la souris** |

Le panneau MCM est également accessible depuis l'interface normale de l'inventaire.

Les touches peuvent être modifiées dans la section **COMMANDES** ou dans les paramètres du mod.

Pendant l'attribution d'une touche :

- **DELETE / BACKSPACE** — effacer l'attribution ;
- **ESC** — annuler ;
- **R** — rétablir l'attribution par défaut ;
- **TOUT RÉINITIALISER** — rétablir toutes les attributions par défaut après confirmation.

Si une même combinaison est attribuée à plusieurs actions, MCM signale un conflit.

## Fenêtre du menu créatif

La fenêtre peut être :

- déplacée ;
- redimensionnée en largeur et en hauteur ;
- redimensionnée depuis ses bords et ses coins ;
- réduite ;
- fermée ;
- remise à sa disposition par défaut.

Sa taille, sa position et la dernière section ouverte sont conservées entre les lancements du jeu.

Les grands catalogues utilisent le défilement et s'adaptent automatiquement à la taille actuelle de la fenêtre.

## Recherche

La recherche est disponible dans les catalogues de :

- sorts ;
- objets ;
- matériaux ;
- atouts ;
- créatures.

Elle peut tenir compte non seulement du nom affiché, mais aussi du nom anglais, de la clé de localisation, de l'identifiant technique ou du chemin XML.

La recherche ne tient pas compte des majuscules et minuscules et tolère de petites fautes de frappe dans les mots suffisamment longs.

L'interface de MCM est localisée dans 11 langues. Pour le contenu normal du jeu, les traductions de Noita sont réutilisées chaque fois que possible.

# Sorts

La section des sorts permet de travailler non seulement avec le catalogue, mais aussi avec les véritables sorts du joueur actuel.

Sont disponibles en même temps :

- les emplacements de la baguette active ;
- **TOUJOURS LANCÉ** ;
- l'inventaire de sorts ;
- le catalogue de sorts.

## Remplacement rapide

Vous pouvez sélectionner un emplacement précis de la baguette puis faire un Clic G sur le sort voulu dans le catalogue. Le sort sera placé dans l'emplacement sélectionné.

## Glisser-déposer

Les sorts existants peuvent être déplacés :

- entre les emplacements de la baguette ;
- vers **TOUJOURS LANCÉ** ;
- de **TOUJOURS LANCÉ** vers les emplacements normaux ;
- vers un emplacement précis de l'inventaire de sorts ;
- de l'inventaire vers la baguette ;
- dans le monde du jeu ;
- dans la corbeille.

Pour les cartes de sort existantes, MCM essaie de déplacer l'entité de jeu elle-même plutôt que d'en créer une nouvelle copie. Cela permet de conserver l'état modifié de la carte, y compris celui ajouté par d'autres mods.

Le sort d'origine reste à sa place tant que la nouvelle destination n'a pas été confirmée. Une opération refusée ou impossible ne devrait pas détruire la carte d'origine.

## Toujours lancé

Les sorts permanents disposent de leur propre zone.

Lors d'un déplacement entre les emplacements normaux et **TOUJOURS LANCÉ**, MCM tient compte de la capacité de la baguette afin de conserver une structure correcte des emplacements normaux.

## Annuler / Rétablir

Pour les modifications internes de la baguette, un historique limité **ANNULER / RÉTABLIR** est disponible.

Il s'applique aux opérations qui peuvent être restaurées sans risque à partir de l'état de la baguette elle-même.

Le transfert d'un véritable sort vers le monde extérieur ou vers l'inventaire normal du jeu ne peut pas toujours être inversé correctement par la seule restauration de l'état de la baguette. Ces actions ne sont donc pas toujours annulables.

# Baguettes

MCM comprend un éditeur complet de la baguette active.

Vous pouvez modifier :

- la capacité ;
- le nombre de sorts par tir ;
- le temps de recharge ;
- le délai entre les tirs ;
- la dispersion ;
- le multiplicateur de vitesse des projectiles ;
- le mana maximal ;
- la recharge de mana ;
- la récupération du recul ;
- le niveau de la baguette ;
- le mélange ;
- le mode sans recharge.

Vous pouvez également modifier l'apparence et les paramètres associés :

- le nom affiché ;
- les verrouillages ;
- l'image de la baguette ;
- le décalage de l'image ;
- le point de tir.

Un catalogue visuel d'apparences de baguettes est disponible.

## Baguettes sauvegardées

Une baguette peut être sauvegardée afin de réutiliser plus tard son état enregistré.

Sont sauvegardés :

- les caractéristiques ;
- le mana ;
- l'apparence ;
- les sorts normaux ;
- **TOUJOURS LANCÉ** ;
- la disposition des cartes ;
- les utilisations restantes ;
- l'état figé des cartes.

Les baguettes sauvegardées restent disponibles entre les mondes et lors des lancements ultérieurs de Noita.

### Appliquer

**APPLIQUER** applique l'état sauvegardé à la baguette actuellement détenue par le joueur.

### Copie

**COPIE** crée une copie distincte de la baguette sauvegardée.

Si un emplacement adapté est libre dans l'inventaire rapide, la nouvelle baguette y est placée. Sinon, elle est créée dans le monde près du joueur.

Si la création ne peut pas être menée à terme correctement, MCM essaie de supprimer l'entité incomplète.

# Objets et liquides

## Objets

**Clic G** sur une entrée du catalogue crée un objet près du joueur.

**Clic D** essaie de placer l'objet directement dans l'inventaire.

Un objet peut également être glissé :

- vers une zone compatible de l'inventaire rapide ;
- hors du menu, vers un point choisi dans le monde du jeu.

Si la carte est relâchée dans le menu sans destination valable, l'opération est annulée.

Le catalogue contient des modèles : l'entrée elle-même ne disparaît donc pas après la création d'un objet.

MCM respecte la séparation normale de l'inventaire rapide de Noita entre les emplacements de baguettes et d'objets, et ne devrait pas remplacer sans raison un objet déjà présent.

## Liquides

MCM peut créer de véritables récipients du jeu contenant le liquide sélectionné.

Le récipient créé se comporte comme un objet normal de Noita :

- il peut être conservé dans l'inventaire ;
- jeté dans le monde ;
- brisé ;
- son contenu peut se répandre ;
- il participe aux réactions normales entre matériaux.

# Matériaux

Le catalogue de matériaux est construit à partir des substances enregistrées dans l'instance actuelle de Noita.

Il comprend différents types de matériaux, notamment :

- les liquides ;
- les poudres ;
- les gaz ;
- le feu ;
- les matériaux solides ;
- les matériaux statiques ;
- les matériaux à affichage spécial.

Si un autre mod actif ajoute correctement son propre matériau à Noita, celui-ci peut également apparaître dans MCM.

## Peindre avec des matériaux

1. Choisissez un matériau.
2. Choisissez la taille du pinceau.
3. Cliquez sur **COMMENCER À PEINDRE**.
4. Fermez l'inventaire.
5. Maintenez la touche de peinture attribuée dans le monde du jeu.

Par défaut, le **bouton central de la souris** est utilisé.

Ouvrir l'inventaire met fin au mode de peinture.

## Comportement des matériaux

MCM crée de véritables matériaux du monde du jeu, et non des particules décoratives.

Une fois placés, ils continuent à suivre la simulation normale de Noita :

- les liquides s'écoulent ;
- les poudres tombent ;
- les gaz se répandent ;
- le feu interagit avec l'environnement ;
- les substances réagissent entre elles ;
- les matériaux instables peuvent se transformer en d'autres matériaux.

Selon le type de matériau, MCM emploie la méthode de placement appropriée, y compris des fonctions supplémentaires de NoitaPatcher dans les cas qui ne peuvent pas être traités correctement avec les moyens habituels des mods.

# Atouts

## Créer un atout

**Clic G** crée l'atout sélectionné dans le monde du jeu.

Il peut être ramassé comme un atout normal de Noita.

## Obtenir des atouts

MCM permet d'obtenir :

- 1 copie ;
- 10 copies ;
- 100 copies.

L'obtention en masse est traitée progressivement afin de ne pas exécuter un grand nombre d'opérations lourdes en une seule image.

L'interface affiche la progression et la suite de l'opération peut être annulée. Les copies déjà obtenues avec succès restent acquises au joueur après l'annulation.

## Supprimer des atouts

Supprimer un atout sans risque est nettement plus difficile que l'obtenir.

Certains atouts modifient plusieurs systèmes du jeu à la fois, créent des entités ou déclenchent des effets pour lesquels il n'existe pas de méthode universelle permettant de tout inverser.

MCM ne supprime donc que les changements pris en charge pour lesquels il peut effectuer une opération inverse avec une fiabilité suffisante.

Le mod essaie d'annuler uniquement l'état créé par l'application concernée de l'atout, sans réinitialiser inutilement d'autres effets ou paramètres du joueur.

# Effets

MCM permet d'appliquer et de retirer des éléments pris en charge, notamment :

- des effets du jeu ;
- des états liés aux matériaux.

Lors du retrait, le mod essaie de ne pas toucher aux états externes appartenant aux atouts ou à d'autres systèmes du jeu.

Cela permet de nettoyer les effets propres à MCM sans supprimer indistinctement tous les états similaires du joueur.

# Créatures et transformations

## Créer des créatures

**Clic G** crée la créature sélectionnée près du joueur.

La carte d'une créature peut également être glissée hors du menu afin de la créer à l'endroit choisi dans le monde du jeu.

**Clic D** sur une entrée prise en charge tente de transformer le joueur actuel dans la forme correspondante.

## Compatibilité des formes

Les créatures de Noita diffèrent fortement par leur structure interne.

MCM distingue donc les cibles de transformation à partir de chemins XML exacts et ne considère pas automatiquement comme interchangeables toutes les créatures qui se ressemblent.

Pendant une transformation, MCM utilise les capacités de la forme sélectionnée et applique si nécessaire des règles de compatibilité particulières à certaines créatures.

# Retour après une transformation et mort de la forme

Vous pouvez revenir à la forme humaine avec l'action attribuée, **TAB par défaut**.

MCM utilise d'abord les mécanismes normaux de Noita pour terminer une transformation. Pour les cas plus complexes, une restauration supplémentaire au moyen de NoitaPatcher est prévue.

Le mod prend également en charge certaines situations où une forme temporaire subit des dégâts mortels.

Dans ces cas, MCM essaie de :

- conserver le cadavre de la forme morte ;
- restaurer le joueur humain ;
- rendre le contrôle ;
- conserver l'inventaire ;
- restaurer l'état lié au joueur.

Il ne s'agit pas d'une immortalité absolue. Des modes de mort inhabituels provenant d'autres mods, des mods incompatibles ou une défaillance interne de Noita peuvent contourner le mécanisme normal de restauration.

# Prendre le contrôle d'une créature

En plus de choisir une forme dans le catalogue, MCM peut prendre le contrôle d'**une créature déjà présente dans le monde du jeu**.

La touche par défaut est **G**.

Placez le curseur sur une cible compatible et utilisez l'action attribuée.

MCM vérifie la créature, effectue la transformation vers une forme compatible et ne retire l'entité d'origine du monde qu'après confirmation de la réussite de la transformation.

Si la transformation n'aboutit pas, la créature d'origine ne devrait pas simplement disparaître.

Cette fonction ne se limite pas au catalogue statique de MCM. Une créature compatible ajoutée par un autre mod peut également passer la vérification, même si une compatibilité universelle avec toutes les entités tierces n'est pas garantie.

# Joueur

**JOUEUR** est une entrée spéciale du catalogue de créatures.

Ce n'est pas une forme normale dans laquelle le joueur peut se transformer.

**Clic G** crée un personnage séparé pour lequel MCM essaie de copier :

- l'apparence du joueur ;
- les points de vie maximaux.

**Clic D** sur l'entrée **JOUEUR** ne transforme pas le joueur normal en cette entité.

Si le joueur est déjà sous forme humaine, l'action ne fait rien. S'il est actuellement transformé en une autre créature, l'action de retour à la forme humaine est utilisée.

# Météo et heure

MCM permet de modifier :

- l'heure de la journée ;
- des préréglages météo ;
- certains paramètres météo pris en charge séparément.

Vous pouvez imposer l'état souhaité puis libérer le paramètre concerné du contrôle de MCM.

Par exemple, après avoir imposé une heure, vous pouvez rendre à Noita le déroulement naturel du temps.

# Règles du monde

La section **RÈGLES** permet de modifier plus profondément le comportement du monde du jeu.

Selon la règle concernée, il est possible de contrôler des paramètres tels que :

- les relations entre créatures ;
- l'or ;
- l'utilisation des sorts ;
- le brouillard de guerre ;
- les récompenses liées à certains types de morts ;
- les apparitions d'objets de soin ;
- le sang ;
- la gravité ;
- le comportement physique ;
- la force du coup de pied ;
- les articulations physiques ;
- le cycle jour-nuit ;
- d'autres paramètres globaux pris en charge.

La caractéristique essentielle est que les règles de MCM sont conçues comme des **modifications réversibles**.

Pour les réglages pris en charge, le mod conserve l'état d'origine et permet de ramener les paramètres à leur valeur normale.

Lorsqu'un multiplicateur est utilisé, la nouvelle valeur est calculée par rapport à l'état de référence au lieu de se multiplier indéfiniment à partir d'un résultat déjà modifié.

Les opérations qui doivent modifier un grand nombre d'entités ou d'objets physiques sont traitées progressivement afin d'éviter de tenter de modifier le monde entier au moment même du clic.

# Téléportation

MCM permet de se déplacer rapidement vers des destinations prédéfinies du jeu, notamment des points :

- de l'itinéraire principal ;
- des Montagnes sacrées ;
- de grandes zones latérales ;
- d'autres lieux pris en charge.

Avant la téléportation, le mod peut charger la zone de destination et essaie de trouver un espace libre à proximité afin de ne pas placer le joueur directement dans un mur solide ou un autre obstacle.

# Entangled Worlds

**Entangled Worlds / Noita Proxy est facultatif.**

MCM fonctionne entièrement en solo sans lui.

Lorsque Entangled Worlds est installé, des fonctions multijoueur expérimentales supplémentaires sont activées.

Pour une meilleure compatibilité, il est recommandé que tous les participants utilisent la même version de MCM.

## Objets, baguettes et sorts

Lorsque c'est possible, les objets présents dans le monde et les sorts jetés utilisent les mécanismes normaux d'Entangled Worlds.

Les modifications de l'inventaire peuvent également être transmises au moyen d'Entangled Worlds.

## Atouts

Un atout créé par MCM reste une véritable entité du jeu et, lorsque c'est possible, est transmis au moyen du système normal d'objets du monde d'Entangled Worlds.

## Matériaux

La peinture avec des matériaux dispose d'une prise en charge multijoueur expérimentale.

MCM synchronise les zones du monde concernées afin que le résultat puisse apparaître chez les autres participants.

Pour que cela fonctionne correctement, le matériau correspondant doit également exister chez l'autre joueur. Si les ensembles de mods diffèrent, un rendu identique de tous les matériaux ne peut pas être garanti.

## Météo et règles du monde

Les modifications prises en charge de la météo et des règles globales peuvent être synchronisées au moyen d'Entangled Worlds.

## Transformations et contrôle des créatures

Les transformations bénéficient d'une prise en charge supplémentaire avec Entangled Worlds.

Lors de la prise de contrôle d'une créature déjà existante, le mod tient également compte de son état réseau. Si MCM ne peut pas déterminer avec suffisamment de certitude que l'entité d'origine peut être supprimée, il préfère la laisser en place.

## Joueur

La création de l'entité spéciale **JOUEUR** est également prise en charge avec Entangled Worlds. Dans ce cas, elle reprend les couleurs de l'apparence de la personne qui l'a créée.

## Téléportation entre joueurs

Lorsque Entangled Worlds est actif, la section de téléportation affiche les joueurs disponibles.

**REJOINDRE** vous téléporte près du joueur sélectionné.

**AMENER ICI** envoie au joueur sélectionné une demande de téléportation vers vous.

Dans les deux cas, MCM essaie d'utiliser un espace libre à proximité de la destination.

## Limites

La prise en charge d'Entangled Worlds reste expérimentale.

**En multijoueur, se transformer en un boss de grande taille ou composé de nombreuses articulations peut provoquer une chute critique des performances et rendre la session de jeu en cours pratiquement inutilisable.**

Noita est extrêmement difficile à synchroniser entièrement, surtout lorsque plusieurs éléments changent en même temps :

- le monde de pixels ;
- les matériaux ;
- les objets physiques ;
- les créatures et boss complexes ;
- le contenu d'autres mods.

MCM ne promet donc pas une synchronisation parfaite de tous les états imaginables.

# NoitaPatcher et mods non sécurisés

La version complète de MCM inclut **NoitaPatcher**.

Il est utilisé pour des fonctions que les outils habituels de modification de Noita ne permettent pas de réaliser de façon suffisante, notamment pour certains mécanismes de :

- restauration après des transformations complexes ;
- manipulation des entités du jeu ;
- interaction avec le monde du jeu ;
- placement de certains matériaux ;
- compatibilité étendue.

La version complète nécessite donc d'autoriser les **mods non sécurisés**.

NoitaPatcher est déjà inclus dans la compilation prête à l'emploi de MCM. Il n'est pas nécessaire de l'installer séparément.

# Si quelque chose ne fonctionne pas

## MCM ne se charge pas

Vérifiez qu'après extraction, le fichier suivant existe :

```text
Noita/mods/metamorph_creative_menu/mod.xml
```

Vérifiez que :

- MCM est activé dans le menu **Mods** ;
- **[x]** apparaît à côté ;
- les **mods non sécurisés sont autorisés** ;
- le jeu a été lancé avec les mods actifs.

## Les fonctions utilisant NoitaPatcher ne marchent pas

Vérifiez la présence de :

```text
metamorph_creative_menu/NoitaPatcher/noitapatcher.dll
```

et assurez-vous que les **mods non sécurisés** sont autorisés.

## Impossible de revenir depuis une forme

Essayez l'action de retour attribuée, **TAB par défaut**.

Si le problème se reproduit, il est utile d'indiquer dans le signalement :

- le nom exact de la créature ;
- le chemin XML, s'il est connu ;
- la manière dont la forme a été obtenue ;
- si le retour normal fonctionne ;
- si le problème apparaît uniquement après des dégâts mortels ;
- si Entangled Worlds est utilisé.

## Problèmes avec Entangled Worlds

Vérifiez :

- que tous les participants utilisent la même version de MCM ;
- que les versions d'Entangled Worlds sont compatibles ;
- que le même ensemble de mods est utilisé si le problème concerne des matériaux ou des créatures provenant d'autres mods.

# Signaler un problème

[Créer une Issue](https://github.com/zerodancing/Metamorph-Creative-Menu/issues)

Pour qu'un signalement soit utile, indiquez de préférence :

- la version de MCM ;
- ce que vous faisiez exactement ;
- le résultat attendu ;
- le résultat obtenu ;
- le nom de la créature, de l'objet, de l'atout ou du matériau concerné ;
- si Entangled Worlds est utilisé ;
- les autres mods susceptibles d'être liés au problème ;
- le texte de l'erreur ou l'extrait correspondant du journal ;
- une capture d'écran ou une vidéo si elle aide à montrer le problème.

# Composants tiers

- **Noita** — Nolla Games.
- **NoitaPatcher** — dextercd, inclus dans la version complète.
- **lbase64** — Ilya Kolbin, inclus dans MCM.
- **Entangled Worlds / Noita Proxy** — IntQuant et les personnes ayant contribué au projet ; s'installe séparément et reste facultatif.

Les informations détaillées sur les projets d'origine et leurs licences se trouvent dans [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

---

**Metamorph: Creative Menu** est un mod non officiel créé par des utilisateurs pour Noita. Le projet n'est pas affilié à Nolla Games et ne fait pas officiellement partie du jeu.

[↑ Retour au choix de la langue](#languages)