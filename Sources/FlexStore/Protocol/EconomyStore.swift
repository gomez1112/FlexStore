//
//  EconomyStore.swift
//  FlexStore
//
//  Created by Gerard Gomez on 12/14/25.
//


import Foundation

/// Interface that applies consumable grants to an app-defined economy model.
public protocol EconomyStore: Sendable {
    /// Applies a consumable grant to the backing store.
    ///
    /// - Parameter grant: The consumable to apply.
    @MainActor
    func apply(_ grant: ConsumableGrant) throws
}
