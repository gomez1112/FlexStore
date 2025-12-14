//
//  NonConsumablePurchaseButton.swift
//  FlexStore
//
//  Created by Gerard Gomez on 11/27/25.
//

import SwiftUI

public struct NonConsumablePurchaseButton<Tier: SubscriptionTier>: View {
    @Environment(StoreKitService<Tier>.self) private var store
    
    private let productID: String
    private let label: String
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    
    public init(productID: String, label: String = "Purchase") {
        self.productID = productID
        self.label = label
    }
    
    public var body: some View {
        Button {
            Task {
                isPurchasing = true
                defer { isPurchasing = false }
                
                guard let product = store.products.first(where: { $0.id == productID }) else {
                    errorMessage = "Product not found."
                    return
                }
                
                do {
                    _ = try await store.purchase(product)
                } catch is CancellationError {
                    // User cancelled; do nothing.
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        } label: {
            if isPurchasing {
                ProgressView()
            } else {
                Text(label)
            }
        }
        .disabled(isPurchasing)
        .alert("Purchase Error", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK") { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "Unknown error")
        })
    }
}
