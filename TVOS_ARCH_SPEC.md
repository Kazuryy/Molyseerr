# TVOS Architecture Specification - Seerr

**Document Version**: 1.0
**Date**: 2025-12-24
**Prepared by**: Senior Software Architect
**Purpose**: Technical specification for porting Seerr to Apple TV (tvOS)

---

## Table of Contents

1. [Design System](#1-design-system)
2. [Business Logic (Critical)](#2-business-logic-critical)
3. [API Endpoints](#3-api-endpoints)
4. [Technical Stack Overview](#4-technical-stack-overview)
5. [Architecture Recommendations](#5-architecture-recommendations)

---

## 1. Design System

### 1.1 Color Palette (HEX Codes)

This application uses Tailwind CSS v3 color system. All colors below are extracted from the source code.

#### Primary Colors
| Color Name | HEX Code | Usage | Component References |
|------------|----------|-------|---------------------|
| **Indigo 500** | `#6366f1` | Primary actions, badges (default/primary state) | Badge.tsx (line 80), StatusBadge.tsx (line 142) |
| **Indigo 600** | `#4f46e5` | Primary buttons, accents, focused states | Calendar components, input focus states |
| **Blue 500** | `#3b82f6` | Movie media type badge | TitleCard.tsx (line 347) |
| **Purple 600** | `#9333ea` | TV Show media type badge | TitleCard.tsx (line 348) |

#### Success States
| Color Name | HEX Code | Usage | Component References |
|------------|----------|-------|---------------------|
| **Green 500** | `#22c55e` | Success badges, "Available" status, vote progress bars | Badge.tsx (line 52), StatusBadge.tsx (line 154), DeletionRequestCard.tsx (line 337) |
| **Emerald 600** | `#10b981` | Alternative success state | Badge.tsx (line 72) |

#### Warning States
| Color Name | HEX Code | Usage | Component References |
|------------|----------|-------|---------------------|
| **Yellow 500** | `#eab308` | Warning badges, "Pending" status | Badge.tsx (line 44), StatusBadge.tsx (line 355) |
| **Amber 300** | _(Tailwind default)_ | Watchlist star icon | TitleCard.tsx (line 369) |

#### Error/Danger States
| Color Name | HEX Code | Usage | Component References |
|------------|----------|-------|---------------------|
| **Red 500** | `#ef4444` | Danger badges, error states, negative vote bars | Badge.tsx (line 36), DeletionRequestCard.tsx (line 348) |
| **Red 600** | `#dc2626` | Hover states for danger actions | Badge.tsx (line 39) |

#### Background & Surface Colors
| Color Name | HEX Code | Usage | Component References |
|------------|----------|-------|---------------------|
| **Gray 900** | `#111827` | Main background | globals.css (line 42), body background |
| **Gray 800** | `#1f2937` | Card backgrounds, modals, elevated surfaces | TitleCard.tsx (line 307), RequestItem.tsx (line 409), scrollbar track |
| **Gray 700** | `#374151` | Input fields, secondary surfaces, borders | globals.css (line 355), input/select backgrounds |
| **Gray 600** | `#4b5563` | Scrollbar thumb, disabled states | globals.css (line 28) |
| **Gray 500** | `#6b7280` | Borders, separators | Input borders throughout |
| **Gray 400** | `#9ca3af` | Secondary text, placeholders | Text elements |
| **Gray 300** | `#d1d5db` | Primary text on dark backgrounds | Typography (tailwind.config.js line 24) |

### 1.2 Border Radius Rules

| Element Type | Border Radius | CSS Class | Usage |
|--------------|---------------|-----------|-------|
| **Cards** | `0.75rem` (12px) | `rounded-xl` | TitleCard.tsx (line 307), RequestItem.tsx (line 409) |
| **Badges** | `9999px` (full) | `rounded-full` | Badge.tsx (line 24), media type badges |
| **Buttons** | `0.375rem` (6px) | `rounded-md` | Standard button style |
| **Input Fields** | `0.375rem` (6px) | `rounded-md` | globals.css (line 355) |
| **Small Elements** | `0.5rem` (8px) | `rounded-lg` | Modal elements, tooltips |

### 1.3 Typography

#### Font Family
- **Primary**: Inter (custom font loaded via Tailwind config)
- **Fallback**: System sans-serif stack (default Tailwind)
- **Reference**: tailwind.config.js (line 18-19)

#### Font Sizes & Weights
| Element | Size | Weight | Line Height | Usage |
|---------|------|--------|-------------|-------|
| **Card Title** | `1.25rem` (20px) | `700` (bold) | `tight` | TitleCard.tsx (line 480) |
| **Media Type Badge** | `0.75rem` (12px) | `500` (medium) | Normal | TitleCard.tsx (line 351) |
| **Badge Text** | `0.875rem` (14px) | `600` (semibold) | `1.25rem` | Badge.tsx (line 24) |
| **Body Text** | `0.875rem` (14px) | `400` (normal) | `1.25rem` | Standard content |

### 1.4 Shadows & Effects

| Effect | CSS Value | Usage |
|--------|-----------|-------|
| **Card Shadow (normal)** | `shadow` (Tailwind default) | Resting state |
| **Card Shadow (hover)** | `shadow-lg` | Hover state (TitleCard.tsx line 309) |
| **Ring (normal)** | `ring-1 ring-gray-700` | Card outline |
| **Ring (focused)** | `ring-1 ring-gray-500` | Focus/hover state |
| **Badge Shadow** | `shadow-md` | Media type badges (line 345) |

### 1.5 Spacing & Layout

| Element | Padding | Gap | Notes |
|---------|---------|-----|-------|
| **Card** | `0.5rem` (8px) vertical | N/A | TitleCard wrapper |
| **Badge** | `0.5rem` (8px) horizontal | N/A | Badge.tsx (line 24) |
| **Grid Gap** | `1rem` (16px) | `gap-4` | Card grids |
| **Card Aspect Ratio** | 150% (2:3 poster) | N/A | TitleCard.tsx (line 313) |

---

## 2. Business Logic (Critical)

### 2.1 Media Status System

#### Status Enumeration
**Source**: `server/constants/media.ts`

```typescript
enum MediaStatus {
  UNKNOWN = 1,       // No data available
  PENDING = 2,       // Request submitted, waiting approval
  PROCESSING = 3,    // Approved, downloading/processing
  PARTIALLY_AVAILABLE = 4, // Some content available (TV shows)
  AVAILABLE = 5,     // Fully available in media server
  BLACKLISTED = 6,   // Hidden from user
  DELETED = 7        // Removed from system
}
```

#### Status Badge Mapping
**Source**: `src/components/StatusBadge/index.tsx` (lines 153-387)

| Status | Badge Type | Color | Icon | Display Text |
|--------|-----------|-------|------|--------------|
| `AVAILABLE` | `success` | Green (#22c55e) | None | "Available" / "4K Available" |
| `PARTIALLY_AVAILABLE` | `success` | Green (#22c55e) | None | "Partially Available" |
| `PROCESSING` | `primary` | Indigo (#6366f1) | Spinner (if downloading) | "Processing" / "Requested" |
| `PENDING` | `warning` | Yellow (#eab308) | None | "Pending" |
| `BLACKLISTED` | `danger` | Red (#ef4444) | None | "Blacklisted" |
| `DELETED` | `danger` | Red (#ef4444) | None | "Deleted" |
| `UNKNOWN` | N/A | None | None | No badge shown |

### 2.2 Button Display Logic (Pseudo-code)

**Source**: Analyzed from `src/components/TitleCard/index.tsx` (lines 414-531)

#### Decision Tree for Button Display

```pseudocode
FUNCTION determineButtonDisplay(media):
    // Step 1: Check user permissions
    IF NOT user.hasPermission([REQUEST, REQUEST_MOVIE or REQUEST_TV]):
        RETURN "NO_BUTTON"
    END IF

    // Step 2: Check blacklist status
    IF media.status == BLACKLISTED:
        IF user.hasPermission(MANAGE_BLACKLIST):
            RETURN "SHOW_BLACKLISTED_ITEM" (Eye icon button)
        ELSE:
            RETURN "NO_BUTTON"
        END IF
    END IF

    // Step 3: Determine action based on status
    SWITCH media.status:
        CASE UNKNOWN:
        CASE DELETED:
        CASE NULL:
            // Media not requested yet
            RETURN "REQUEST_BUTTON" (ArrowDownTrayIcon, text: "Request")

        CASE PENDING:
            // Request submitted, awaiting approval
            RETURN "PENDING_BADGE" (Yellow badge, no button)

        CASE PROCESSING:
            // Currently downloading
            RETURN "PROCESSING_BADGE" (Indigo badge with spinner)

        CASE AVAILABLE:
        CASE PARTIALLY_AVAILABLE:
            // Available to watch
            IF media.hasPlexUrl OR media.hasJellyfinUrl:
                RETURN "VIEW_BADGE_WITH_LINK" (Green badge, clickable to media server)
            ELSE IF user.hasPermission(MANAGE_REQUESTS):
                RETURN "MANAGE_LINK" (Link to media details page)
            ELSE:
                RETURN "AVAILABLE_BADGE" (Green badge, no action)
            END IF

        DEFAULT:
            RETURN "NO_BUTTON"
    END SWITCH
END FUNCTION

// Additional Actions (Top-right of card)
FUNCTION determineSecondaryActions(media):
    actions = []

    // Watchlist toggle (only for non-Plex users)
    IF user.type != PLEX AND media.status != BLACKLISTED:
        IF media.isOnWatchlist:
            actions.append("REMOVE_FROM_WATCHLIST" (MinusCircleIcon))
        ELSE:
            actions.append("ADD_TO_WATCHLIST" (StarIcon))
        END IF
    END IF

    // Blacklist/Hide option
    IF user.hasPermission(MANAGE_BLACKLIST):
        IF media.status == BLACKLISTED:
            actions.append("UNHIDE" (EyeIcon))
        ELSE IF media.status NOT IN [PROCESSING, AVAILABLE, PARTIALLY_AVAILABLE, PENDING]:
            actions.append("HIDE" (EyeSlashIcon))
        END IF
    END IF

    RETURN actions
END FUNCTION
```

#### Critical Business Rules

1. **Request Button Visibility**:
   - Only shown when `status` is `UNKNOWN`, `DELETED`, or `null`
   - User MUST have `REQUEST` permission AND (`REQUEST_MOVIE` OR `REQUEST_TV` based on media type)
   - Button disappears after successful request submission

2. **Status Badge Priority**:
   - `BLACKLISTED` > `AVAILABLE` > `PROCESSING` > `PENDING` > `UNKNOWN`
   - Badges are always displayed in top-left corner of card

3. **Download Progress Display**:
   - Only shown for `AVAILABLE` or `PROCESSING` status
   - Requires `inProgress=true` and valid `downloadItem[]` data
   - Progress bar overlay on badge shows download percentage
   - **Source**: StatusBadge.tsx (lines 138-151)

4. **4K Variant Logic**:
   - Media can have both standard (1080p) and 4K versions
   - Each version has independent status tracking (`status` vs `status4k`)
   - 4K badges show "4K Available" / "4K Pending" prefix
   - **Source**: Media.ts (lines 103-107)

### 2.3 Media Type Identification

**Source**: `server/constants/media.ts` (lines 9-12)

```typescript
enum MediaType {
  MOVIE = 'movie',
  TV = 'tv'
}
```

#### Visual Differentiation
- **Movies**: Blue badge (#3b82f6) with "FILM" text
- **TV Shows**: Purple badge (#9333ea) with "SÉRIE" text
- **Collections**: Blue badge (same as movies) with "COLLECTION" text

**Reference**: TitleCard.tsx (lines 343-357)

### 2.4 Deletion Request System (New Feature)

**Source**: `server/entity/DeletionRequest.ts`, `src/components/DeletionRequest/DeletionRequestCard/index.tsx`

#### Deletion Flow Logic

```pseudocode
FUNCTION deletionRequestWorkflow(media):
    // Check if deletion is enabled
    IF NOT settings.deletion.enabled:
        RETURN "FEATURE_DISABLED"
    END IF

    // Check existing deletion request
    existingRequest = API.GET("/api/v1/deletion/check/" + media.id)
    IF existingRequest.exists:
        RETURN showDeletionVotingUI(existingRequest)
    END IF

    // Check permissions
    IF user.isAdmin OR settings.deletion.allowNonAdminDeletionRequests:
        RETURN showCreateDeletionButton()
    ELSE:
        RETURN "NO_PERMISSION"
    END IF
END FUNCTION

FUNCTION showDeletionVotingUI(deletionRequest):
    votingActive = deletionRequest.votingEndsAt > NOW()

    IF votingActive:
        // Show vote buttons
        userVote = API.GET("/api/v1/deletion/" + deletionRequest.id + "/vote/me")

        IF userVote.exists:
            RETURN showVoteStatus(userVote, deletionRequest.votesFor, deletionRequest.votesAgainst)
        ELSE:
            RETURN showVoteButtons("Vote For Delete", "Vote Against")
        END IF
    ELSE:
        // Voting ended - show results
        votePercentage = (votesFor / (votesFor + votesAgainst)) * 100

        IF votePercentage >= settings.deletion.requiredVotePercentage:
            IF user.isAdmin:
                RETURN showExecuteButton()
            ELSE:
                RETURN "AWAITING_ADMIN_EXECUTION"
            END IF
        ELSE:
            RETURN "DELETION_REJECTED"
        END IF
    END IF
END FUNCTION
```

#### Deletion Request Status Colors
- **Vote For Progress Bar**: Green (#22c55e)
- **Vote Against Progress Bar**: Red (#ef4444)
- **Background**: Gray 800 (#1f2937)
- **Voting Info Card**: Yellow warning background (yellow-900/20 with yellow-500/30 border)

**Reference**: DeletionRequestCard.tsx (lines 334-348), DeletionRequestButton/index.tsx (line 212)

---

## 3. API Endpoints

### 3.1 Core Media Endpoints

#### Discovery & Trending
| Endpoint | Method | Description | Query Parameters | Response Model |
|----------|--------|-------------|------------------|----------------|
| `/api/v1/discover/movies` | GET | Discover movies | `page`, `language`, `genre`, `sortBy` | `PagedResponse<MovieResult>` |
| `/api/v1/discover/tv` | GET | Discover TV shows | `page`, `language`, `genre`, `sortBy` | `PagedResponse<TvResult>` |
| `/api/v1/discover/trending` | GET | Trending media (all types) | `page`, `timeWindow` ("day"\|"week") | `PagedResponse<SearchResult>` |
| `/api/v1/discover/watchlist` | GET | User's watchlist | `page` | `PagedResponse<MediaResult>` |
| `/api/v1/available-media` | GET | Available media (DB-only, fast) | `page`, `type` ("movie"\|"tv"), `sortBy` | `PagedResponse<MediaResult>` |

**Reference**: server/routes/index.ts (lines 474-550), server/routes/discover.ts

#### Search
| Endpoint | Method | Description | Query Parameters | Response Model |
|----------|--------|-------------|------------------|----------------|
| `/api/v1/search` | GET | Multi-search (movies, TV, people) | `query`, `page`, `language` | `PagedResponse<SearchResult>` |
| `/api/v1/search/keyword` | GET | Search by keyword | `query`, `page` | `PagedResponse<Keyword>` |
| `/api/v1/search/company` | GET | Search production companies | `query`, `page` | `PagedResponse<Company>` |

**Reference**: server/routes/search.ts

#### Media Details
| Endpoint | Method | Description | Path Parameters | Response Model |
|----------|--------|-------------|-----------------|----------------|
| `/api/v1/movie/:id` | GET | Get movie details | `id` (TMDB ID) | `MovieDetails` |
| `/api/v1/tv/:id` | GET | Get TV show details | `id` (TMDB ID) | `TvDetails` |
| `/api/v1/media/:id` | GET | Get media entity (internal DB) | `id` (Media ID) | `Media` |

**Reference**: server/routes/movie.ts (lines 16-44), server/routes/tv.ts

### 3.2 Request Management

| Endpoint | Method | Description | Body/Params | Response |
|----------|--------|-------------|-------------|----------|
| `/api/v1/request` | GET | Get all requests | Query: `filter`, `skip`, `take`, `requestedBy`, `mediaType` | `RequestResultsResponse` |
| `/api/v1/request` | POST | Create new request | Body: `MediaRequestBody` | `MediaRequest` |
| `/api/v1/request/:requestId` | GET | Get specific request | Param: `requestId` | `MediaRequest` |
| `/api/v1/request/:requestId` | DELETE | Cancel request | Param: `requestId` | `204 No Content` |
| `/api/v1/request/:requestId/approve` | POST | Approve request (admin) | Param: `requestId` | `MediaRequest` |
| `/api/v1/request/:requestId/decline` | POST | Decline request (admin) | Param: `requestId` | `MediaRequest` |

**Reference**: server/routes/request.ts (lines 32-100)

#### MediaRequestBody Interface
```typescript
interface MediaRequestBody {
  mediaType: 'movie' | 'tv';
  mediaId: number;        // TMDB ID
  seasons?: number[];     // For TV shows only
  is4k?: boolean;         // Request 4K version
  serverId?: number;      // Target Radarr/Sonarr server
  profileId?: number;     // Quality profile
  rootFolder?: string;    // Storage location
}
```

### 3.3 Watchlist & Blacklist

#### Watchlist
| Endpoint | Method | Description | Body | Response |
|----------|--------|-------------|------|----------|
| `/api/v1/watchlist` | POST | Add to watchlist | `{ tmdbId, mediaType, title }` | `Watchlist` |
| `/api/v1/watchlist/:tmdbId` | DELETE | Remove from watchlist | N/A | `204 No Content` |

**Reference**: server/routes/watchlist.ts

#### Blacklist
| Endpoint | Method | Description | Body | Response |
|----------|--------|-------------|------|----------|
| `/api/v1/blacklist` | POST | Hide media | `{ tmdbId, mediaType, title, user }` | `Blacklist` |
| `/api/v1/blacklist/:tmdbId` | DELETE | Unhide media | N/A | `204 No Content` |

**Reference**: server/routes/blacklist.ts, TitleCard.tsx (lines 171-253)

### 3.4 Deletion Request System

| Endpoint | Method | Description | Body/Params | Response |
|----------|--------|-------------|-------------|----------|
| `/api/v1/deletion` | GET | Get all deletion requests | Query: `page`, `pageSize` | `PaginatedResponse<DeletionRequest>` |
| `/api/v1/deletion` | POST | Create deletion request | `{ mediaId, reason }` | `DeletionRequest` |
| `/api/v1/deletion/:id` | GET | Get specific deletion request | Param: `id` | `DeletionRequest` |
| `/api/v1/deletion/check/:mediaId` | GET | Check if deletion exists | Param: `mediaId` | `{ exists, deletionRequest? }` |
| `/api/v1/deletion/:id/vote` | POST | Vote on deletion | `{ vote: "for" \| "against" }` | `DeletionVote` |
| `/api/v1/deletion/:id/vote` | DELETE | Remove vote | N/A | `204 No Content` |
| `/api/v1/deletion/:id/vote/me` | GET | Get current user's vote | N/A | `DeletionVote \| null` |
| `/api/v1/deletion/:id/execute` | POST | Execute deletion (admin) | N/A | `DeletionRequest` |
| `/api/v1/deletion/:id/cancel` | POST | Cancel deletion (admin) | N/A | `DeletionRequest` |

**Reference**: server/routes/deletion.ts, src/hooks/useDeletionRequests.ts

### 3.5 Settings & Configuration

| Endpoint | Method | Description | Response |
|----------|--------|-------------|----------|
| `/api/v1/settings/public` | GET | Get public settings | `PublicSettings` |
| `/api/v1/settings/main` | GET | Get main settings (admin) | `MainSettings` |
| `/api/v1/user/me` | GET | Get current user info | `User` |

**Reference**: server/routes/index.ts (lines 111-120)

### 3.6 Response Models (Key Interfaces)

#### Pagination Wrapper
```typescript
interface PaginatedResponse<T> {
  page: number;
  totalPages: number;
  totalResults: number;
  results: T[];
}
```

#### Media Result
```typescript
interface MediaResult {
  id: number;               // TMDB ID
  mediaType: 'movie' | 'tv';
  mediaInfo?: {
    id: number;             // Internal Media ID
    tmdbId: number;
    status: MediaStatus;
    status4k: MediaStatus;
    requests: MediaRequest[];
    downloadStatus?: DownloadingItem[];
    mediaAddedAt?: Date;
    plexUrl?: string;
    jellyfinMediaId?: string;
  };
}
```

#### DeletionRequest
```typescript
interface DeletionRequest {
  id: number;
  mediaId: number;
  media: Media;
  requestedBy: User;
  reason?: string;
  status: 'PENDING' | 'APPROVED' | 'REJECTED' | 'EXECUTED';
  votingEndsAt: Date;
  votesFor: number;
  votesAgainst: number;
  createdAt: Date;
  updatedAt: Date;
}
```

---

## 4. Technical Stack Overview

### 4.1 Current Architecture

**Frontend**:
- Framework: Next.js 14.2.25 (React 18.3.1)
- Styling: Tailwind CSS 3.2.7
- State Management: SWR 2.3.7 (data fetching/caching)
- API Client: Axios 1.13.2
- Internationalization: React-Intl 6.6.8

**Backend**:
- Runtime: Node.js + Express.js
- Language: TypeScript 4.9.5
- ORM: TypeORM
- Database: PostgreSQL / SQLite
- External APIs: TMDB, Radarr, Sonarr, Plex/Jellyfin/Emby

**Reference**: package.json, server structure analysis

### 4.2 Key Dependencies for tvOS Port

#### Data Fetching Pattern (SWR)
```typescript
// Example from useDeletionRequests.ts
import useSWR from 'swr';

const { data, error, mutate } = useSWR<DeletionRequestsResponse>(
  '/api/v1/deletion',
  {
    refreshInterval: 30000,  // Auto-refresh every 30s
    revalidateOnFocus: true
  }
);
```

For tvOS: Consider replacing with SwiftUI's `@State`, `@ObservableObject`, or Combine framework.

#### Authentication Pattern
- Header-based auth: `Cookie` or `Authorization` header
- Session management via Express sessions
- User permissions checked on every request
- **Reference**: server/middleware/auth.ts

---

## 5. Architecture Recommendations

### 5.1 tvOS Implementation Strategy

#### Option 1: Native Swift/SwiftUI (Recommended)
**Pros**:
- Best performance on Apple TV
- Native tvOS controls (Focus Engine, Siri Remote gestures)
- Access to native media player (AVKit)
- Better integration with Apple ecosystem

**Cons**:
- Complete rewrite required
- Longer development time
- Need to maintain two codebases

#### Option 2: Hybrid (SwiftUI + WebKit)
**Pros**:
- Reuse existing web components
- Faster initial development
- Shared business logic

**Cons**:
- Poor performance for video-heavy UI
- Limited tvOS-specific features
- Not recommended by Apple

### 5.2 Critical tvOS Adaptations

#### UI Layout
- **Card Grid**: Use `LazyVGrid` with 5-7 columns (depending on screen size)
- **Focus Engine**: Implement `.focusable()` modifiers on all interactive elements
- **Card Scaling**: Scale focused card to 1.1x with shadow increase (mimicking TitleCard hover state)

#### Navigation
- **Tab Bar**: Replace sidebar with tvOS Tab Bar
  - Tabs: Home, Discover, Search, Requests, Settings
- **Deep Linking**: Support Siri and Apple TV App integration

#### Media Player Integration
- Use `AVPlayerViewController` for Plex/Jellyfin playback
- Support external player URLs (iOS deep links)

#### Networking
- Reuse existing REST API endpoints (no changes needed on backend)
- Implement `URLSession` with:
  - Cookie-based authentication
  - Automatic retry logic
  - Image caching for posters/backdrops

#### State Management
- Use Combine framework for reactive data flow
- Create `MediaService`, `RequestService`, `DeletionService` classes
- Implement `@StateObject` for view models

### 5.3 Performance Considerations

#### Image Loading
- Current: TMDB image CDN (`https://image.tmdb.org/t/p/w300_and_h450_face{path}`)
- tvOS: Use higher resolution (`w780` or `original`) for 4K displays
- Implement aggressive image caching (NSCache + disk cache)

#### Data Pagination
- tvOS: Implement infinite scroll with prefetching
- Load next page when user scrolls to 80% of current page
- Current API supports `page` parameter on all list endpoints

#### Offline Mode
- Cache media metadata locally (Core Data)
- Show cached data when network unavailable
- Sync on reconnection

### 5.4 Security Notes

#### API Authentication
- Current: Cookie-based sessions
- tvOS: Should support both cookie and token-based auth
- Implement secure credential storage (Keychain)

#### HTTPS Requirement
- tvOS App Transport Security (ATS) requires HTTPS
- Ensure backend has valid SSL certificate

---

## Appendix A: Color Palette Reference Card

Quick reference for tvOS color implementation:

```swift
// SwiftUI Color Extensions
extension Color {
    // Primary
    static let seerrIndigo500 = Color(hex: "6366f1")
    static let seerrIndigo600 = Color(hex: "4f46e5")

    // Success
    static let seerrGreen500 = Color(hex: "22c55e")

    // Warning
    static let seerrYellow500 = Color(hex: "eab308")

    // Danger
    static let seerrRed500 = Color(hex: "ef4444")
    static let seerrRed600 = Color(hex: "dc2626")

    // Backgrounds
    static let seerrGray900 = Color(hex: "111827")
    static let seerrGray800 = Color(hex: "1f2937")
    static let seerrGray700 = Color(hex: "374151")

    // Media Types
    static let seerrBlue500 = Color(hex: "3b82f6")
    static let seerrPurple600 = Color(hex: "9333ea")
}

// Helper extension
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
```

---

## Appendix B: Key Files Reference

| Purpose | File Path | Key Information |
|---------|-----------|-----------------|
| Color Palette | `tailwind.config.js` | Color system, typography |
| Media Card UI | `src/components/TitleCard/index.tsx` | Card layout, button logic |
| Status Logic | `src/components/StatusBadge/index.tsx` | Badge colors, status mapping |
| Status Enum | `server/constants/media.ts` | MediaStatus values |
| Media Entity | `server/entity/Media.ts` | Database schema, status fields |
| API Routes | `server/routes/index.ts` | Main API router |
| Request Routes | `server/routes/request.ts` | Request CRUD operations |
| Deletion Routes | `server/routes/deletion.ts` | Deletion voting API |
| Search | `server/routes/search.ts` | Search endpoints |
| Global Styles | `src/styles/globals.css` | Base styles, scrollbar, iOS fixes |

---

## Document Changelog

- **v1.0** (2025-12-24): Initial architecture specification created

---

**Next Steps**:
1. Review this specification with development team
2. Create SwiftUI component mockups based on design system
3. Implement API client layer in Swift
4. Build prototype with media card grid and focus engine
5. Test authentication flow and session management

**Questions for Stakeholders**:
- Should tvOS app support offline mode?
- Is there a preferred media player (native AVKit vs Plex/Jellyfin native apps)?
- Should deletion voting feature be included in tvOS v1.0?
- Any specific tvOS-only features required (SharePlay, Picture-in-Picture, etc.)?
