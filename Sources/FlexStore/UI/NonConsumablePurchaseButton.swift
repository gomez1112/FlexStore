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
                await MainActor.run { isPurchasing = true }
                if let product = store.products.first(where: { $0.id == productID }) {
                    do {
                        let result = try await store.purchase(product)
                        // Handle specific result cases if needed
                        // If your StoreKitService exposes a cancellable outcome, you could set a friendly message.
                        // For now, we do nothing on success.
                        _ = result
                    } catch is CancellationError {
                        await MainActor.run { errorMessage = "Purchase was cancelled." }
                    } catch {
                        await MainActor.run { errorMessage = error.localizedDescription }
                    }
                }
                await MainActor.run { isPurchasing = false }
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
