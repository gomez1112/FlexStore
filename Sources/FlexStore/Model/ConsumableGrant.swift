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
    public enum Kind: Hashable, Sendable {
        case hints
        case coins
        case tokens(String) // for custom currencies
    }

    public var kind: Kind
    public var amount: Int

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

    public init() {}

    // MARK: - Register

    public mutating func registerExact(_ productID: String, grant: ConsumableGrant) {
        exact[productID] = grant
    }

    /// Matches product IDs like: "\(prefix)\(digits)"
    /// Example: prefix "com.app.hints" matches "com.app.hints10", "com.app.hints50"
    public mutating func registerSuffixInt(prefix: String, kind: ConsumableGrant.Kind) {
        suffixRules.append(.init(prefix: prefix, kind: kind))
    }

    // MARK: - Resolve

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
    func makeHandler(_ apply: @escaping @MainActor @Sendable (ConsumableGrant) -> Void) -> @MainActor @Sendable (String) -> Void {
        { productID in
            guard let grant = self.grant(for: productID) else { return }
            apply(grant)
        }
    }
}
