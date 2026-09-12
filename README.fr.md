<a id="languages"></a>

[English](README.md) · [Русский](README.ru.md) · [Português (Brasil)](README.pt-BR.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [**Français**](README.fr.md) · [Italiano](README.it.md) · [Polski](README.pl.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

<h1 align="center">Metamorph: Creative Menu</h1>

<p align="center">Un menu créatif et une boîte à outils sandbox pour Noita : sorts, baguettes, objets, matériaux, perks, effets, créatures, transformations, possession, téléportation, météo, règles du monde, intégration multijoueur et outils de récupération.</p>

<p align="center"><strong>Créateur et mainteneur : <a href="https://github.com/zerodancing">zerodancing</a></strong></p>

---

# Télécharger

Pour jouer normalement, utilisez la build prête à installer :

[**⬇️ Télécharger la build la plus récente**](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip)

[Page de la dernière build](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build) · [Changelog](metamorph_creative_menu/CHANGELOG.txt)

La release GitHub est générée automatiquement à partir de l'arbre de développement complet. Les tests, outils QA, diagnostics, sources natives et outils de build restent dans le dépôt, mais sont exclus de l'archive destinée aux joueurs.

La build standalone GitHub inclut NoitaPatcher et la récupération native, donc **Unsafe Mods doit être autorisé**.

# Installation

1. Téléchargez `Metamorph-Creative-Menu.zip` avec le lien ci-dessus.
2. Lancez Noita et ouvrez **Mods** depuis le menu principal.
3. Cliquez sur **Open mods folder**.
4. Extrayez ou déplacez le dossier `metamorph_creative_menu` dans le dossier `mods`. Le chemin final doit contenir directement `metamorph_creative_menu/mod.xml`, sans dossier supplémentaire créé par l'archive.
5. Si une ancienne copie est déjà installée, remplacez entièrement le dossier `metamorph_creative_menu` au lieu de fusionner anciens et nouveaux fichiers.
6. Revenez dans Noita et actualisez la liste des mods.
7. Autorisez **Unsafe Mods**.
8. Activez **Metamorph: Creative Menu** puis démarrez une partie avec les mods actifs.

N'activez pas en même temps la build standalone GitHub et la version Steam Workshop.

# Build standalone et Steam Workshop

La build distribuée par ce dépôt GitHub est la build standalone complète. Elle contient NoitaPatcher et les fonctions qui exigent un accès non restreint à l'API de mods, notamment les opérations bas niveau sur les matériaux et la récupération native après Game Over.

La [build Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3785170245) s'installe séparément. Elle n'inclut pas les composants natifs nécessaires aux fonctions réservées à la build standalone.

Les deux builds utilisent la même identité de mod. Les installer en même temps peut produire des fichiers dupliqués ou en conflit et n'est pas pris en charge.

# À propos du mod

**Metamorph: Creative Menu (MCM)** est un menu créatif et une boîte à outils sandbox pour Noita.

Il réunit des outils pour :

- les sorts et l'inventaire de sorts ;
- l'édition des baguettes et les presets réutilisables ;
- les objets et conteneurs de liquides ;
- le catalogue complet des matériaux et la peinture de matériaux ;
- les perks et la suppression prise en charge des perks ;
- les statuts et entités GameEffect ;
- les créatures, transformations et la possession ;
- la météo et le temps ;
- les règles globales du monde ;
- la téléportation ;
- l'intégration optionnelle avec Entangled Worlds ;
- les chemins de récupération après transformation, mort de forme et Game Over.

MCM essaie d'agir sur l'état réel de Noita au lieu de tout remplacer par des copies décoratives. Les cartes de sort existantes sont déplacées comme entités, la remise d'objets respecte la structure de l'inventaire, les modifications de baguette utilisent des chemins commit/rollback, les matériaux restent de vrais matériaux simulés et les règles réversibles conservent assez d'état d'origine pour restaurer plus tard les paramètres pris en charge.

Entangled Worlds est optionnel. Sans lui, MCM reste un mod solo complet.

# Contrôles

Contrôles par défaut :

| Action | Entrée par défaut |
| --- | --- |
| Ouvrir / fermer le menu créatif | **F4** |
| Revenir à la forme humaine pendant une transformation | **TAB** |
| Posséder une créature dans le monde | **G** |
| Peindre avec le matériau sélectionné | **Bouton central de la souris** |

Le panneau créatif est aussi disponible via l'interface d'inventaire normale de Noita.

Les touches peuvent être modifiées dans la section **CONTROLS** de MCM et dans les paramètres de mod de Noita. Les touches clavier, boutons de souris et combinaisons exactes avec **CTRL / SHIFT / ALT** sont pris en charge.

Pendant la capture d'une touche :

- **DELETE / BACKSPACE** efface l'assignation ;
- **ESC** annule ;
- **R** restaure la touche par défaut de cette action ;
- **RESET ALL** restaure toutes les touches par défaut après confirmation.

Les assignations identiques restent modifiables, mais MCM signale le conflit au lieu de remplacer silencieusement une autre action.

La navigation du menu, les sections, le retour depuis une forme, la possession, la peinture de matériaux, le nettoyage des effets, la libération de la météo, la réinitialisation des règles du monde et les actions multijoueur prises en charge peuvent être réassignés.

# Fenêtre Creative Menu

Le panneau créatif direct est une fenêtre redimensionnable et persistante, pas un overlay de debug fixe.

Elle peut être :

- déplacée par sa barre de titre ;
- redimensionnée depuis les bords et les coins ;
- minimisée ;
- fermée ;
- restaurée à sa disposition par défaut.

Sa position, sa largeur, sa hauteur et la dernière section ouverte sont conservées entre les sessions. Après un changement de résolution, la géométrie enregistrée est ramenée dans la zone visible de l'interface.

Les listes et catalogues utilisent des mises en page mesurées et les conteneurs de défilement de Noita. Redimensionner la fenêtre change immédiatement la quantité de contenu visible, et les libellés traduits peuvent passer sur plusieurs lignes sans recouvrir les contrôles voisins. Dans les dispositions étroites, les contrôles passent sur des lignes supplémentaires plutôt que de se superposer.

Ouvrir ou simplement survoler la fenêtre détachée ne désactive pas durablement le gameplay. Lorsqu'un clic, un drag ou un champ texte actif pourrait aussi déclencher une action du joueur, MCM désactive temporairement les contrôles concernés puis les restaure.

# Recherche et localisation

La recherche est disponible dans les principaux catalogues, notamment les sorts, objets, matériaux, perks et créatures.

Selon l'entrée, elle peut correspondre à :

- son nom dans la langue actuelle de l'interface ;
- son nom anglais ;
- une clé de localisation ;
- un identifiant technique ;
- un chemin XML.

La recherche ignore la casse, normalise les accents et séparateurs courants et tolère de petites fautes de frappe dans les requêtes longues.

L'interface propre à MCM est localisée en :

- anglais ;
- russe ;
- portugais brésilien ;
- espagnol ;
- allemand ;
- français ;
- italien ;
- polonais ;
- chinois simplifié ;
- japonais ;
- coréen.

Pour le contenu normal de Noita, le mod réutilise autant que possible les clés de localisation du jeu au lieu de maintenir des noms dupliqués.

# Sorts

La section des sorts travaille à la fois avec le catalogue et avec les entités de sort déjà détenues par le joueur.

L'espace principal contient :

- les slots normaux de la baguette active ;
- les cartes **ALWAYS CAST** ;
- l'inventaire de sorts du joueur ;
- le catalogue de sorts avec recherche.

## Remplacement rapide du slot sélectionné

Un clic court sélectionne un slot de baguette. Ensuite, un clic LMB court sur un sort du catalogue remplace ce slot.

C'est le chemin rapide pour l'édition ordinaire. Le déplacement précis utilise le drag-and-drop.

## Drag-and-drop transactionnel

Les cartes existantes peuvent être déplacées :

- entre les slots de la baguette ;
- des slots normaux vers **ALWAYS CAST** ;
- de **ALWAYS CAST** vers les slots normaux ;
- vers un slot précis de l'inventaire de sorts ;
- de l'inventaire vers la baguette ;
- vers le monde ;
- vers la corbeille lorsque c'est pris en charge.

Pour une carte existante, MCM déplace l'entité réelle autant que possible. L'état mutable, les utilisations restantes et les données ajoutées par d'autres mods ne sont donc pas perdus simplement parce que la carte change d'emplacement.

La source reste intacte jusqu'à validation de la transaction de destination. Une cible invalide ou inconnue annule l'opération au lieu de supprimer la carte originale. Un relâchement de souris effectue au maximum une opération validée.

Les cartes du catalogue sont des modèles et ne sont jamais consommées par le drag.

## Always Cast

Les cartes Always Cast ont leur propre bande. Promotion, rétrogradation et échange tiennent compte de la capacité effective des slots normaux afin d'éviter une structure de baguette invalide.

## Annuler et rétablir

Les mutations internes de la baguette disposent d'un historique limité **UNDO / REDO**.

Les opérations qui remettent une vraie entité au monde extérieur ou à un autre inventaire ne peuvent pas toujours être inversées de manière sûre depuis un snapshot de baguette. Ces transferts externes ne sont donc pas promis comme universellement annulables.

# Baguettes

L'espace baguette édite la baguette actuellement tenue par le joueur.

Les statistiques prises en charge incluent :

- capacité / slots ;
- sorts par tir ;
- temps de recharge ;
- délai entre les tirs ;
- dispersion ;
- multiplicateur de vitesse des projectiles ;
- mana maximal ;
- recharge de mana ;
- récupération du recul ;
- niveau de la baguette ;
- shuffle ;
- comportement sans recharge.

MCM édite aussi la présentation et les métadonnées associées :

- nom affiché ;
- verrous de la baguette et des cartes ;
- chemin du sprite ;
- offsets du sprite ;
- position de tir.

Un catalogue visuel d'apparences suit les données XML des baguettes lorsqu'elles sont disponibles.

## Presets de baguette

Les baguettes peuvent être enregistrées sous forme de presets persistants nommés et réutilisées dans d'autres mondes ou sessions de Noita.

Un preset peut conserver :

- les statistiques de la baguette ;
- les valeurs de mana ;
- les métadonnées visuelles ;
- les cartes normales ;
- les cartes Always Cast ;
- les positions de slots ;
- les utilisations restantes ;
- l'état gelé des cartes.

Chaque preset propose deux opérations séparées :

- **APPLY** écrit le blueprint enregistré sur la baguette actuellement tenue ;
- **GET COPY** construit une nouvelle baguette à partir du même blueprint.

Une copie est placée dans un slot libre de baguette de l'inventaire rapide lorsque c'est possible. Sans slot adapté, la baguette terminée est laissée dans le monde près du joueur.

Le remplacement de baguette et le chargement de preset utilisent des chemins commit/rollback. Si la construction ou le placement ne peut pas être terminé, MCM tente de supprimer l'arbre d'entité incomplet au lieu de laisser une baguette partielle cassée.

# Objets et liquides

## Objets

Un clic court **LMB** sur une entrée de catalogue crée un objet pris en charge près du joueur.

**RMB** tente de remettre l'objet à la zone appropriée de l'inventaire.

Les entrées du catalogue peuvent aussi être glissées :

- vers une cible compatible de l'inventaire rapide ;
- hors du menu vers une position exacte du monde.

Relâcher une carte dans le menu sans cible valide annule l'opération. La carte du catalogue n'est qu'un modèle et reste disponible.

MCM respecte la séparation normale de l'inventaire rapide de Noita entre slots de baguettes et d'objets. Un échec de chargement XML, de remplissage de liquide, de transfert vers l'inventaire ou de transfert multijoueur optionnel supprime la nouvelle entité lorsque c'est possible.

Certains vrais objets d'inventaire vivent dans des répertoires du jeu orientés créatures. MCM classe les cas connus par comportement plutôt que de supposer que le nom du dossier suffit à déterminer s'il s'agit d'un objet ou d'une créature.

## Liquides

Les entrées de liquide créent de vrais conteneurs Noita remplis, pas des objets décoratifs d'interface.

Le conteneur peut être transporté, jeté, cassé et renversé, et son contenu participe aux réactions normales de matériaux.

# Matériaux

La section Materials est un outil de peinture du monde basé sur le registre réel des matériaux de Noita.

Le catalogue est construit à partir des liquides, sables / poudres, gaz, feux, solides et matériaux statiques ou d'effets enregistrés par le moteur. Les matériaux correctement ajoutés par d'autres mods actifs peuvent donc apparaître automatiquement.

La découverte et la validation coûteuse des matériaux sont réparties en travail borné au lieu de scanner tout le catalogue en une seule frame UI.

## Présentation des matériaux

Les liquides utilisent la même présentation de conteneur rempli que la section Objets.

Pour les matériaux non liquides, MCM privilégie les textures et teintes définies dans `materials.xml`, y compris les définitions héritées. Si aucune texture n'est définie, le fallback vient de la couleur réelle du matériau dans le moteur plutôt que d'une couleur de preview arbitraire.

## Peinture

1. Sélectionnez un matériau.
2. Sélectionnez la taille du pinceau.
3. Activez le mode peinture.
4. Fermez l'inventaire.
5. Maintenez l'entrée de dessin configurée dans le monde.

Ouvrir l'inventaire arrête le mode peinture actif.

La peinture ne crée pas seulement des particules décoratives. MCM place de vraies cellules dans le monde via un chemin adapté au moteur. Les matériaux dynamiques continuent à suivre la simulation Noita : les liquides coulent, les poudres tombent, les gaz se déplacent, le feu réagit et les substances instables peuvent se transformer via les réactions de matériaux.

Les différentes classes de matériaux nécessitent des stratégies de placement différentes. La build standalone peut utiliser l'accès direct à la grille du monde de NoitaPatcher et un petit fallback PixelScene pour les cas définis que Noita refuse de construire directement à une coordonnée de texture donnée.

Les files de travail sont bornées afin qu'un gros pinceau maintenu n'exécute pas volontairement une quantité illimitée de travail en une seule frame.

# Perks

## Créer et recevoir des perks

**LMB** crée un pickup normal du perk sélectionné dans le monde.

L'action de réception peut accorder le perk individuellement ou en lot. Les opérations en lot sont traitées comme des jobs bornés au lieu d'appliquer toutes les copies dans une seule frame UI.

L'interface affiche la progression, et le travail encore en attente peut être annulé. Les copies déjà validées avant l'annulation restent appliquées.

Chaque copie accordée passe toujours par le chemin normal d'application du perk au lieu de simuler directement l'état final.

## Supprimer des perks

Supprimer un perk est bien plus complexe que l'accorder. Les perks peuvent modifier des globals, composants, entités, statistiques du joueur et mécaniques persistantes, et Noita ne fournit pas d'opération inverse universelle.

MCM ne supprime donc que l'état pour lequel il dispose d'une inversion suivie suffisamment sûre. Le journal de transaction tente d'enlever uniquement l'état appartenant à cette application du perk sans réinitialiser l'état indépendant du joueur.

Si un nettoyage est partiel ou ne peut pas être prouvé complet, il reste traité comme incomplet au lieu d'être silencieusement annoncé comme réussi.

Un perk tiers peut être accordable sans être supprimable correctement.

# Effets

La section Effects applique et retire les statuts de matériaux et entités GameEffect pris en charge.

La suppression tient compte de la propriété lorsque c'est possible. MCM évite d'effacer aveuglément des effets cachés similaires appartenant à des perks, au jeu ou à un autre système.

Les effets persistants créés par MCM utilisent un nettoyage / une expiration bornés afin que retirer un effet MCM ne réinitialise pas l'état d'autres systèmes.

# Créatures

Le catalogue de créatures conserve les chemins XML exacts au lieu de fusionner toutes les entités aux noms similaires.

Interactions prises en charge :

- **LMB** — crée l'entité définie sélectionnée près du joueur ;
- drag hors du menu — crée l'entité à la position confirmée du curseur monde ;
- **RMB** — transforme le joueur actuel en une forme prise en charge ;
- entrée spéciale **PLAYER** — crée ou restaure un état de joueur comme décrit ci-dessous.

Relâcher une carte glissée au-dessus du menu annule le spawn dans le monde.

Les règles de compatibilité pour les formes dangereuses ou inhabituelles utilisent des chemins exacts. Un nom de fichier contenant simplement un mot familier ne rend pas automatiquement l'entité équivalente à une autre forme.

# Transformations et retour à la forme humaine

Les formes jouables conservent les mouvements natifs utiles, attaques, présentation et physique lorsque c'est pratique. Les composants qui entrent directement en conflit avec l'entrée du joueur peuvent être désactivés ou adaptés tant que la forme est contrôlée par le joueur.

Certaines créatures complexes exigent une logique supplémentaire. Les boss, wrappers scriptés et entités très dépendantes de la physique ne sont pas garantis de se comporter exactement comme leur version contrôlée par l'IA lorsqu'ils servent de forme au joueur.

L'action de retour configurée — **TAB** par défaut — utilise d'abord le chemin normal de fin de transformation. Si cela ne suffit pas, la build standalone possède des chemins supplémentaires de restauration via NoitaPatcher.

Dans les cas de dégâts mortels pris en charge, MCM tente de :

- laisser la forme temporaire morte ou son cadavre dans le monde lorsque c'est approprié ;
- restaurer une entité humaine du joueur ;
- rendre l'authority et les contrôles ;
- préserver l'inventaire ;
- restaurer l'état pertinent du joueur.

Il s'agit d'une logique de récupération, pas d'une immortalité absolue. Un kill script tiers, un état moteur incompatible ou un crash du processus peut contourner le handoff pris en charge.

# Possession

La possession contrôle une créature déjà présente dans le monde au lieu de choisir une forme dans le catalogue.

La touche par défaut est **G**.

Visez une créature adaptée puis utilisez l'action de possession. MCM valide la cible, prépare une transition compatible et ne supprime ou retire l'entité d'origine qu'après confirmation du nouvel état contrôlé par le joueur.

Si la transition échoue, la créature d'origine ne doit pas simplement disparaître.

La possession n'est pas limitée au catalogue interne de MCM. Une créature compatible créée par un autre mod peut fonctionner, mais la compatibilité universelle avec toutes les entités tierces n'est pas garantie.

# Entrée Player

**PLAYER** est une entrée spéciale du catalogue de créatures et non une cible de polymorph ordinaire.

Son action de spawn crée un personnage séparé de type joueur et essaie de copier une présentation appropriée ainsi que les informations de santé maximale.

Utiliser l'action de transformation sur **PLAYER** ne transforme pas un joueur déjà humain en doublon. Si le joueur se trouve dans une autre forme, cette action sert à revenir à la forme humaine.

# Récupération Game Over en solo

La build standalone solo inclut un chemin supplémentaire de récupération pour l'écran Game Over standard de Noita.

Lorsque l'intégration native peut identifier en toute sécurité les structures nécessaires du jeu, MCM ajoute une action **« I didn't die »** à l'interface Game Over.

MCM conserve une sauvegarde glissante de l'état du joueur pendant la partie. Activer la récupération demande la restauration via le chemin de mise à jour normal de MCM au lieu de reconstruire tout le joueur directement dans le handler du clic UI.

Une récupération prise en charge tente de :

- restaurer ou obtenir une entité de joueur vivante ;
- la rendre authoritative à nouveau ;
- effacer l'état Game Over du moteur ;
- rendre les contrôles et un état jouable ;
- nettoyer au mieux l'audio, la musique et l'interface Game Over ;
- offrir une courte fenêtre de protection après restauration.

Le helper natif est conçu en fail-closed. Il analyse l'exécutable Noita pris en charge en cours d'exécution pour y trouver des structures connues au lieu d'écrire à une adresse unique codée en dur. Si les structures attendues ne peuvent plus être identifiées en sécurité après une mise à jour, la récupération optionnelle n'est pas utilisée plutôt que d'écrire dans une zone incertaine.

# Météo et temps

MCM peut contrôler l'état météo et temporel pris en charge, y compris des presets et paramètres individuels exposés par l'implémentation actuelle.

Un état forcé peut ensuite être relâché vers le contrôle normal du jeu. Par exemple, après avoir forcé une heure précise, MCM peut abandonner ce paramètre afin que le cycle naturel de Noita reprenne.

Les changements météo sont traités comme un état contrôlé et non comme des commandes console à sens unique.

# Règles du monde

La section **RULES** modifie le comportement global pris en charge du jeu.

Les règles couvrent notamment :

- les relations entre créatures ;
- le comportement de l'or ;
- l'utilisation des sorts ;
- le fog of war ;
- certaines récompenses de kill ;
- les drops de soin ;
- le comportement lié au sang ;
- la gravité ;
- la physique ;
- la force du coup de pied ;
- les joints physiques ;
- le cycle jour/nuit ;
- d'autres paramètres globaux pris en charge.

Le principal objectif est la réversibilité.

Pour les règles prises en charge, MCM enregistre ou dérive l'état d'origine afin de pouvoir restaurer le paramètre plus tard. Les multiplicateurs sont appliqués par rapport à la valeur d'origine au lieu de multiplier à répétition une valeur déjà modifiée.

Les règles qui doivent toucher beaucoup d'entités ou d'objets physiques utilisent un travail borné réparti sur les frames au lieu de tenter de réécrire le monde entier synchroniquement en un clic.

# Téléportation

La section de téléportation propose des destinations préparées dans le monde, notamment des points de la route principale, les Holy Mountains, de grandes zones latérales et d'autres lieux pris en charge.

Avant de déplacer le joueur, MCM peut demander le chargement de la zone cible et cherche un espace libre utilisable à proximité au lieu de placer volontairement le joueur dans un terrain solide.

La téléportation dépend toujours de la capacité du monde à charger et fournir une destination valide. Les mondes fortement modifiés peuvent nécessiter un comportement de fallback.

# Entangled Worlds

**Entangled Worlds / Noita Proxy est optionnel.** MCM fonctionne sans lui.

Lorsque EW est présent, MCM active des comportements supplémentaires adaptés au multijoueur. Tous les peers devraient utiliser des builds MCM compatibles lorsqu'ils dépendent d'un état synchronisé propre à MCM.

## Authority et formes

Les formes de joueur nécessitent un traitement particulier de l'ownership, car un joueur transformé ne doit pas laisser accidentellement une deuxième authority réseau.

MCM coordonne l'ownership, le retirement et le retour à la forme humaine avec EW lorsque c'est pris en charge. Les entités de boss et de type Kolmi disposent d'un traitement lifecycle supplémentaire destiné à éviter les authorities dupliquées et les anciennes copies contrôlées par le réseau.

Le chemin de mort normal d'EW reste responsable des entités qui ne sont pas reconnues comme état de forme appartenant à MCM.

## Objets, baguettes et sorts

Lorsque c'est possible, MCM utilise les mécanismes normaux d'objets / inventaire d'EW au lieu d'inventer un système de transport parallèle.

Les mutations validées de baguette et d'inventaire de sorts demandent le refresh multijoueur approprié lorsque l'intégration est disponible. Les objets de monde créés par MCM peuvent être remis au chemin world-item standard d'EW.

## Perks

Les pickups normaux de perks peuvent utiliser la synchronisation world-item standard d'EW. La gestion de l'état des perks par MCM coordonne refresh et opérations bornées afin que les actions en lot n'émettent pas un refresh global coûteux pour chaque copie.

## Matériaux

La peinture de matériaux possède un chemin de compatibilité dédié, car les modifications de cellules du monde ne sont pas des entités d'objets normales.

MCM garde le travail de peinture borné, sépare le travail aux frontières de chunks et coordonne les étapes world-frame / persistance nécessaires d'EW avant de libérer le travail de conversion synchronisé. Un chunk de bord encore non chargé est reporté plutôt que de bloquer tout le trait actif.

L'objectif est que les peers EW proches puissent voir l'état peint pris en charge sans devoir rejouer à distance l'action UI normale de MCM sous forme d'un appel PixelScene basé uniquement sur un filename.

Cela hérite toujours des hypothèses d'identifiants de matériaux d'EW : un jeu récepteur ne peut pas créer correctement un matériau absent de son registre ou dont le registre moteur est incompatible.

## Météo, possession et état du monde

L'état multijoueur pris en charge par MCM inclut aussi la coordination de la météo, de la possession et de certains comportements de règles / lifecycle. Des contrôles d'authority évitent que deux peers essaient de posséder le même état simultanément.

Le support EW est volontairement conservateur. Lorsque l'intégration ne peut pas prouver un chemin de synchronisation sûr, MCM préfère le comportement local pris en charge plutôt que de prétendre que toute opération solo est automatiquement sûre en multijoueur.

# Compatibilité et limites

Noita expose de nombreux systèmes via des entités faiblement couplées, XML, composants Lua et comportement natif du moteur. MCM ne peut donc pas garantir une compatibilité universelle avec toutes les entités modifiées ni toutes les futures mises à jour du jeu.

Limites importantes :

- une créature peut être spawnable sans être une forme de joueur sûre ;
- un perk peut être accordable sans disposer d'une inversion fiable ;
- les transferts externes de sorts ou objets ne peuvent pas toujours être annulés depuis un snapshot interne ;
- des scripts tiers peuvent contourner les chemins de mort et récupération pris en charge ;
- les fonctions natives de récupération dépendent d'un comportement pris en charge de l'exécutable Noita et se désactivent en fail-closed si les structures nécessaires ne peuvent pas être identifiées ;
- Entangled Worlds ne peut pas synchroniser un matériau absent du registre du jeu récepteur ;
- des inventaires, entités ou règles fortement modifiés peuvent nécessiter un travail de compatibilité propre au mod concerné.

MCM essaie de préserver l'état d'origine et de rollback les mutations échouées, mais un outil sandbox qui modifie l'état vivant du jeu ne peut pas rendre toute combinaison de mods tiers entièrement transactionnelle.

# Données sauvegardées

MCM conserve l'état utilisateur qui doit survivre entre les sessions, notamment les paramètres pris en charge, les touches, la disposition du menu et les presets de baguette.

L'identité du mod reste stable afin que les mises à jour normales conservent les données prises en charge. Il est néanmoins recommandé de remplacer entièrement le dossier du mod lors de l'installation d'une nouvelle build standalone, car fusionner anciens et nouveaux fichiers peut laisser des fichiers runtime obsolètes.

# Dépannage

## Le mod n'apparaît pas

Vérifiez que la structure se termine par :

`mods/metamorph_creative_menu/mod.xml`

Un dossier d'archive supplémentaire au-dessus de `metamorph_creative_menu` empêche Noita de détecter correctement le mod.

## Les fonctions natives ou de matériaux ne marchent pas

Vérifiez que **Unsafe Mods** est autorisé et que vous avez installé la build standalone GitHub sans mélanger de fichiers de la Workshop.

## Le menu s'ouvre mais une action du jeu se déclenche aussi

Vérifiez les conflits de touches personnalisées. MCM affiche les doublons mais permet volontairement de les conserver si vous le souhaitez.

## Une créature ne peut pas être utilisée comme transformation sûre

Toute entité XML spawnable n'est pas nécessairement une forme de joueur prise en charge. Des règles par chemin exact existent pour les créatures nécessitant un traitement spécial.

## Un perk ne peut pas être retiré

La suppression n'est proposée que lorsque MCM dispose d'une opération inverse prise en charge pour l'état suivi. C'est volontaire : deviner un nettoyage peut endommager un état du joueur sans rapport.

## Le multijoueur se comporte différemment entre les peers

Utilisez des builds MCM compatibles sur tous les participants et un environnement Noita / Entangled Worlds compatible. MCM ne peut pas réparer un registre de matériaux incompatible ni des modifications réseau arbitraires d'autres mods.

# Signaler un bug

Un bon rapport doit inclure :

- ce que vous essayiez de faire ;
- la section et l'action exactes de MCM ;
- si le problème se produit en solo, avec Entangled Worlds ou dans les deux cas ;
- si la build standalone ou Workshop est installée ;
- si d'autres mods de gameplay sont actifs ;
- des étapes fiables de reproduction ;
- les logs Noita / EW pertinents lorsqu'ils sont disponibles.

Pour les problèmes de transformation, possession, objet ou matériau, indiquez l'entité ou le matériau exact si possible. Les identifiants techniques sont souvent plus utiles qu'un nom traduit affiché.

# Dépôt et source de développement

Le dépôt contient volontairement **l'arbre de développement complet**, et non la même archive réduite téléchargée par les joueurs.

`metamorph_creative_menu/` contient le code runtime avec :

- les tests automatisés ;
- les outils QA ;
- les diagnostics ;
- les sources natives ;
- les outils de build ;
- les règles de nettoyage de release ;
- la documentation de développement.

Ces fichiers sont utiles au développement et aux tests de régression, ils restent donc dans le source GitHub. Le ZIP prêt pour les joueurs est généré séparément et exclut le contenu réservé au développement.

Le paquet joueur reçoit aussi un nettoyage spécifique au release, notamment le `README.txt` minimal du paquet, tandis que l'arbre source conserve sa documentation de développement.

# Tests

La suite automatisée se trouve dans `metamorph_creative_menu/tests/` et combine des vérifications de contrat Python avec des mocks Lua.

Depuis la racine du dépôt, le workflow de release exécute la suite sur le source importé complet avant de publier la build joueur. `texlua` est requis pour la partie mocks Lua.

Les vérifications de source hygiene protègent également les fichiers orientés production et la documentation contre les restes d'historique de développement, anciennes surfaces de debug et artefacts accidentels de processus.

# Import du source et processus de release

Le source de développement complet peut être importé depuis une archive de la famille `Metamorph-Creative-Menu-v...zip`.

Le workflow d'import vérifie la structure, exige les composants complets de développement, exécute source hygiene et la suite de régression avant de commit l'arbre importé.

Une archive ModWorkshop / player-style n'est pas traitée comme source de développement.

La release publique `latest-build` est ensuite produite depuis le source complet par un player-builder séparé. Celui-ci retire QA, tests, diagnostics, source natif et autres payloads réservés au développement, applique les règles de nettoyage, valide l'archive résultante puis seulement met à jour l'asset de téléchargement stable.

Cette séparation permet au dépôt de rester complet pour le développement tout en gardant le téléchargement normal des joueurs compact et sans instrumentation de développement.

# Composants tiers

Les composants tiers, dépendances incluses et projets upstream sont documentés dans [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
