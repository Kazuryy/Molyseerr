//
//  GenreColorHelper.swift
//  Molyseerr
//
//  Created by Claude on 27/12/2025.
//

import SwiftUI

/// Helper to map TMDB genre IDs to duotone color gradients
/// Matches the visual style from Seerr web app
struct GenreColorHelper {

    /// Get gradient colors for a genre
    /// Returns a tuple of (primary, secondary) colors for gradient overlay
    static func getColors(for genreId: Int) -> (Color, Color) {
        switch genreId {
        // Action (28) - Red tones
        case 28:
            return (Color(red: 220/255, green: 38/255, blue: 38/255),
                   Color(red: 127/255, green: 29/255, blue: 29/255))

        // Adventure (12) - Green tones
        case 12:
            return (Color(red: 34/255, green: 197/255, blue: 94/255),
                   Color(red: 21/255, green: 128/255, blue: 61/255))

        // Animation (16) - Pink tones
        case 16:
            return (Color(red: 236/255, green: 72/255, blue: 153/255),
                   Color(red: 157/255, green: 23/255, blue: 77/255))

        // Comedy (35) - Orange tones
        case 35:
            return (Color(red: 251/255, green: 146/255, blue: 60/255),
                   Color(red: 194/255, green: 65/255, blue: 12/255))

        // Crime (80) - Dark red tones
        case 80:
            return (Color(red: 185/255, green: 28/255, blue: 28/255),
                   Color(red: 127/255, green: 29/255, blue: 29/255))

        // Documentary (99) - Teal tones
        case 99:
            return (Color(red: 20/255, green: 184/255, blue: 166/255),
                   Color(red: 13/255, green: 148/255, blue: 136/255))

        // Drama (18) - Purple tones
        case 18:
            return (Color(red: 168/255, green: 85/255, blue: 247/255),
                   Color(red: 107/255, green: 33/255, blue: 168/255))

        // Family (10751) - Yellow tones
        case 10751:
            return (Color(red: 250/255, green: 204/255, blue: 21/255),
                   Color(red: 202/255, green: 138/255, blue: 4/255))

        // Fantasy (14) - Indigo tones
        case 14:
            return (Color(red: 129/255, green: 140/255, blue: 248/255),
                   Color(red: 67/255, green: 56/255, blue: 202/255))

        // History (36) - Brown tones
        case 36:
            return (Color(red: 180/255, green: 83/255, blue: 9/255),
                   Color(red: 120/255, green: 53/255, blue: 15/255))

        // Horror (27) - Black tones
        case 27:
            return (Color(red: 64/255, green: 64/255, blue: 64/255),
                   Color(red: 23/255, green: 23/255, blue: 23/255))

        // Music (10402) - Cyan tones
        case 10402:
            return (Color(red: 34/255, green: 211/255, blue: 238/255),
                   Color(red: 8/255, green: 145/255, blue: 178/255))

        // Mystery (9648) - Deep purple tones
        case 9648:
            return (Color(red: 139/255, green: 92/255, blue: 246/255),
                   Color(red: 88/255, green: 28/255, blue: 135/255))

        // Romance (10749) - Rose tones
        case 10749:
            return (Color(red: 251/255, green: 113/255, blue: 133/255),
                   Color(red: 190/255, green: 18/255, blue: 60/255))

        // Science Fiction (878) - Light blue tones
        case 878:
            return (Color(red: 56/255, green: 189/255, blue: 248/255),
                   Color(red: 3/255, green: 105/255, blue: 161/255))

        // TV Movie (10770) - Gray-blue tones
        case 10770:
            return (Color(red: 100/255, green: 116/255, blue: 139/255),
                   Color(red: 51/255, green: 65/255, blue: 85/255))

        // Thriller (53) - Dark teal tones
        case 53:
            return (Color(red: 20/255, green: 184/255, blue: 166/255),
                   Color(red: 17/255, green: 94/255, blue: 89/255))

        // War (10752) - Olive tones
        case 10752:
            return (Color(red: 132/255, green: 204/255, blue: 22/255),
                   Color(red: 77/255, green: 124/255, blue: 15/255))

        // Western (37) - Amber tones
        case 37:
            return (Color(red: 245/255, green: 158/255, blue: 11/255),
                   Color(red: 180/255, green: 83/255, blue: 9/255))

        // TV Genres
        // Action & Adventure (10759) - Red tones
        case 10759:
            return (Color(red: 220/255, green: 38/255, blue: 38/255),
                   Color(red: 127/255, green: 29/255, blue: 29/255))

        // Kids (10762) - Bright yellow
        case 10762:
            return (Color(red: 253/255, green: 224/255, blue: 71/255),
                   Color(red: 234/255, green: 179/255, blue: 8/255))

        // News (10763) - Blue tones
        case 10763:
            return (Color(red: 59/255, green: 130/255, blue: 246/255),
                   Color(red: 29/255, green: 78/255, blue: 216/255))

        // Reality (10764) - Orange-red
        case 10764:
            return (Color(red: 249/255, green: 115/255, blue: 22/255),
                   Color(red: 194/255, green: 65/255, blue: 12/255))

        // Sci-Fi & Fantasy (10765) - Purple-blue
        case 10765:
            return (Color(red: 147/255, green: 51/255, blue: 234/255),
                   Color(red: 88/255, green: 28/255, blue: 135/255))

        // Soap (10766) - Pink
        case 10766:
            return (Color(red: 244/255, green: 114/255, blue: 182/255),
                   Color(red: 190/255, green: 24/255, blue: 93/255))

        // Talk (10767) - Sky blue
        case 10767:
            return (Color(red: 14/255, green: 165/255, blue: 233/255),
                   Color(red: 2/255, green: 132/255, blue: 199/255))

        // War & Politics (10768) - Dark green
        case 10768:
            return (Color(red: 34/255, green: 197/255, blue: 94/255),
                   Color(red: 22/255, green: 101/255, blue: 52/255))

        // Default fallback - Purple (Seerr brand color)
        default:
            return (Color(red: 139/255, green: 92/255, blue: 246/255),
                   Color(red: 109/255, green: 40/255, blue: 217/255))
        }
    }
}
