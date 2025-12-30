# Molyseerr - Roadmap de développement

**Mise à jour:** 24 Décembre 2025
**Version actuelle:** 0.1.0 (MVP en cours)

---

## 🎯 Vision

Client tvOS natif pour Overseerr/Jellyseerr (Seerr) qui combine:
- L'UX d'Apple TV+ (navigation fluide, design moderne)
- Les fonctionnalités de Seerr (découverte, requêtes, gestion de watchlist)
- Une expérience 100% native tvOS

---

## ✅ Phase 0: Foundation (COMPLÉTÉ)

**Status:** ✅ Done

- [x] Architecture MVVM mise en place
- [x] Data layer (Models, Services, API client)
- [x] Configuration .env pour dev
- [x] Design reference document (APPLE_TV_DESIGN_REFERENCE.md)
- [x] Intégration Kingfisher 8.6.2
- [x] TrendingViewModel fonctionnel
- [x] HomeViewModel avec 4 sliders (Trending, Popular Movies/TV, Upcoming)
- [x] Composants de base (MediaCardView, HorizontalMediaRow, HeroBannerView)
- [x] Hero banner Apple TV+ style
- [x] Navigation et layout de base

**Ce qui marche:**
- App se connecte à Seerr via API
- Charge et affiche le contenu trending/popular
- Hero banner avec gradient et boutons
- Rows horizontales scrollables
- Focus effects sur les cards

**Ce qui manque:**
- Images réelles (placeholders pour l'instant)
- Badges MediaInfo (Available, Pending, etc.)
- Navigation vers détails
- Gestion des requêtes

---

## 🚀 Phase 1: Core UX (PRIORITÉ HAUTE)

**Objectif:** Rendre l'app utilisable pour la découverte de contenu

### 1.1 Images & Visuels (⭐ CRITIQUE)
**Pourquoi en premier?** Sans images, impossible de tester le vrai look & feel

- [ ] Intégrer Kingfisher pour charger les posters TMDB
- [ ] Ajouter backdrop images au hero banner
- [ ] Gérer les états de chargement des images (skeleton, fade-in)
- [ ] Fallback pour images manquantes
- [ ] Cache des images optimisé

**Estimation:** 1-2 jours
**Fichiers:** `MediaCardView.swift`, `HeroBannerView.swift`, nouveau `ImageLoader.swift`

---

### 1.2 Page Détails (⭐ CRITIQUE)
**Pourquoi?** Point d'entrée vers les actions (request, watchlist)

- [ ] Créer `MediaDetailView.swift`
- [ ] Créer `MediaDetailViewModel.swift`
- [ ] Navigation card → detail (push navigation)
- [ ] Afficher infos complètes (synopsis, cast, genres, runtime, rating)
- [ ] Backdrop full-screen en arrière-plan
- [ ] Tabs: Overview / Episodes (pour TV) / Cast / Similar

**Estimation:** 2-3 jours
**Dépend de:** 1.1 (Images)

---

### 1.3 Actions utilisateur (⭐ HAUTE)
**Pourquoi?** Cœur de la valeur ajoutée de Seerr

Dans MediaDetailView, implémenter:
- [ ] Bouton "Request" (avec logique Available/Pending/Processing)
- [ ] Bouton "Add to Watchlist"
- [ ] Afficher badges de status (Available, Pending, etc.)
- [ ] Gestion des erreurs de requête
- [ ] Confirmation visuelle après action

**Estimation:** 2 jours
**Fichiers:** `MediaDetailView.swift`, nouveau `RequestManager.swift`

---

## 📱 Phase 2: Navigation & Structure (PRIORITÉ MOYENNE)

### 2.1 TabView Navigation
**Pourquoi?** Architecture standard tvOS pour plusieurs sections

- [ ] Remplacer root par `TabView`
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

### 3.4 Slider Configuration Dynamique
**Pourquoi?** Synchronisation avec Seerr web

- [ ] API pour récupérer config des sliders (enabled/disabled)
- [ ] Cacher les sliders désactivés
- [ ] Ordre personnalisable

**Estimation:** 2 jours
**Dépend de:** API Seerr côté serveur

---

### 3.5 Intégration Jellyfin/Swiftfin - Bouton Play
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

## 📊 Priorités suggérées (ordre recommandé)

### Sprint 1: MVP utilisable (5-7 jours)
1. **Images (1.1)** - 2 jours → Rendre l'app visuellement correcte
2. **Page Détails (1.2)** - 3 jours → Navigation fonctionnelle
3. **Actions Request (1.3)** - 2 jours → Valeur ajoutée principale

**Résultat:** App permettant de découvrir et requêter du contenu

---

### Sprint 2: Structure complète (4-5 jours)
4. **TabView Navigation (2.1)** - 1 jour
5. **Page Search (2.2)** - 2 jours
6. **Page Requests (2.3)** - 2 jours

**Résultat:** App complète avec toutes les sections principales

---

### Sprint 3: Polish (3-5 jours)
7. **Settings (2.4)** - 1 jour
8. **Continue Watching (3.2)** - 2 jours
9. **Hero Banner avancé (3.1)** - 2 jours

**Résultat:** App polie, prête pour usage quotidien

---

### Sprint 4+: Features avancées
10. Login/Auth (4.1)
11. Genres & Filtres (3.3)
12. Slider Config (3.4)
13. Multi-profils (4.2)

---

## 🎯 Recommandation: Par où commencer MAINTENANT?

### Option A: Quick Win visuel (RECOMMANDÉ)
**Prochaine étape:** Implémenter les images (1.1)

**Pourquoi?**
- Impact visuel immédiat
- Permet de voir le vrai look de l'app
- Nécessaire pour toutes les features suivantes
- Relativement simple (Kingfisher fait le gros du travail)

**Fichiers à créer/modifier:**
- Nouveau: `Molyseerr/Utils/ImageLoader.swift`
- Modifier: `MediaCardView.swift` (ajouter AsyncImage)
- Modifier: `HeroBannerView.swift` (backdrop image)

---

### Option B: Feature complète
**Prochaine étape:** Page Détails (1.2)

**Pourquoi?**
- Permet de tester la navigation
- Débloque les actions (request, watchlist)
- Composant central de l'app

---

## 🤔 Ma recommandation

**Commence par 1.1 (Images)** pour ces raisons:

1. **Feedback visuel rapide** - Tu verras immédiatement si le design fonctionne
2. **Bloquant pour la suite** - Difficile de tester les détails sans images
3. **Relativement facile** - Kingfisher + TMDB image URLs = simple
4. **Motivation** - Voir l'app prendre vie avec de vraies affiches

Une fois les images intégrées, tu enchaînes direct sur la page détails (1.2) puis les actions (1.3).

**En ~1 semaine, tu as un MVP fonctionnel!**

---

## 📝 Notes

- **Temps estimés** = pour une personne avec ton niveau (intermédiaire Swift/SwiftUI)
- **Dépendances** clairement indiquées
- **Flexibilité** = Tu peux sauter des features "nice-to-have" si besoin
- **Tests** = Peuvent être faits au fur et à mesure ou à la fin

---

**Question pour toi:** Tu veux qu'on attaque les images maintenant, ou tu préfères une autre priorité?
