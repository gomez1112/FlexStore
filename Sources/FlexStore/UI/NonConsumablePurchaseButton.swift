//
//  NonConsumablePurchaseButton.swift
//  FlexStore
//
//  Created by Gerard Gomez on 11/27/25.
//

import SwiftUI

public struct NonConsumablePurchaseButton<Tier: SubscriptionTier, Label: View>: View {
    @Environment(StoreKitService<Tier>.self) private var store
    
    private let productID: String
    private let label: (PurchaseState) -> Label
    
    @State private var state: PurchaseState = .idle
    @State private var alert: FlexStoreError?
    
    public enum PurchaseState: Equatable, Sendable {
        case idle
        case purchasing
        case purchased
    }
    
    public init(
        productID: String,
        @ViewBuilder label: @escaping (PurchaseState) -> Label
    ) {
        self.productID = productID
        self.label = label
    }
    
    public var body: some View {
        let alreadyOwned = store.purchasedNonConsumables.contains(productID)
        
        Button {
            Task { @MainActor in
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
                            // StoreKitService processes + finishes transactions.
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
}

// MARK: - Convenience init

public extension NonConsumablePurchaseButton where Label == AnyView {
    init(productID: String, title: LocalizedStringKey = "Purchase") {
        self.init(productID: productID) { state in
            AnyView(
                Group {
                    switch state {
                        case .purchasing:
                            ProgressView()
                        case .purchased:
                            Text("Purchased")
                        case .idle:
                            Text(title)
                    }
                }
            )
        }
    }
}
