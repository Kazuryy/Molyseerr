# Deletion Requests Feature - Documentation

## Vue d'ensemble

La fonctionnalité **Deletion Requests** (Leaving Soon) permet aux utilisateurs de voter pour supprimer du contenu média de la bibliothèque Seerr. C'est une fonctionnalité collaborative où la communauté vote pour décider si un film ou une série TV doit être retiré.

Cette implémentation est un portage complet de la fonctionnalité web Seerr vers l'application Apple TV Molyseerr.

## Architecture

### Modèles de données

#### `DeletionRequest.swift`
- **DeletionRequestStatus**: Enum représentant les états possibles (pending, voting, approved, rejected, completed, cancelled)
- **DeletionRequest**: Modèle principal contenant toutes les informations sur une demande de suppression
  - Informations média (title, posterPath, backdropPath, mediaType)
  - Statistiques de vote (votesFor, votesAgainst, votePercentage)
  - Métadonnées (requestedBy, votingEndsAt, status)
  - Propriétés calculées (voteProgress, keepProgress, votingEndsAtFormatted)
- **DeletionVote**: Modèle représentant un vote individuel
- **CreateDeletionRequestBody**: Objet pour créer une nouvelle demande
- **DeletionVoteBody**: Objet pour voter
- **DeletionRequestsResponse**: Réponse paginée de l'API

#### `MediaListResponse.swift` (modifié)
- **CalendarItem**: Modèle utilisé pour les sorties du jour et le calendrier (déjà existant, amélioré avec posterURL, backdropURL, releaseDateFormatted)
- **CalendarDay**: Groupement par jour de calendrier
- **CalendarResponse**: Réponse API calendrier
- **WatchlistItem**: Élément de watchlist (amélioré avec Identifiable et displayId)

### Services API

#### Ajouts dans `SeerrService.swift`
Toutes les méthodes API nécessaires ont été ajoutées :

```swift
// Récupérer la liste paginée
func getDeletionRequests(take: Int, skip: Int, status: DeletionRequestStatus?) async throws -> DeletionRequestsResponse

// Récupérer une demande spécifique
func getDeletionRequest(id: Int) async throws -> DeletionRequest

// Vérifier si une demande existe pour un média
func checkDeletionRequest(mediaId: Int, mediaType: String) async throws -> DeletionRequest?

// Créer une demande de suppression
func createDeletionRequest(_ body: CreateDeletionRequestBody) async throws -> DeletionRequest

// Voter (true = supprimer, false = conserver)
func voteDeletionRequest(deletionRequestId: Int, vote: Bool) async throws -> DeletionVote

// Retirer son vote
func removeVoteDeletionRequest(deletionRequestId: Int) async throws

// Obtenir son vote actuel
func getMyDeletionVote(deletionRequestId: Int) async throws -> DeletionVote?

// Exécuter la suppression (admin uniquement)
func executeDeletionRequest(deletionRequestId: Int) async throws -> DeletionRequest

// Annuler la demande
func cancelDeletionRequest(deletionRequestId: Int) async throws -> DeletionRequest
```

### ViewModels

#### `DeletionRequestsViewModel.swift`
ViewModel principal gérant :
- Chargement des demandes de suppression (paginé, filtré par status)
- Chargement des demandes en cours de vote (pour le slider)
- Gestion des votes (pour/contre/retirer)
- Actions administrateur (exécuter, annuler)
- Cache local des votes utilisateur
- Gestion d'erreurs

**Propriétés publiées:**
- `deletionRequests`: Liste complète des demandes
- `votingRequests`: Demandes en cours de vote (pour slider)
- `isLoading`, `isVotingLoading`: États de chargement
- `errorMessage`: Message d'erreur
- `currentFilter`: Filtre actuel (status)
- `userVotes`: Map des votes utilisateur

### Composants UI

#### 1. `DeletionSliderCard.swift`
Carte compacte pour le slider horizontal sur la page Discover.

**Caractéristiques:**
- Taille: 640x360
- Image de fond (backdrop) avec gradient
- Badge de statut coloré
- Titre et temps restant pour voter
- Barre de progression (vert = conserver, rouge = supprimer)
- Boutons de vote (Keep/Remove)
- Support du Focus Engine tvOS
- Animation de focus (scale + shadow)

#### 2. `DeletionRequestCard.swift`
Carte détaillée pour la liste complète.

**Caractéristiques:**
- Hauteur: 320px
- Layout horizontal en 3 sections:
  - **Gauche**: Poster + titre + raison + demandeur
  - **Centre**: Temps restant + barre de progression + statistiques de vote + statut de vote utilisateur
  - **Droite**: Boutons d'action
- Actions disponibles:
  - Vote Keep/Remove (si voting actif)
  - Clear Vote (si déjà voté)
  - Execute (admin, si approuvé)
  - Cancel (admin/demandeur, si pending/voting)

#### 3. `DeletionRequestsRow.swift`
Row horizontale pour la page Discover.

**Caractéristiques:**
- Titre: "Voting Now - Leaving Soon"
- Lien "View All" vers la liste complète
- Scroll horizontal des demandes en cours de vote
- États: Loading, Empty, Content
- Empty state: "No content is currently up for removal"

#### 4. `DeletionRequestsListView.swift`
Vue de liste complète avec filtres.

**Caractéristiques:**
- En-tête avec titre et description
- Barre de filtres (All, Voting, Approved, Rejected, Completed, Cancelled)
- Liste verticale de cartes détaillées
- Pagination ("Load More")
- États: Loading, Empty, Content, Error
- Navigation vers détails

## Intégration

### Dans `DiscoverView.swift` - Gestion dynamique via sliders

La fonctionnalité Deletion Requests est **gérée dynamiquement** via le système de sliders configurables de Seerr :

1. **Configuration serveur** : L'administrateur active/désactive le slider "Deletion Requests" (type 22) dans les paramètres Seerr
2. **Position dynamique** : Le slider apparaît à la position définie par l'ordre dans la configuration
3. **Détection automatique** : `DiscoverSliderRow` détecte le type `deletionRequests` et affiche `DeletionRequestsRow`

```swift
// Dans loadSliderContent()
if slider.type == .deletionRequests {
    // Set flag to display DeletionRequestsRow (which manages its own data)
    showDeletionRequests = true
    print("✅ Showing Deletion Requests slider")
    isLoading = false
}

// Dans body
else if showDeletionRequests {
    // Display Deletion Requests with custom row
    DeletionRequestsRow()
}
```

**Avantages de cette approche :**
- ✅ Activation/désactivation depuis les paramètres Seerr
- ✅ Position configurable dans l'ordre des sliders
- ✅ Cohérent avec les autres sliders (Today's Releases, etc.)
- ✅ Pas de code hardcodé dans la vue principale
- ✅ **Masquage automatique** : Le slider disparaît automatiquement s'il n'y a aucun vote en cours

### Comportement de masquage automatique

Le composant `DeletionRequestsRow` implémente une logique intelligente de visibilité :

```swift
var body: some View {
    Group {
        // Only show if there are voting requests or still loading
        if viewModel.isVotingLoading || !viewModel.votingRequests.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                // Content...
            }
        }
    }
}
```

**États d'affichage :**
- ⏳ **Loading** : Affiche des placeholders pendant le chargement
- ✅ **Votes actifs** : Affiche le slider avec les demandes en cours de vote
- 🚫 **Aucun vote** : Le slider est **complètement masqué** (pas d'empty state visible)

Cela évite d'encombrer l'interface avec un slider vide et améliore l'UX.

## Design tvOS

Tous les composants respectent les règles de [TECH_RULES.md](../TECH_RULES.md):

### Focus Engine
✅ Utilisation de `Button` et `.focusable()`
✅ Pas de `onTapGesture`
✅ Navigation avec les flèches directionnelles

### Feedback Visuel
✅ `.scaleEffect(isFocused ? 1.05 : 1.0)`
✅ `.shadow(color: isFocused ? .white.opacity(0.3) : .clear)`
✅ `.animation(.easeInOut(duration: 0.2))`

### Images
✅ Utilisation de **Kingfisher** (`KFImage`)
✅ Pas d'`AsyncImage`
✅ Tailles TMDB appropriées (w500 pour posters, w1280 pour backdrops)

### Layout
✅ Safe area: 90px horizontal padding
✅ Composants horizontaux scrollables (`LazyHStack`)
✅ Design inspiré d'Apple TV+

## Flux utilisateur

### 1. Découverte
L'utilisateur navigue sur la page **Discover** et voit la section "Voting Now - Leaving Soon" si des demandes sont actives.

### 2. Consultation
L'utilisateur peut:
- Consulter les demandes dans le slider horizontal
- Cliquer sur "View All" pour voir toutes les demandes
- Filtrer par statut (All, Voting, Approved, etc.)

### 3. Vote
L'utilisateur peut voter:
- **Keep** (vote contre la suppression) - bouton vert
- **Remove** (vote pour la suppression) - bouton rouge
- **Clear Vote** pour retirer son vote

### 4. Feedback visuel
- Badge coloré selon le statut
- Barre de progression vert/rouge
- Compteur de temps restant
- Indication du vote utilisateur

### 5. Administration (si admin)
- **Execute**: Exécuter la suppression (si approuvée)
- **Cancel**: Annuler la demande

## États et couleurs

### Status Badge Colors
| Status | Color | Signification |
|--------|-------|---------------|
| Pending | Gray | En attente |
| Voting | Blue | Vote en cours |
| Approved | Green | Approuvé |
| Rejected | Red | Rejeté |
| Completed | Purple | Complété |
| Cancelled | Orange | Annulé |

### Vote Progress
- **Vert**: Votes "Keep" (conserver)
- **Rouge**: Votes "Remove" (supprimer)

## Sémantique des votes

⚠️ **Important**: La sémantique peut sembler inversée dans le code backend:
- `vote: true` = Vote POUR la suppression (Remove)
- `vote: false` = Vote CONTRE la suppression (Keep)

Dans l'UI, nous présentons cela de manière claire:
- Bouton **Keep** (vert) → envoie `vote: false`
- Bouton **Remove** (rouge) → envoie `vote: true`

## Endpoints API utilisés

Tous les endpoints sont sous `/api/v1/deletion`:

```
GET    /deletion                    - Liste paginée
GET    /deletion/:id                - Détails
GET    /deletion/check/:mediaId     - Vérifier existence
POST   /deletion                    - Créer demande
POST   /deletion/:id/vote           - Voter
DELETE /deletion/:id/vote           - Retirer vote
GET    /deletion/:id/vote/me        - Mon vote
POST   /deletion/:id/execute        - Exécuter (admin)
POST   /deletion/:id/cancel         - Annuler
```

## Tests recommandés

1. **Chargement initial**
   - Vérifier que les demandes en cours de vote s'affichent
   - Tester les états vides (no content)

2. **Vote**
   - Voter Keep
   - Voter Remove
   - Changer de vote
   - Retirer son vote

3. **Navigation**
   - Slider horizontal avec Focus Engine
   - Navigation vers liste complète
   - Filtres de statut

4. **Filtres**
   - Tous les statuts
   - Pagination

5. **États**
   - Loading
   - Empty
   - Error
   - Content

6. **Admin (si applicable)**
   - Execute deletion
   - Cancel request

## Fichiers créés

```
Molyseerr/
├── Models/
│   ├── DeletionRequest.swift          ✅ Nouveau
│   └── MediaListResponse.swift        ✏️ Modifié (ajout helpers CalendarItem/WatchlistItem)
├── ViewModels/
│   └── DeletionRequestsViewModel.swift ✅ Nouveau
├── Views/
│   ├── DeletionRequestsListView.swift ✅ Nouveau
│   └── Components/
│       ├── DeletionRequestCard.swift  ✅ Nouveau
│       ├── DeletionSliderCard.swift   ✅ Nouveau
│       └── DeletionRequestsRow.swift  ✅ Nouveau
└── Services/
    └── SeerrService.swift             ✏️ Modifié (ajout méthodes)
```

## Fichiers modifiés

```
Molyseerr/
├── Models/
│   └── MediaListResponse.swift        ✏️ Ajout helpers pour CalendarItem et WatchlistItem
├── Views/
│   └── DiscoverView.swift             ✏️ Ajout DeletionRequestsRow
└── Services/
    └── SeerrService.swift             ✏️ Ajout endpoints Deletion
```

## Prochaines étapes possibles

1. **Créer une demande de suppression**
   - Ajouter un bouton dans `MediaDetailView`
   - Modal avec champ raison (500 caractères max)
   - Vérifier les permissions

2. **Notifications**
   - Intégrer les notifications push quand vote commence/termine
   - Badge sur l'icône de l'app

3. **Paramètres admin**
   - Vue de configuration dans Settings
   - Durée du vote, pourcentage requis, auto-delete, etc.

4. **Optimisations**
   - Cache des demandes
   - Refresh pull-to-refresh
   - Infinite scroll

## Références

- **Source web**: Local Seerr repository
- **API Documentation**: Seerr API `seerr-api.yml`
- **Design Reference**: [docs/APPLE_TV_DESIGN_REFERENCE.md](APPLE_TV_DESIGN_REFERENCE.md)
- **Technical Rules**: [TECH_RULES.md](../TECH_RULES.md)

---

**Auteur**: Claude
**Date**: 27 décembre 2025
**Version**: 1.0.0
