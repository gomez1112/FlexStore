//
//  RestorePurchasesButton.swift
//  FlexStore
//
//  Created by Gerard Gomez on 11/27/25.

import SwiftUI

// MARK: - Default Label

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

// MARK: - Public Button (clean call site)

public struct RestorePurchasesButton<Tier: SubscriptionTier>: View {
    private let title: LocalizedStringKey
    
    public init(title: LocalizedStringKey = "Restore Purchases") {
        self.title = title
    }
    
    public var body: some View {
        _RestorePurchasesButtonImpl<Tier, FlexStoreDefaultRestoreLabel> { isRestoring in
            FlexStoreDefaultRestoreLabel(isRestoring: isRestoring, title: title)
        }
    }
}

// MARK: - Custom Label API

public extension RestorePurchasesButton {
    func label<Label: View>(
        @ViewBuilder _ builder: @escaping (Bool) -> Label
    ) -> some View {
        _RestorePurchasesButtonImpl<Tier, Label>(label: builder)
    }
}

// MARK: - Implementation (internal)

private struct _RestorePurchasesButtonImpl<Tier: SubscriptionTier, Label: View>: View {
    @Environment(StoreKitService<Tier>.self) private var store
    @State private var isRestoring = false
    
    let label: (Bool) -> Label
    
    var body: some View {
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


