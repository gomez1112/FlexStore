//
//  File.swift
//  FlexStore
//
//  Created by Gerard Gomez on 11/27/25.
//

import SwiftUI

/// A pre-styled Marketing Hero View.
public struct DefaultPassMarketingView: View {
    public let title: LocalizedStringKey
    public let subtitle: LocalizedStringKey?
    public let features: [LocalizedStringKey]
    public let highlight: LocalizedStringKey?
    
    public init(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        features: [LocalizedStringKey] = [],
        highlight: LocalizedStringKey? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.features = features
        self.highlight = highlight
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            
            if let subtitle {
                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if !features.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(features.enumerated()), id: \.offset) { _, feature in
                        Label {
                            Text(feature)
                        } icon: {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        .font(.callout)
                    }
                }
                .padding(.top, 8)
            }
            
            if let highlight {
                Text(highlight)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.thinMaterial, in: Capsule())
                    .padding(.top, 10)
            }
        }
        .padding(24)
        .frame(maxWidth: 400)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.accentColor.opacity(0.1))
        }
    }
}

