//
//  FlexFeatureSpotlightView.swift
//  FlexStore
//
//  Created by Gerard Gomez on 12/14/25.
//

import SwiftUI

/// A rotating, single-feature spotlight for subscription paywalls.
public struct FlexFeatureSpotlightView: View {
    @State private var viewModel: FlexFeatureSpotlightViewModel
    private let showsControls: Bool

    @ScaledMetric private var horizontalPadding: CGFloat = 20
    @ScaledMetric private var verticalPadding: CGFloat = 18
    @ScaledMetric private var contentSpacing: CGFloat = 16
    @ScaledMetric private var iconSize: CGFloat = 44
    @ScaledMetric private var cornerRadius: CGFloat = 24
    @ScaledMetric private var controlSpacing: CGFloat = 12
    @ScaledMetric private var indicatorSize: CGFloat = 8
    @ScaledMetric private var buttonPadding: CGFloat = 8

    /// Creates a feature spotlight with an internal view model.
    ///
    /// - Parameters:
    ///   - features: The features to spotlight.
    ///   - autoAdvanceInterval: Duration between auto-advances. Set to `nil` to disable.
    ///   - showsControls: Whether to show paging controls.
    public init(
        features: [FlexPaywallFeature],
        autoAdvanceInterval: Duration? = .seconds(6),
        showsControls: Bool = true
    ) {
        _viewModel = State(initialValue: FlexFeatureSpotlightViewModel(
            features: features,
            autoAdvanceInterval: autoAdvanceInterval
        ))
        self.showsControls = showsControls
    }

    /// Creates a feature spotlight using a caller-provided view model.
    ///
    /// - Parameters:
    ///   - viewModel: The view model powering the spotlight.
    ///   - showsControls: Whether to show paging controls.
    public init(viewModel: FlexFeatureSpotlightViewModel, showsControls: Bool = true) {
        _viewModel = State(initialValue: viewModel)
        self.showsControls = showsControls
    }

    public var body: some View {
        VStack(spacing: contentSpacing) {
            if let feature = viewModel.currentFeature {
                FlexFeatureSpotlightCard(
                    feature: feature,
                    iconSize: iconSize,
                    horizontalPadding: horizontalPadding,
                    verticalPadding: verticalPadding,
                    cornerRadius: cornerRadius
                )

                if showsControls {
                    FlexFeatureSpotlightControls(
                        viewModel: viewModel,
                        indicatorSize: indicatorSize,
                        controlSpacing: controlSpacing,
                        buttonPadding: buttonPadding
                    )
                }
            } else {
                FlexFeatureSpotlightEmptyState(
                    horizontalPadding: horizontalPadding,
                    verticalPadding: verticalPadding,
                    cornerRadius: cornerRadius
                )
            }
        }
        .task {
            viewModel.startAutoAdvance()
        }
        .onDisappear {
            viewModel.stopAutoAdvance()
        }
    }
}

private struct FlexFeatureSpotlightCard: View {
    let feature: FlexPaywallFeature
    let iconSize: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        HStack(alignment: .center, spacing: horizontalPadding * 0.6) {
            ZStack {
                feature.tint.opacity(0.2)
                    .frame(width: iconSize, height: iconSize)
                    .clipShape(.circle)

                Image(systemName: feature.systemImage)
                    .font(.title3)
                    .foregroundStyle(feature.tint)
            }

            VStack(alignment: .leading, spacing: verticalPadding * 0.2) {
                Text(feature.title)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(feature.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
        )
    }
}

private struct FlexFeatureSpotlightControls: View {
    @Bindable var viewModel: FlexFeatureSpotlightViewModel
    let indicatorSize: CGFloat
    let controlSpacing: CGFloat
    let buttonPadding: CGFloat

    var body: some View {
        HStack(spacing: controlSpacing) {
            Button("Previous", systemImage: "chevron.left") {
                viewModel.goToPrevious()
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.bordered)
            .padding(buttonPadding)

            FlexFeatureSpotlightIndicators(
                count: viewModel.features.count,
                currentIndex: viewModel.currentIndex,
                indicatorSize: indicatorSize,
                controlSpacing: controlSpacing
            )

            Button("Next", systemImage: "chevron.right") {
                viewModel.goToNext()
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.bordered)
            .padding(buttonPadding)
        }
    }
}

private struct FlexFeatureSpotlightIndicators: View {
    let count: Int
    let currentIndex: Int
    let indicatorSize: CGFloat
    let controlSpacing: CGFloat

    var body: some View {
        HStack(spacing: controlSpacing * 0.4) {
            ForEach(0..<count, id: \.self) { index in
                Color.white
                    .opacity(index == currentIndex ? 1 : 0.4)
                    .frame(width: indicatorSize, height: indicatorSize)
                    .clipShape(.circle)
            }
        }
        .accessibilityLabel("Feature spotlight")
        .accessibilityValue("\(currentIndex + 1) of \(max(count, 1))")
    }
}

private struct FlexFeatureSpotlightEmptyState: View {
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        VStack(spacing: verticalPadding * 0.3) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("Add features to spotlight")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
        )
    }
}
