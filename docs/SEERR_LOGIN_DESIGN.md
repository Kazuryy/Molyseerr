# Page de Connexion Seerr - Analyse Visuelle Desktop

## 🎨 Description Visuelle Complète

### Background Animé
**Composant:** `ImageFader`
- **Images de fond:** Backdrops TMDB qui changent automatiquement
- **Rotation:** Change toutes les 6 secondes (6000ms)
- **Animation:** Fade in/out avec transition opacity de 300ms
- **Effet:** Fond flou + gradient sombre par-dessus
  - Gradient: De `rgba(45, 55, 72, 0.47)` (haut) vers `#1A202E` (bas solide)
  - Effet de flou: `backdrop-filter: blur(5px)`
- **Source des images:** API endpoint `/api/v1/backdrops` qui retourne des URLs TMDB

### Structure de la Page

```
┌─────────────────────────────────────────────┐
│                                    [🌐 FR] │  ← Language picker (top-right)
│                                             │
│              [Background animé]             │  ← Backdrops TMDB qui changent
│                  ↓ ↓ ↓                     │     avec gradient overlay
│            ╔═══════════╗                    │
│            ║   SEERR   ║                    │  ← Logo empilé (logo_stacked.svg)
│            ║   LOGO    ║                    │     Hauteur: 192px (h-48)
│            ╚═══════════╝                    │
│                                             │
│        ┌─────────────────────────┐          │
│        │ ┌───────────────────┐   │          │
│        │ │ [❌ Error Message] │   │          │  ← Apparaît avec transition si erreur
│        │ └───────────────────┘   │          │
│        │                         │          │
│        │  Login with Seerr       │          │  ← Titre centré
│        │                         │          │
│        │  ┌───────────────────┐  │          │
│        │  │ Email / Username  │  │          │  ← Champ texte 1
│        │  └───────────────────┘  │          │     Background: gray-700/80
│        │                         │          │
│        │  ┌───────────────────┐  │          │
│        │  │ Password    [👁]  │  │          │  ← Champ password avec toggle
│        │  └───────────────────┘  │          │     Background: gray-700/80
│        │         [Forgot Password?]         │  ← Lien (si email activé)
│        │                         │          │
│        │  ┌───────────────────┐  │          │
│        │  │ [→] Sign In       │  │          │  ← Bouton principal (bleu)
│        │  └───────────────────┘  │          │
│        │                         │          │
│        │ ──── Or sign in with ────          │  ← Séparateur (si options multiples)
│        │                         │          │
│        │  ┌────────┐ ┌────────┐  │          │
│        │  │  PLEX  │ │ JELLY  │  │          │  ← Boutons alternatifs
│        │  └────────┘ └────────┘  │          │     (selon config serveur)
│        │                         │          │
│        └─────────────────────────┘          │  ← Card semi-transparente
│                                             │     bg-gray-800 bg-opacity-50
│                                             │     avec backdrop-filter blur(5px)
└─────────────────────────────────────────────┘
```

## 🎬 Comportements Animés

### 1. Background Images
- **Effet de rotation** entre plusieurs backdrops
- Transition en douceur (opacity fade)
- Toujours un gradient sombre par-dessus pour lisibilité

### 2. Transitions
- **Erreur:** Apparaît/disparaît avec transition opacity 300ms
- **Switch Login Type:** Si utilisateur clique pour changer entre Seerr/Plex/Jellyfin
  - Fade out (0ms) puis fade in (500ms)
  - Focus automatique sur le champ email/username après transition

### 3. États du Bouton
- **Normal:** "Sign In" avec icône →
- **Loading:** "Signing In..." avec spinner
- **Disabled:** Grisé si formulaire invalide

## 🎨 Styles et Couleurs

### Card Principale
- Background: `bg-gray-800` avec `opacity-50`
- Effet: `backdrop-filter: blur(5px)` (verre dépoli)
- Bordure: Arrondie (`rounded-lg`)
- Padding: `px-10 py-8`
- Max Width: `sm:max-w-md` (448px)
- Centré horizontalement

### Champs de Texte
- Background: `bg-gray-700/80` (gris foncé semi-transparent)
- Placeholder: `text-gray-400`
- Bordure arrondie standard
- Focus: Bordure bleue (standard)

### Bouton Principal
- Background: Bleu (bouton primary)
- Icône: Flèche "→" (ArrowLeftOnRectangleIcon)
- Full width
- Shadow subtile

### Boutons Alternatifs (Plex/Jellyfin)
- Background: Transparent
- Contient logo + texte
- Si seule option: Pleine largeur et plus grand
- Si multiples: Disposition flex avec gap

## 📋 Champs du Formulaire

### LocalLogin (Seerr)
1. **Email/Username**
   - ID: `email`
   - Placeholder: "Email Address / Username"
   - Type: `text` avec `inputMode="email"`
   - Validation: Requis

2. **Password**
   - ID: `password`
   - Type: `password` avec toggle show/hide
   - Validation: Requis
   - Autocomplete: `current-password`

3. **Submit Button**
   - Texte: "Sign In" (ou "Signing In..." si loading)
   - Disabled si formulaire invalide ou en cours

### Jellyfin/Emby Login
Similar avec champs serveur/username/password

### Plex Login
- Un seul gros bouton "Sign in with Plex"
- Ouvre OAuth popup

## 🔄 Flow Utilisateur

1. **Arrivée sur page:**
   - Background animé démarre
   - Logo apparaît
   - Form de login affiché (selon config)

2. **Remplissage:**
   - User entre email/username
   - User entre password
   - Bouton devient actif

3. **Submit:**
   - Bouton passe en état "Signing In..."
   - POST `/api/v1/auth/local`
   - Si erreur → Message rouge apparaît avec transition
   - Si succès → Revalidate user → Redirect "/"

4. **Options alternatives:**
   - Si configuré: Boutons Plex/Jellyfin en dessous
   - Switch entre modes avec animation fade

## 🎯 Points Clés pour tvOS

### À Adapter:
1. **Background animé** → Garder mais optimiser
2. **Card floutée** → Simplifier le blur pour perfs tvOS
3. **Champs texte** → Utiliser TextField tvOS natif
4. **Boutons** → Gros boutons focusables
5. **Logo** → Garder centré en haut
6. **Séparateur** → Garder pour clarté
7. **Animations** → Réduire pour fluidité

### À Simplifier:
1. **Language picker** → Optionnel pour MVP
2. **Forgot password** → Optionnel pour MVP
3. **Multiple auth methods** → Commencer avec local login seulement
4. **Form validation temps réel** → Simplifier

### Design tvOS:
- Logo: Plus grand (300-400pt de large)
- Champs: Hauteur 70pt minimum
- Boutons: 70pt hauteur avec texte 28-30pt
- Card: Plus large pour remplir écran
- Espacements: Augmenter (tvOS specs)
- Focus: États focalisés clairs avec bordures blanches

## 📐 Dimensions Desktop

- **Container max-width:** 448px (sm:max-w-md)
- **Logo height:** 192px (h-48)
- **Card padding:** 40px horizontal, 32px vertical
- **Input height:** ~40px standard
- **Button height:** ~44px standard
- **Gap entre éléments:** 16-24px

## 🎨 Gradient Background

```css
background: linear-gradient(
  180deg,
  rgba(45, 55, 72, 0.47) 0%,   /* Top: Semi-transparent */
  #1A202E 100%                  /* Bottom: Solid dark */
)
```

---

**Source:** Local Seerr repository (`src/components/Login/`)
**Date:** 25 décembre 2024
