//
//  File.swift
//  FlexStore
//
//  Created by Gerard Gomez on 11/27/25.
//

import SwiftUI

/// Hard gate: renders `unlocked` only if `requiredTier` is met.
public struct TierGate<Tier: SubscriptionTier, Unlocked: View, Locked: View>: View {
    @Environment(StoreKitService<Tier>.self) private var store

    private let requiredTier: Tier
    private let unlocked: () -> Unlocked
    private let locked: () -> Locked

    /// Creates a tier gate.
    ///
    /// - Parameters:
    ///   - requiredTier: Minimum tier required to see the unlocked content.
    ///   - unlocked: Builder for the content shown when access is granted.
    ///   - locked: Builder for the fallback content when access is denied.
    public init(
        requiredTier: Tier,
        @ViewBuilder unlocked: @escaping () -> Unlocked,
        @ViewBuilder locked: @escaping () -> Locked
    ) {
        self.requiredTier = requiredTier
        self.unlocked = unlocked
        self.locked = locked
    }
    
    public var body: some View {
        if store.subscriptionTier >= requiredTier {
            unlocked()
        } else {
            locked()
        }
    }
}
