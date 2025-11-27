//
//  File.swift
//  FlexStore
//
//  Created by Gerard Gomez on 11/27/25.
//

import Foundation

/// A protocol that lets the app define its own access levels / tiers.
///
/// Example conformance:
/// ```swift
/// enum AppTier: Int, SubscriptionTier {
///     case free = 0
///     case gold = 1
///
///     static var defaultTier: AppTier { .free }
///
///     // Map from StoreKit Group Level (set in App Store Connect)
///     init?(levelOfService: Int) {
///         self.init(rawValue: levelOfService)
///     }
///
///     // Fallback Map from Product ID
///     init?(productID: String) {
///         switch productID {
///         case "com.app.gold": self = .gold
///         default: return nil
///         }
///     }
/// }
/// ```
public protocol SubscriptionTier: Comparable, Hashable, CaseIterable, Sendable {
    /// The default state (e.g. `.free`, `.guest`).
    static var defaultTier: Self { get }
    
    /// Initialize from a StoreKit subscription group "level of service" integer.
    init?(levelOfService: Int)
    
    /// Initialize from a product identifier.
    init?(productID: String)
}
