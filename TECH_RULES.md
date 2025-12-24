# Règles Techniques pour le projet tvOS (Seerr Client)

## 1. Stack Technique & Outils
* **Langage :** Swift 5.9+ (Utilise la syntaxe moderne `if let x` sans répétition).
* **Framework UI :** SwiftUI (100% déclaratif).
* **Plateforme Cible :** tvOS 17.0+ (Apple TV 4K).
* **Gestion des Images :** Utilise la librairie tierce **Kingfisher** via Swift Package Manager (SPM).
    * *Règle :* Ne jamais utiliser `AsyncImage` natif (pas assez de cache). Utilise `KFImage`.
* **Réseau :** `URLSession` native avec `async/await`.

## 2. Règles UX/UI Spécifiques tvOS (CRITIQUE)
* **Focus Engine (Impératif) :**
    * ❌ INTERDIT : N'utilise jamais `onTapGesture`. La télécommande n'est pas une souris.
    * ✅ OBLIGATOIRE : Utilise des composants `Button` ou `NavigationLink` standards.
    * L'interface doit être pilotable entièrement avec les flèches (Haut/Bas/Gauche/Droite).
* **Feedback Visuel :**
    * Tout élément interactif doit avoir un état "Focus" visible.
    * Utilise `.scaleEffect(isFocused ? 1.1 : 1.0)` pour les posters.
    * Ajoute une bordure ou une ombre quand `isFocused` est vrai.
* **Navigation :**
    * Structure : `TabView` racine (Tab bar en haut de l'écran).
    * Listes : Utilise `ScrollView(.vertical)` contenant des `ScrollView(.horizontal)` pour les rangées de films (Style Netflix).

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