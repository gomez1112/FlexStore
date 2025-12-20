//
//  ManageSubscriptionsButton.swift
//  FlexStore
//
//  Created by Gerard Gomez on 12/14/25.
//

import SwiftUI
import StoreKit

/// Default label used by ``ManageSubscriptionsButton``.
public struct FlexStoreDefaultManageSubscriptionsLabel: View {
    let isOpening: Bool
    let title: LocalizedStringKey
    let systemImage: String

    /// Creates the default manage subscriptions label.
    ///
    /// - Parameters:
    ///   - isOpening: Indicates the App Store sheet is being requested.
    ///   - title: Title to display inside the label.
    ///   - systemImage: Symbol to display with the title.
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

/// Button that opens the system manage-subscriptions sheet.
public struct ManageSubscriptionsButton: View {
    private let title: LocalizedStringKey
    private let systemImage: String

    /// Creates a manage subscriptions button.
    ///
    /// - Parameters:
    ///   - title: Title displayed in the label. Defaults to "Manage Subscriptions".
    ///   - systemImage: Symbol displayed next to the title. Defaults to `"gear"`.
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
    /// Supplies a custom label that reflects whether the App Store sheet is opening.
    ///
    /// - Parameter builder: Builder closure receiving `true` while the sheet request is in progress.
    /// - Returns: A view wrapping the button with a custom label.
    func label<Label: View>(
        @ViewBuilder _ builder: @escaping (Bool) -> Label
    ) -> some View {
        _ManageSubscriptionsButtonImpl(label: builder)
    }
}

private struct _ManageSubscriptionsButtonImpl<Label: View>: View {
    @Environment(\.openURL) private var openURL

    @State private var isOpening = false
    @State private var alert: FlexStoreError?
    @State private var showingManageSubscriptions = false

    let label: (Bool) -> Label

    var body: some View {
        Button {
            #if os(iOS) || os(visionOS)
            showingManageSubscriptions = true
            #else
            isOpening = true
            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                _ = openURL(url)
            }
            isOpening = false
            #endif
        } label: {
            label(isOpening)
        }
        .disabled(isOpening)
        .manageSubscriptionsSheetIfAvailable(isPresented: $showingManageSubscriptions)
        .alert(item: $alert) { error in
            Alert(
                title: Text(error.title),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

private extension View {
    @ViewBuilder
    func manageSubscriptionsSheetIfAvailable(isPresented: Binding<Bool>) -> some View {
        #if os(iOS) || os(visionOS)
        manageSubscriptionsSheet(isPresented: isPresented)
        #else
        self
        #endif
    }
}
