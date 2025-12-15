//
//  ConsumableGrant.swift
//  FlexStore
//
//  Created by Gerard Gomez on 12/14/25.
//


import Foundation
import Observation

/// What the purchase “means” to the app.
public struct ConsumableGrant: Hashable, Sendable {
    /// High-level categories of consumables.
    public enum Kind: Hashable, Sendable {
        /// General-purpose hints or tips.
        case hints
        /// Currency-like consumable.
        case coins
        /// Custom token identified by name for flexible economies.
        case tokens(String) // for custom currencies
    }

    /// The type of consumable being granted.
    public var kind: Kind

    /// The number of units to award.
    public var amount: Int

    /// Creates a consumable grant.
    ///
    /// - Parameters:
    ///   - kind: The consumable kind to award.
    ///   - amount: The quantity being granted.
    public init(_ kind: Kind, amount: Int) {
        self.kind = kind
        self.amount = amount
    }
}

/// Declarative mapping from product IDs -> consumable meaning.
/// Supports:
/// - exact IDs ("com.app.hints10" -> 10 hints)
/// - suffix integer parsing ("com.app.hints" + "10" -> 10 hints)
public struct ConsumableCatalog: Sendable {
    private var exact: [String: ConsumableGrant] = [:]
    private var suffixRules: [SuffixRule] = []

    /// Creates an empty catalog.
    public init() {}

    // MARK: - Register

    /// Registers an exact product identifier mapping to a consumable grant.
    ///
    /// - Parameters:
    ///   - productID: Exact product identifier to match.
    ///   - grant: The consumable grant to apply.
    public mutating func registerExact(_ productID: String, grant: ConsumableGrant) {
        exact[productID] = grant
    }

    /// Matches product IDs like: "\(prefix)\(digits)"
    /// Example: prefix "com.app.hints" matches "com.app.hints10", "com.app.hints50"
    ///
    /// - Parameters:
    ///   - prefix: Product identifier prefix before the numeric quantity.
    ///   - kind: Consumable kind associated with the numeric suffix.
    public mutating func registerSuffixInt(prefix: String, kind: ConsumableGrant.Kind) {
        suffixRules.append(.init(prefix: prefix, kind: kind))
    }

    // MARK: - Resolve

    /// Resolves a consumable grant for the provided product identifier.
    ///
    /// - Parameter productID: The purchased product identifier.
    /// - Returns: A `ConsumableGrant` when a match is found; otherwise `nil`.
    public func grant(for productID: String) -> ConsumableGrant? {
        if let g = exact[productID] { return g }

        for rule in suffixRules {
            guard productID.hasPrefix(rule.prefix) else { continue }
            let suffix = productID.dropFirst(rule.prefix.count)
            guard let amount = Int(suffix), amount > 0 else { continue }
            return ConsumableGrant(rule.kind, amount: amount)
        }

        return nil
    }

    private struct SuffixRule: Sendable {
        let prefix: String
        let kind: ConsumableGrant.Kind
    }
}

/// Convenience: build the StoreKitService callback from a catalog.
/// Usage:
/// store.onConsumablePurchased = catalog.makeHandler { grant in ... }
public extension ConsumableCatalog {
    /// Builds a handler you can assign to `StoreKitService.onConsumablePurchased` to apply grants automatically.
    ///
    /// - Parameter apply: Closure that applies the resolved grant.
    /// - Returns: A handler that accepts a product identifier and invokes `apply` when a grant exists.
    func makeHandler(_ apply: @escaping @MainActor @Sendable (ConsumableGrant) -> Void) -> @MainActor @Sendable (String) -> Void {
        { productID in
            guard let grant = self.grant(for: productID) else { return }
            apply(grant)
        }
    }
}
