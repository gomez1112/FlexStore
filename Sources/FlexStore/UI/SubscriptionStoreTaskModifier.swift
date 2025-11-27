//
//  File.swift
//  FlexStore
//
//  Created by Gerard Gomez on 11/27/25.
//

import SwiftUI
import StoreKit

struct SubscriptionStoreTaskModifier<Tier: SubscriptionTier>: ViewModifier {
    let manager: StoreKitService<Tier>
    let groupID: String?
    let productIDs: Set<String>
    
    @Environment(\.scenePhase) private var scenePhase
    
    func body(content: Content) -> some View {
        content
        // Inject Manager for @Environment usage
            .environment(manager)
            .task {
                if !productIDs.isEmpty {
                    await manager.loadProducts(productIDs)
                }
                if let groupID {
                    await manager.refreshSubscriptionStatus(groupID: groupID)
                }
            }
        // Re-check if products update (rare)
            .onChange(of: manager.products) { _, _ in
                if let groupID { Task { await manager.refreshSubscriptionStatus(groupID: groupID) } }
            }
        // Re-check on foreground
            .onChange(of: scenePhase) { _, phase in
                if phase == .active, let groupID {
                    Task { await manager.refreshSubscriptionStatus(groupID: groupID) }
                }
            }
    }
}

public extension View {
    /// Attach the StoreKitManager to the view hierarchy.
    /// - Parameters:
    ///   - manager: Your `@State` manager instance.
    ///   - groupID: The Subscription Group ID (optional, nil if only using consumables).
    ///   - ids: All product IDs to load.
    func attachStoreKit<Tier: SubscriptionTier>(
        manager: StoreKitService<Tier>,
        groupID: String?,
        ids: Set<String>
    ) -> some View {
        modifier(SubscriptionStoreTaskModifier(manager: manager, groupID: groupID, productIDs: ids))
    }
}
