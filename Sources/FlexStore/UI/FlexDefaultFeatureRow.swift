//
//  FlexDefaultFeatureRow.swift
//  FlexStore
//
//  Created by Gerard Gomez on 12/14/25.
//


import SwiftUI

public struct FlexDefaultFeatureRow: View {
    private let feature: FlexPaywallFeature

    public init(_ feature: FlexPaywallFeature) {
        self.feature = feature
    }

    public var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(feature.tint.opacity(0.2))
                    .frame(width: 48, height: 48)

                Image(systemName: feature.systemImage)
                    .font(.title3)
                    .foregroundStyle(feature.tint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(feature.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
        )
    }
}
