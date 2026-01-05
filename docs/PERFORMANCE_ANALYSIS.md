# Molyseerr - Analyse de Performance

**Date:** 3 Janvier 2026
**Branche:** refactor/performance-improvements
**Version:** 0.2.0

---

## 🎯 Problèmes Identifiés

### Symptômes Utilisateur
- ⏱️ **Délai de focus:** 1 seconde avant de changer d'objet
- ⏱️ **Chargement sliders:** 2 secondes par slider
- ⏱️ **Sluggishness général:** Navigation lente

---

## 🔍 Bottlenecks Critiques Identifiés

### 1. APPELS API SÉQUENTIELS (CRITIQUE)
**Fichier:** `Molyseerr/Views/DiscoverView.swift:457-520`

**Problème:**
```swift
for info in mediaInfos {
    let details = try await tmdbService.getMovieDetails(id: info.tmdbId)
    // Un appel à la fois...
}
```

**Impact:**
- Slider avec 20 items = 20 requêtes séquentielles
- Temps: 20 × ~200ms = **4 secondes minimum**
- Bloque l'UI pendant le chargement

**Solution:**
- Paralléliser avec `TaskGroup`
- Temps attendu: < 500ms pour 20 items

---

### 2. IMAGES EN TAILLE ORIGINALE (CRITIQUE)
**Fichier:** `Molyseerr/Utils/TMDBImageHelper.swift:61-62`

**Problème:**
```swift
static func backdropURL(path: String?) -> URL? {
    return imageURL(path: path, size: .original)  // 2K-4K images, 5-10 MB
}
```

**Impact:**
- HeroBanner charge des images 5-10 MB
- Décodage GPU très coûteux sur tvOS
- Téléchargement lent sur connexions limitées

**Solution:**
- Utiliser `w1280` au lieu de `.original`
- Fichiers 5× plus petits
- Décodage 3× plus rapide

---

### 3. EFFETS VISUELS LOURDS SUR FOCUS (HAUTE)
**Fichier:** `Molyseerr/Views/Components/MediaCardView.swift:38-40`

**Problème:**
```swift
.scaleEffect(isFocused ? focusScale : 1.0)
.shadow(radius: isFocused ? 20 : 4, y: isFocused ? 10 : 2)
.animation(.easeInOut(duration: 0.15), value: isFocused)
```

**Impact:**
- Chaque changement de focus recalcule les ombres
- GPU doit re-renderer toute la carte
- Délai perceptible de ~1 seconde

**Solution:**
- Réduire l'intensité des shadows
- Utiliser `.compositingGroup()` pour rasteriser
- Considérer `.drawingGroup()` pour performance

---

### 4. LAZY STACKS + KINGFISHER (HAUTE)
**Fichiers:** Multiple views avec `LazyVStack`/`LazyHStack`

**Problème:**
- tvOS 18 a des problèmes connus avec `LazyVStack` + `KFImage`
- Memory leak: les images ne sont pas libérées correctement
- Pire sur Apple TV HD (lag jusqu'à 20 secondes)

**Impact:**
- Mémoire qui augmente constamment
- Performance qui se dégrade avec le temps
- Crashes potentiels sur devices avec peu de RAM

**Solution:**
- Configurer Kingfisher memory cache limits
- Utiliser `DownsamplingImageProcessor`
- Considérer `List` au lieu de `LazyVStack` pour grandes listes

---

### 5. DOUBLE CHARGEMENT DES DONNÉES (MOYENNE)
**Fichier:** `Molyseerr/Views/DiscoverView.swift:253-257`

**Problème:**
```swift
.onAppear {
    Task {
        await watchlistManager.loadWatchlist()
        await viewModel.fetchSliders(refresh: true)
    }
}
```

**Impact:**
- `.onAppear` peut être appelé plusieurs fois
- Pas de debouncing ou déduplication
- Requêtes redondantes

**Solution:**
- Ajouter un flag pour éviter double-load
- Débouncer les requêtes

---

### 6. MULTIPLES @FOCUSSTATE (MOYENNE)
**Fichier:** `Molyseerr/Views/MediaDetail/MovieDetailView.swift:17-19`

**Problème:**
```swift
@FocusState private var focusedCastID: Int?
@FocusState private var isCrewFocused: Bool
@FocusState private var isInfoFocused: Bool
```

**Impact:**
- tvOS focus engine doit gérer 3 états séparés
- Chaque changement trigger des recalculs de view
- Overhead de performance cumulatif

**Solution:**
- Centraliser avec un seul FocusState enum
- Réduire la complexité de l'arbre de vues

---

### 7. CONFIGURATION TOPSHELF SÉQUENTIELLE (MOYENNE)
**Fichier:** `Molyseerr/Views/TopShelfConfigView.swift:300-325`

**Problème:**
```swift
for item in items {
    let images = try await TMDBService.shared.getMovieImages(id: id)  // SÉQUENTIEL
    _ = try await TopShelfImageCompositor.shared.compositeImages(...) // SÉQUENTIEL
}
```

**Impact:**
- Cache TopShelf prend très longtemps
- Une erreur arrête tout le process
- Pas de parallélisation

**Solution:**
- Utiliser TaskGroup pour paralléliser
- Ajouter error recovery

---

## 📊 Meilleures Pratiques tvOS (2025)

### Sources de Recherche
- **Apple WWDC 2025:** "Optimize SwiftUI performance with Instruments"
- **Apple Documentation:** "Understanding and improving SwiftUI performance"
- **Community Research:** Medium, GitHub issues, Developer Forums

### Recommandations Clés

#### Performance SwiftUI Générale
1. **Minimiser les updates de view body**
   - Le body ne doit que décrire le layout, pas calculer
   - Déplacer la logique dans ViewModels

2. **Granulariser les states**
   - Éviter qu'un changement de state n'invalide toute la vue
   - Créer des sous-vues indépendantes

3. **Lazy views pour listes**
   - `LazyVStack`/`LazyHStack` pour grandes listes
   - ⚠️ Attention aux problèmes Kingfisher sur tvOS

4. **Éviter les effets visuels lourds**
   - `.shadow`, `.blur`, `.mask` sont coûteux sur GPU
   - Utiliser sparingly, jamais dans des listes qui scrollent

5. **Ne pas polluer l'Environment**
   - Éviter de stocker des valeurs qui changent souvent
   - Préférer @StateObject pour ownership clair

#### Kingfisher + tvOS Spécifique

**Problèmes connus:**
- ⚠️ `LazyVStack` + `KFImage` ne libère pas la mémoire correctement
- Les propriétés de KFImage ne sont pas deallocated jusqu'à destruction du stack entier
- `List` fonctionne mieux mais pas toujours possible

**Solutions recommandées:**
```swift
// 1. Downsampling pour réduire mémoire
KFImage(url)
    .setProcessor(DownsamplingImageProcessor(size: targetSize))

// 2. Cache limits
ImageCache.default.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024 // 100 MB

// 3. Placeholder avec taille fixe
KFImage(url)
    .placeholder {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 250, height: 375) // Même taille que l'image finale
    }
```

#### Instruments 26 (Nouveau en 2025)
- Outil dédié SwiftUI performance
- **Cause & Effect Graph:** Visualise les chaînes d'updates
- **Long View Body Updates:** Identifie les bodies trop lents
- **Unnecessary View Updates:** Détecte les invalidations excessives

---

## 🚀 Plan d'Optimisation

### Phase 1: Quick Wins (Impact Immédiat)

#### 1.1 Réduire la taille des images
- [ ] Changer `.original` → `w1280` pour backdrops
- [ ] Ajouter `DownsamplingImageProcessor` pour Kingfisher
- [ ] Configurer memory cache limits

**Impact attendu:** ⭐⭐⭐⭐
- Temps de chargement: -60%
- Mémoire utilisée: -80%
- Décodage GPU: -70%

#### 1.2 Paralléliser les appels API
- [ ] Remplacer boucles `for await` par `TaskGroup` dans `DiscoverView`
- [ ] Paralléliser `convertMediaInfoToResults()`
- [ ] Ajouter timeout et error handling

**Impact attendu:** ⭐⭐⭐⭐⭐
- Temps de chargement sliders: 4-8s → < 1s
- Amélioration immédiate de l'UX

#### 1.3 Optimiser les effets de focus
- [ ] Réduire l'intensité des shadows
- [ ] Ajouter `.compositingGroup()` sur MediaCardView
- [ ] Tester `.drawingGroup()` pour rasterisation

**Impact attendu:** ⭐⭐⭐
- Délai de focus: 1s → < 200ms
- Fluidité de navigation améliorée

---

### Phase 2: Optimisations Structurelles

#### 2.1 Améliorer le lazy loading
- [ ] Précharger les images des 3-5 items suivants
- [ ] Implémenter pagination pour sliders très longs
- [ ] Ajouter loading states progressifs

#### 2.2 Optimiser les ViewModels
- [ ] Éviter les double-loads (flag de déduplication)
- [ ] Débouncer les requêtes watchlist
- [ ] Cacher les données fetchées

#### 2.3 Profiling avec Instruments
- [ ] Utiliser SwiftUI Instrument (Instruments 26)
- [ ] Identifier "Long View Body Updates"
- [ ] Analyser avec Cause & Effect Graph

---

## 📈 Résultats Attendus

### Métriques Avant Optimisation
- ⏱️ Chargement slider: **4-8 secondes**
- ⏱️ Délai de focus: **~1 seconde**
- 💾 Mémoire images: **~50-100 MB** pour hero banner

### Métriques Cibles (Post Phase 1)
- ⏱️ Chargement slider: **< 1 seconde** (amélioration 80%)
- ⏱️ Délai de focus: **< 200ms** (amélioration 80%)
- 💾 Mémoire images: **< 20 MB** (amélioration 60-80%)

---

## 🔧 Outils de Debugging

### Instruments 26
```bash
# Profiler l'app
instruments -t "SwiftUI" -D ~/Desktop/perf.trace "Molyseerr.app"
```

### SwiftUI Debug
```swift
// Ajouter dans views pour debug
._printChanges() // Affiche pourquoi la view s'update
```

### Kingfisher Debug
```swift
// Activer logging
KingfisherManager.shared.defaultOptions = [
    .printCachingLog,
    .debugPrint
]
```

---

## 📝 Notes Techniques

### tvOS Memory Constraints
- Extensions: ~15-20 MB max
- App principale: Plus flexible mais surveiller
- Images décompressées: width × height × 4 bytes
  - Exemple 1280×720 JPEG = 3.5 MB décompressé en RAM

### SwiftUI View Lifecycle sur tvOS
- `.onAppear` peut être appelé plusieurs fois
- Focus state déclenche des re-renders fréquents
- LazyStacks ne garantissent pas le dealloc sur tvOS 18

### Kingfisher Best Practices
- Toujours utiliser des placeholders de taille fixe
- Downsampler pour images > 1 MB
- Memory cache limits obligatoires sur tvOS
- Considérer disk cache pour persistence

---

## 🎯 Prochaines Étapes

1. **Implémenter Phase 1** (Quick Wins)
2. **Tester sur device physique** (Apple TV HD + 4K)
3. **Profiler avec Instruments 26**
4. **Mesurer les améliorations**
5. **Documenter les résultats**
6. **Passer à Phase 2** si nécessaire

---

**Dernière mise à jour:** 3 Janvier 2026
**Responsable:** Claude Code
**Branche:** refactor/performance-improvements
