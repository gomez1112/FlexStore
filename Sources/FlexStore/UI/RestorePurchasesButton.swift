//
//  RestorePurchasesButton.swift
//  FlexStore
//
//  Created by Gerard Gomez on 11/27/25.
//

import SwiftUI

public struct RestorePurchasesButton<Tier: SubscriptionTier, Label: View>: View {
    @Environment(StoreKitService<Tier>.self) private var store
    @State private var isRestoring = false
    
    private let label: (Bool) -> Label
    
    public init(@ViewBuilder label: @escaping (Bool) -> Label) {
        self.label = label
    }
    
    public var body: some View {
        Button {
            Task { @MainActor in
                guard !isRestoring else { return }
                isRestoring = true
                defer { isRestoring = false }
                await store.restorePurchases()
            }
        } label: {
            label(isRestoring)
        }
        .disabled(isRestoring)
    }
}

public extension RestorePurchasesButton where Label == AnyView {
    init(title: LocalizedStringKey = "Restore Purchases") {
        self.init { isRestoring in
            AnyView(
                Group {
                    if isRestoring { ProgressView() }
                    else { Text(title) }
                }
            )
        }
    }
}
