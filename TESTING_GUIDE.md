# Guide de test des améliorations

## Pré-requis

Assurez-vous que le projet compile sans erreur dans Xcode.

## Test 1 : Boutons d'action du header

### Objectif
Tester les nouveaux styles de boutons dans `CinematicHeaderView`.

### Procédure
1. Lancez l'app dans le simulateur Apple TV
2. Naviguez vers une page de détail de film ou série
3. Testez les boutons en bas du header cinématique :
   - **Bouton "Request"** : Devrait avoir un fond indigo
   - **Bouton "My List"** : Devrait avoir un fond translucide blanc
   - **Bouton "Trailer"** : Devrait avoir un fond translucide blanc

### Comportement attendu
- ✅ Au focus, les boutons doivent s'agrandir légèrement (scale 1.08)
- ✅ Au focus, l'ombre doit devenir plus prononcée
- ✅ Pour le bouton Request, l'ombre doit être bleue/indigo au focus
- ✅ La transition doit être fluide (0.15s easeInOut)
- ✅ Le texte et l'icône doivent rester blancs

### Problèmes potentiels
- Si les boutons ne réagissent pas au focus : vérifier `.buttonStyle(.borderless)`
- Si l'animation est saccadée : vérifier que `@FocusState` est bien utilisé dans `ActionButtonStyle`

---

## Test 2 : Sélecteur de saisons

### Objectif
Tester le nouveau composant `SeasonsSelector`.

### Procédure
1. Naviguez vers une page de détail de série TV (ex: Breaking Bad, The Office)
2. Scrollez jusqu'à la section "Episodes"
3. Observez la rangée horizontale de boutons de saisons

### Comportement attendu
- ✅ Les saisons doivent être affichées horizontalement
- ✅ La première saison doit être sélectionnée par défaut (fond blanc, texte noir)
- ✅ Les autres saisons doivent avoir un fond translucide blanc (texte blanc)
- ✅ En changeant de saison, la sélection doit être animée
- ✅ Le scroll doit centrer automatiquement la saison sélectionnée
- ✅ La saison sélectionnée doit avoir un scale légèrement plus grand (1.05)

---

## Test 3 : Grille d'épisodes

### Objectif
Tester l'affichage des épisodes dans `EpisodeSelector`.

### Procédure
1. Sur une page de série, sélectionnez une saison
2. Attendez le chargement des épisodes
3. Observez la grille horizontale d'épisodes

### Comportement attendu

#### État loading
- ✅ Un spinner doit s'afficher avec le texte "Loading episodes..."
- ✅ L'animation doit être centrée

#### État content (épisodes chargés)
- ✅ Les épisodes doivent s'afficher en grille horizontale scrollable
- ✅ Chaque carte d'épisode doit montrer :
  - Image thumbnail 16:9
  - Numéro de saison/épisode (ex: "S1 E5")
  - Titre de l'épisode
  - Description (3 lignes max)
- ✅ Au focus, la carte doit :
  - S'agrandir légèrement (scale 1.05)
  - Afficher une icône "play" au centre
  - Avoir une animation fluide (0.15s easeInOut)

#### État empty (pas d'épisodes)
- ✅ Une icône "tv.slash" doit s'afficher
- ✅ Le message "No episodes available" doit être visible

---

## Checklist finale

Avant de considérer les changements comme terminés :

- [ ] Tous les tests ci-dessus passent
- [ ] Aucune erreur de compilation
- [ ] Aucun warning SwiftUI dans la console
- [ ] Les animations sont fluides
- [ ] Le focus fonctionne correctement partout
- [ ] Les images se chargent correctement
- [ ] Pas de crash ou de freeze
- [ ] Le style est cohérent avec le reste de l'app
- [ ] Les couleurs Seerr sont respectées
