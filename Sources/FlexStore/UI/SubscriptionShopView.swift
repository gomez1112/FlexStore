//
//  SubscriptionShopView.swift
//  FlexStore
//
//  Created by Gerard Gomez on 11/27/25.
//

import SwiftUI
import StoreKit

// MARK: - Configuration

/// Configuration object for customizing the subscription shop appearance
public struct SubscriptionShopConfiguration {
    public let title: String
    public let subtitle: String
    public let heroImage: ImageResource?
    public let heroSystemImage: String?
    public let features: [SubscriptionFeature]?
    public let tiers: [AppSubscriptionTier]
    public let theme: SubscriptionShopTheme
    public let pickerBackground: AnyShapeStyle
    public let policies: SubscriptionStorePolicies?
    
    /// Full initializer with all options
    public init(
        title: String,
        subtitle: String,
        heroImage: ImageResource? = nil,
        heroSystemImage: String? = nil,
        features: [SubscriptionFeature]? = nil,
        tiers: [AppSubscriptionTier],
        theme: SubscriptionShopTheme = .default,
        pickerBackground: some ShapeStyle = Material.thinMaterial,
        policies: SubscriptionStorePolicies? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.heroImage = heroImage
        self.heroSystemImage = heroSystemImage
        self.features = features
        self.tiers = tiers
        self.theme = theme
        self.pickerBackground = AnyShapeStyle(pickerBackground)
        self.policies = policies
    }
    
    /// Convenience initializer for simple setup (Apple-style, no features list)
    public static func simple(
        title: String,
        subtitle: String,
        heroImage: ImageResource? = nil,
        heroSystemImage: String? = nil,
        tiers: [AppSubscriptionTier],
        theme: SubscriptionShopTheme = .default,
        pickerBackground: some ShapeStyle = Material.thinMaterial,
        policies: SubscriptionStorePolicies? = nil
    ) -> SubscriptionShopConfiguration {
        SubscriptionShopConfiguration(
            title: title,
            subtitle: subtitle,
            heroImage: heroImage,
            heroSystemImage: heroSystemImage,
            features: nil,
            tiers: tiers,
            theme: theme,
            pickerBackground: pickerBackground,
            policies: policies
        )
    }
}

/// Represents a feature to display in the subscription shop
public struct SubscriptionFeature: Identifiable {
    public let id = UUID()
    public let icon: String
    public let title: String
    public let description: String
    public let accentColor: Color
    
    public init(icon: String, title: String, description: String, accentColor: Color) {
        self.icon = icon
        self.title = title
        self.description = description
        self.accentColor = accentColor
    }
}

/// Represents a subscription tier with its associated product ID and visual styling
public struct AppSubscriptionTier: Identifiable {
    public let id: String // Product ID
    public let image: ImageResource?
    public let systemImage: String?
    public let color: Color
    
    public init(productID: String, image: ImageResource, color: Color) {
        self.id = productID
        self.image = image
        self.systemImage = nil
        self.color = color
    }
    
    public init(productID: String, systemImage: String, color: Color) {
        self.id = productID
        self.image = nil
        self.systemImage = systemImage
        self.color = color
    }
}

// MARK: - Theme Configuration

/// Theme configuration for the subscription shop
public struct SubscriptionShopTheme: Sendable {
    public let primaryGradientColors: [Color]
    public let accentGlowColor: Color
    public let titleColor: Color
    public let subtitleColor: Color
    public let cardStyle: CardStyle
    public let heroStyle: HeroStyle
    
    public enum CardStyle: Sendable {
        case glass
        case solid
        case elevated
        case gradient
    }
    
    public enum HeroStyle: Sendable {
        case floating
        case simple
        case bordered
        case none
    }
    
    public init(
        primaryGradientColors: [Color],
        accentGlowColor: Color,
        titleColor: Color = .white,
        subtitleColor: Color = .white.opacity(0.9),
        cardStyle: CardStyle = .elevated,
        heroStyle: HeroStyle = .simple
    ) {
        self.primaryGradientColors = primaryGradientColors
        self.accentGlowColor = accentGlowColor
        self.titleColor = titleColor
        self.subtitleColor = subtitleColor
        self.cardStyle = cardStyle
        self.heroStyle = heroStyle
    }
    
    // MARK: - Built-in Themes
    
    public static let `default` = SubscriptionShopTheme(
        primaryGradientColors: [
            Color(red: 0.1, green: 0.15, blue: 0.25),
            Color(red: 0.15, green: 0.1, blue: 0.3),
            Color(red: 0.2, green: 0.1, blue: 0.25)
        ],
        accentGlowColor: .purple,
        heroStyle: .simple
    )
    
    public static let nature = SubscriptionShopTheme(
        primaryGradientColors: [
            Color(red: 0.05, green: 0.2, blue: 0.15),
            Color(red: 0.1, green: 0.25, blue: 0.2),
            Color(red: 0.08, green: 0.18, blue: 0.22)
        ],
        accentGlowColor: Color(red: 0.3, green: 0.8, blue: 0.5),
        heroStyle: .simple
    )
    
    public static let ocean = SubscriptionShopTheme(
        primaryGradientColors: [
            Color(red: 0.05, green: 0.15, blue: 0.3),
            Color(red: 0.1, green: 0.2, blue: 0.4),
            Color(red: 0.08, green: 0.12, blue: 0.35)
        ],
        accentGlowColor: .cyan,
        heroStyle: .simple
    )
    
    public static let sunset = SubscriptionShopTheme(
        primaryGradientColors: [
            Color(red: 0.35, green: 0.15, blue: 0.2),
            Color(red: 0.4, green: 0.2, blue: 0.15),
            Color(red: 0.3, green: 0.12, blue: 0.25)
        ],
        accentGlowColor: .orange,
        heroStyle: .simple
    )
    
    public static let skyPurple = SubscriptionShopTheme(
        primaryGradientColors: [
            Color(red: 0.55, green: 0.45, blue: 0.75),
            Color(red: 0.5, green: 0.4, blue: 0.7),
            Color(red: 0.6, green: 0.5, blue: 0.8)
        ],
        accentGlowColor: Color(red: 0.7, green: 0.6, blue: 0.9),
        heroStyle: .simple
    )
    
    public static let streaming = SubscriptionShopTheme(
        primaryGradientColors: [
            Color(red: 0.2, green: 0.35, blue: 0.6),
            Color(red: 0.3, green: 0.4, blue: 0.65),
            Color(red: 0.85, green: 0.5, blue: 0.3)
        ],
        accentGlowColor: .orange,
        heroStyle: .simple
    )
    
    // MARK: - Custom Theme Builders
    
    public static func custom(
        colors: [Color],
        accent: Color,
        titleColor: Color = .white,
        subtitleColor: Color = .white.opacity(0.9),
        cardStyle: CardStyle = .elevated,
        heroStyle: HeroStyle = .simple
    ) -> SubscriptionShopTheme {
        SubscriptionShopTheme(
            primaryGradientColors: colors,
            accentGlowColor: accent,
            titleColor: titleColor,
            subtitleColor: subtitleColor,
            cardStyle: cardStyle,
            heroStyle: heroStyle
        )
    }
    
    public static func from(
        baseColor: Color,
        cardStyle: CardStyle = .elevated,
        heroStyle: HeroStyle = .simple
    ) -> SubscriptionShopTheme {
        SubscriptionShopTheme(
            primaryGradientColors: [
                baseColor.opacity(0.9),
                baseColor,
                baseColor.opacity(0.8)
            ],
            accentGlowColor: baseColor,
            cardStyle: cardStyle,
            heroStyle: heroStyle
        )
    }
}

// MARK: - Main View

/// A reusable, customizable subscription shop view
///
/// Example usage:
/// ```swift
/// SubscriptionShopView(
///     groupID: "your_group_id",
///     configuration: .simple(
///         title: "Premium Pass",
///         subtitle: "Unlock all features",
///         tiers: [...],
///         theme: .skyPurple,
///         pickerBackground: .thinMaterial
///     )
/// )
/// ```
public struct SubscriptionShopView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let groupID: String
    private let configuration: SubscriptionShopConfiguration
    
    public init(groupID: String, configuration: SubscriptionShopConfiguration) {
        self.groupID = groupID
        self.configuration = configuration
    }
    
    public var body: some View {
        SubscriptionStoreView(groupID: groupID) {
            SubscriptionMarketingContent(configuration: configuration)
                .containerBackground(for: .subscriptionStoreFullHeight) {
                    SubscriptionBackground(theme: configuration.theme)
                }
        }
        .backgroundStyle(.clear)
        .subscriptionStoreButtonLabel(.multiline)
        .subscriptionStorePickerItemBackground(configuration.pickerBackground)
        .subscriptionStoreControlIcon { product, _ in
            TierBadge(tier: findTier(for: product.id))
        }
        .onInAppPurchaseCompletion { _, _ in
            dismiss()
        }
        .flexStorePolicies(configuration.policies)
    }
    
    private func findTier(for productID: String) -> AppSubscriptionTier {
        configuration.tiers.first { $0.id == productID } ?? configuration.tiers.first!
    }
}

// MARK: - Marketing Content

struct SubscriptionMarketingContent: View {
    let configuration: SubscriptionShopConfiguration
    
    var body: some View {
        VStack(spacing: 0) {
            SubscriptionHeader(
                title: configuration.title,
                subtitle: configuration.subtitle,
                heroImage: configuration.heroImage,
                heroSystemImage: configuration.heroSystemImage,
                theme: configuration.theme
            )
            .padding(.bottom, configuration.features != nil ? 24 : 8)
            
            if let features = configuration.features, !features.isEmpty {
                SubscriptionFeaturesList(
                    features: features,
                    theme: configuration.theme
                )
            }
        }
    }
}

// MARK: - Header

struct SubscriptionHeader: View {
    let title: String
    let subtitle: String
    let heroImage: ImageResource?
    let heroSystemImage: String?
    let theme: SubscriptionShopTheme
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            if heroImage != nil || heroSystemImage != nil {
                heroView
            }
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(theme.titleColor)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(theme.subtitleColor)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(.top)
        .padding(.horizontal)
        .onAppear {
            if theme.heroStyle == .floating || theme.heroStyle == .bordered {
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
        }
    }
    
    @ViewBuilder
    private var heroView: some View {
        switch theme.heroStyle {
            case .floating:
                floatingHero
            case .simple:
                simpleHero
            case .bordered:
                borderedHero
            case .none:
                EmptyView()
        }
    }
    
    private var simpleHero: some View {
        Group {
            if let heroImage {
                Image(heroImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
            } else if let heroSystemImage {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [theme.accentGlowColor, theme.accentGlowColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: heroSystemImage)
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(.white)
                }
                .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
            }
        }
    }
    
    private var floatingHero: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [theme.accentGlowColor.opacity(0.4), theme.accentGlowColor.opacity(0.1), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
                .scaleEffect(isAnimating ? 1.1 : 0.95)
                .opacity(isAnimating ? 0.6 : 0.8)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.25), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .frame(width: 180, height: 180)
                .blur(radius: 20)
            
            if let heroImage {
                Image(heroImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 130, height: 130)
                    .clipShape(Circle())
                    .shadow(color: theme.accentGlowColor.opacity(0.4), radius: 25, y: 8)
                    .shadow(color: .black.opacity(0.3), radius: 15, y: 10)
            } else if let heroSystemImage {
                ZStack {
                    Circle()
                        .fill(theme.accentGlowColor.opacity(0.3))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: heroSystemImage)
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(.white)
                }
                .shadow(color: theme.accentGlowColor.opacity(0.4), radius: 25, y: 8)
            }
        }
    }
    
    private var borderedHero: some View {
        Group {
            if let heroImage {
                Image(heroImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 130, height: 130)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(
                                AngularGradient(
                                    colors: [
                                        .white.opacity(0.8),
                                        theme.accentGlowColor.opacity(0.6),
                                        .white.opacity(0.4),
                                        theme.accentGlowColor.opacity(0.8),
                                        .white.opacity(0.8)
                                    ],
                                    center: .center,
                                    startAngle: .degrees(isAnimating ? 360 : 0),
                                    endAngle: .degrees(isAnimating ? 720 : 360)
                                ),
                                lineWidth: 3
                            )
                    )
                    .shadow(color: theme.accentGlowColor.opacity(0.4), radius: 20, y: 8)
            } else if let heroSystemImage {
                ZStack {
                    Circle()
                        .fill(theme.accentGlowColor.opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: heroSystemImage)
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(.white)
                }
                .overlay(
                    Circle()
                        .strokeBorder(
                            AngularGradient(
                                colors: [
                                    .white.opacity(0.8),
                                    theme.accentGlowColor.opacity(0.6),
                                    .white.opacity(0.4),
                                    theme.accentGlowColor.opacity(0.8),
                                    .white.opacity(0.8)
                                ],
                                center: .center,
                                startAngle: .degrees(isAnimating ? 360 : 0),
                                endAngle: .degrees(isAnimating ? 720 : 360)
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: theme.accentGlowColor.opacity(0.4), radius: 20, y: 8)
            }
        }
    }
}

// MARK: - Features List

struct SubscriptionFeaturesList: View {
    let features: [SubscriptionFeature]
    let theme: SubscriptionShopTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What's Included")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(theme.titleColor.opacity(0.9))
                .padding(.horizontal, 20)
            
            VStack(spacing: 10) {
                ForEach(features) { feature in
                    SubscriptionFeatureCard(
                        icon: feature.icon,
                        title: feature.title,
                        description: feature.description,
                        accentColor: feature.accentColor,
                        cardStyle: theme.cardStyle
                    )
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical)
    }
}

// MARK: - Feature Card

struct SubscriptionFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let accentColor: Color
    let cardStyle: SubscriptionShopTheme.CardStyle
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 46, height: 46)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accentColor.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 25
                        )
                    )
                    .frame(width: 46, height: 46)
                    .blur(radius: 4)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .shadow(color: accentColor.opacity(0.5), radius: 3)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(titleColor)
                
                Text(description)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(descriptionColor)
                    .lineLimit(2)
            }
            
            Spacer(minLength: 0)
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(accentColor.opacity(0.8))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(cardOverlay)
    }
    
    private var titleColor: Color {
        switch cardStyle {
            case .glass: return .white
            case .solid, .elevated, .gradient: return .white.opacity(0.95)
        }
    }
    
    private var descriptionColor: Color {
        switch cardStyle {
            case .glass: return .white.opacity(0.75)
            case .solid, .elevated, .gradient: return .white.opacity(0.7)
        }
    }
    
    @ViewBuilder
    private var cardBackground: some View {
        switch cardStyle {
            case .glass:
                Rectangle().fill(.ultraThinMaterial)
            case .solid:
                Color(white: 0.1)
            case .elevated:
                ZStack {
                    Color(white: 0.12)
                    LinearGradient(colors: [.white.opacity(0.08), .clear], startPoint: .top, endPoint: .center)
                }
            case .gradient:
                LinearGradient(colors: [Color(white: 0.15), Color(white: 0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    @ViewBuilder
    private var cardOverlay: some View {
        switch cardStyle {
            case .glass:
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(.white.opacity(0.15), lineWidth: 1)
            case .solid:
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [.white.opacity(0.1), .clear], startPoint: .top, endPoint: .bottom),
                        lineWidth: 1
                    )
            case .elevated:
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [.white.opacity(0.2), .white.opacity(0.05), .clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1
                    )
                    .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
            case .gradient:
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [.white.opacity(0.15), .white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1
                    )
        }
    }
}

// MARK: - Tier Badge

struct TierBadge: View {
    let tier: AppSubscriptionTier
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [tier.color.opacity(0.3), tier.color.opacity(0.1)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 25
                    )
                )
                .frame(width: 48, height: 48)
            
            Circle()
                .strokeBorder(tier.color.opacity(0.4), lineWidth: 1.5)
                .frame(width: 48, height: 48)
            
            if let image = tier.image {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
                    .shadow(color: tier.color.opacity(0.5), radius: 4)
            } else if let systemImage = tier.systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(tier.color)
            }
        }
    }
}

// MARK: - Background (Apple-style with overlays)

struct SubscriptionBackground: View {
    let theme: SubscriptionShopTheme
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: theme.primaryGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Top highlight (like Apple's cloud overlay)
            GeometryReader { geometry in
                Ellipse()
                    .fill(.white.opacity(0.1))
                    .frame(width: geometry.size.width * 1.5, height: 300)
                    .offset(x: -geometry.size.width * 0.25, y: -150)
                
                // Bottom glow
                Ellipse()
                    .fill(theme.accentGlowColor.opacity(0.15))
                    .frame(width: geometry.size.width * 1.2, height: 400)
                    .offset(x: -geometry.size.width * 0.1, y: geometry.size.height - 200)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Custom Background Support

/// Use this when you want to provide your own custom background view
public struct SubscriptionShopViewWithCustomBackground<Background: View>: View {
    @Environment(\.dismiss) private var dismiss
    
    private let groupID: String
    private let configuration: SubscriptionShopConfiguration
    private let background: Background
    
    public init(
        groupID: String,
        configuration: SubscriptionShopConfiguration,
        @ViewBuilder background: () -> Background
    ) {
        self.groupID = groupID
        self.configuration = configuration
        self.background = background()
    }
    
    public var body: some View {
        SubscriptionStoreView(groupID: groupID) {
            SubscriptionMarketingContent(configuration: configuration)
                .containerBackground(for: .subscriptionStoreFullHeight) {
                    background
                }
        }
        .backgroundStyle(.clear)
        .subscriptionStoreButtonLabel(.multiline)
        .subscriptionStorePickerItemBackground(configuration.pickerBackground)
        .subscriptionStoreControlIcon { product, _ in
            TierBadge(tier: findTier(for: product.id))
        }
        .onInAppPurchaseCompletion { _, _ in
            dismiss()
        }
    }
    
    private func findTier(for productID: String) -> AppSubscriptionTier {
        configuration.tiers.first { $0.id == productID } ?? configuration.tiers.first!
    }
}
