//
//  RestorePurchasesButton.swift
//  FlexStore
//
//  Created by Gerard Gomez on 11/27/25.

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

// MARK: - Default Label (no AnyView)

public extension RestorePurchasesButton where Label == FlexStoreDefaultRestoreLabel {
    /// Nice call site:
    /// `RestorePurchasesButton<AppTier>()`
    /// or `RestorePurchasesButton<AppTier>(title: "Restore")`
    init(title: LocalizedStringKey = "Restore Purchases") {
        self.init { isRestoring in
            FlexStoreDefaultRestoreLabel(isRestoring: isRestoring, title: title)
        }
    }
}

public struct FlexStoreDefaultRestoreLabel: View {
    let isRestoring: Bool
    let title: LocalizedStringKey
    
    public init(isRestoring: Bool, title: LocalizedStringKey) {
        self.isRestoring = isRestoring
        self.title = title
    }
    
    public var body: some View {
        if isRestoring {
            HStack(spacing: 8) {
                ProgressView()
                Text("Restoring…")
            }
        } else {
            Text(title)
        }
    }
}

