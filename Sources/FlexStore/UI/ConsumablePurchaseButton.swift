//
//  ConsumablePurchaseButton.swift
//  FlexStore
//
//  Created by Gerard Gomez on 12/14/25.
//

import SwiftUI

/// Not nested inside a generic type -> avoids the “parent type” conversion problem.
public enum FlexStoreConsumablePurchaseState: Equatable, Sendable {
    case idle
    case purchasing
    case success
}

public struct ConsumablePurchaseButton<Tier: SubscriptionTier, Label: View>: View {
    @Environment(StoreKitService<Tier>.self) private var store
    
    private let productID: String
    private let resetAfter: Duration?
    private let label: (FlexStoreConsumablePurchaseState) -> Label
    
    @State private var state: FlexStoreConsumablePurchaseState = .idle
    @State private var alert: FlexStoreError?
    
    public init(
        productID: String,
        resetAfter: Duration? = .seconds(1.2),
        @ViewBuilder label: @escaping (FlexStoreConsumablePurchaseState) -> Label
    ) {
        self.productID = productID
        self.resetAfter = resetAfter
        self.label = label
    }
    
    public var body: some View {
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

// MARK: - Default Label (no AnyView)

public extension ConsumablePurchaseButton where Label == FlexStoreDefaultConsumableLabel {
    /// Nice call site:
    /// `ConsumablePurchaseButton<AppTier>(productID: "com.app.hints10")`
    init(
        productID: String,
        title: LocalizedStringKey = "Buy",
        successTitle: LocalizedStringKey = "Added"
    ) {
        self.init(productID: productID) { state in
            FlexStoreDefaultConsumableLabel(
                state: state,
                title: title,
                successTitle: successTitle
            )
        }
    }
}

public struct FlexStoreDefaultConsumableLabel: View {
    let state: FlexStoreConsumablePurchaseState
    let title: LocalizedStringKey
    let successTitle: LocalizedStringKey
    
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

