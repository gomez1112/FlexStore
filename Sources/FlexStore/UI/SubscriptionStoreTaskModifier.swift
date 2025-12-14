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
    
    private var taskKey: String {
        let idsKey = productIDs.sorted().joined(separator: "|")
        return "\(groupID ?? "")::\(idsKey)"
    }
    
    func body(content: Content) -> some View {
        content
            .environment(manager)
            .task(id: taskKey) {
                await manager.configure(productIDs: productIDs, subscriptionGroupID: groupID)
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
