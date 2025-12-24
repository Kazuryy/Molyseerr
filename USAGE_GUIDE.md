# Sir Seerr - Data Layer Usage Guide

## Configuration initiale

### 1. Ajouter Kingfisher (Swift Package Manager)

Dans Xcode :
1. File → Add Package Dependencies...
2. URL : `https://github.com/onevcat/Kingfisher.git`
3. Version : "Up to Next Major Version" avec `8.0.0`
4. Sélectionner la target "Sir Seerr"

### 2. Configurer l'API

```swift
// Dans votre AppDelegate ou au démarrage de l'app
let service = SeerrService.shared

// Configurer l'URL de base (défaut: http://localhost:5055)
service.setBaseURL("https://votre-serveur-seerr.com")

// Configurer la clé API (TEMPORAIRE pour MVP)
service.setApiKey("VOTRE_CLE_API_ICI")
```

## Utilisation du Service API

### Récupérer les contenus tendances

```swift
Task {
    do {
        let trending = try await SeerrService.shared.getTrending(page: 1)
        print("Total résultats: \(trending.totalResults)")

        for media in trending.results {
            print("- \(media.title)")

            // Accéder au statut (CRITIQUE pour la logique des boutons)
            if let mediaInfo = media.mediaInfo {
                print("  Statut: \(mediaInfo.status.displayText)")
            }
        }
    } catch {
        print("Erreur: \(error.localizedDescription)")
    }
}
```

### Découvrir des films

```swift
Task {
    do {
        let movies = try await SeerrService.shared.discoverMovies(
            page: 1,
            sortBy: "popularity.desc",
            genre: 28  // Action (optionnel)
        )

        for movie in movies.results {
            print("Film: \(movie.title)")

            // URL du poster (pour Kingfisher)
            if let posterURL = SeerrConfig.imageURL(path: movie.posterPath) {
                // Utiliser avec KFImage dans SwiftUI
            }
        }
    } catch {
        print("Erreur: \(error.localizedDescription)")
    }
}
```

### Découvrir des séries TV

```swift
Task {
    do {
        let shows = try await SeerrService.shared.discoverTV(
            page: 1,
            sortBy: "popularity.desc"
        )

        for show in shows.results {
            print("Série: \(show.name)")
        }
    } catch {
        print("Erreur: \(error.localizedDescription)")
    }
}
```

### Obtenir les détails d'un film

```swift
Task {
    do {
        let movie = try await SeerrService.shared.getMovieDetails(id: 550) // Fight Club

        print("Titre: \(movie.title)")
        print("Synopsis: \(movie.overview ?? "")")
        print("Note: \(movie.voteAverage ?? 0)/10")

        // Informations critiques pour la logique métier
        if let mediaInfo = movie.mediaInfo {
            print("Statut: \(mediaInfo.status)")
            print("Requests: \(mediaInfo.requests?.count ?? 0)")
        }

        // Cast
        if let cast = movie.credits?.cast?.prefix(5) {
            for actor in cast {
                print("- \(actor.name) as \(actor.character ?? "")")
            }
        }
    } catch {
        print("Erreur: \(error.localizedDescription)")
    }
}
```

### Créer une requête de média

```swift
Task {
    do {
        let requestBody = MediaRequestBody(
            mediaType: .movie,
            mediaId: 550,  // TMDB ID
            seasons: nil,  // Seulement pour les séries
            is4k: false,
            serverId: nil,
            profileId: nil,
            rootFolder: nil
        )

        let request = try await SeerrService.shared.createRequest(requestBody)
        print("Requête créée avec succès! ID: \(request.id)")
        print("Statut: \(request.status)")
    } catch let error as SeerrError {
        switch error {
        case .unauthorized:
            print("Erreur: Clé API invalide")
        case .forbidden:
            print("Erreur: Permissions insuffisantes")
        default:
            print("Erreur: \(error.localizedDescription)")
        }
    } catch {
        print("Erreur: \(error.localizedDescription)")
    }
}
```

### Récupérer les requêtes de l'utilisateur

```swift
Task {
    do {
        let requests = try await SeerrService.shared.getRequests(
            skip: 0,
            take: 20,
            filter: "pending"  // "all", "approved", "pending", "processing", "available"
        )

        print("Total: \(requests.pageInfo.results) requêtes")

        for request in requests.results {
            if let media = request.media {
                print("Requête #\(request.id) - TMDB ID: \(media.tmdbId)")
            }
        }
    } catch {
        print("Erreur: \(error.localizedDescription)")
    }
}
```

### Rechercher du contenu

```swift
Task {
    do {
        let results = try await SeerrService.shared.search(
            query: "Breaking Bad",
            page: 1
        )

        for media in results.results {
            print("Résultat: \(media.title)")
        }
    } catch {
        print("Erreur: \(error.localizedDescription)")
    }
}
```

## Exemple d'utilisation dans un ViewModel (MVVM)

```swift
import SwiftUI

@MainActor
class TrendingViewModel: ObservableObject {
    @Published var movies: [MediaResult] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = SeerrService.shared

    func loadTrending() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let response = try await service.getTrending(page: 1)
                self.movies = response.results
            } catch let error as SeerrError {
                self.errorMessage = error.localizedDescription
            } catch {
                self.errorMessage = "Erreur inconnue"
            }

            self.isLoading = false
        }
    }
}
```

## Logique de Statut (CRITIQUE)

Selon `TVOS_ARCH_SPEC.md Section 2.2`, voici comment déterminer l'affichage des boutons :

```swift
func determineButtonDisplay(mediaInfo: MediaInfo?) -> ButtonState {
    guard let mediaInfo = mediaInfo else {
        return .requestButton  // Pas encore demandé
    }

    switch mediaInfo.status {
    case .unknown, .deleted:
        return .requestButton
    case .pending:
        return .pendingBadge
    case .processing:
        return .processingBadge
    case .available, .partiallyAvailable:
        return .availableBadge
    case .blacklisted:
        return .blacklistedBadge
    }
}

enum ButtonState {
    case requestButton
    case pendingBadge
    case processingBadge
    case availableBadge
    case blacklistedBadge
}
```

## URLs des Images (TMDB)

```swift
// Poster pour une grille (500px)
let posterURL = SeerrConfig.imageURL(path: movie.posterPath, size: .poster)

// Backdrop pour le fond d'écran (qualité originale)
let backdropURL = SeerrConfig.imageURL(path: movie.backdropPath, size: .backdrop)

// Utilisation avec Kingfisher dans SwiftUI
KFImage(posterURL)
    .placeholder {
        Color.gray
    }
    .resizable()
    .aspectRatio(2/3, contentMode: .fit)
```

## Gestion des Erreurs

Toutes les méthodes du service peuvent lever des `SeerrError` :

```swift
do {
    let movies = try await service.discoverMovies()
} catch SeerrError.unauthorized {
    // Clé API invalide
} catch SeerrError.forbidden {
    // Permissions insuffisantes
} catch SeerrError.notFound {
    // Ressource non trouvée
} catch SeerrError.networkError(let error) {
    // Erreur réseau
} catch SeerrError.decodingError(let error) {
    // Erreur de décodage JSON
} catch {
    // Autre erreur
}
```

## Prochaines Étapes

Cette couche de données est maintenant prête. Les prochaines phases seront :

- **Phase 2** : ViewModels (MVVM) pour gérer l'état
- **Phase 3** : Vues SwiftUI avec support du Focus Engine
- **Phase 4** : Navigation et Tab Bar tvOS
- **Phase 5** : Intégration Kingfisher et optimisations

**Important** : Ne pas créer de vues SwiftUI maintenant. La logique de données doit être testée d'abord.
