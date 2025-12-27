# Référence Seerr - Patterns et Fonctionnalités

Ce document compile les patterns importants extraits du code source de Seerr pour guider l'implémentation tvOS.

**Source:** `REDACTED_USER_PATH<Documents/GitHub/seerr/`

---

## 📊 Statuts des Médias (MediaStatus)

Basé sur: `@server/constants/media.ts`

Les médias dans Seerr ont plusieurs états possibles:

```typescript
enum MediaStatus {
  UNKNOWN = 1,
  PENDING = 2,      // Request en attente
  PROCESSING = 3,   // En cours de téléchargement
  PARTIALLY_AVAILABLE = 4,  // Partiellement disponible (séries)
  AVAILABLE = 5     // Disponible et prêt
}
```

### Affichage dans l'UI:
- **PENDING** → Badge orange "Pending"
- **PROCESSING** → Badge bleu "Processing"
- **PARTIALLY_AVAILABLE** → Badge vert "Partial"
- **AVAILABLE** → Badge vert "Available"

---

## 🎬 TitleCard Component

**Fichier:** `src/components/TitleCard/index.tsx`

### Propriétés importantes:
```typescript
interface TitleCardProps {
  id: number;
  image?: string;           // URL du poster
  summary?: string;         // Synopsis
  year?: string;           // Année (YYYY)
  title: string;
  userScore?: number;      // Note (0-10)
  mediaType: 'movie' | 'tv';
  status?: MediaStatus;
  canExpand?: boolean;     // Pour afficher les détails au hover
  inProgress?: boolean;    // Indicateur de chargement
  isAddedToWatchlist?: boolean;
}
```

### Comportements clés:
1. **Hover Effect:** Affiche les détails (résumé, année, note) sur hover
2. **Status Badge:** Petit badge en haut à gauche montrant le statut
3. **Watchlist Toggle:** Bouton pour ajouter/retirer de la watchlist
4. **Request Modal:** Ouvre la modale de requête au clic si non disponible

---

## 🎯 RequestButton Component

**Fichier:** `src/components/RequestButton/index.tsx`

### Logique des requêtes:

```typescript
interface RequestButtonProps {
  mediaType: 'movie' | 'tv';
  tmdbId: number;
  media?: Media;
  onUpdate: () => void;
  isShowComplete?: boolean;      // Si toute la série est complète
  is4kShowComplete?: boolean;    // Si toute la série est complète en 4K
}
```

### États du bouton:
1. **Non requesté** → Bouton "Request"
2. **Request pending** → "View Request" + options approve/decline (admin)
3. **Available** → "Request More" (pour les séries)
4. **4K Support** → Boutons séparés pour SD/4K

### Permissions:
- **User normal:** Peut faire des requêtes
- **Admin (`MANAGE_REQUESTS`):** Peut approuver/décliner

---

## 📋 RequestModal

**Fichier:** `src/components/RequestModal/index.tsx`

### Pour les films:
- Sélection de qualité (SD/4K)
- Sélection du serveur (Radarr/Sonarr)
- Soumission immédiate

### Pour les séries:
- Sélection des saisons
- Sélection des épisodes individuels (optionnel)
- Qualité par saison
- Serveur par saison

### Flow de requête:
```
1. User clique "Request"
2. Modal s'ouvre
3. User sélectionne options (saisons, qualité)
4. Submit → POST /api/v1/request
5. Status passe à PENDING
6. Admin approuve → Status passe à PROCESSING
7. Media disponible → Status passe à AVAILABLE
```

---

## 🎨 Design Patterns Seerr

### 1. Layout Principal
- **Sidebar** (gauche): Navigation
- **Main Content**: Grille de cartes ou détails
- **Top Bar**: Search, user menu, notifications

### 2. Discover Page (`pages/discover/index.tsx`)
- **Sliders horizontaux** par catégorie:
  - Trending
  - Popular Movies
  - Popular TV
  - Upcoming
- **Filtres**: Genre, année, note

### 3. Detail Page (`pages/movie/[movieId].tsx`, `pages/tv/[tvId].tsx`)
- **Hero Backdrop** en plein écran
- **Poster** + infos à gauche
- **Overview** + métadonnées
- **Request Button** proéminent
- **Cast horizontal scroll**
- **Similar/Recommended** en bas

### 4. StatusBadgeMini Component
Petit badge coloré affiché sur les TitleCards:
```tsx
<StatusBadgeMini status={MediaStatus.AVAILABLE} />
```

Couleurs:
- PENDING → `bg-yellow-500`
- PROCESSING → `bg-blue-500`
- AVAILABLE → `bg-green-500`
- PARTIALLY_AVAILABLE → `bg-green-400`

---

## 🔄 API Patterns

### Endpoints clés utilisés:

```typescript
// Get media details
GET /api/v1/movie/{tmdbId}
GET /api/v1/tv/{tmdbId}

// Create request
POST /api/v1/request
Body: {
  mediaType: 'movie' | 'tv',
  mediaId: number,
  seasons?: number[],
  is4k?: boolean,
  serverId?: number
}

// Manage request (admin)
POST /api/v1/request/{requestId}/approve
POST /api/v1/request/{requestId}/decline
DELETE /api/v1/request/{requestId}

// Watchlist
POST /api/v1/user/me/watchlist
DELETE /api/v1/user/me/watchlist/{tmdbId}

// Discover
GET /api/v1/discover/trending
GET /api/v1/discover/movies
GET /api/v1/discover/tv
```

---

## 🎯 Priorités d'implémentation tvOS

### Phase 1: Core Viewing
✅ Display trending/popular content
✅ Show media details
✅ Display media status (Available/Pending/Processing)

### Phase 2: Request Flow
- [ ] Request button with proper states
- [ ] Request modal (simplified for tvOS)
- [ ] Season/episode selection (TV)
- [ ] Status updates

### Phase 3: User Features
- [ ] Watchlist management
- [ ] Request history
- [ ] Notifications

### Phase 4: Admin (optional)
- [ ] Approve/decline requests
- [ ] Manage users

---

## 🎨 tvOS Adaptations

### Différences avec Web:
1. **No Hover:** Utiliser `.buttonStyle(.card)` et `@FocusState` au lieu de hover
2. **No Sidebar:** Utiliser TabView ou menu en overlay
3. **Large Touch Targets:** Minimum 250x375pt pour les posters
4. **Simplified Modals:** Pas de petites modales, utiliser des vues plein écran
5. **Remote Navigation:** Tout doit être accessible aux flèches directionnelles

### Composants tvOS équivalents:
- `TitleCard` → `MediaCardView` (avec focus effect)
- `RequestButton` → Button avec states dans `MediaDetailView`
- `StatusBadgeMini` → Badge dans metadataRow
- `RequestModal` → Full-screen sheet pour sélection

---

## 📝 Notes Importantes

1. **mediaInfo field:** Tous les détails (MovieDetails/TVDetails) contiennent un champ `mediaInfo` optionnel qui indique:
   - `status`: MediaStatus actuel
   - `requests`: Array de toutes les requêtes
   - `downloadStatus`: Array de downloads en cours

2. **4K Support:** Seerr supporte des requêtes séparées SD/4K. À simplifier pour MVP tvOS.

3. **Seasons handling:** Pour les séries, chaque saison peut avoir son propre statut et ses propres requêtes.

4. **Permissions:** Le système de permissions de Seerr est complexe. Pour MVP, simplifier à:
   - User: Peut voir et requêter
   - Admin: Peut approuver

---

## 🔗 Fichiers de référence importants

- `server/entity/Media.ts` - Modèle Media
- `server/entity/MediaRequest.ts` - Modèle Request
- `server/constants/media.ts` - Enums et constantes
- `src/components/TitleCard/index.tsx` - Carte média
- `src/components/RequestButton/index.tsx` - Logique de requête
- `src/pages/movie/[movieId].tsx` - Page détail film
- `src/pages/tv/[tvId].tsx` - Page détail série

---

**Dernière mise à jour:** 25 décembre 2024
