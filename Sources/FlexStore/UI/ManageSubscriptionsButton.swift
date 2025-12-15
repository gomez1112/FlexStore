//
//  ManageSubscriptionsButton.swift
//  FlexStore
//
//  Created by Gerard Gomez on 12/14/25.
//

import SwiftUI
import StoreKit

public struct FlexStoreDefaultManageSubscriptionsLabel: View {
    let isOpening: Bool
    let title: LocalizedStringKey
    let systemImage: String

    public init(
        isOpening: Bool,
        title: LocalizedStringKey,
        systemImage: String
    ) {
        self.isOpening = isOpening
        self.title = title
        self.systemImage = systemImage
    }

    public var body: some View {
        if isOpening {
            HStack {
                ProgressView()
                Text("Opening App Store…")
            }
        } else {
            Label(title, systemImage: systemImage)
        }
    }
}

public struct ManageSubscriptionsButton: View {
    private let title: LocalizedStringKey
    private let systemImage: String

    public init(
        title: LocalizedStringKey = "Manage Subscriptions",
        systemImage: String = "gear"
    ) {
        self.title = title
        self.systemImage = systemImage
    }

    public var body: some View {
        _ManageSubscriptionsButtonImpl { isOpening in
            FlexStoreDefaultManageSubscriptionsLabel(
                isOpening: isOpening,
                title: title,
                systemImage: systemImage
            )
        }
    }
}

public extension ManageSubscriptionsButton {
    func label<Label: View>(
        @ViewBuilder _ builder: @escaping (Bool) -> Label
    ) -> some View {
        _ManageSubscriptionsButtonImpl(label: builder)
    }
}

private struct _ManageSubscriptionsButtonImpl<Label: View>: View {
    @State private var isOpening = false
    @State private var alert: FlexStoreError?

    let label: (Bool) -> Label

    var body: some View {
        Button {
            Task { @MainActor in
                await openManageSubscriptions()
            }
        } label: {
            label(isOpening)
        }
        .disabled(isOpening)
        .alert(item: $alert) { error in
            Alert(
                title: Text(error.title),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    @MainActor
    private func openManageSubscriptions() async {
        guard !isOpening else { return }

        isOpening = true
        defer { isOpening = false }

        do {
            try await AppStore.showManageSubscriptions()
        } catch {
            alert = FlexStoreError(
                title: "Unable to Open",
                message: error.localizedDescription
            )
        }
    }
}
