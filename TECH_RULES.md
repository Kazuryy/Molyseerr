# Règles Techniques pour le projet tvOS (Seerr Client)

## 1. Stack Technique & Outils
* **Langage :** Swift 5.9+ (Utilise la syntaxe moderne `if let x` sans répétition).
* **Framework UI :** SwiftUI (100% déclaratif).
* **Plateforme Cible :** tvOS 26.2+ (Apple TV 4K, 2025).
* **Gestion des Images :** Utilise la librairie tierce **Kingfisher** (v8.6.2+) via Swift Package Manager (SPM).
    * *Règle :* Ne jamais utiliser `AsyncImage` natif (pas assez de cache). Utilise `KFImage`.
* **Réseau :** `URLSession` native avec `async/await`.
* **Configuration Dev :** Fichier `.env` pour baseURL et API key (git-ignored, voir `.env.example`).

## 2. Règles UX/UI Spécifiques tvOS (CRITIQUE)

> **📖 Référence Design :** Voir [docs/APPLE_TV_DESIGN_REFERENCE.md](docs/APPLE_TV_DESIGN_REFERENCE.md) pour le guide complet du style Apple TV+

* **Focus Engine (Impératif) :**
    * ❌ INTERDIT : N'utilise jamais `onTapGesture`. La télécommande n'est pas une souris.
    * ✅ OBLIGATOIRE : Utilise des composants `Button` ou `NavigationLink` standards avec `.focusable()`.
    * L'interface doit être pilotable entièrement avec les flèches (Haut/Bas/Gauche/Droite).
* **Feedback Visuel :**
    * Tout élément interactif doit avoir un état "Focus" visible.
    * Utilise `.scaleEffect(isFocused ? 1.1 : 1.0)` pour les posters.
    * Ajoute une bordure blanche (4px) ou une ombre quand `isFocused` est vrai.
    * Animation fluide : `.animation(.easeInOut(duration: 0.2))`.
* **Navigation :**
    * Structure : Navigation horizontale prioritaire (rows scrollables).
    * Hero Banner en haut avec backdrop plein écran.
    * Rows horizontales (`LazyHStack`) pour les catégories.
    * Safe area tvOS : 90px horizontal padding.
    * Pas de bouton "Back" - utiliser le bouton MENU du remote.

## 3. Architecture & Data
* **Pattern :** MVVM (Model - View - ViewModel).
    * **Model :** Structs `Codable` immuables (basées sur `seerr-api.yml`).
    * **ViewModel :** Classes `@ObservableObject` qui gèrent l'état et les appels API.
    * **View :** Juste de l'affichage, pas de logique métier complexe.
* **Service API :** Singleton `SeerrService`.
* **Simplification MVP :**
    * Pas de flow de login complexe. Utilise une constante globale `let API_KEY = "..."` pour l'instant.
    * Pas de persistance locale complexe (CoreData). L'API est la source de vérité.

## 4. Performance & Optimisation
* **Images :**
    * Utilise les tailles TMDB `w500` pour les grilles.
    * Utilise `original` uniquement pour le fond d'écran (Backdrop).
* **Concurrence :**
    * Les appels réseaux doivent être sur des `Task` détachées.
    * Les mises à jour UI (`@Published`) doivent être sur le `MainActor`.