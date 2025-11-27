//
//  File.swift
//  FlexStore
//
//  Created by Gerard Gomez on 11/27/25.
//

import SwiftUI

/// Soft Gate: Blurs content and shows an overlay if `requiredTier` is not met.
public struct BlurredTierGate<Tier: SubscriptionTier, Content: View>: View {
    @Environment(StoreKitService<Tier>.self) private var store
    
    private let requiredTier: Tier
    private let title: LocalizedStringKey
    private let message: LocalizedStringKey
    private let buttonTitle: LocalizedStringKey
    private let onUpgrade: () -> Void
    private let content: () -> Content
    
    public init(
        requiredTier: Tier,
        title: LocalizedStringKey = "Premium Feature",
        message: LocalizedStringKey = "Unlock this feature with a pass.",
        buttonTitle: LocalizedStringKey = "View Options",
        onUpgrade: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.requiredTier = requiredTier
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.onUpgrade = onUpgrade
        self.content = content
    }
    
    public var body: some View {
        let isUnlocked = store.subscriptionTier >= requiredTier
        
        ZStack {
            content()
                .blur(radius: isUnlocked ? 0 : 8)
                .allowsHitTesting(isUnlocked)
            
            if !isUnlocked {
                VStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    
                    Text(title)
                        .font(.headline)
                    
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: onUpgrade) {
                        Text(buttonTitle)
                            .padding(.horizontal, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(20)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 10)
                .padding()
            }
        }
    }
}
