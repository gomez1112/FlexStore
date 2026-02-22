//
//  File.swift
//  FlexStore
//
//  Created by Gerard Gomez on 11/27/25.
//


import SwiftUI
import StoreKit

/// A generic "Pass" store view wrapping `SubscriptionStoreView`.
/// - Supports tier-based icons AND per-product icons (monthly vs yearly).
public struct SubscriptionPassStoreView<Tier: SubscriptionTier, MarketingContent: View>: View {
    private let groupID: String
    private let visibleRelationships: Product.SubscriptionRelationship
    private let iconProvider: (Tier, Product) -> Image
    private let marketing: () -> MarketingContent
    private let policies: SubscriptionStorePolicies?

    /// Creates a subscription pass store view with custom marketing content and iconography.
    ///
    /// - Parameters:
    ///   - groupID: Subscription group identifier to present.
    ///   - visibleRelationships: Filters which subscription relationships are shown. Defaults to `.all`.
    ///   - iconProvider: Closure returning an icon for the resolved tier and product.
    ///   - policies: Optional custom destinations for privacy policy and terms links.
    ///   - marketing: View builder used to present marketing content above the picker.
    public init(
        groupID: String,
        visibleRelationships: Product.SubscriptionRelationship = .all,
        iconProvider: @escaping (Tier, Product) -> Image = { _, _ in Image(systemName: "star.fill") },
        policies: SubscriptionStorePolicies? = nil,
        @ViewBuilder marketing: @escaping () -> MarketingContent
    ) {
        self.groupID = groupID
        self.visibleRelationships = visibleRelationships
        self.iconProvider = iconProvider
        self.policies = policies
        self.marketing = marketing
    }
    
    public var body: some View {
        SubscriptionStoreView(groupID: groupID, visibleRelationships: visibleRelationships) {
            marketing()
#if !os(watchOS)
                .padding(.vertical, 30)
#endif
        }
        .subscriptionStoreControlIcon { product, info in
            // Prefer group-level mapping, fallback to productID mapping.
            let tier =
            Tier(levelOfService: info.groupLevel)
            ?? Tier(productID: product.id)
            ?? .defaultTier
            
            return iconProvider(tier, product)
                .symbolVariant(.fill)
        }
        .flexStorePolicies(policies)
#if !os(watchOS)
        .subscriptionStoreButtonLabel(.multiline)
        .subscriptionStorePickerItemBackground(.thinMaterial)
#endif
    }
}
