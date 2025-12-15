//
//  ConsumablePurchaseButton.swift
//  FlexStore
//
//  Created by Gerard Gomez on 12/14/25.
//
import SwiftUI

// MARK: - State

/// Purchase state for consumable transactions.
public enum FlexStoreConsumablePurchaseState: Equatable, Sendable {
    case idle
    case purchasing
    case success
}

// MARK: - Default Label

/// Default label used by ``ConsumablePurchaseButton``.
public struct FlexStoreDefaultConsumableLabel: View {
    let state: FlexStoreConsumablePurchaseState
    let title: LocalizedStringKey
    let successTitle: LocalizedStringKey

    /// Creates the default consumable label.
    ///
    /// - Parameters:
    ///   - state: Current purchase state.
    ///   - title: Title shown before purchase.
    ///   - successTitle: Title shown when the purchase succeeds.
    public init(
        state: FlexStoreConsumablePurchaseState,
        title: LocalizedStringKey,
        successTitle: LocalizedStringKey
    ) {
        self.state = state
        self.title = title
        self.successTitle = successTitle
    }
    
    public var body: some View {
        switch state {
            case .purchasing:
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Processing…")
                }
            case .success:
                Label(successTitle, systemImage: "checkmark.circle.fill")
            case .idle:
                Text(title)
        }
    }
}

// MARK: - Public Button (clean call site)

/// Button that purchases a consumable product and briefly shows success state.
public struct ConsumablePurchaseButton<Tier: SubscriptionTier>: View {
    private let productID: String
    private let title: LocalizedStringKey
    private let successTitle: LocalizedStringKey
    private let resetAfter: Duration?

    /// Creates a consumable purchase button.
    ///
    /// - Parameters:
    ///   - productID: Identifier of the consumable product.
    ///   - title: Title shown while idle. Defaults to "Buy".
    ///   - successTitle: Title shown after a successful purchase. Defaults to "Added".
    ///   - resetAfter: Duration after which the success state resets to idle. Pass `nil` to keep the success state.
    public init(
        productID: String,
        title: LocalizedStringKey = "Buy",
        successTitle: LocalizedStringKey = "Added",
        resetAfter: Duration? = .seconds(1.2)
    ) {
        self.productID = productID
        self.title = title
        self.successTitle = successTitle
        self.resetAfter = resetAfter
    }
    
    public var body: some View {
        _ConsumablePurchaseButtonImpl<Tier, FlexStoreDefaultConsumableLabel>(
            productID: productID,
            resetAfter: resetAfter
        ) { state in
            FlexStoreDefaultConsumableLabel(state: state, title: title, successTitle: successTitle)
        }
    }
}

// MARK: - Custom Label API (no extra generics at call site)

public extension ConsumablePurchaseButton {
    /// Supplies a custom label that reacts to consumable purchase state changes.
    ///
    /// - Parameter builder: Builder closure receiving the current purchase state.
    /// - Returns: A view wrapping the button with a custom label.
    func label<Label: View>(
        @ViewBuilder _ builder: @escaping (FlexStoreConsumablePurchaseState) -> Label
    ) -> some View {
        _ConsumablePurchaseButtonImpl<Tier, Label>(
            productID: productID,
            resetAfter: resetAfter,
            label: builder
        )
    }
}

// MARK: - Implementation (internal)

private struct _ConsumablePurchaseButtonImpl<Tier: SubscriptionTier, Label: View>: View {
    @Environment(StoreKitService<Tier>.self) private var store
    
    let productID: String
    let resetAfter: Duration?
    let label: (FlexStoreConsumablePurchaseState) -> Label
    
    @State private var state: FlexStoreConsumablePurchaseState = .idle
    @State private var alert: FlexStoreError?
    
    var body: some View {
        Button {
            Task { @MainActor in
                await purchase()
            }
        } label: {
            label(state)
        }
        .disabled(state == .purchasing)
        .alert(item: $alert) { err in
            Alert(
                title: Text(err.title),
                message: Text(err.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    @MainActor
    private func purchase() async {
        guard state != .purchasing else { return }
        
        state = .purchasing
        defer {
            if state == .purchasing { state = .idle }
        }
        
        do {
            let outcome = try await store.purchase(productID: productID)
            switch outcome {
                case .success:
                    state = .success
                    if let resetAfter {
                        Task { @MainActor in
                            try? await Task.sleep(for: resetAfter)
                            if state == .success { state = .idle }
                        }
                    }
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


