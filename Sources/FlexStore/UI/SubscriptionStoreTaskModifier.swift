//
//  File.swift
//  FlexStore
//
//  Created by Gerard Gomez on 11/27/25.
//

import SwiftUI

private struct StoreKitAttachModifier<Tier: SubscriptionTier>: ViewModifier {
    let manager: StoreKitService<Tier>
    let groupID: String?
    let productIDs: Set<String>
    
    @Environment(\.scenePhase) private var scenePhase
    
    func body(content: Content) -> some View {
        content
            .environment(manager)
            .task(id: productIDs) {
                if !productIDs.isEmpty {
                    await manager.loadProducts(productIDs)
                }
            }
            .task(id: groupID) {
                // Configure group ID + refresh when it changes
                if let groupID {
                    await manager.refreshSubscriptionStatus(groupID: groupID)
                }
            }
            .task {
                // Ensure non-consumables are hydrated on first appearance
                await manager.configure(productIDs: [], subscriptionGroupID: nil)
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active, let groupID else { return }
                Task { await manager.refreshSubscriptionStatus(groupID: groupID) }
            }
    }
}

public extension View {
    /// Attaches a `StoreKitService` to the environment and performs initial loading.
    func attachStoreKit<Tier: SubscriptionTier>(
        manager: StoreKitService<Tier>,
        groupID: String? = nil,
        ids: Set<String> = []
    ) -> some View {
        modifier(StoreKitAttachModifier(manager: manager, groupID: groupID, productIDs: ids))
    }
}
