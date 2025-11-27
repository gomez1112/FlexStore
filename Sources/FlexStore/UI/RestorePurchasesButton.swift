//
//  RestorePurchasesButton.swift
//  FlexStore
//
//  Created by Gerard Gomez on 11/27/25.
//

import SwiftUI

public struct RestorePurchasesButton<Tier: SubscriptionTier>: View {
    @Environment(StoreKitService<Tier>.self) private var store
    @State private var isRestoring = false
    
    public init() {}
    
    public var body: some View {
        Button {
            isRestoring = true
            Task {
                await store.restorePurchases()
                isRestoring = false
            }
        } label: {
            if isRestoring {
                ProgressView()
            } else {
                Text("Restore Purchases")
            }
        }
        .disabled(isRestoring)
    }
}
