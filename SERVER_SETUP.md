# Server Setup Guide - Enabling Available Media Sliders

## 📋 Overview

For the Available Movies and Available TV sliders to appear in the Discover tab, they must be **enabled in your Seerr server settings**. This guide walks you through the server-side configuration.

## 🔧 Prerequisites

- Seerr server installed and running
- Admin access to Seerr web interface
- At least one media item with status "Available" (5) or "Partially Available" (4)

## 🚀 Step-by-Step Configuration

### 1. Access Seerr Web Interface

1. Open your browser
2. Navigate to your Seerr server URL
   ```
   Example: http://localhost:5055
   ```
3. Log in with admin credentials

### 2. Navigate to Discover Settings

1. Click **Settings** in the sidebar
2. Click **Discover** in the settings menu

You should see a page with two columns:
- **Enabled Sliders** (left)
- **Available Sliders** (right)

### 3. Enable Available Movies Slider

**Option A: Drag & Drop**
1. Find **"Available Movies"** in the "Available Sliders" column (right)
2. Drag it to the **"Enabled Sliders"** column (left)
3. Position it where you want it to appear in the order

**Option B: Click to Add**
1. Find **"Available Movies"** in the "Available Sliders" column
2. Click the **"+"** button (if available)
3. It will move to "Enabled Sliders"

### 4. Enable Available TV Slider

Repeat the same process for **"Available TV"**:
1. Find **"Available TV"** in the "Available Sliders" column
2. Drag or click to add it to "Enabled Sliders"
3. Position it in your desired order

### 5. Configure Slider Order (Optional)

You can reorder sliders by dragging them up or down in the **"Enabled Sliders"** column.

**Recommended Order:**
1. Recently Added
2. Available Movies
3. Available TV
4. Popular Movies
5. Popular TV
6. Movie Genres
7. TV Genres
8. Upcoming Movies
9. Upcoming TV
10. (Other sliders as desired)

### 6. Save Configuration

1. Click **"Save Changes"** at the bottom of the page
2. Wait for confirmation message

### 7. Verify in Molyseerr App

1. Close and reopen Molyseerr app (to refresh config)
2. Navigate to **Discover** tab
3. You should now see:
   - "Available Movies" slider
   - "Available TV" slider

## 📊 Slider Details

### Available Movies Slider
- **Type ID:** 24
- **Data Source:** `/api/v1/available/movies?type=movie`
- **Displays:** Movies with status AVAILABLE (5) or PARTIALLY_AVAILABLE (4)
- **Sort Order:** Recently Added (newest first)
- **Limit:** 20 movies

### Available TV Slider
- **Type ID:** 25
- **Data Source:** `/api/v1/available/movies?type=tv`
- **Displays:** TV shows with status AVAILABLE (5) or PARTIALLY_AVAILABLE (4)
- **Sort Order:** Recently Added (newest first)
- **Limit:** 20 shows

## 🐛 Troubleshooting

### Sliders Don't Appear in App

**Problem:** Enabled sliders on server but don't see them in Molyseerr.

**Solutions:**
1. **Force-close and reopen** the app
2. **Check network connection** - ensure app can reach server
3. **Verify API key** - ensure authentication is valid
4. **Check server logs** - look for errors in `/api/v1/settings/discover`
5. **Clear app cache** - delete and reinstall app (nuclear option)

### Sliders Are Empty

**Problem:** Sliders appear but show no content.

**Possible Causes:**
1. **No available media** - you haven't downloaded any movies/TV shows yet
   - Solution: Add media to your library via requests or manual import
   - Check Seerr → Media to confirm media exists with status "Available"

2. **Permission issues** - user doesn't have access to view available media
   - Solution: Check user permissions in Settings → Users
   - Ensure user has "VIEW_MEDIA" permission

3. **API error** - server error when fetching available media
   - Solution: Check server logs for errors
   - Look for `/api/v1/available/movies` endpoint errors

### Sliders Show Wrong Content

**Problem:** Available Movies shows TV shows or vice versa.

**This shouldn't happen** - if it does, it's a bug. Report it with:
- Server version
- App version
- Screenshots
- Server logs from `/api/v1/available/movies` calls

## 🔍 Verifying Server Setup

### Check via API (Advanced)

You can manually test the endpoint using `curl`:

**Test Available Movies:**
```bash
curl -X GET "http://your-server:5055/api/v1/available/movies?type=movie&page=1" \
  -H "X-Api-Key: your-api-key" \
  -H "Accept: application/json"
```

**Expected Response:**
```json
{
  "page": 1,
  "totalPages": 3,
  "totalResults": 55,
  "results": [
    {
      "id": 550,
      "mediaType": "movie",
      "title": "Fight Club",
      "posterPath": "/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg",
      "mediaInfo": {
        "status": 5,
        "mediaAddedAt": "2025-01-20T15:30:00.000Z"
      }
    }
  ]
}
```

**Test Available TV:**
```bash
curl -X GET "http://your-server:5055/api/v1/available/movies?type=tv&page=1" \
  -H "X-Api-Key: your-api-key" \
  -H "Accept: application/json"
```

If these return empty results (`"results": []`), you need to add media to your library first.

### Check Slider Configuration

**Get current slider config:**
```bash
curl -X GET "http://your-server:5055/api/v1/settings/discover" \
  -H "X-Api-Key: your-api-key" \
  -H "Accept: application/json"
```

**Look for in response:**
```json
[
  {
    "id": "abc123",
    "type": 24,
    "title": "Available Movies",
    "enabled": true,
    "data": null
  },
  {
    "id": "def456",
    "type": 25,
    "title": "Available TV",
    "enabled": true,
    "data": null
  }
]
```

If `"enabled": false`, the sliders are not active.

## 📝 Notes

### Media Status Codes
```
1 = UNKNOWN
2 = PENDING
3 = PROCESSING
4 = PARTIALLY_AVAILABLE  ← Shows in "Available" sliders
5 = AVAILABLE            ← Shows in "Available" sliders
6 = BLACKLISTED
7 = DELETED
```

### Difference: Recently Added vs Available

**Recently Added Slider:**
- Shows last 20 items added to library
- Filter: `allavailable` (status 4 or 5)
- Sort: `mediaAdded` DESC
- Includes both movies AND TV shows

**Available Movies Slider:**
- Shows available movies only
- Filter: status 4 or 5 + `mediaType = movie`
- Sort: `mediaAddedAt` DESC
- Maximum 20 items

**Available TV Slider:**
- Shows available TV shows only
- Filter: status 4 or 5 + `mediaType = tv`
- Sort: `mediaAddedAt` DESC
- Maximum 20 items

### Client-Side Filtering

The server returns enriched TMDB data for each item, allowing future client-side filtering by:
- Genre
- Release year
- Rating
- Studio/Network
- Language

These filters are not yet implemented in the app but the data is available.

## 🎯 Recommended Slider Setup

For optimal user experience, enable these sliders in this order:

### Discovery-Focused (Default View)
1. **Recently Added** - Shows newest content regardless of type
2. **Trending** - Popular across movies & TV
3. **Movie Genres** - Visual genre browsing for movies
4. **TV Genres** - Visual genre browsing for TV
5. **Today's Releases** - Calendar-based new episodes/movies

### Content-Focused (Movies/TV Tabs)
The new dedicated Movies and TV tabs make the following sliders **less critical** in Discover:
- Popular Movies (now in Movies tab)
- Popular TV (now in TV Shows tab)
- Upcoming Movies (now in Movies tab)
- Upcoming TV (now in TV Shows tab)
- Available Movies (now in Movies tab)
- Available TV (now in TV Shows tab)

**Consider disabling these from Discover** to reduce clutter, since users can now access them via dedicated tabs.

## ✅ Verification Checklist

After configuration, verify:
- [ ] Available Movies slider appears in Discover tab
- [ ] Available TV slider appears in Discover tab
- [ ] Sliders show correct media (movies vs TV)
- [ ] Media items have posters and titles
- [ ] Clicking a media item opens details page
- [ ] Recently added items appear first
- [ ] Empty sliders handled gracefully (if no available media)

## 🔄 Updating Configuration

To change slider order or disable sliders:
1. Go back to Settings → Discover
2. Drag sliders to reorder
3. Drag sliders to "Available Sliders" column to disable
4. Save changes
5. Refresh Molyseerr app

Changes take effect immediately after app refresh.

## 📞 Support

If you encounter issues:
1. Check this guide's troubleshooting section
2. Review server logs in `/logs` directory
3. Open an issue on GitHub with:
   - Server version
   - App version
   - Steps to reproduce
   - Server logs
   - Screenshots

---

**Last Updated:** 2025-12-29
**Applies to:** Seerr v3.0+ and Molyseerr v1.0+
