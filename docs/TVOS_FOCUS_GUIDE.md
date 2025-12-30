# 📺 Guide du Focus tvOS - Éviter le Double Zoom

## ❌ Le Problème : Double Zoom

Quand on crée des cartes focusables sur tvOS, il est facile de créer un **double zoom** désagréable :
- Le bouton zoome (effet de focus)
- L'image **à l'intérieur** zoome aussi

Résultat : un effet moche et peu naturel.

## ✅ La Solution : Approche Swiftfin

### Principe de base

**Ne PAS gérer manuellement le zoom avec `scaleEffect` !**

Utiliser le **CardButtonStyle natif tvOS** qui gère tout automatiquement.

### Code Correct

```swift
var body: some View {
    VStack(alignment: .leading, spacing: 12) {
        Button {
            onTap()
        } label: {
            ZStack {
                Color.clear

                // Image avec .fit (PAS .fill)
                KFImage(imageURL)
                    .placeholder { Color.gray.opacity(0.3) }
                    .resizable()
                    .aspectRatio(16/9, contentMode: .fit)  // ← .fit !

                overlayView
            }
            .frame(width: cardWidth, height: cardHeight)
            .cornerRadius(12)
        }
        .buttonStyle(.card)  // ← CardButtonStyle natif tvOS
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        .focused($isFocused)  // Tracking focus pour overlays

        // Métadonnées en dessous
        metadata
    }
}
```

### ❌ Code À NE PAS FAIRE

```swift
// MAUVAIS : Gestion manuelle du zoom
Button { ... } label: {
    ZStack {
        KFImage(imageURL)
            .resizable()
            .aspectRatio(16/9, contentMode: .fill)  // ❌ .fill crée un zoom interne
        overlayView
    }
}
.buttonStyle(.borderless)  // ❌ Pas le bon style
.scaleEffect(isFocused ? 1.05 : 1.0)  // ❌ Zoom manuel
.animation(.easeInOut(duration: 0.15), value: isFocused)  // ❌ Animation manuelle
```

## 🔑 Points Clés

### 1. Button Style : `.card` pas `.borderless`

```swift
.buttonStyle(.card)  // ✅ CardButtonStyle natif tvOS
// Au lieu de:
.buttonStyle(.borderless)  // ❌
```

**Pourquoi ?**
- `.card` est le **CardButtonStyle natif de tvOS**
- Il gère automatiquement :
  - L'effet "lift" (élévation au focus)
  - Le zoom fluide
  - Les animations de transition
  - L'ombre dynamique

### 2. Image Content Mode : `.fit` pas `.fill`

```swift
.aspectRatio(16/9, contentMode: .fit)  // ✅
// Au lieu de:
.aspectRatio(16/9, contentMode: .fill)  // ❌
```

**Pourquoi ?**
- `.fill` fait **zoomer l'image** pour remplir le conteneur → double zoom
- `.fit` garde l'image **proportionnée** dans le conteneur → zoom uniforme

### 3. Pas de `scaleEffect` Manuel

```swift
// ✅ Laisser .card gérer le zoom
.buttonStyle(.card)
.focused($isFocused)

// ❌ NE PAS ajouter de scaleEffect
.scaleEffect(isFocused ? 1.05 : 1.0)
.animation(.easeInOut(duration: 0.15), value: isFocused)
```

### 4. Ordre des Modificateurs

```swift
Button { ... } label: { ... }
    .buttonStyle(.card)      // 1. Style du bouton
    .shadow(...)             // 2. Ombre (après le style)
    .focused($isFocused)     // 3. Tracking focus
```

L'ombre doit être **après** `.buttonStyle(.card)` pour s'appliquer au bouton entier.

## 📚 Référence Swiftfin

### EpisodeCard.swift

**Fichier:** `Swiftfin tvOS/Views/ItemView/Components/EpisodeSelector/Components/EpisodeCard.swift`

```swift
var body: some View {
    VStack(alignment: .leading) {
        Button {
            router.route(to: .videoPlayer(item: episode, ...))
        } label: {
            ZStack {
                Color.clear
                ImageView(episode.imageSource(.primary, maxWidth: 500))
                    .failure { SystemImageContentView(...) }
                overlayView
            }
            .posterStyle(.landscape)  // Aspect ratio 16:9
        }
        .buttonStyle(.card)  // ← La clé !
        .posterShadow()
        .focused($isFocused)
    }
}
```

### Modificateur `.posterStyle()`

```swift
func posterStyle(_ type: PosterDisplayType, contentMode: ContentMode = .fill) -> some View {
    switch type {
    case .landscape:
        posterAspectRatio(type, contentMode: contentMode)
        #if !os(tvOS)
            .posterBorder()
            .posterCornerRadius(type)
        #endif
    }
}

func posterAspectRatio(_ type: PosterDisplayType, contentMode: ContentMode = .fill) -> some View {
    switch type {
    case .landscape:
        aspectRatio(1.77, contentMode: contentMode)  // 16:9
    }
}
```

**Important :** Sur tvOS, pas de border ni corner radius (gérés par `.card`)

## 🎯 Résultat

- ✅ Un seul zoom fluide et naturel
- ✅ Animation native tvOS professionnelle
- ✅ Effet "lift" (élévation) au focus
- ✅ Ombre dynamique
- ✅ Code simple et maintenable

## 🔗 Ressources

- [CardButtonStyle | Apple Developer](https://developer.apple.com/documentation/swiftui/cardbuttonstyle)
- [Build SwiftUI apps for tvOS | WWDC](https://wwdcnotes.com/documentation/wwdcnotes/wwdc20-10042-build-swiftui-apps-for-tvos/)
- [Focus in SwiftUI for Apple TV](https://www.tothenew.com/blog/how-to-control-focus-in-swiftui-for-apple-tv-apps/)

## 💡 Rappel Rapide

Pour rappeler ce concept :
> "Utilise `.buttonStyle(.card)` natif tvOS au lieu de gérer manuellement le zoom avec `scaleEffect`. Image en `.fit` pas `.fill`."

---

**Date:** 30 décembre 2025
**Source:** Analyse de Swiftfin tvOS
**Statut:** ✅ Validé et implémenté dans EpisodeCard.swift
