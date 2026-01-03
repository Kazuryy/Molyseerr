# Molyseerr - Roadmap de développement

**Mise à jour:** 3 Janvier 2026
**Version actuelle:** 0.2.0 (MVP avancé)

---

## 🎯 Vision

Client tvOS natif pour Overseerr/Jellyseerr (Seerr) qui combine:
- L'UX d'Apple TV+ (navigation fluide, design moderne)
- Les fonctionnalités de Seerr (découverte, requêtes, gestion de watchlist)
- Une expérience 100% native tvOS

---

## ✅ Réalisations récentes

### Phase 0 & 1: Foundation + Core Features (COMPLÉTÉ)
- [x] Architecture MVVM complète
- [x] Intégration Kingfisher pour images
- [x] Hero banner avec trending content
- [x] Page Discover avec sliders dynamiques
- [x] Page MediaDetail complète avec actions
- [x] System de requêtes fonctionnel
- [x] Watchlist management
- [x] Page Requests avec filtres
- [x] Page Search
- [x] Navigation TabView
- [x] **TopShelf Extension** (Janvier 2026)
  - [x] Configuration et setup
  - [x] Cache d'images optimisé avec ImageIO
  - [x] Hero carousel avec backdrops
  - [x] Deep linking vers l'app
  - [x] Gestion mémoire pour device physique

---

## 🚧 Tâches en cours / À venir

### Configuration & Optimisation

- [ ] **Configuration du Hero de la page Discover**
  - Identifier la source des données (trending vs featured)
  - Permettre customisation via settings
  - Support multi-sources (Trending, Popular, Watchlist)

- [ ] **Mappage TopShelf vers éléments de l'app**
  - Deep linking fonctionnel (molyseerr://media/tv/{id})
  - Navigation directe vers MediaDetail depuis TopShelf
  - Sync des settings TopShelf avec l'app principale

- [ ] **Optimisation de la page Discover**
  - Performance du chargement des sliders
  - Lazy loading intelligent
  - Cache des données discover
  - Gestion des erreurs réseau améliorée

- [ ] **Clean du lancement de l'app**
  - Splash screen optimisé
  - Loading states cohérents
  - Gestion des premiers lancements
  - Vérification de la connexion serveur

### Permissions & Sécurité

- [ ] **Support des permissions basé sur l'API**
  - Détection du niveau de permission utilisateur
  - UI adaptée selon les droits (admin, user, request-only)
  - Gestion des actions non autorisées
  - Messages d'erreur contextuels

### Internationalisation

- [ ] **Support du multi-language**
  - Localisation FR/EN minimum
  - String catalogs SwiftUI
  - Traductions des genres/catégories
  - Format des dates selon locale

- [ ] **Support des régions/langues Seerr**
  - Sync avec les préférences Seerr WebApp
  - Découverte de contenu selon région
  - Affichage du contenu dans la langue préférée

### UI/UX Improvements

- [ ] **Clean de la page Profile**
  - Réorganisation des informations
  - Stats utilisateur (requests, watchlist size)
  - Historique d'activité
  - Design cohérent avec Apple TV+

- [ ] **Clean de la page Details**
  - Optimisation du layout
  - Better loading states
  - Animations améliorées
  - Cast & Crew section enrichie

- [ ] **Amélioration de la page Login**
  - Sélection de l'user si déjà enregistré
  - Option pour retirer un user
  - Multiple profiles management
  - Remember me option
  - QR code login (optionnel)

### Navigation & Structure

- [ ] **Réorganisation du menu**
  - Déplacer Profile en haut du menu burger
  - Renommer "TVShows" → "Series"
  - Icônes cohérentes
  - Keyboard shortcuts

---

## 🎨 Phase 3: Features avancées (EN COURS)
- [ ] Tab 1: Home (actuel)
- [ ] Tab 2: Search
- [ ] Tab 3: Requests (mes requêtes)
- [ ] Tab 4: Settings
- [ ] Icônes SF Symbols pour chaque tab

**Estimation:** 1 jour
**Fichiers:** `MolyserrApp.swift`, nouveau `MainTabView.swift`

---

### 2.2 Page Search
**Pourquoi?** Découverte active du contenu

- [ ] Créer `SearchView.swift` + ViewModel
- [ ] Barre de recherche tvOS (keyboard)
- [ ] Résultats en grille
- [ ] Filtres: Movies / TV / All
- [ ] Navigation vers détails

**Estimation:** 2 jours

---

### 2.3 Page Requests
**Pourquoi?** Suivi des demandes en cours

- [ ] Créer `RequestsView.swift` + ViewModel
- [ ] Liste des requêtes avec filtres (All, Pending, Approved, Available)
- [ ] Statut visuel clair
- [ ] Pull-to-refresh
- [ ] Action: Cancel request

**Estimation:** 1-2 jours

---

### 2.4 Page Settings
**Pourquoi?** Configuration serveur, logout, préférences

- [ ] Créer `SettingsView.swift`
- [ ] Afficher server URL, user info
- [ ] Bouton déconnexion
- [ ] Préférences: Language, Quality (4K toggle)
- [ ] About section (version, credits)

**Estimation:** 1 jour

---

## 🎨 Phase 3: Polish & Features avancées (PRIORITÉ BASSE)

### 3.1 Améliorations Hero Banner
- [ ] Pagination dots (plusieurs featured items)
- [ ] Auto-rotate toutes les 10s
- [ ] Intégrer trailers video (optionnel)
- [ ] Logo image au lieu de texte

**Estimation:** 2 jours

---

### 3.2 Continue Watching
**Pourquoi?** Feature signature d'Apple TV+

- [ ] Endpoint Seerr pour "Continue Watching"
- [ ] Row dédiée après hero banner
- [ ] Cards 16:9 (backdrop) avec progress bar
- [ ] Update du progress via Seerr

**Estimation:** 2-3 jours

---

### 3.3 Genres & Filtres
- [ ] Page "Genres" avec grilles
- [ ] Filtres avancés (année, rating, etc.)
- [ ] Collections TMDB

**Estimation:** 3 jours

---

### 3.4 TopShelf Extension (⚠️ DEBUGGING EN COURS)
**Status:** Extension créée mais écran noir sur device physique

**Problème identifié:**
- Contrainte mémoire tvOS : ~15-20 MB pour extensions
- Images décompressées (1280×720×4 bytes) = 3.5 MB par image
- 4 images = 14 MB → dépasse la limite → iOS tue silencieusement l'extension

**Solution implémentée:**
- ImageIO thumbnailing au lieu de UIGraphics
- Génération directe de miniatures sans charger image complète
- Réduction RAM : 500 KB au lieu de 7 MB par image
- Compression JPEG 90% pour qualité maximale

**Tâches:**
- [x] Setup extension TopShelf
- [x] Configuration entitlements et permissions réseau
- [x] Cache d'images optimisé (ImageIO)
- [x] Hero carousel avec backdrops
- [x] Deep linking molyseerr://
- [ ] **Validation sur device physique** (test final en cours)
- [ ] Settings synchronisés (mode Hero vs Sectioned)
- [ ] Support multiple sources (Trending, Watchlist, Popular)

**Fichiers clés:**
- `ContentProvider.swift` - Génération du contenu TopShelf
- `TopShelfImageCache.swift` - Optimisation mémoire avec ImageIO
- `TopShelfSettings.swift` - Configuration partagée

**Estimation restante:** 1-2 jours pour validation finale

---

### 3.5 Slider Configuration Dynamique
**Pourquoi?** Synchronisation avec Seerr web

- [ ] API pour récupérer config des sliders (enabled/disabled)
- [ ] Cacher les sliders désactivés
- [ ] Ordre personnalisable
- [ ] Configuration persistée

**Estimation:** 2 jours
**Dépend de:** API Seerr côté serveur

---

### 3.6 Intégration Jellyfin/Swiftfin - Bouton Play
**Pourquoi?** Lancer la lecture directe depuis Molyseerr vers Swiftfin

**Context:** Swiftfin a une infrastructure de deep linking partiellement implémentée mais incomplète
- URL scheme prévu: `jellyfin://users/{UserID}/items/{ItemID}`
- Code de parsing existe dans AppURLHandler.swift mais navigation désactivée (TODO ligne 83)
- tvOS n'a pas le URL scheme configuré dans Info.plist

**Tâches:**
- [ ] Vérifier si Swiftfin a complété son système de deep linking
- [ ] Ajouter détection si contenu disponible sur Jellyfin (via API)
- [ ] Bouton "Play on Jellyfin" dans MediaDetailView
- [ ] Construire URL deep link: `jellyfin://users/{UserID}/items/{ItemID}`
- [ ] Fallback gracieux si Swiftfin non installé
- [ ] Option alternative: afficher instructions d'installation Swiftfin

**Estimation:** 2-3 jours
**Dépend de:**
- Swiftfin finisse son implémentation deep linking (actuellement TODO)
- API pour vérifier disponibilité contenu sur Jellyfin
- MediaDetailView (1.2)

**Fichiers Swiftfin à surveiller:**
- `/Swiftfin/Swiftfin/Objects/AppURLHandler.swift` (ligne 83 - TODO à résoudre)
- `/Swiftfin/Swiftfin tvOS/Resources/Info.plist` (manque CFBundleURLTypes)
- `/Swiftfin/Shared/Coordinators/Navigation/NavigationRoute/NavigationRoute+Item.swift`

**Statut:** ⏸️ EN ATTENTE - Swiftfin doit compléter deep linking d'abord

---

## 🔐 Phase 4: Auth & Multi-utilisateurs (FUTUR)

### 4.1 Login Screen
- [ ] Remplacer hardcoded API key
- [ ] Page de login (username/password)
- [ ] Keychain storage sécurisé
- [ ] Support QR code (optionnel)

**Estimation:** 2-3 jours

---

### 4.2 Multi-profils
- [ ] Sélection du profil au démarrage
- [ ] Watchlists séparées par utilisateur
- [ ] Permissions (admin, user, etc.)

**Estimation:** 3 jours

---

## 🧪 Phase 5: Testing & Release (FUTUR)

### 5.1 Tests
- [ ] Unit tests pour ViewModels
- [ ] Tests API (mock responses)
- [ ] UI tests pour navigation

**Estimation:** 3-5 jours

---

### 5.2 App Store Prep
- [ ] Screenshots tvOS
- [ ] Description App Store
- [ ] Privacy policy
- [ ] Icône app finale
- [ ] Beta TestFlight

**Estimation:** 2 jours

---

## 📊 Sprint actuel : Polish & Optimisation (Janvier 2026)

### Objectifs prioritaires

**1. Finalisation TopShelf** (1-2 jours)
- Validation écran noir sur device physique
- Test de la solution ImageIO optimisée
- Configuration des sources (Trending/Watchlist/Popular)
- Settings synchronisés entre app et extension

**2. Configuration & Clean** (2-3 jours)
- Configuration Hero Discover (source de données)
- Optimisation page Discover (performance)
- Clean lancement app (splash, loading states)
- Clean page Details (layout, animations)
- Clean page Profile (stats, historique)

**3. UX Improvements** (2-3 jours)
- Page Login améliorée (multi-users, remember me)
- Réorganisation menu (Profile en haut, TVShows→Series)
- Support permissions API
- Gestion erreurs réseau cohérente

**4. Internationalisation** (3-4 jours)
- Multi-language (FR/EN minimum)
- Sync régions/langues avec Seerr
- Localisation genres/catégories
- Format dates selon locale

**Résultat attendu:** App stable, performante et prête pour usage quotidien

---

## 🎯 Prochaines étapes (Post-Sprint actuel)

### Sprint suivant: Features avancées
1. **Continue Watching** - Row dédiée avec progress
2. **Hero Banner amélioré** - Auto-rotate, trailers
3. **Genres & Filtres** - Page genres, filtres avancés
4. **Jellyfin Integration** - Bouton Play vers Swiftfin

### Backlog long terme
- Login/Auth sécurisé (Keychain, QR code)
- Multi-profils
- Tests unitaires et UI
- App Store preparation

---

## 📝 Notes importantes

### TopShelf - Leçons apprises (Janvier 2026)

**Problème résolu:** Écran noir sur Apple TV physique
- **Cause:** Dépassement limite mémoire (15-20 MB pour extensions tvOS)
- **Solution:** ImageIO thumbnailing au lieu de UIGraphics
- **Impact:** 95% réduction RAM (500 KB vs 7 MB par image)
- **Qualité:** Identique à l'original avec compression 90%

**Points clés tvOS:**
- Simulateur ≠ Device physique (limite RAM très différente)
- Extensions tuées silencieusement sans log d'erreur
- ImageIO = méthode recommandée par Apple pour thumbnails
- `kCGImageSourceThumbnailMaxPixelSize` crucial pour mémoire

### Décisions architecturales

**Images:**
- Source: w1280 de TMDB
- Optimisation: Thumbnail 1280px max via ImageIO
- Cache: Extension propre (pas App Group pour simplicité)
- Format: JPEG 90% pour balance qualité/taille

**Navigation:**
- Deep linking: `molyseerr://media/{type}/{id}`
- TabView principal avec 4 sections
- Hero banner source configurable

---

## 🤔 Questions ouvertes

1. **Continue Watching:** Seerr a-t-il un endpoint dédié ou faut-il le construire?
2. **Jellyfin Play:** Attendre Swiftfin deep linking ou implémenter autre solution?
3. **Multi-language:** Traductions professionnelles ou communautaires?
4. **App Store:** Beta TestFlight avant release public?

---

**Dernière mise à jour:** 3 Janvier 2026  
**Prochaine review:** Après validation TopShelf sur device
