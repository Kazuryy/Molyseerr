# Swiftfin Design System Documentation

> **Source**: Analysé depuis local Swiftfin repository
> **Objectif**: Reproduire l'esthétique Swiftfin pour Molyseerr (client Seerr pour tvOS)

---

## 🎨 Système de Couleurs

### Couleurs Principales
**Source**: `/Shared/Extensions/Color.swift`

```swift
// Couleur de marque Jellyfin
Color.jellyfinPurple = Color(red: 172/255, green: 92/255, blue: 195/255)
// RGB: (172, 92, 195) - Violet Jellyfin

// Adaptation pour Molyseerr (utiliser le violet Seerr)
Color.seerrPurple = Color(red: 0.6, green: 0.2, blue: 0.8)  // À ajuster selon Seerr
```

### Couleurs Système (iOS/tvOS)
```swift
// Backgrounds
Color.systemBackground           // Fond principal
Color.secondarySystemBackground  // Fond secondaire
Color.tertiarySystemBackground   // Fond tertiaire

// Fills (pour cartes/containers)
Color.systemFill                 // Fill principal
Color.secondarySystemFill        // Fill secondaire
Color.tertiarySystemFill         // Fill tertiaire

// Texte
.foregroundStyle(.primary)       // Texte principal
.foregroundStyle(.secondary)     // Texte secondaire
Color(UIColor.lightGray)         // Métadonnées
```

### Patterns d'Utilisation
- **Actions primaires**: Violet de marque (Jellyfin/Seerr)
- **Cartes/Containers**: `.systemFill`
- **Séparateurs**: `.secondarySystemFill` (1px)
- **Texte secondaire**: `.secondary` ou `lightGray`

---

## 📝 Système Typographique

### Échelle de Polices
```swift
.largeTitle        // Grands en-têtes
.title             // Titres de section
.title2            // Titres de cartes (TRÈS UTILISÉ)
.title3            // Sous-sections
.headline          // Contenu emphasisé
.subheadline       // En-têtes secondaires (items de liste)
.body              // Texte par défaut
.callout           // Items de liste
.footnote          // Titres de posters
.caption           // Métadonnées, timestamps
.caption2          // Petits caractères
```

### Poids de Police
```swift
.bold              // En-têtes de section
.semibold          // Titres, labels importants
.regular           // Texte du corps
.medium            // Emphase subtile
```

### Combinaisons Courantes
```swift
// En-têtes de section
Text("Section Title")
    .font(.title2)
    .fontWeight(.bold)

// Titres de posters
Text(item.displayTitle)
    .font(.footnote)
    .fontWeight(.regular)

// Métadonnées
Text("2024 • 2h 15m • PG-13")
    .font(.caption)
    .foregroundStyle(.secondary)

// Titres de lignes de liste
Text(title)
    .font(.subheadline)
    .fontWeight(.semibold)
    .lineLimit(2)
```

---

## 📐 Système d'Espacement

### Padding de Bord (EdgePadding)
**Source**: `/Shared/Extensions/EdgeInsets.swift`

```swift
// Padding adaptatif selon appareil
EdgeInsets.edgePadding
// iPhone: 16pt
// iPad: 24pt
// tvOS: 44pt

// Utilisation
.edgePadding()            // Tous les côtés
.edgePadding(.horizontal) // Horizontal uniquement
.edgePadding(.vertical)   // Vertical uniquement
```

### Espacements Communs
```swift
// VStack/HStack
VStack(alignment: .leading, spacing: 5)    // Serré
VStack(alignment: .leading, spacing: 10)   // Par défaut
HStack(spacing: EdgeInsets.edgePadding)    // Large

// Padding
.padding(.vertical, 8)     // Items de liste
.padding(.vertical, 10)    // Diviseurs de section
.padding(4)                // Minimal
.padding(20)               // Fonds de modales
```

---

## 🔘 Styles de Boutons

### 1. Primary Button (Bouton Principal)
**Source**: `/Shared/Components/PrimaryButtonStyle.swift`

```swift
Button("Connect") {
    action()
}
.buttonStyle(.primary)
.frame(maxHeight: 75)
.foregroundStyle(
    accentColor.overlayColor,  // Couleur de texte
    accentColor                // Couleur de fond
)
.disabled(isInvalid)
.opacity(isInvalid ? 0.5 : 1)
```

**Caractéristiques**:
- Coins arrondis: 10pt
- Hauteur idéale: 44pt (max 75pt)
- Police: `.semibold`
- Focus: Ajustement de luminosité
- Support rôles `.destructive` (rouge), `.cancel`

### 2. ChevronButton (Navigation)
**Source**: `/Shared/Components/ChevronButton.swift`

```swift
// Simple
ChevronButton("Settings") {
    navigate()
}

// Avec sous-titre
ChevronButton("Server") {
    navigate()
} subtitle: {
    Text("http://192.168.1.46:5055")
}

// Avec icône
ChevronButton(
    "Logs",
    systemName: "doc.text.fill"
) {
    navigate()
}
```

**Caractéristiques**:
- Layout HStack: label, subtitle, chevron
- Icône chevron.right (ou arrow.up.right pour liens externes)
- Icônes en gras, texte régulier
- Styles `.primary` et `.secondary`

### 3. Toolbar Pill Button
**Source**: `/Swiftfin/Extensions/ButtonStyle-iOS.swift`

```swift
Button("Filter") {
    toggle()
}
.buttonStyle(.toolbarPill)

// Avec couleurs personnalisées
.buttonStyle(.toolbarPill(Color.blue, Color.white))
```

**Caractéristiques**:
- Forme de pilule (coins arrondis 10pt)
- Fond teinté
- Padding: 5pt vertical, 10pt horizontal
- Police: `.headline`
- Opacité 50% quand désactivé/pressé

---

## 📝 Styles d'Input

### TextField Pattern
```swift
TextField("Server URL", text: $url)
    .disableAutocorrection(true)
    .textInputAutocapitalization(.never)
    .keyboardType(.URL)
    .focused($focusedField)
```

### SecureField avec Toggle
```swift
SecureField(
    "Password",
    text: $password,
    maskToggle: .enabled  // Swiftfin custom
)
.autocorrectionDisabled()
.textInputAutocapitalization(.never)
.focused($focusedField)
.onSubmit {
    // Navigation vers champ suivant
}
```

**Règles Clés**:
- ✅ Toujours désactiver autocorrect pour credentials
- ✅ Utiliser `.never` capitalization pour usernames/URLs
- ✅ Définir keyboard types appropriés (`.URL`, `.default`)
- ✅ Implémenter FocusState pour navigation
- ✅ Chaîner `.onSubmit` pour flux séquentiel

---

## 🃏 Composants de Carte

### Information Card
**Source**: `/Swiftfin/Views/ItemView/Components/AboutView/Components/AboutView+Card.swift`

```swift
ItemView.AboutView.Card(
    title: "Overview",
    subtitle: "Optional subtitle"
) {
    // Action optionnelle
} content: {
    // Contenu de la carte
    Text("Description...")
}
```

**Caractéristiques**:
- Background: `Color.systemFill`
- Corner radius: Ratio dynamique `1/45` de la hauteur
- Titre: `.title2` + `.semibold`, 2 lignes max
- Sous-titre: `.subheadline` + `.secondary`, 2 lignes max
- Style de bouton: `.plain` pour tap
- Padding: Système par défaut

### Tailles de Carte
```swift
// iPhone: 3 colonnes
let itemWidth = (screenWidth - edgePadding * 2 - itemSpacing * 2) / 3

// iPad: Colonnes dynamiques basées sur largeur min
let portraitMinWidth: CGFloat = 140

// Ratios d'aspect
height = width * 3/2      // Cartes portrait
width = height * 1.65     // Cartes paysage
```

---

## 🖼️ Composants Poster/Image

### PosterButton
**Source**: `/Swiftfin/Components/PosterButton.swift`

```swift
PosterButton(
    item: item,
    type: .portrait  // ou .landscape, .square
) { namespace in
    onSelect(item, in: namespace)
} label: {
    PosterButton<Item>.TitleContentView(title: item.displayTitle)
        .lineLimit(1, reservesSpace: true)
}
```

**Types d'Affichage**:
- **Portrait**: Ratio 2:3 (classique affiche film)
- **Landscape**: Ratio 1.77:1 (16:9)
- **Square**: Ratio 1:1

**Modificateurs de Style**:
```swift
.posterStyle(type, contentMode: .fill)
.posterCornerRadius(type)      // Coins arrondis ratio-based
.posterBorder()                // Bordure blanche 1px à 10% opacité
.posterShadow()                // Ombre: 4pt radius, 2pt y-offset
```

### Overlays de Poster
```swift
// Indicateur de progression (barre de 5pt)
ProgressIndicator(progress: 0.65, height: 5)

// Indicateur "vu" (cercle 25pt avec checkmark)
WatchedIndicator(size: 25)

// Indicateur "non vu" (cercle 25pt)
UnwatchedIndicator(size: 25)
    .foregroundColor(accentColor)

// Indicateur favori (étoile 25pt)
FavoriteIndicator(size: 25)
```

### PosterImage
**Source**: `/Shared/Components/PosterImage.swift`

```swift
PosterImage(
    item: item,
    type: .landscape,
    contentMode: .fill,
    maxWidth: 300
)
```

**Fonctionnalités**:
- Support BlurHash pour placeholders
- Fallback: icône système + titre
- Background: `.complexSecondary`
- Qualité image: 90%
- Largeurs max: 300pt (landscape), 200pt (portrait)

---

## 📋 Composants de Liste

### LibraryRow (Item de Liste Personnalisé)
**Source**: `/Swiftfin/Views/PagingLibraryView/Components/LibraryRow.swift`

```swift
ListRow(insets: .init(horizontal: EdgeInsets.edgePadding)) {
    // Contenu de gauche (poster)
    PosterImage(item: item, type: .landscape)
        .posterShadow()
        .frame(width: 110)  // ou 60 pour portrait
        .padding(.vertical, 8)
} content: {
    // Contenu principal
    VStack(alignment: .leading, spacing: 5) {
        Text(title)
            .font(.subheadline)
            .fontWeight(.semibold)
            .lineLimit(2)

        DotHStack {
            Text("2024")
            Text("2h 15m")
            Text("PG-13")
        }
        .font(.caption)
        .foregroundColor(Color(UIColor.lightGray))
    }
}
.onSelect { /* action */ }
```

**Dimensions**:
- Poster landscape: 110pt largeur
- Poster portrait: 60pt largeur
- Padding vertical: 8pt
- Séparateur: 1px en bas

### DotHStack (Affichage de Métadonnées)
**Source**: `/Swiftfin/Components/DotHStack.swift`

```swift
DotHStack(padding: 5) {
    Text("2024")
    Text("2h 15m")
    Text("PG-13")
}
.font(.caption)
.foregroundColor(Color(UIColor.lightGray))
```

**Pattern**: Insère des cercles de 2pt comme séparateurs entre items

---

## 🔲 Layouts de Grille

### Configuration PagingLibraryView
**Source**: `/Swiftfin/Views/PagingLibraryView/PagingLibraryView.swift`

```swift
// Grilles iPhone
.landscape: .columns(2)
.portrait:  .columns(3)
.square:    .columns(3)

// Grilles iPad
.landscape: .minWidth(200)
.portrait:  .minWidth(150)
.square:    .minWidth(150)

// Layouts de liste
.list: .columns(listColumnCount)  // Configurable, sans espacement
```

**Fonctionnalités**:
- Calcul dynamique de colonnes
- Dimensionnement selon type de poster
- Mémorisation de préférence de layout par bibliothèque
- Scroll infini avec trigger à 300pt

---

## 🎬 Patterns de Vue Détail

### Cinematic Scroll View
**Source**: `/Swiftfin/Views/ItemView/ScrollViews/CinematicScrollView.swift`

```swift
OffsetScrollView(heightRatio: 0.75) {
    // Header avec image backdrop
    ImageView(backdropSource)
        .aspectRatio(1.77, contentMode: .fill)
        .frame(height: screenHeight * 0.6)
        .bottomEdgeGradient(bottomColor: averageColor)
} overlay: {
    // Overlay avec logo/titre, métadonnées, actions
    VStack {
        ImageView(logoSource)
            .frame(height: 100)

        DotHStack {
            Text(genre)
            Text(year)
            Text(runtime)
        }

        PlayButton()
        ActionButtonHStack()
    }
    .background {
        BlurView(style: .systemThinMaterialDark)
            .maskLinearGradient { /* gradient stops */ }
    }
} content: {
    // Contenu scrollable (genres, cast, etc.)
}
```

**Caractéristiques Clés**:
- Ratio de hauteur 75% pour header parallax
- Backdrop: 60% de hauteur d'écran
- Gradient de bas vers contenu
- Blur fin (thin material) pour overlay
- Logo: 100pt de hauteur
- Texte blanc sur fond blur sombre

### Episode Cards
**Source**: `/Swiftfin/Views/ItemView/Components/EpisodeSelector/Components/EpisodeCard.swift`

```swift
VStack(alignment: .leading) {
    // Poster landscape avec overlay
    Button {
        playEpisode()
    } label: {
        ImageView(episode.primaryImage)
            .overlay {
                if hasProgress {
                    LandscapePosterProgressBar(
                        title: "45 min left",
                        progress: 0.65
                    )
                }
            }
            .posterStyle(.landscape)
            .posterShadow()
    }

    // Info épisode
    EpisodeContent(
        header: title,
        subHeader: "S1:E5",
        content: overview
    )
}
```

---

## ⚙️ Patterns Settings/Forms

### Structure Settings View
**Source**: `/Shared/Views/SettingsView/SettingsView.swift`

```swift
Form(image: .jellyfinBlobBlue) {
    Section {
        UserProfileRow(user: user)

        ChevronButton("Server") {
            navigate()
        } subtitle: {
            Text(serverName)
        }
    }

    Section {
        Button("Switch User") {
            signOut()
        }
        .buttonStyle(.primary)
        .foregroundStyle(accentColor.overlayColor, accentColor)
    }

    Section("Video Player") {
        Picker("Type", selection: $playerType) {
            // options
        }

        ChevronButton("Settings") {
            navigate()
        }
    } learnMore: {
        // Contenu d'aide additionnel
    }
}
```

**Patterns de Form**:
- Image d'en-tête (optionnelle, max 400pt)
- Sections groupées avec headers/footers
- Titre navigation bar: `.inline`
- Primary button pour actions importantes
- ChevronButton pour navigation
- Picker/Toggle pour réglages
- ColorPicker avec `supportsOpacity: false`

---

## 🔐 Patterns Serveur/Login

### ConnectToServerView
**Source**: `/Shared/Views/ConnecToServerView/ConnectToServerView.swift`

```swift
List {
    Section("Connect to Server") {
        TextField("Server URL", text: $url)
            .focused($focusField)

        Button("Connect") {
            connect()
        }
        .buttonStyle(.primary)
        .frame(maxHeight: 75)
        .disabled(url.isEmpty)
        .foregroundStyle(accentColor.overlayColor, accentColor)
        .opacity(url.isEmpty ? 0.5 : 1)
    }

    Section("Local Servers") {
        if servers.isEmpty {
            Text("No local servers found")
                .font(.callout)
                .foregroundColor(.secondary)
        } else {
            ForEach(servers) { server in
                LocalServerButton(server: server)
            }
        }
    }
}
```

### UserSignInView
**Source**: `/Shared/Views/UserSignInView/UserSignInView.swift`

```swift
Section {
    TextField("Username", text: $username)
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .focused($focusedField, equals: .username)
        .onSubmit {
            focusedField = .password
        }

    SecureField("Password", text: $password, maskToggle: .enabled)
        .focused($focusedField, equals: .password)
} header: {
    Text("Sign In to \(serverName)")
} footer: {
    Label("Description", systemImage: "exclamationmark.circle.fill")
        .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
}

Button("Sign In") {
    signIn()
}
.buttonStyle(.primary)
.foregroundStyle(Color.jellyfinPurple.overlayColor, Color.jellyfinPurple)
```

---

## 🛠️ View Modifiers Réutilisables

### Modificateurs Communs
**Source**: `/Shared/Extensions/ViewExtensions/ViewExtensions.swift`

```swift
// Visibilité (sans retirer de la hiérarchie)
.isVisible(opacity: 1.0, condition)
.hidden(condition)

// Application conditionnelle
.if(condition) { view in
    view.modifier()
}

.ifLet(optionalValue) { view, value in
    view.withValue(value)
}

// Coins
.cornerRadius(10)
.cornerRadius(ratio: 1/30, of: \.width)

// Edge padding
.edgePadding()
.edgePadding(.horizontal)

// Styling de poster
.posterStyle(.portrait)
.posterCornerRadius(.landscape)
.posterBorder()
.posterShadow()

// Gestion d'erreur
.errorMessage($error)

// Première/Dernière apparition
.onFirstAppear { }
.onFinalDisappear { }

// Tracking de frame
.trackingSize($size)
.trackingFrame($frame)
```

---

## 🎭 Patterns d'Animation & Transition

```swift
// Transitions d'état
.animation(.linear(duration: 0.1), value: viewState)

// Matched geometry
.matchedTransitionSource(id: "item", in: namespace)

// Actions de lecteur vidéo
.videoPlayerActionButtonTransition()
// = .opacity.combined(with: .scale).animation(.snappy)

// Masques de gradient
.maskLinearGradient {
    (location: 0, opacity: 0)
    (location: 0.3, opacity: 1)
    (location: 1, opacity: 1)
}
```

---

## 📁 Patterns d'Organisation de Composants

### Structure de Fichiers
```
Shared/
  ├── Components/          // Composants UI réutilisables
  ├── Extensions/          // Extensions de types
  ├── ViewModels/          // Logique métier
  └── Views/               // Implémentations d'écrans
      └── [ScreenName]/
          ├── [ScreenName]View.swift
          └── Components/  // Composants spécifiques à l'écran
```

### Pattern d'Extension de Composant
```swift
extension ItemView {
    struct MovieItemContentView: View { }
    struct SeriesItemContentView: View { }

    struct PlayButton: View { }
    struct ActionButtonHStack: View { }
}
```

---

## 🎯 Principes de Design Clés

1. **Cohérence**: Utiliser couleurs et polices système partout
2. **Hiérarchie**: Hiérarchie visuelle claire avec tailles et poids de police
3. **Espacement**: Padding adaptatif (16pt phone, 24pt pad, 44pt tvOS)
4. **Accessibilité**: Support type dynamique, contraste élevé, mouvement réduit
5. **Performance**: Lazy loading, cache d'images, layouts efficaces
6. **Réutilisabilité**: Composants génériques avec protocols
7. **Dark Mode**: Couleurs et materials système pour adaptation auto
8. **Focus States**: Support tvOS/accessibilité avec indicateurs de focus

---

## 📝 Référence Rapide

### Couleurs
- **Marque**: `Color.jellyfinPurple` (172, 92, 195)
- **Backgrounds**: `.systemFill`, `.secondarySystemFill`
- **Texte**: `.primary`, `.secondary`, `Color(UIColor.lightGray)`

### Typographie
- **En-têtes**: `.title2` + `.bold`
- **Corps**: `.body` / `.subheadline` + `.semibold`
- **Métadonnées**: `.caption` + `.foregroundStyle(.secondary)`

### Espacement
- **Edge padding**: 16pt (phone), 24pt (pad), 44pt (tvOS)
- **Espacement composants**: 5-10pt
- **Espacement sections**: EdgeInsets.edgePadding

### Boutons
- **Primary**: 10pt coins, 44pt+ hauteur, fond teinté
- **Chevron**: Navigation avec icône chevron droite
- **Pill**: Style toolbar, extrémités arrondies

### Images
- **Posters**: 2:3 (portrait), 1.77:1 (landscape), 1:1 (square)
- **Corner radius**: Ratio-based (1/30 largeur pour landscape)
- **Shadow**: 4pt radius, 2pt y-offset
- **Placeholders**: BlurHash

### Listes
- **Hauteur de ligne**: Variable selon contenu
- **Séparateur**: 1px `.secondarySystemFill`
- **Largeur poster**: 60pt (portrait), 110pt (landscape)

---

## 🎬 Application à Molyseerr

### Adaptations Nécessaires

1. **Couleur de Marque**
   - Remplacer `jellyfinPurple` par violet Seerr
   - Garder tous les autres patterns de couleur système

2. **Terminologie**
   - "Jellyfin Server" → "Seerr Server"
   - "Media Server" → "Media Request Server"
   - Adapter messages selon contexte Seerr

3. **Fonctionnalités Spécifiques**
   - Login: Support Jellyfin ET Local (dual auth)
   - Requests: Ajouter indicateurs de statut (pending, approved, etc.)
   - Availability: Afficher disponibilité média

4. **Navigation**
   - Home (Trending/Popular)
   - Requests (User requests)
   - Search
   - Settings

5. **Composants à Créer**
   - `RequestStatusBadge` (pending/approved/declined)
   - `AvailabilityIndicator` (available/unavailable)
   - `RequestButton` (style primary)
   - `MediaTypeToggle` (movie/tv switch)

---

Ce système de design fournit une fondation cohérente, accessible et maintenable pour construire Molyseerr en suivant l'excellente UX de Swiftfin tout en l'adaptant aux besoins de Seerr! 🚀