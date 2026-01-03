# Molyseerr TopShelf Extension

Extension tvOS pour afficher du contenu dynamique sur l'écran d'accueil.

## 📁 Fichiers

- **ContentProvider.swift** - Provider principal qui fournit le contenu TopShelf
- **TopShelfSettings.swift** - Gestion des settings partagés via App Group
- **TopShelfImageCache.swift** - Cache local d'images pour l'extension
- **Info.plist** - Configuration de l'extension
- **Molyseerr TopShelf.entitlements** - Entitlements pour App Group

## 🎨 Modes d'affichage

### Hero Mode (Par défaut)
Style Apple TV+ avec backdrops plein écran en carousel. Les images occupent tout l'espace disponible avec titre et description superposés.

### Sectioned Mode
Style Netflix avec posters en grille scrollable. Affiche une section avec titre et plusieurs items.

## 📊 Sources de contenu

- **Trending** (Par défaut) - Trending de la semaine via TMDB direct
- **Popular Movies** - Films populaires
- **Popular TV Shows** - Séries populaires
- **Watchlist** - Watchlist de l'utilisateur (TODO)

## 🔧 Configuration

Les utilisateurs peuvent configurer le TopShelf dans **Settings** > **TopShelf (Home Screen)**.

Les paramètres sont automatiquement synchronisés entre l'app et l'extension via UserDefaults avec App Group.

## 🚀 Setup

Voir [TOPSHELF_SETUP.md](../TOPSHELF_SETUP.md) pour les instructions complètes de configuration dans Xcode.

## 🔗 Deep Links

Format : `molyseerr://media/{type}/{id}`
- `type` : "movie" ou "tv"
- `id` : TMDB ID

Ces liens permettent d'ouvrir directement un media depuis TopShelf.

## 💾 Cache

Les images sont téléchargées et mises en cache dans :
```
App Group Container/TopShelfCache/
```

Le cache est partagé entre l'app principale et l'extension pour économiser l'espace.

## 📝 Notes techniques

- Limite de 6 items pour respecter la contrainte mémoire (~30MB)
- Images téléchargées de manière asynchrone
- Mise à jour automatique en arrière-plan (contrôlée par tvOS)
- Appels TMDB directs (pas de dépendance Seerr)
