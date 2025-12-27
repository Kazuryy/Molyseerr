# Apple TV+ Design Reference

> Documentation de référence pour le design et la navigation dans Molyseerr
> Basé sur les Apple Human Interface Guidelines et l'app Apple TV+

**Date:** 24 Décembre 2025
**Version tvOS:** 26.2 (2025)
**Sources officielles:** [Apple Developer HIG](https://developer.apple.com/design/human-interface-guidelines/designing-for-tvos)

---

## 🎯 Principes Fondamentaux

### Navigation Basée sur le Focus

La navigation tvOS repose sur un **modèle de focus** où :
- **Un seul élément** est sélectionné à la fois
- Le Focus Engine d'Apple détermine automatiquement où le focus doit se déplacer
- Des animations subtiles et l'effet parallax créent une sensation de profondeur
- Le focus met en évidence et agrandit légèrement les éléments à l'écran

**Règles importantes :**
- Toujours rendre le focus **évident** (bordure, zoom, ombre)
- Ne **jamais** afficher de curseur
- Les états focus/non-focus doivent être **clairs**
- Espacement constant entre éléments pour une navigation fluide

### Gestures du Siri Remote

| Gesture | Action | Usage |
|---------|--------|-------|
| **Swipe** | Déplacer le focus | Navigation entre éléments |
| **Click** | Activer/Sélectionner | Confirmer, lire, ouvrir |
| **Tap** | Navigation rapide | Sauter entre sections |
| **MENU** | Retour | Toujours utilisé pour revenir en arrière |

**⚠️ Important :** Pas de bouton "Back" dans l'UI - utiliser uniquement le bouton MENU du remote.

---

## 🏗️ Architecture de Navigation Apple TV+

### 1. Structure Globale

```
┌─────────────────────────────────────────┐
│  Navigation Bar (Top)                   │
│  - Logo / Titre                         │
│  - Tabs (optionnel)                     │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│  Hero Banner (Featured Content)         │
│  - Backdrop plein écran                 │
│  - Titre + Description overlay          │
│  - Boutons d'action (Play, +)           │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│  Row 1: "Trending Now"                  │
│  [Card] [Card] [Card] [Card] →          │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│  Row 2: "Continue Watching"             │
│  [Card] [Card] [Card] [Card] →          │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│  Row 3: "Recommended"                   │
│  [Card] [Card] [Card] [Card] →          │
└─────────────────────────────────────────┘
```

### 2. Hero Banner

**Caractéristiques :**
- Image backdrop en **edge-to-edge** (plein écran)
- Ratio : **16:9**
- Overlay gradient pour lisibilité du texte
- Titre en gros (`.largeTitle` ou `.title`)
- Description limitée à 3-4 lignes
- Boutons d'action avec icônes SF Symbols

**Boutons typiques :**
- Play (`play.fill`) - Action primaire
- Add to Watchlist (`plus`)
- Info (`info.circle`)

### 3. Rows Horizontales Scrollables

**Implémentation :**
```swift
ScrollView(.horizontal, showsIndicators: false) {
    LazyHStack(spacing: 40) {
        ForEach(items) { item in
            MediaCard(item: item)
        }
    }
    .padding(.horizontal, 90) // Safe area tvOS
}
```

**Spacing recommandé :**
- Entre cartes : `40-50px`
- Padding horizontal : `90px` (safe area tvOS)
- Padding vertical : `40px`

### 4. Media Cards

**Ratio Poster :** 2:3 (portrait)
**Taille recommandée :** 250x375pt (scaling automatique)

**Anatomie d'une carte :**
```
┌──────────────┐
│              │
│   [Image]    │ ← Poster 2:3
│   [Poster]   │
│              │
└──────────────┘
    [Titre]       ← Optionnel, en dessous
```

**Effets au focus :**
- Scale : `1.0 → 1.1` (zoom 10%)
- Ombre portée : `.shadow(radius: 20)`
- Animation fluide : `.animation(.easeInOut)`

---

## 🎨 Design Visuel

### Nouveautés tvOS 26 (2025)

**Liquid Glass :**
- Matériau translucide qui réfléchit et réfracte l'environnement
- Transformations dynamiques pour mettre le contenu en avant
- Utilisé dans la sidebar et les overlays

**Sidebar Navigation :**
- Navigation personnalisable
- Affichage automatique des profils au réveil
- Accès rapide aux recommandations et Watchlist

### Typographie

| Élément | Style SwiftUI | Taille |
|---------|---------------|--------|
| Hero Title | `.largeTitle` | 76pt |
| Section Title | `.title2` | 34pt |
| Card Title | `.headline` | 17pt |
| Description | `.body` | 17pt |
| Metadata | `.caption` | 12pt |

**Lisibilité à 10 pieds :**
- Police minimale : **17pt**
- Contraste élevé (texte blanc sur fond sombre)
- Poids de police : `.medium` ou `.semibold` pour titres

### Couleurs

**Palette Apple TV+ :**
- Background : Noir pur `#000000`
- Surface : Gris foncé `#1C1C1E`
- Texte primaire : Blanc `#FFFFFF`
- Texte secondaire : Gris `#8E8E93`
- Accent : Blanc (pour focus)

**Focus :**
- Bordure blanche : `4px solid #FFFFFF`
- Ombre : `0 10px 40px rgba(0,0,0,0.5)`

---

## 📐 Layout & Spacing

### Grid System

**tvOS Safe Area :**
- Horizontal : `90px` de chaque côté
- Vertical : `60px` haut/bas

**Spacing recommandé :**
```
Row Title      : 40px top padding
Cards          : 40px horizontal spacing
Between Rows   : 60px vertical spacing
Section Header : 20px bottom margin
```

### Dimensions Standards

| Élément | Largeur | Hauteur |
|---------|---------|---------|
| Poster Card | 250pt | 375pt |
| Backdrop Card | 400pt | 225pt |
| Hero Banner | Full width | 720pt |
| Row Height | ~450pt | Variable |

---

## ⚡ Interactions & Animations

### Focus Effects

**Standard tvOS :**
```swift
.focusable()
.hoverEffect(.highlight) // ou .lift
```

**Custom Focus :**
```swift
.scaleEffect(isFocused ? 1.1 : 1.0)
.shadow(radius: isFocused ? 20 : 0)
.animation(.easeInOut(duration: 0.2), value: isFocused)
```

### Transitions

**Navigation :**
- Push/Pop : Slide horizontale
- Modal : Slide verticale
- Durée : `0.3-0.5s`
- Easing : `.easeInOut`

**Content Loading :**
- Skeleton screens (pas de spinners)
- Fade in : `0.3s`
- Stagger delay : `0.05s` entre items

---

## 🔊 Audio & Feedback

### Sons Système

tvOS joue automatiquement des sons pour :
- Focus déplacé
- Sélection
- Navigation back

**Ne pas :** Ajouter de sons custom pour navigation basique.
**À faire :** Sons custom pour actions spécifiques (play, bookmark, etc.)

---

## 📱 Exemples d'Apps Référence

**Apps utilisant ces patterns :**
- Apple TV+ (évidemment)
- Netflix
- Disney+
- Prime Video
- HBO Max

**Différences notables :**
- Netflix : Prévisualisation auto-play au focus
- Disney+ : Animations plus "magiques"
- Prime Video : Plus de métadonnées visibles

---

## 🚀 Implémentation dans Molyseerr

### Phase actuelle

✅ **Complété :**
- Architecture MVVM
- Data layer (Models, Services)
- TrendingViewModel
- ContentView basique (liste verticale)

🔄 **En cours :**
- Transformation en layout Apple TV+ style
- Hero banner avec premier trending item
- Rows horizontales scrollables
- Media cards avec focus effects

⏳ **À venir :**
- Sidebar navigation
- Détails de média en modal
- Intégration Kingfisher pour images
- Status badges (Available, Pending, etc.)

### Composants à créer

1. **HeroBannerView** - Featured content en haut
2. **MediaCardView** - Carte poster avec focus
3. **HorizontalMediaRow** - Row scrollable de cartes
4. **HomeView** - Remplacement de ContentView actuel

---

## 📚 Ressources Officielles

### Documentation Apple

- [Designing for tvOS - HIG](https://developer.apple.com/design/human-interface-guidelines/designing-for-tvos)
- [tvOS Design Resources](https://developer.apple.com/design/resources/)
- [SF Symbols](https://developer.apple.com/sf-symbols/)
- [Best Practices - Tech Talks](https://developer.apple.com/videos/play/techtalks-apple-tv/8/)

### Communauté

- [Medium - Designing for Apple TV](https://medium.com/@flarup/designing-for-the-apple-tv-5992c3aab1e4)
- [GitHub - tvOS Guidelines](https://github.com/BasThomas/tvOS-guidelines)

### Design Tools

- Sketch / Figma : Templates tvOS
- SF Symbols App : Icônes natives Apple

---

## ⚖️ Considérations Légales

### ✅ Autorisé

- S'inspirer des patterns de navigation Apple TV+
- Utiliser les composants SwiftUI standards
- Suivre les Human Interface Guidelines
- Créer une expérience similaire

### ❌ Interdit

- Copier les assets graphiques d'Apple TV+
- Utiliser le nom "Apple TV+" ou logo Apple
- Reverse engineering du code Apple
- Prétendre être affilié à Apple

**En résumé :** On peut faire une app qui **ressemble** à Apple TV+, mais pas une **copie** d'Apple TV+.

---

## 📝 Notes de Développement

### Focus Engine

Le Focus Engine est intelligent mais peut nécessiter des hints :
```swift
.focusSection() // Grouper des éléments
.prefersDefaultFocus(in: namespace) // Focus par défaut
```

### Performance

**tvOS a moins de RAM qu'iOS :**
- Lazy loading obligatoire (`LazyVStack`, `LazyHStack`)
- Image caching crucial (Kingfisher)
- Limiter nombre de vues à l'écran

### Testing

**Simulateur tvOS :**
- Raccourcis clavier pour remote
- Option + Arrow : Swipe rapide
- Espace : Click

**Device physique recommandé** pour test final du focus.

---

*Document créé le 24/12/2025 pour Molyseerr*
*Dernière mise à jour : 24/12/2025*
