import SwiftUI
import StoreKit

// MARK: - Configuration

/// Configuration object for customizing the subscription shop appearance
public struct SubscriptionShopConfiguration: Sendable {
    public let title: String
    public let subtitle: String
    public let heroImage: ImageResource?
    public let heroSystemImage: String?
    public let features: [SubscriptionFeature]?
    public let tiers: [SubscriptionShopProduct]
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
        tiers: [SubscriptionShopProduct],
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
        tiers: [SubscriptionShopProduct],
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
public struct SubscriptionFeature: Identifiable, Sendable {
    public let id: String
    public let icon: String
    public let title: String
    public let description: String
    public let accentColor: Color
    
    public init(id: String? = nil, icon: String, title: String, description: String, accentColor: Color) {
        self.id = id ?? "\(icon)|\(title)|\(description)"
        self.icon = icon
        self.title = title
        self.description = description
        self.accentColor = accentColor
    }
}

/// Represents a subscription tier with its associated product ID and visual styling
public struct SubscriptionShopProduct: Identifiable, Sendable {
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

@available(*, deprecated, renamed: "SubscriptionShopProduct")
public typealias AppSubscriptionTier = SubscriptionShopProduct
