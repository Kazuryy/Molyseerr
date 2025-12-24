//
//  MediaInfo.swift
//  Molyseerr
//
//  Created by Claude on 24/12/2025.
//

import Foundation

/// Media entity from Seerr database
/// Source: seerr-api.yml MediaInfo schema & TVOS_ARCH_SPEC.md Section 3.6
/// CRITICAL: Contains status, requests, and metadata needed for button logic
struct MediaInfo: Codable, Identifiable {
    let id: Int
    let tmdbId: Int
    let tvdbId: Int?
    let status: MediaStatus
    let status4k: MediaStatus?
    let requests: [MediaRequest]?
    let createdAt: String
    let updatedAt: String
    let plexUrl: String?
    let jellyfinMediaId: String?
    let mediaAddedAt: String?
}
