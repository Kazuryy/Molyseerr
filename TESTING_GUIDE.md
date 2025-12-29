# Testing Guide - Available Media & Movies/Series Pages

## 🧪 Test Plan

### Prerequisites
1. Seerr server running and configured
2. App connected to server with valid API key
3. User authenticated
4. Some media items in library with status AVAILABLE (5) or PARTIALLY_AVAILABLE (4)

## 1️⃣ Available Sliders in Discover Tab

### Test Case 1.1: Available Movies Slider Appears
**Steps:**
1. Open Seerr web app → Settings → Discover
2. Enable "Available Movies" slider (drag to enabled section)
3. Save configuration
4. Open Molyseerr app
5. Navigate to Discover tab

**Expected:**
- ✅ "Available Movies" slider appears in Discover page
- ✅ Shows movies with status AVAILABLE or PARTIALLY_AVAILABLE
- ✅ Sorted by "Recently Added" (most recent first)
- ✅ Maximum 20 items displayed
- ✅ Each card shows poster, title, and availability badge

**Error States to Test:**
- Empty state: If no available movies → Should show empty slider or hide slider
- Loading state: Should show placeholder cards while loading
- Error state: If API fails → Should show error message

### Test Case 1.2: Available TV Slider Appears
**Steps:**
1. Open Seerr web app → Settings → Discover
2. Enable "Available TV" slider
3. Save configuration
4. Restart Molyseerr app
5. Navigate to Discover tab

**Expected:**
- ✅ "Available TV" slider appears in Discover page
- ✅ Shows TV shows with status AVAILABLE or PARTIALLY_AVAILABLE
- ✅ Sorted by "Recently Added"
- ✅ Maximum 20 items displayed
- ✅ Each card shows poster, title, and availability badge

### Test Case 1.3: Slider Data Accuracy
**Steps:**
1. Note down 3-5 available movies in Seerr web app
2. Open Molyseerr app → Discover tab
3. Find the "Available Movies" slider
4. Compare movies shown

**Expected:**
- ✅ Same movies appear in both web app and tvOS app
- ✅ Posters match TMDB posters
- ✅ Titles are correct
- ✅ Recently added items appear first

## 2️⃣ Movies Tab

### Test Case 2.1: Tab Navigation
**Steps:**
1. Launch Molyseerr app
2. Look at bottom tab bar
3. Select "Movies" tab

**Expected:**
- ✅ Three tabs visible: Discover, Movies, TV Shows
- ✅ "Movies" tab icon is a film symbol
- ✅ Tab switches instantly without loading
- ✅ Focus highlights current tab

### Test Case 2.2: Movies Page Layout
**Steps:**
1. Navigate to Movies tab
2. Observe page structure

**Expected:**
- ✅ Title "Movies" in top left
- ✅ 4 horizontal sliders:
  1. Available in Library
  2. Popular Movies
  3. Upcoming Releases
  4. Browse by Genre
- ✅ Each slider has "See All" button (currently non-functional)
- ✅ Scroll works smoothly horizontally

### Test Case 2.3: Available in Library Slider
**Steps:**
1. Navigate to Movies tab
2. Find "Available in Library" slider
3. Scroll through movies

**Expected:**
- ✅ Shows only movies with status AVAILABLE or PARTIALLY_AVAILABLE
- ✅ Sorted by date added (newest first)
- ✅ Up to 20 movies displayed
- ✅ Each card is focusable with zoom effect (8%)
- ✅ Tapping a card navigates to MediaDetailView

**Data Validation:**
- Compare with Seerr web /available/movies page
- Verify all shown movies are actually available in library

### Test Case 2.4: Popular Movies Slider
**Steps:**
1. Navigate to Movies tab
2. Find "Popular Movies" slider
3. Scroll through movies

**Expected:**
- ✅ Shows popular movies from TMDB
- ✅ Sorted by popularity (most popular first)
- ✅ Up to 20 movies displayed
- ✅ Mix of available and non-available movies
- ✅ Request button appears on non-available movies

### Test Case 2.5: Upcoming Releases Slider
**Steps:**
1. Navigate to Movies tab
2. Find "Upcoming Releases" slider
3. Check release dates

**Expected:**
- ✅ Shows only movies with future release dates
- ✅ Sorted by popularity (not release date)
- ✅ No upper date limit
- ✅ Release dates are in the future
- ✅ Shows "Coming Soon" badge or release date

### Test Case 2.6: Browse by Genre Section
**Steps:**
1. Navigate to Movies tab
2. Scroll to "Browse by Genre"
3. Observe genre cards

**Expected:**
- ✅ Genre cards displayed horizontally
- ✅ Each card 480x270px with backdrop image
- ✅ Genre name displayed on card
- ✅ Duotone gradient overlay
- ✅ Cards zoom 8% on focus
- ✅ Vertical padding prevents clipping

### Test Case 2.7: Genre Navigation
**Steps:**
1. Navigate to Movies tab
2. Scroll to genres section
3. Select "Action" genre (or any genre)

**Expected:**
- ✅ Navigates to GenreMoviesView
- ✅ Shows grid of movies in that genre
- ✅ Navigation title shows genre name
- ✅ Grid has adaptive columns (minimum 300px)
- ✅ Each card is focusable and clickable
- ✅ Back button returns to Movies tab

### Test Case 2.8: Parallel Loading
**Steps:**
1. Close app completely
2. Relaunch app
3. Navigate to Movies tab
4. Observe loading behavior

**Expected:**
- ✅ All 4 sections load simultaneously (not sequential)
- ✅ Loading state shows briefly (~1-2 seconds)
- ✅ Sections appear as data arrives
- ✅ No blocking or freezing
- ✅ Error in one section doesn't break others

## 3️⃣ TV Shows Tab

### Test Case 3.1: Tab Navigation
**Steps:**
1. Navigate to "TV Shows" tab
2. Observe page structure

**Expected:**
- ✅ Title "TV Shows" in top left
- ✅ Same 4-slider structure as Movies:
  1. Available in Library
  2. Popular TV Shows
  3. Upcoming Shows
  4. Browse by Genre

### Test Case 3.2: Available in Library Slider
**Steps:**
1. Navigate to TV Shows tab
2. Find "Available in Library" slider

**Expected:**
- ✅ Shows only TV shows with status AVAILABLE or PARTIALLY_AVAILABLE
- ✅ Sorted by date added
- ✅ Up to 20 shows displayed
- ✅ Shows poster, title, availability badge

### Test Case 3.3: Popular TV Shows Slider
**Steps:**
1. Navigate to TV Shows tab
2. Find "Popular TV Shows" slider

**Expected:**
- ✅ Shows popular TV shows from TMDB
- ✅ Sorted by popularity
- ✅ Up to 20 shows displayed
- ✅ Mix of available and non-available shows

### Test Case 3.4: Upcoming Shows Slider
**Steps:**
1. Navigate to TV Shows tab
2. Find "Upcoming Shows" slider

**Expected:**
- ✅ Shows TV shows with future air dates
- ✅ Sorted by popularity
- ✅ Shows with upcoming episodes/seasons

### Test Case 3.5: Genre Navigation
**Steps:**
1. Navigate to TV Shows tab
2. Select a genre (e.g., "Drama")

**Expected:**
- ✅ Navigates to GenreTVView
- ✅ Shows grid of TV shows in that genre
- ✅ Grid layout same as movies
- ✅ All cards focusable and clickable

## 4️⃣ Focus & Navigation (tvOS Specific)

### Test Case 4.1: Focus Effects
**Steps:**
1. Navigate through any slider
2. Observe focus behavior

**Expected:**
- ✅ Focused card scales to 108% (8% zoom)
- ✅ Shadow appears/grows on focus
- ✅ Animation duration 0.15s
- ✅ Smooth transitions
- ✅ No clipping (vertical padding works)

### Test Case 4.2: Scroll Behavior
**Steps:**
1. Navigate to Movies tab
2. Focus on first card in "Popular Movies"
3. Swipe right continuously on remote

**Expected:**
- ✅ Slider scrolls horizontally
- ✅ Focus follows scroll
- ✅ Smooth scrolling (no jank)
- ✅ End of slider stops scrolling
- ✅ Focus doesn't jump to other sliders

### Test Case 4.3: Vertical Navigation
**Steps:**
1. Navigate to Movies tab
2. Focus on a card in "Available in Library"
3. Swipe down on remote

**Expected:**
- ✅ Focus moves to "Popular Movies" slider
- ✅ Swipe down again → "Upcoming Releases"
- ✅ Swipe down again → "Browse by Genre"
- ✅ No unexpected focus jumps

### Test Case 4.4: Tab Switching
**Steps:**
1. Navigate to Movies tab
2. Focus on a movie card
3. Swipe to TV Shows tab
4. Swipe back to Movies tab

**Expected:**
- ✅ Focus state preserved per tab
- ✅ Scroll position maintained
- ✅ No reload on tab switch (data cached)
- ✅ Smooth transition

## 5️⃣ Error Handling

### Test Case 5.1: Network Error
**Steps:**
1. Disconnect from network
2. Navigate to Movies tab

**Expected:**
- ✅ Error message displayed
- ✅ "Retry" button appears
- ✅ App doesn't crash
- ✅ Other tabs still accessible

### Test Case 5.2: Empty Available Media
**Steps:**
1. Delete all available movies from Seerr
2. Navigate to Movies tab

**Expected:**
- ✅ "Available in Library" slider is empty or hidden
- ✅ Other sliders still show content
- ✅ No crash or error

### Test Case 5.3: API Timeout
**Steps:**
1. Simulate slow network (Network Link Conditioner)
2. Navigate to Movies tab

**Expected:**
- ✅ Loading state shows for extended period
- ✅ Eventually shows error or partial results
- ✅ App remains responsive
- ✅ User can navigate away

## 6️⃣ Performance

### Test Case 6.1: Memory Usage
**Steps:**
1. Open Instruments → Allocations
2. Navigate through all tabs
3. Scroll through all sliders
4. Navigate to genre pages

**Expected:**
- ✅ Memory usage stays reasonable (<200MB)
- ✅ No significant memory leaks
- ✅ Images released when off-screen

### Test Case 6.2: Scroll Performance
**Steps:**
1. Navigate to Movies tab
2. Rapidly scroll through "Popular Movies"
3. Monitor frame rate

**Expected:**
- ✅ 60 FPS maintained
- ✅ No stuttering or jank
- ✅ Images load smoothly
- ✅ Focus effects smooth

### Test Case 6.3: Initial Load Time
**Steps:**
1. Close app
2. Relaunch app
3. Time from launch to Movies tab fully loaded

**Expected:**
- ✅ Total time < 3 seconds
- ✅ Parallel loading visible in Network tab
- ✅ UI responsive during load

## 7️⃣ Data Integrity

### Test Case 7.1: Available Movies Match Seerr
**Steps:**
1. Open Seerr web → /available/movies
2. Note first 10 movies shown
3. Open Molyseerr → Discover tab → Available Movies slider
4. Compare movies

**Expected:**
- ✅ Same movies in same order
- ✅ Posters match
- ✅ Availability status matches

### Test Case 7.2: Genre Movies Match TMDB
**Steps:**
1. Open TMDB website → Browse Movies → Action
2. Note top 10 action movies
3. Open Molyseerr → Movies → Action genre
4. Compare movies

**Expected:**
- ✅ Similar movies appear (TMDB API may differ slightly)
- ✅ Posters are correct TMDB posters
- ✅ No duplicate entries

## 8️⃣ Edge Cases

### Test Case 8.1: Very Long Titles
**Steps:**
1. Find a movie/show with very long title
2. View in slider

**Expected:**
- ✅ Title truncates gracefully
- ✅ No layout breaking
- ✅ Ellipsis appears

### Test Case 8.2: Missing Posters
**Steps:**
1. Find media with no poster
2. View in slider

**Expected:**
- ✅ Placeholder image shown
- ✅ No broken image icon
- ✅ Card still focusable

### Test Case 8.3: Rapid Tab Switching
**Steps:**
1. Rapidly switch between Discover, Movies, TV Shows
2. Do this 10+ times quickly

**Expected:**
- ✅ No crashes
- ✅ No memory leaks
- ✅ Tabs load correctly each time
- ✅ Focus state preserved

## ✅ Test Checklist Summary

### Available Sliders (Discover Tab)
- [ ] Available Movies slider appears when enabled
- [ ] Available TV slider appears when enabled
- [ ] Data matches Seerr web app
- [ ] Sorting by "Recently Added" works
- [ ] Empty states handled gracefully

### Movies Tab
- [ ] Tab navigation works
- [ ] All 4 sliders load
- [ ] Available in Library shows correct movies
- [ ] Popular Movies loads from TMDB
- [ ] Upcoming Releases shows future movies
- [ ] Genre browsing works
- [ ] Genre detail pages work
- [ ] Parallel loading observable

### TV Shows Tab
- [ ] Tab navigation works
- [ ] All 4 sliders load
- [ ] Available in Library shows correct TV shows
- [ ] Popular TV Shows loads from TMDB
- [ ] Upcoming Shows works
- [ ] Genre browsing works
- [ ] Genre detail pages work

### Focus & Navigation
- [ ] Focus effects work (8% zoom)
- [ ] Horizontal scrolling smooth
- [ ] Vertical navigation between sliders works
- [ ] Tab switching preserves state
- [ ] No clipping on focus

### Error Handling
- [ ] Network errors handled
- [ ] Empty states handled
- [ ] Timeouts handled gracefully

### Performance
- [ ] Memory usage reasonable
- [ ] Scroll performance 60 FPS
- [ ] Initial load < 3 seconds

### Data Integrity
- [ ] Available media matches Seerr
- [ ] Genres match TMDB
- [ ] No duplicate entries

### Edge Cases
- [ ] Long titles handled
- [ ] Missing posters handled
- [ ] Rapid interactions don't crash

---

## 🐛 Bug Reporting Template

If you find issues, report with this format:

```markdown
### Bug: [Short description]

**Environment:**
- Seerr version: [version]
- tvOS version: [version]
- Device: Apple TV [model]

**Steps to Reproduce:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected Behavior:**
[What should happen]

**Actual Behavior:**
[What actually happens]

**Screenshots/Logs:**
[If applicable]

**Severity:**
- [ ] Critical (app crashes)
- [ ] High (feature broken)
- [ ] Medium (annoying but works)
- [ ] Low (cosmetic)
```

---

**Last Updated:** 2025-12-29
**Tested By:** [Your name]
**Status:** 🟡 Pending Testing
