# Structure du Projet Molyseerr (tvOS)

## 📂 Arborescence

```
Molyseerr/
├── Molyseerr.xcodeproj
├── Molyseerr/
│   ├── MolyseerrApp.swift           # Point d'entrée de l'app
│   ├── ContentView.swift            # Vue principale (temporaire)
│   │
│   ├── Models/                      # 📦 Modèles de données (Phase 1 ✅)
│   │   ├── MediaStatus.swift        # Enums: MediaStatus, MediaType, RequestStatus
│   │   ├── User.swift               # Modèle utilisateur
│   │   ├── MediaInfo.swift          # Info média (statut, requêtes) - CRITIQUE
│   │   ├── MediaRequest.swift       # Requête média + corps de requête
│   │   ├── Movie.swift              # MovieResult, MovieDetails, Genre, Cast
│   │   ├── TVShow.swift             # TVResult, TVDetails, Season, Episode
│   │   └── PaginatedResponse.swift  # Wrapper pagination + MediaResult
│   │
│   ├── Services/                    # 🌐 Couche réseau (Phase 1 ✅)
│   │   ├── SeerrService.swift       # Service API Singleton (async/await)
│   │   ├── SeerrError.swift         # Gestion des erreurs
│   │   └── SeerrConfig.swift        # Configuration (URLs, images)
│   │
│   ├── Extensions/                  # 🎨 Extensions utilitaires (Phase 1 ✅)
│   │   └── MediaStatus+Helpers.swift # Couleurs, textes de statut, palette Seerr
│   │
│   ├── ViewModels/                  # 🧠 Logique métier (Phase 2 - À venir)
│   │   └── (vide pour l'instant)
│   │
│   └── Views/                       # 🖼️ Interface SwiftUI (Phase 3 - À venir)
│       └── (vide pour l'instant)
│
├── TECH_RULES.md                    # 📘 Règles techniques du projet
├── TVOS_ARCH_SPEC.md                # 📐 Spécifications d'architecture
├── seerr-api.yml                    # 📋 Documentation API OpenAPI
├── USAGE_GUIDE.md                   # 📖 Guide d'utilisation du service
├── DATA_LAYER_README.md             # ✅ Récapitulatif Phase 1
└── PROJECT_STRUCTURE.md             # 📂 Ce fichier
```

---

## 🎯 Phases d'implémentation

### ✅ Phase 1 - Couche de Données (TERMINÉE)

**Objectif** : Créer une base solide pour communiquer avec l'API Seerr.

**Livrables** :
- ✅ 8 fichiers de modèles (Models/)
- ✅ 3 fichiers de service API (Services/)
- ✅ 1 fichier d'extensions (Extensions/)
- ✅ Configuration Kingfisher (SPM - à ajouter manuellement)
- ✅ Authentification par API Key
- ✅ Gestion des erreurs
- ✅ Tous les endpoints principaux

**Technologies** :
- Swift 5.9+ (syntaxe moderne)
- URLSession native avec async/await
- Codable pour le JSON
- Kingfisher pour les images (à installer)

---

### 🔜 Phase 2 - ViewModels (Logique Métier)

**Objectif** : Créer les ViewModels pour gérer l'état de l'application (pattern MVVM).

**À créer** :
- `TrendingViewModel` : Gère le contenu trending
- `DiscoverViewModel` : Gère la découverte de films/séries
- `MediaDetailsViewModel` : Détails d'un film/série
- `RequestsViewModel` : Gestion des requêtes utilisateur
- `SearchViewModel` : Recherche de contenu

**Principes** :
- Classes `@ObservableObject`
- Propriétés `@Published` pour la réactivité
- Logique de statut (Section 2.2 TVOS_ARCH_SPEC.md)
- Gestion de l'état de chargement/erreur

---

### 🔜 Phase 3 - Vues SwiftUI (Interface)

**Objectif** : Créer l'interface utilisateur tvOS avec support du Focus Engine.

**Composants à créer** :
- `MediaCardView` : Carte de film/série avec focus
- `StatusBadgeView` : Badge de statut (couleurs selon MediaStatus)
- `MediaGridView` : Grille de cartes (LazyVGrid)
- `TrendingView` : Vue principale du contenu trending
- `DiscoverView` : Vue de découverte
- `MediaDetailsView` : Vue détaillée d'un film/série

**Règles UX tvOS (CRITIQUE)** :
- ❌ **JAMAIS** `onTapGesture` (pas de souris sur Apple TV)
- ✅ **TOUJOURS** utiliser `Button` ou `NavigationLink`
- ✅ Support du Focus Engine (`.focusable()`)
- ✅ Effet de focus (`.scaleEffect(isFocused ? 1.1 : 1.0)`)
- ✅ Bordures/ombres sur focus

---

### 🔜 Phase 4 - Navigation

**Objectif** : Implémenter la navigation tvOS avec Tab Bar.

**Structure** :
- `TabView` racine (Tab bar en haut)
- Tabs : Home, Discover, Search, Requests, Settings
- Navigation en profondeur pour les détails

---

### 🔜 Phase 5 - Optimisations & Polish

**Objectif** : Optimiser les performances et l'expérience utilisateur.

**Tâches** :
- Intégration Kingfisher (cache images)
- Pagination infinie (scroll)
- Préchargement des images
- Animations fluides
- Tests de performance

---

## 🔑 Fichiers Critiques

### Pour la logique métier

| Fichier | Importance | Raison |
|---------|------------|--------|
| **MediaInfo.swift** | 🔴 CRITIQUE | Contient `status`, `requests`, `permissions` pour la logique des boutons |
| **MediaStatus.swift** | 🔴 CRITIQUE | Énumérations des statuts (logique conditionnelle partout) |
| **SeerrService.swift** | 🔴 CRITIQUE | Service principal pour toutes les requêtes API |
| **MediaStatus+Helpers.swift** | 🟡 Important | Couleurs et textes UI (design system) |

### Pour la configuration

| Fichier | Importance | Raison |
|---------|------------|--------|
| **SeerrConfig.swift** | 🟡 Important | URLs TMDB, configuration globale |
| **SeerrError.swift** | 🟡 Important | Gestion des erreurs typées |

---

## 📋 Checklist d'intégration

Avant de passer à la Phase 2, assurez-vous de :

- [ ] **Ajouter tous les fichiers .swift au projet Xcode**
  - Models/
  - Services/
  - Extensions/

- [ ] **Installer Kingfisher via Swift Package Manager**
  - URL : `https://github.com/onevcat/Kingfisher.git`
  - Version : `8.0.0`

- [ ] **Configurer le service API au démarrage**
  ```swift
  SeerrService.shared.setBaseURL("http://localhost:5055")
  SeerrService.shared.setApiKey("VOTRE_CLE_API")
  ```

- [ ] **Tester un appel API simple**
  ```swift
  let trending = try await SeerrService.shared.getTrending()
  print("✅ \(trending.results.count) résultats")
  ```

- [ ] **Vérifier la compilation** (⌘B dans Xcode)

---

## 🎨 Design System

La palette de couleurs est disponible dans `MediaStatus+Helpers.swift` :

```swift
Color.seerrIndigo500   // #6366f1 - Actions principales
Color.seerrGreen500    // #22c55e - Disponible
Color.seerrYellow500   // #eab308 - En attente
Color.seerrRed500      // #ef4444 - Erreur/Blacklist
Color.seerrGray900     // #111827 - Fond principal
Color.seerrBlue500     // #3b82f6 - Badge Film
Color.seerrPurple600   // #9333ea - Badge Série
```

---

## 📚 Documentation de référence

### Documents du projet
1. **TECH_RULES.md** : Règles techniques (Swift, SwiftUI, tvOS)
2. **TVOS_ARCH_SPEC.md** : Architecture et logique métier
3. **seerr-api.yml** : Spécification complète de l'API
4. **USAGE_GUIDE.md** : Exemples de code et utilisation

### Sections clés
- **Logique de statut** : TVOS_ARCH_SPEC.md Section 2.1 et 2.2
- **Endpoints API** : TVOS_ARCH_SPEC.md Section 3
- **Couleurs** : TVOS_ARCH_SPEC.md Annexe A
- **Règles UX tvOS** : TECH_RULES.md Section 2

---

## 🤝 Contribution

Pour ajouter de nouvelles fonctionnalités, suivre l'ordre des phases :

1. **Modèles** (si nouveaux types de données)
2. **Service** (si nouveaux endpoints)
3. **ViewModel** (logique métier)
4. **View** (interface)

Toujours respecter :
- Les règles TECH_RULES.md (pas de `onTapGesture`, Focus Engine, etc.)
- L'architecture MVVM
- Les conventions Swift (camelCase, etc.)
- Les commentaires en français (code en anglais)

---

**Date de création** : 2025-12-24
**Phase actuelle** : Phase 1 ✅ TERMINÉE
**Prochaine phase** : Phase 2 (ViewModels)
