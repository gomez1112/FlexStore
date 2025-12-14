//
//  FlexSubscriptionPaywall.swift
//  FlexStore
//
//  Created by Gerard Gomez on 12/14/25.
//


import SwiftUI
import StoreKit

public struct FlexSubscriptionPaywall<Tier: SubscriptionTier, Header: View, Background: View, FeatureRow: View>: View {
    private let groupID: String
    private let visibleRelationships: Product.SubscriptionRelationship

    private let header: () -> Header
    private let background: () -> Background

    private let sectionTitle: LocalizedStringKey
    private let features: [FlexPaywallFeature]
    private let featureRow: (FlexPaywallFeature) -> FeatureRow

    private let pickerItemMaterial: Material
    private let useMultilineButtonLabel: Bool

    private let iconProvider: (Tier, Product) -> Image
    private let onPurchaseCompletion: (@MainActor (Product) -> Void)?

    public init(
        groupID: String,
        visibleRelationships: Product.SubscriptionRelationship = .all,
        sectionTitle: LocalizedStringKey = "What's Included",
        features: [FlexPaywallFeature] = [],
        pickerItemMaterial: Material = .ultraThinMaterial,
        useMultilineButtonLabel: Bool = true,
        iconProvider: @escaping (Tier, Product) -> Image,
        onPurchaseCompletion: (@MainActor (Product) -> Void)? = nil,
        @ViewBuilder background: @escaping () -> Background,
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder featureRow: @escaping (FlexPaywallFeature) -> FeatureRow
    ) {
        self.groupID = groupID
        self.visibleRelationships = visibleRelationships
        self.sectionTitle = sectionTitle
        self.features = features
        self.pickerItemMaterial = pickerItemMaterial
        self.useMultilineButtonLabel = useMultilineButtonLabel
        self.iconProvider = iconProvider
        self.onPurchaseCompletion = onPurchaseCompletion
        self.background = background
        self.header = header
        self.featureRow = featureRow
    }

    public var body: some View {
            SubscriptionStoreView(groupID: groupID, visibleRelationships: visibleRelationships) {
                VStack(spacing: 0) {
                    header()
                        .padding(.bottom, 28)

                    if !features.isEmpty {
                        featuresSection
                    }
                }
                .containerBackground(for: .subscriptionStoreFullHeight) {
                    background()
                }
            }
            .backgroundStyle(.clear)
            .subscriptionStoreControlIcon { product, info in
                // Don’t name SubscriptionStoreControlInfo. Use it.
                let tier =
                    Tier(levelOfService: info.groupLevel)
                    ?? Tier(productID: product.id)
                    ?? .defaultTier

                return iconProvider(tier, product).symbolVariant(.fill)
            }
            .onInAppPurchaseCompletion { product, result in
                // Only dismiss / callback on success.
                // `result` is inferred; we don’t need to name it.
                if case .success = result {
                    onPurchaseCompletion?(product)
                }
            }

#if !os(watchOS)
            .subscriptionStorePickerItemBackground(pickerItemMaterial)
            .subscriptionStoreButtonLabel(useMultilineButtonLabel ? .multiline : .singleLine)
#endif
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(sectionTitle)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach(features) { feature in
                    featureRow(feature)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}
