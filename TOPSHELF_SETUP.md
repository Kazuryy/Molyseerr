# TopShelf Extension Setup Guide

Ce guide explique comment configurer l'extension TopShelf pour Molyseerr dans Xcode.

## 📋 Vue d'ensemble

L'extension TopShelf permet d'afficher du contenu dynamique sur l'écran d'accueil tvOS lorsque Molyseerr est en focus.

**Fonctionnalités :**
- ✅ Affichage en mode Hero (style Apple TV+) avec backdrops plein écran
- ✅ Affichage en mode Sectioned (style Netflix) avec posters scrollables
- ✅ Sources de contenu configurables (Trending, Popular Movies, Popular TV, Watchlist)
- ✅ 6 éléments maximum affichés
- ✅ Appels TMDB directs (pas de dépendance Seerr)
- ✅ Cache d'images optimisé
- ✅ Deep links vers l'app

## 🛠️ Configuration dans Xcode

### Étape 1 : Créer le Target TopShelf Extension

1. Ouvrez le projet `Molyseerr.xcodeproj` dans Xcode
2. Dans le navigateur de projet, sélectionnez le projet Molyseerr
3. Cliquez sur le bouton `+` en bas de la liste des targets
4. Choisissez `tvOS` → `TV Services Extension`
5. Configurez l'extension :
   - **Product Name:** `Molyseerr TopShelf`
   - **Organization Identifier:** `com.molycorp.Sir-Seerr`
   - **Bundle Identifier:** `com.molycorp.Sir-Seerr.Molyseerr-TopShelf`
   - **Language:** Swift
6. Cliquez sur `Finish`
7. **Ne pas** activer le scheme quand Xcode le propose

### Étape 2 : Ajouter les fichiers au Target

Les fichiers suivants ont déjà été créés dans le dossier `Molyseerr TopShelf/` :
- `ContentProvider.swift` - Provider principal
- `TopShelfSettings.swift` - Settings partagés
- `TopShelfImageCache.swift` - Cache d'images
- `Info.plist` - Configuration de l'extension

**Dans Xcode :**
1. Supprimez le fichier `ServiceProvider.swift` généré automatiquement
2. Faites glisser les fichiers du dossier `Molyseerr TopShelf/` dans le target TopShelf dans Xcode
3. Assurez-vous que tous les fichiers sont bien associés au target `Molyseerr TopShelf`

### Étape 3 : Créer l'App Group

**Important :** Les App Groups permettent de partager des données entre l'app principale et l'extension.

1. Sélectionnez le target `Molyseerr` (l'app principale)
2. Allez dans l'onglet `Signing & Capabilities`
3. Cliquez sur `+ Capability`
4. Ajoutez `App Groups`
5. Cliquez sur `+` et créez un nouveau groupe :
   - **Identifier:** `group.com.molycorp.Molyseerr.shared`
6. Répétez les étapes 1-5 pour le target `Molyseerr TopShelf`
7. Assurez-vous que les deux targets utilisent le même App Group ID

### Étape 4 : Ajouter les fichiers partagés

Certains fichiers doivent être partagés entre l'app et l'extension :

1. Sélectionnez `TMDBService.swift`
2. Dans le File Inspector (panel de droite), cochez `Molyseerr TopShelf` dans la section `Target Membership`
3. Répétez pour ces fichiers :
   - `TMDBImageHelper.swift`
   - `TopShelfSettings.swift`
   - `TopShelfImageCache.swift`

### Étape 5 : Configurer le Bundle Identifier

1. Sélectionnez le target `Molyseerr TopShelf`
2. Dans l'onglet `General`, vérifiez que le Bundle Identifier est :
   ```
   com.molycorp.Sir-Seerr.Molyseerr-TopShelf
   ```
3. Assurez-vous que la version et le build number correspondent à ceux de l'app principale

### Étape 6 : Configurer les URL Schemes (Deep Links)

Pour que les liens depuis TopShelf ouvrent l'app :

1. Sélectionnez le target `Molyseerr` (l'app principale)
2. Allez dans l'onglet `Info`
3. Développez `URL Types`
4. Ajoutez un nouveau URL Type :
   - **Identifier:** `molyseerr`
   - **URL Schemes:** `molyseerr`
   - **Role:** `Editor`

### Étape 7 : Gérer les Deep Links dans l'app

Ajoutez ce code dans `MolyseerrApp.swift` :

```swift
.onOpenURL { url in
    handleDeepLink(url)
}

private func handleDeepLink(_ url: URL) {
    // molyseerr://media/movie/123
    // molyseerr://media/tv/456
    guard url.scheme == "molyseerr" else { return }

    let pathComponents = url.pathComponents
    if pathComponents.count >= 3 && pathComponents[1] == "media" {
        let mediaType = pathComponents[2]
        if let mediaId = Int(pathComponents[3]) {
            // Navigate to media detail
            // TODO: Implement navigation
        }
    }
}
```

### Étape 8 : Build Settings

**IMPORTANT :** Vérifiez ces settings pour le target TopShelf :

1. **Deployment Target:** tvOS 15.0 ou supérieur
2. **Enable Bitcode:** No
3. **Minimum Deployment:** Doit correspondre à l'app principale

## 🧪 Test de l'extension

### Build & Run

1. Sélectionnez le scheme `Molyseerr` (pas TopShelf)
2. Build et lancez sur un simulateur tvOS ou un Apple TV physique
3. Quittez l'app (Menu > Home)
4. Naviguez vers l'icône Molyseerr sur l'écran d'accueil
5. Le TopShelf devrait s'afficher au-dessus avec les trending items

### Debugging

Pour debugger l'extension :
1. Lancez l'app principale
2. Dans Xcode : `Debug` → `Attach to Process by PID or Name`
3. Entrez `Molyseerr TopShelf`
4. L'extension se lancera la prochaine fois que tvOS la chargera

### Logs

Les logs de l'extension apparaissent dans la console Xcode avec le préfixe `[TopShelf]`.

## ⚙️ Configuration utilisateur

Les utilisateurs peuvent configurer le TopShelf depuis `Settings` dans l'app :

### Display Mode
- **Hero (Apple TV+ Style)** - Backdrops plein écran, mode carousel
- **Sectioned (Netflix Style)** - Posters en grille avec sections

### Content Source
- **Trending** - Trending movies & TV de la semaine (par défaut)
- **Popular Movies** - Films populaires
- **Popular TV Shows** - Séries populaires
- **My Watchlist** - Watchlist de l'utilisateur (TODO)

## 📝 Notes importantes

### Cache d'images
- Les images sont téléchargées et mises en cache localement dans l'App Group
- Le cache est partagé entre l'app et l'extension
- Les images sont en format JPG pour économiser l'espace

### Limites de mémoire
- Les extensions tvOS ont une limite stricte de ~30MB de mémoire
- C'est pourquoi on limite à 6 items maximum
- Les images sont téléchargées et cachées de manière asynchrone

### Mise à jour du contenu
- L'extension se met à jour automatiquement en arrière-plan
- tvOS contrôle la fréquence des mises à jour (généralement toutes les heures)
- L'app peut forcer une mise à jour via `TVTopShelfContentProvider.topShelfContentDidChange()`

### Deep Links
- Format : `molyseerr://media/{type}/{id}`
- `type` : "movie" ou "tv"
- `id` : TMDB ID du media
- L'app doit implémenter la navigation vers le détail du media

## 🔧 Troubleshooting

### TopShelf ne s'affiche pas
1. Vérifiez que l'extension est bien buildée avec l'app
2. Vérifiez que l'App Group est correctement configuré
3. Redémarrez le simulateur ou l'Apple TV
4. Vérifiez les logs dans la console Xcode

### Images ne se chargent pas
1. Vérifiez la connexion internet
2. Vérifiez que l'App Group est accessible
3. Vérifiez les permissions du cache directory
4. Regardez les logs pour les erreurs de téléchargement

### Deep links ne fonctionnent pas
1. Vérifiez que l'URL Scheme est configuré
2. Vérifiez que `.onOpenURL` est bien appelé
3. Testez avec `xcrun simctl openurl booted molyseerr://media/movie/550`

## 🚀 Prochaines étapes

- [ ] Implémenter la navigation Deep Link dans l'app
- [ ] Ajouter le support Watchlist (sync via App Group)
- [ ] Ajouter plus de sources (Recently Added, Upcoming, etc.)
- [ ] Optimiser le cache d'images (taille max, expiration)
- [ ] Ajouter des analytics pour tracker l'utilisation du TopShelf

## 📚 Ressources

- [Apple TV Services Documentation](https://developer.apple.com/documentation/tvservices)
- [TVTopShelfProvider Reference](https://developer.apple.com/documentation/tvservices/tvtopshelfprovider)
- [App Groups Documentation](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups)
