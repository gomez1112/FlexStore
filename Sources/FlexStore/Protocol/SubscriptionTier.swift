//
//  File.swift
//  FlexStore
//
//  Created by Gerard Gomez on 11/27/25.
//

import Foundation

/// App-defined access tiers (free/pro, bronze/silver/gold, etc).
///
/// You can map from:
/// - StoreKit subscription group "level of service" (preferred)
/// - product identifier (fallback)
public protocol SubscriptionTier: Comparable, Hashable, CaseIterable, Sendable {
    /// The tier to use when a user has no active subscription.
    static var defaultTier: Self { get }

    /// Map from App Store Connect subscription group "level of service".
    init?(levelOfService: Int)

    /// Fallback map from product identifier.
    init?(productID: String)
}

/// Default ordering uses `allCases` order.
/// If you want a different ordering, implement `<` in your Tier type.
public extension SubscriptionTier {
    /// Default comparator that follows the order of `allCases`.
    static func < (lhs: Self, rhs: Self) -> Bool {
        guard let left = Self.allCases.firstIndex(of: lhs),
              let right = Self.allCases.firstIndex(of: rhs) else {
            preconditionFailure("A SubscriptionTier value must occur in allCases")
        }
        return left < right
    }
}

public extension SubscriptionTier where Self: RawRepresentable, RawValue: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}
