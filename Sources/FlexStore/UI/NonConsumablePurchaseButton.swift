//
//  NonConsumablePurchaseButton.swift
//  FlexStore
//
//  Created by Gerard Gomez on 11/27/25.

import SwiftUI

// MARK: - State

/// Purchase state for non-consumable products.
public enum FlexStoreNonConsumablePurchaseState: Equatable, Sendable {
    case idle
    case purchasing
    case purchased
}

// MARK: - Default Label

/// Default label used by ``NonConsumablePurchaseButton``.
public struct FlexStoreDefaultNonConsumableLabel: View {
    let state: FlexStoreNonConsumablePurchaseState
    let title: LocalizedStringKey
    let purchasedTitle: LocalizedStringKey

    /// Creates the default non-consumable label.
    ///
    /// - Parameters:
    ///   - state: Current purchase state.
    ///   - title: Title to display before purchase.
    ///   - purchasedTitle: Title to display after the purchase is owned.
    public init(
        state: FlexStoreNonConsumablePurchaseState,
        title: LocalizedStringKey,
        purchasedTitle: LocalizedStringKey
    ) {
        self.state = state
        self.title = title
        self.purchasedTitle = purchasedTitle
    }
    
    public var body: some View {
        switch state {
            case .purchasing:
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Purchasing…")
                }
            case .purchased:
                Label(purchasedTitle, systemImage: "checkmark.circle.fill")
            case .idle:
                Text(title)
        }
    }
}

// MARK: - Public Button (clean call site)

/// Button that purchases a non-consumable product and reflects the purchase state.
public struct NonConsumablePurchaseButton<Tier: SubscriptionTier>: View {
    private let productID: String
    private let title: LocalizedStringKey
    private let purchasedTitle: LocalizedStringKey

    /// Creates a non-consumable purchase button.
    ///
    /// - Parameters:
    ///   - productID: The identifier of the non-consumable product to buy.
    ///   - title: Title shown before purchase. Defaults to "Purchase".
    ///   - purchasedTitle: Title shown when the item is already owned. Defaults to "Purchased".
    public init(
        productID: String,
        title: LocalizedStringKey = "Purchase",
        purchasedTitle: LocalizedStringKey = "Purchased"
    ) {
        self.productID = productID
        self.title = title
        self.purchasedTitle = purchasedTitle
    }
    
    public var body: some View {
        _NonConsumablePurchaseButtonImpl<Tier, FlexStoreDefaultNonConsumableLabel>(
            productID: productID
        ) { state in
            FlexStoreDefaultNonConsumableLabel(state: state, title: title, purchasedTitle: purchasedTitle)
        }
    }
}

// MARK: - Custom Label API

public extension NonConsumablePurchaseButton {
    /// Supplies a custom label that reacts to purchase state changes.
    ///
    /// - Parameter builder: Builder closure receiving the current purchase state.
    /// - Returns: A view that wraps the button with a custom label.
    func label<Label: View>(
        @ViewBuilder _ builder: @escaping (FlexStoreNonConsumablePurchaseState) -> Label
    ) -> some View {
        _NonConsumablePurchaseButtonImpl<Tier, Label>(
            productID: productID,
            label: builder
        )
    }
}

// MARK: - Implementation (internal)

private struct _NonConsumablePurchaseButtonImpl<Tier: SubscriptionTier, Label: View>: View {
    @Environment(StoreKitService<Tier>.self) private var store
    
    let productID: String
    let label: (FlexStoreNonConsumablePurchaseState) -> Label
    
    @State private var state: FlexStoreNonConsumablePurchaseState = .idle
    @State private var alert: FlexStoreError?
    
    var body: some View {
        let alreadyOwned = store.purchasedNonConsumables.contains(productID)
        
        Button {
            Task { @MainActor in
                await purchase(alreadyOwned: alreadyOwned)
            }
        } label: {
            label(alreadyOwned ? .purchased : state)
        }
        .disabled(state == .purchasing || alreadyOwned)
        .alert(item: $alert) { err in
            Alert(
                title: Text(err.title),
                message: Text(err.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    @MainActor
    private func purchase(alreadyOwned: Bool) async {
        guard state != .purchasing else { return }
        
        if alreadyOwned {
            state = .purchased
            return
        }
        
        state = .purchasing
        defer {
            if store.purchasedNonConsumables.contains(productID) {
                state = .purchased
            } else if state == .purchasing {
                state = .idle
            }
        }
        
        do {
            let outcome = try await store.purchase(productID: productID)
            switch outcome {
                case .success:
                    // StoreKitService will process entitlement updates.
                    break
                case .cancelled:
                    alert = FlexStoreError(title: "Cancelled", message: "Purchase was cancelled.")
                case .pending:
                    alert = FlexStoreError(title: "Pending", message: "Purchase is pending approval.")
            }
        } catch let e as FlexStoreError {
            alert = e
        } catch {
            alert = FlexStoreError(title: "Purchase Error", message: error.localizedDescription)
        }
    }
}

