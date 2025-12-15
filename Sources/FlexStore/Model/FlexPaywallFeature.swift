//
//  FlexPaywallFeature.swift
//  FlexStore
//
//  Created by Gerard Gomez on 12/14/25.
//


import SwiftUI

/// Describes a feature highlighted on a subscription paywall.
public struct FlexPaywallFeature: Identifiable, Hashable, Sendable {
    /// Stable identifier for the feature row.
    public var id: String

    /// SF Symbol name shown alongside the feature.
    public var systemImage: String

    /// Primary title for the feature.
    public var title: String

    /// Supporting subtitle describing the feature benefit.
    public var subtitle: String

    /// Accent color used when rendering the feature row.
    public var tint: Color

    /// Creates a new paywall feature description.
    ///
    /// - Parameters:
    ///   - id: Optional identifier. Defaults to a generated UUID string.
    ///   - systemImage: SF Symbol to display.
    ///   - title: Title for the feature.
    ///   - subtitle: Subtitle copy providing context.
    ///   - tint: Accent color for the row. Defaults to `.accentColor`.
    public init(
        id: String = UUID().uuidString,
        systemImage: String,
        title: String,
        subtitle: String,
        tint: Color = .accentColor
    ) {
        self.id = id
        self.systemImage = systemImage
        self.title = title
        self.subtitle = subtitle
        self.tint = tint
    }
}
