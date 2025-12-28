# tvOS Focus System - Swiftfin Style

Documentation du système de focus utilisé dans Molyseerr, basé sur les meilleures pratiques de Swiftfin.

## Vue d'ensemble

Le système de focus utilise une combinaison de modifiers natifs SwiftUI et tvOS pour créer un effet de focus clair et élégant, identique à celui de Swiftfin.

## Implémentation pour les Cards

### 1. Dans le composant Card

```swift
struct MyCard: View {
    let item: YourItemType

    @FocusState private var isFocused: Bool

    // Constants
    private let cardWidth: CGFloat = 250
    private let cardHeight: CGFloat = 375
    private let focusScale: CGFloat = 1.1  // 10% zoom

    var body: some View {
        NavigationLink {
            DetailView(item: item)
        } label: {
            cardContent
        }
        .buttonStyle(.card)                                    // 1. Style natif tvOS
        .focused($isFocused)                                   // 2. Track focus state
        .scaleEffect(isFocused ? focusScale : 1.0)            // 3. Zoom de toute la card
        .shadow(radius: isFocused ? 20 : 4, y: isFocused ? 10 : 2)  // 4. Shadow dynamique
        .animation(.easeInOut(duration: 0.15), value: isFocused)    // 5. Animation rapide
    }
}
```

### 2. Dans le ScrollView Container

```swift
struct HorizontalRow: View {
    let items: [Item]

    // IMPORTANT: Calculer le padding vertical basé sur le zoom
    // Pour un zoom de 10% sur une card de 375px: 375 * 0.1 / 2 = ~40pt de padding
    private let verticalPadding: CGFloat = 40

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 40) {
                ForEach(items) { item in
                    MyCard(item: item)
                }
            }
            .padding(.horizontal, 48)
            .padding(.vertical, verticalPadding)  // Empêche le clipping
        }
        .scrollClipDisabled()  // Permet au contenu de déborder
    }
}
```

## Composants déjà implémentés

### MediaCardView
- **Dimensions**: 250x375 (2:3 ratio)
- **Focus scale**: 1.1 (10%)
- **Vertical padding requis**: 40pt
- **Fichier**: `Molyseerr/Views/Components/MediaCardView.swift`

### TodayReleaseCard
- **Dimensions**: 450x253 (16:9 ratio)
- **Focus scale**: 1.08 (8%)
- **Vertical padding requis**: 30pt
- **Fichier**: `Molyseerr/Views/Components/TodayReleaseCard.swift`

### HorizontalMediaRow
- **Vertical padding**: 40pt
- **Fichier**: `Molyseerr/Views/Components/HorizontalMediaRow.swift`

### TodayReleasesRow
- **Vertical padding**: 30pt
- **Fichier**: `Molyseerr/Views/Components/TodayReleasesRow.swift`

## Les 5 Modifiers Essentiels (dans l'ordre)

1. **`.buttonStyle(.card)`**
   - Style natif tvOS pour les cartes
   - Fournit l'effet de focus de base
   - Compatible avec NavigationLink

2. **`.focused($isFocused)`**
   - Bind le state @FocusState à la card
   - Permet de tracker quand la card a le focus
   - Nécessaire pour les animations custom

3. **`.scaleEffect(isFocused ? scale : 1.0)`**
   - Zoome **toute la card**, pas juste le contenu
   - Typiquement 1.05-1.1 (5-10%)
   - Cards plus petites = zoom plus prononcé

4. **`.shadow(radius: isFocused ? 20 : 4, y: isFocused ? 10 : 2)`**
   - Shadow subtile quand unfocused (radius: 4, y: 2)
   - Shadow prononcée quand focused (radius: 20, y: 10)
   - Donne de la profondeur à l'effet

5. **`.animation(.easeInOut(duration: 0.15), value: isFocused)`**
   - Animation rapide et fluide (150ms)
   - easeInOut pour un mouvement naturel
   - Appliquée uniquement sur le changement de focus

## Calcul du Vertical Padding

Pour éviter que les cards soient clippées lors du zoom:

```swift
// Formule: (cardHeight * (focusScale - 1.0)) / 2 + margin
//
// Exemple 1: Card 375px avec zoom 1.1
// (375 * 0.1) / 2 + 2 = 18.75 + 2 ≈ 20-40pt
//
// Exemple 2: Card 253px avec zoom 1.08
// (253 * 0.08) / 2 + 2 = 10.12 + 2 ≈ 12-30pt
```

**Recommandations:**
- Card 2:3 (250x375): **40pt** vertical padding
- Card 16:9 (450x253): **30pt** vertical padding
- Toujours arrondir vers le haut pour la sécurité

## Ne PAS utiliser `.hoverEffect(.highlight)`

❌ **Ancien code** (zoome le contenu, pas la card):
```swift
.buttonStyle(.card)
.cardFocus()  // Utilise .hoverEffect(.highlight)
```

✅ **Bon code** (zoome toute la card):
```swift
.buttonStyle(.card)
.focused($isFocused)
.scaleEffect(isFocused ? 1.1 : 1.0)
.shadow(radius: isFocused ? 20 : 4, y: isFocused ? 10 : 2)
.animation(.easeInOut(duration: 0.15), value: isFocused)
```

## Variations communes

### Focus plus subtile (petits éléments)
```swift
private let focusScale: CGFloat = 1.04  // 4% zoom
.animation(.easeInOut(duration: 0.125), value: isFocused)  // 125ms
```

### Focus plus prononcée (grands éléments)
```swift
private let focusScale: CGFloat = 1.15  // 15% zoom
.animation(.bouncy(duration: 0.4), value: isFocused)  // Animation bouncy
```

### Focus avec changement de couleur (style Swiftfin SupplementButton)
```swift
.foregroundStyle(isFocused ? .black : .white)
.background {
    if isFocused {
        Rectangle().foregroundStyle(.white)
    }
}
.overlay {
    if !isFocused {
        RoundedRectangle(cornerRadius: 27)
            .stroke(Color.white, lineWidth: 4)
    }
}
```

## Checklist pour nouveau composant

- [ ] Ajouter `@FocusState private var isFocused: Bool`
- [ ] Utiliser `.buttonStyle(.card)` sur le NavigationLink/Button
- [ ] Ajouter `.focused($isFocused)`
- [ ] Définir `focusScale` approprié pour la taille de la card
- [ ] Ajouter `.scaleEffect(isFocused ? focusScale : 1.0)`
- [ ] Ajouter `.shadow(radius: isFocused ? 20 : 4, y: isFocused ? 10 : 2)`
- [ ] Ajouter `.animation(.easeInOut(duration: 0.15), value: isFocused)`
- [ ] Dans le ScrollView parent:
  - [ ] Calculer le `verticalPadding` approprié
  - [ ] Ajouter `.padding(.vertical, verticalPadding)` au HStack
  - [ ] Ajouter `.scrollClipDisabled()` au ScrollView

## Références

- **Swiftfin**: `Swiftfin tvOS/Components/PosterButton.swift` (local repository)
- **CardButtonStyle** (obsolète): `Molyseerr/Styles/CardButtonStyle.swift`
- **Documentation officielle**: [Apple - Focus in tvOS](https://developer.apple.com/design/human-interface-guidelines/focus-and-selection)

## Date de création
27 décembre 2025

## Auteur
Basé sur l'analyse de Swiftfin et adapté pour Molyseerr
