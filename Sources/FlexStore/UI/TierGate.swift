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
