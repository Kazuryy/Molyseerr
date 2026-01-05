//
//  SliderLoadingCoordinator.swift
//  Molyseerr
//
//  Created by Claude on 04/01/2026.
//

import Foundation

/// Coordinates slider loading to prevent API overload
/// Limits concurrent slider loads and prioritizes visible sliders
actor SliderLoadingCoordinator {
    static let shared = SliderLoadingCoordinator()

    private var activeLoads = 0
    private let maxConcurrentLoads = 6  // Increased from 3 to 6 for better performance
    private var waitingQueue: [CheckedContinuation<Void, Never>] = []

    // Track initial preload progress
    private var totalSliders = 0
    private var loadedSliders = 0
    private var isPreloading = false

    private init() {}

    /// Start preloading mode (for initial app load)
    func startPreload(totalCount: Int) {
        isPreloading = true
        totalSliders = totalCount
        loadedSliders = 0
    }

    /// Finish preloading mode
    func finishPreload() {
        isPreloading = false
    }

    /// Get preload progress (0.0 to 1.0)
    func getPreloadProgress() -> Double {
        guard totalSliders > 0 else { return 1.0 }
        return Double(loadedSliders) / Double(totalSliders)
    }

    /// Request permission to load a slider
    /// Waits if too many sliders are already loading
    func requestLoad() async {
        if activeLoads >= maxConcurrentLoads {
            // Too many active loads, wait in queue
            await withCheckedContinuation { continuation in
                waitingQueue.append(continuation)
            }
        }

        activeLoads += 1
    }

    /// Signal that a slider finished loading
    func finishLoad() {
        activeLoads -= 1

        if isPreloading {
            loadedSliders += 1
        }

        // Allow next waiting slider to load
        if !waitingQueue.isEmpty {
            let next = waitingQueue.removeFirst()
            next.resume()
        }
    }

    /// Get current load count (for debugging)
    func getCurrentLoadCount() -> Int {
        return activeLoads
    }
}
