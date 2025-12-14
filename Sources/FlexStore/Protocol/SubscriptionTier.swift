//
//  File.swift
//  FlexStore
//
//  Created by Gerard Gomez on 11/27/25.
//

import Foundation

public protocol SubscriptionTier: Comparable, Hashable, CaseIterable, Sendable {
    /// The default state (e.g. .free, .guest).
    static var defaultTier: Self { get }
    
    /// Initialize from a product identifier.
    /// This MUST be able to resolve purely from the string, without network calls.
    init?(productID: String)
}

public extension SubscriptionTier where Self: RawRepresentable, Self.RawValue: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
