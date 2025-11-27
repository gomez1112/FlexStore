//
//  File.swift
//  FlexStore
//
//  Created by Gerard Gomez on 11/27/25.
//

import SwiftUI
import StoreKit

/// A generic "Pass" store view wrapping `SubscriptionStoreView`.
public struct SubscriptionPassStoreView<Tier: SubscriptionTier, MarketingContent: View>: View {
    private let groupID: String
    private let visibleRelationships: Product.SubscriptionRelationship
    private let iconProvider: (Tier) -> Image
    private let marketing: () -> MarketingContent
    
    public init(
        groupID: String,
        visibleRelationships: Product.SubscriptionRelationship = .all,
        iconProvider: @escaping (Tier) -> Image = { _ in Image(systemName: "star.fill") },
        @ViewBuilder marketing: @escaping () -> MarketingContent
    ) {
        self.groupID = groupID
        self.visibleRelationships = visibleRelationships
        self.iconProvider = iconProvider
        self.marketing = marketing
    }
    
    public var body: some View {
        SubscriptionStoreView(groupID: groupID, visibleRelationships: visibleRelationships) {
            marketing()
#if !os(watchOS)
                .padding(.vertical, 30)
#endif
        }
        .subscriptionStoreControlIcon { _, info in
            // Map the StoreKit Group Level back to our Tier to determine the icon
            let tier = Tier(levelOfService: info.groupLevel) ?? .defaultTier
            iconProvider(tier)
                .symbolVariant(.fill)
        }
#if !os(watchOS)
        .subscriptionStoreButtonLabel(.multiline)
        .subscriptionStorePickerItemBackground(.thinMaterial)
#endif
    }
}
