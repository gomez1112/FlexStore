# FlexStore

A production-ready, SwiftUI-first wrapper around StoreKit 2 that keeps your paywalls, buttons, and entitlement logic clean. FlexStore ships Apple-native UI, ergonomic helpers, and consumable tooling so you can focus on your product instead of plumbing.

> **Platforms:** iOS 17+, macOS 14+, tvOS 17+, watchOS 10+
> **Tech:** StoreKit 2 + Swift Concurrency + `@Observable`

---

## Quick Start

1. **Define your tiers** conforming to `SubscriptionTier`.

```swift
import FlexStore

enum AppTier: Int, SubscriptionTier {
    case free = 0
    case pro = 1

    static var defaultTier: AppTier { .free }

    init?(levelOfService: Int) { self.init(rawValue: levelOfService) }

    init?(productID: String) {
        switch productID {
        case "com.myapp.pro.monthly", "com.myapp.pro.yearly":
            self = .pro
        default:
            return nil
        }
    }
}
```

2. **Attach `StoreKitService` to your root view** so products and entitlements stay in sync.

```swift
import SwiftUI
import FlexStore

@main
struct MyApp: App {
    @State private var store = StoreKitService<AppTier>()

    private let groupID = "21345678"
    private let productIDs: Set<String> = [
        "com.myapp.pro.monthly",
        "com.myapp.pro.yearly",
        "com.myapp.lifetime",
        "com.myapp.hints10",
        "com.myapp.hints50"
    ]

    var body: some Scene {
        WindowGroup {
            RootView()
                .attachStoreKit(
                    manager: store,
                    groupID: groupID,
                    ids: productIDs
                )
        }
    }
}
```

3. **Render UI based on entitlement state.**

```swift
import SwiftUI
import FlexStore

struct RootView: View {
    @Environment(StoreKitService<AppTier>.self) private var store

    var body: some View {
        VStack(spacing: 12) {
            Text(store.isSubscribed ? "Subscribed ✅" : "Free Tier")
            Text("Plan: \(store.planName)").foregroundStyle(.secondary)
            Text(store.renewalStatusString).font(.footnote).foregroundStyle(.secondary)
        }
        .padding()
    }
}
```

---

## Customization

- **Paywall layout:** `FlexSubscriptionPaywall` lets you supply custom backgrounds, headers, feature rows, icons, and completion handlers while still using the native `SubscriptionStoreView` picker.
- **Feature spotlight:** `FlexFeatureSpotlightView` rotates through a single highlighted feature with optional auto-advance controls, perfect for compact paywalls.
- **Marketing hero:** `DefaultPassMarketingView` provides a ready-made hero + bullet list. Swap in your own marketing view or customize feature rows with `FlexDefaultFeatureRow`.
- **Subscription shop:** `SubscriptionShopView` delivers a reusable, App Store-style subscription shop with built-in themes, tiers, and optional feature lists. Provide your own background with `SubscriptionShopViewWithCustomBackground`.
- **Buttons:** Use `NonConsumablePurchaseButton`, `ConsumablePurchaseButton`, `RestorePurchasesButton`, and `ManageSubscriptionsButton` for drop-in controls. Each offers a `.label { state in ... }` customization point.
- **Gating:** Choose `TierGate` for hard gating or `BlurredTierGate` for soft gating with an upgrade overlay.

---

## Subscription Shop Example

```swift
import SwiftUI
import FlexStore

private let tiers = [
    AppSubscriptionTier(
        productID: "com.myapp.pro.monthly",
        systemImage: "sparkles",
        color: .purple
    ),
    AppSubscriptionTier(
        productID: "com.myapp.pro.yearly",
        systemImage: "crown.fill",
        color: .orange
    )
]

private let features = [
    SubscriptionFeature(
        icon: "bolt.fill",
        title: "Unlimited Access",
        description: "Unlock every tool and template.",
        accentColor: .purple
    ),
    SubscriptionFeature(
        icon: "hand.thumbsup.fill",
        title: "Priority Support",
        description: "Get fast responses from the team.",
        accentColor: .orange
    )
]

private let configuration = SubscriptionShopConfiguration(
    title: "Premium Pass",
    subtitle: "Upgrade to unlock the full experience.",
    heroSystemImage: "star.fill",
    features: features,
    tiers: tiers,
    theme: .skyPurple
)

struct SubscriptionShopScreen: View {
    var body: some View {
        SubscriptionShopView(groupID: "21345678", configuration: configuration)
    }
}
```

## Feature Spotlight Example

```swift
import SwiftUI
import FlexStore

private let spotlightFeatures = [
    FlexPaywallFeature(
        systemImage: "star.fill",
        title: "Curated Highlights",
        subtitle: "Showcase one premium benefit at a time.",
        tint: .yellow
    ),
    FlexPaywallFeature(
        systemImage: "sparkles",
        title: "Auto-Rotating Spotlight",
        subtitle: "Gently cycles through what users unlock.",
        tint: .purple
    )
]

struct SpotlightSection: View {
    var body: some View {
        FlexFeatureSpotlightView(
            features: spotlightFeatures,
            autoAdvanceInterval: .seconds(5),
            showsControls: true
        )
    }
}
```

## Advanced Usage

- **Consumables pipeline:**
  - Describe consumables with `ConsumableCatalog` (`registerExact` or `registerSuffixInt`).
  - Conform to `EconomyStore` or use `SwiftDataEconomyStore` to apply grants.
  - Connect everything with `StoreKitService.installConsumables(catalog:economy:)` and optional `onEconomyError`.
- **Subscription insights:** `StoreKitService` exposes `planName`, `renewalDate`, `willAutoRenew`, `upcomingPlanName`, `isFreeTrial`, and `isBillingRetry` for richer messaging.
- **Product helpers:** Call `product(for:)` to fetch metadata, or use `loadProducts(_:)` when you need a bespoke set of IDs outside of `attachStoreKit`.
- **Hooks:** Respond to completed purchases with `onPurchaseCompletion` in `FlexSubscriptionPaywall`, or set `onConsumablePurchased` to trigger custom flows.

---

## FAQ

**Why don't products appear?**
- Ensure the App Store Connect subscription group ID and product IDs match exactly.
- Confirm the device is signed into a Sandbox or Store environment that has access to your products.

**How do I test purchases safely?**
- Use Sandbox tester accounts and `StoreKitTest` configurations in Xcode. FlexStore works seamlessly with both.

**Can I localize all strings?**
- Yes. All public UI accepts `LocalizedStringKey` so you can localize labels, subtitles, and CTA text.

**What if I only sell a lifetime unlock?**
- Provide just the non-consumable product ID set when attaching `StoreKitService`. The buttons and entitlement helpers still work without subscriptions.

---

## Migration Notes

- **Attach the store once:** Use `.attachStoreKit(manager:groupID:ids:)` at the top of your view hierarchy. Older patterns that configured `StoreKitService` manually in multiple views should be consolidated to avoid duplicate work.
- **Map tiers intentionally:** Prefer mapping tiers via subscription group `levelOfService`. Keep `init?(productID:)` as a fallback for explicit control or non-subscription tiers.
- **Route consumables through the catalog:** If you previously handled consumables ad-hoc, register them in `ConsumableCatalog` and wire through `installConsumables` to centralize validation and error handling.
- **Adopt the provided UI components:** The bundled buttons, paywalls, and gates handle loading states, errors, and entitlement updates. Swap custom code for these components to reduce maintenance.
