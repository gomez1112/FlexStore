//
//  FlexFeatureSpotlightViewModel.swift
//  FlexStore
//
//  Created by Gerard Gomez on 12/14/25.
//

import Observation
import SwiftUI

/// View model that powers the rotating paywall feature spotlight.
@MainActor
@Observable
public final class FlexFeatureSpotlightViewModel {
    /// The feature list that can be spotlighted.
    public private(set) var features: [FlexPaywallFeature]

    /// The index of the currently highlighted feature.
    public private(set) var currentIndex: Int = 0

    /// Interval for auto-advancing the spotlight. Set to `nil` to disable auto-advance.
    public var autoAdvanceInterval: Duration?

    @ObservationIgnored
    private var autoAdvanceTask: Task<Void, Never>?

    /// Creates a new spotlight view model.
    ///
    /// - Parameters:
    ///   - features: List of paywall features to rotate through.
    ///   - autoAdvanceInterval: Duration to wait before moving to the next feature.
    public init(features: [FlexPaywallFeature], autoAdvanceInterval: Duration? = .seconds(6)) {
        self.features = features
        self.autoAdvanceInterval = autoAdvanceInterval
    }

    deinit {
        autoAdvanceTask?.cancel()
    }

    /// The current feature being highlighted, if any.
    public var currentFeature: FlexPaywallFeature? {
        guard !features.isEmpty else { return nil }
        return features[currentIndex]
    }

    /// Replace the list of features and reset the spotlight if needed.
    public func updateFeatures(_ features: [FlexPaywallFeature]) {
        self.features = features
        if currentIndex >= features.count {
            currentIndex = 0
        }
    }

    /// Advance to the next feature in the list.
    public func goToNext() {
        guard !features.isEmpty else { return }
        currentIndex = (currentIndex + 1) % features.count
    }

    /// Move to the previous feature in the list.
    public func goToPrevious() {
        guard !features.isEmpty else { return }
        currentIndex = (currentIndex - 1 + features.count) % features.count
    }

    /// Begin automatically advancing through features, if an interval is set.
    public func startAutoAdvance() {
        guard let interval = autoAdvanceInterval else { return }
        stopAutoAdvance()

        autoAdvanceTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: interval)
                } catch {
                    return
                }

                if Task.isCancelled { return }
                self.goToNext()
            }
        }
    }

    /// Stop automatically advancing the spotlight.
    public func stopAutoAdvance() {
        autoAdvanceTask?.cancel()
        autoAdvanceTask = nil
    }
}
