# FlexStore

A modern, SwiftUI-first wrapper around StoreKit 2.

FlexStore helps you ship StoreKit with **clean APIs**, **Apple-native UI**, and ergonomic buttons—plus a flexible way to handle **consumables** (hints/coins/credits/custom currencies) and **custom paywalls**.

> **Platforms:** iOS 17+, macOS 14+, tvOS 17+, watchOS 10+  
> **Tech:** StoreKit 2 + Swift Concurrency + `@Observable`

---

## Highlights

- 🧩 **Custom tiers** via `SubscriptionTier`
- 🔄 **Auto-sync** (transaction updates + unfinished + entitlements)
- 🧾 **Subscription status helpers** (renewal date, trial, billing retry, upcoming plan)
- 🔒 **UI gating**
  - `TierGate` (hard gate)
  - `BlurredTierGate` (soft gate)
- 🛍 **Apple-native subscription UI**
  - `SubscriptionPassStoreView` (simple “marketing + picker”)
  - `FlexSubscriptionPaywall` (fully-custom paywall layout like PlantPal)
- 🧰 **Buttons**
  - `NonConsumablePurchaseButton`
  - `ConsumablePurchaseButton`
  - `RestorePurchasesButton`
  - `ManageSubscriptionsButton`
- 🪙 **Consumables done right**
  - `ConsumableCatalog` maps product IDs → grants
  - `EconomyStore` protocol
  - `SwiftDataEconomyStore` applies grants to SwiftData via key paths
  - `StoreKitService.installConsumables(...)` wires StoreKit → catalog → economy (+ error hook)

---

## Installation

### Swift Package Manager

In Xcode:

1. **File → Add Package Dependencies…**
2. Paste your FlexStore repo URL
3. Add the **FlexStore** product to your target

---

## Quick Start

### 1) Define your tiers

Define an enum conforming to `SubscriptionTier`. FlexStore can map tiers from:

- **Subscription group level** (preferred)
- **Product IDs** (fallback / explicit control)

```swift
import FlexStore

enum AppTier: Int, SubscriptionTier {
    case free = 0
    case pro  = 1

    static var defaultTier: AppTier { .free }

    init?(levelOfService: Int) {
        self.init(rawValue: levelOfService)
    }

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

---

### 2) Attach FlexStore to your root view

```swift
import SwiftUI
import FlexStore

@main
struct MyApp: App {
    @State private var store = StoreKitService<AppTier>()

    private let groupID = "21345678"
    private let productIDs: Set<String> = [
        // subscriptions
        "com.myapp.pro.monthly",
        "com.myapp.pro.yearly",

        // non-consumable
        "com.myapp.lifetime",

        // consumables
        "com.myapp.hints10",
        "com.myapp.hints50",
        "com.myapp.gems10"
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

---

### 3) Read state in views

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

## UI Gating

### TierGate (hard gate)

```swift
TierGate(requiredTier: .pro) {
    ProFeatureView()
} locked: {
    Text("Upgrade to Pro to unlock this feature.")
}
```

### BlurredTierGate (soft gate / paywall overlay)

```swift
@State private var showPaywall = false

BlurredTierGate(requiredTier: .pro, onUpgrade: { showPaywall = true }) {
    AnalyticsDashboard()
}
.sheet(isPresented: $showPaywall) {
    PaywallView()
}
```

---

## Purchasing Buttons

### Non-consumable purchase

```swift
NonConsumablePurchaseButton<AppTier>(
    productID: "com.myapp.lifetime",
    title: "Unlock Lifetime"
)
.buttonStyle(.borderedProminent)
```

### Consumable purchase

```swift
ConsumablePurchaseButton<AppTier>(
    productID: "com.myapp.hints10",
    title: "Buy 10 Hints",
    successTitle: "Added"
)
.buttonStyle(.borderedProminent)
```

### Restore + Manage Subscriptions

```swift
RestorePurchasesButton<AppTier>()
ManageSubscriptionsButton()
```

---

## Apple-native Subscription UI

### Option A: Simple marketing + picker (`SubscriptionPassStoreView`)

Use Apple’s `SubscriptionStoreView` with your own marketing content.

```swift
import SwiftUI
import FlexStore

struct PaywallView: View {
    var body: some View {
        SubscriptionPassStoreView<AppTier, DefaultPassMarketingView>(
            groupID: "21345678",
            iconProvider: { tier, product in
                // ✅ different icons for monthly vs yearly (or tiers)
                switch product.id {
                case "com.myapp.pro.yearly":  Image(systemName: "calendar.badge.clock")
                case "com.myapp.pro.monthly": Image(systemName: "calendar")
                default:
                    switch tier {
                    case .free: Image(systemName: "leaf.fill")
                    case .pro:  Image(systemName: "star.fill")
                    }
                }
            }
        ) {
            DefaultPassMarketingView(
                title: "Go Pro",
                subtitle: "Unlock everything.",
                features: ["Unlimited projects", "Advanced analytics", "Priority support"],
                highlight: "Cancel anytime"
            )
        }
    }
}
```

> **Note:** The `iconProvider` receives `(Tier, Product)` so you can differentiate monthly/yearly even if both map to `.pro`.

---

## Custom Paywall Layout (PlantPal-style)

If you want a premium branded paywall (custom background, hero, feature list, etc.), use:

- `FlexSubscriptionPaywall`
- `FlexPaywallFeature`
- `FlexDefaultFeatureRow` (optional default row)

### 1) Define features

`FlexPaywallFeature` uses `titleKey`/`subtitleKey` as **String localization keys** (Sendable-friendly).  
`Text(feature.titleKey)` still localizes via `Localizable.strings`.

```swift
import FlexStore
import SwiftUI

let features: [FlexPaywallFeature] = [
    .init(
        systemImage: "bell.badge.fill",
        titleKey: "paywall.feature.reminders.title",
        subtitleKey: "paywall.feature.reminders.subtitle",
        tint: .green
    ),
    .init(
        systemImage: "paintpalette.fill",
        titleKey: "paywall.feature.themes.title",
        subtitleKey: "paywall.feature.themes.subtitle",
        tint: .yellow
    )
]
```

### 2) Build a paywall view

```swift
import SwiftUI
import FlexStore
import StoreKit

struct FancyPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    private let groupID = "21345678"

    var body: some View {
        FlexSubscriptionPaywall<AppTier, HeaderView, BackgroundView, FlexDefaultFeatureRow>(
            groupID: groupID,
            sectionTitle: "What's Included",
            features: features,
            pickerItemMaterial: .ultraThickMaterial,
            iconProvider: { tier, product in
                // ✅ choose icons/badges by product ID (silver/gold/platinum/monthly/yearly)
                switch product.id {
                case "com.myapp.pro.yearly":  Image(systemName: "crown.fill")
                case "com.myapp.pro.monthly": Image(systemName: "sparkles")
                default:
                    switch tier {
                    case .free: Image(systemName: "leaf.fill")
                    case .pro:  Image(systemName: "star.fill")
                    }
                }
            },
            onPurchaseCompletion: { _ in
                dismiss()
            },
            background: {
                BackgroundView()
            },
            header: {
                HeaderView()
            },
            featureRow: { feature in
                FlexDefaultFeatureRow(feature)
            }
        )
    }
}

struct HeaderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.white)
            Text("Garden Pass")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
            Text("Unlock premium features and themes.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
        }
        .padding(.top)
        .padding(.horizontal)
    }
}

struct BackgroundView: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.10, green: 0.35, blue: 0.28),
                Color(red: 0.18, green: 0.55, blue: 0.42),
                Color(red: 0.28, green: 0.70, blue: 0.55).opacity(0.85)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
```

---

## Consumables

StoreKit gives you a `productID`. Your app decides what it’s worth (10 hints, 500 coins, 25 gems, etc.).  
FlexStore makes that mapping declarative.

### Product IDs → Grants (Catalog)

#### Exact mapping

```swift
var catalog = ConsumableCatalog()
catalog.registerExact("com.myapp.hints10", grant: .init(.hints, amount: 10))
catalog.registerExact("com.myapp.hints50", grant: .init(.hints, amount: 50))
```

#### Suffix-int mapping (recommended)

Product IDs like: `com.myapp.hints10`, `com.myapp.hints50`, `com.myapp.coins500`

```swift
var catalog = ConsumableCatalog()
catalog.registerSuffixInt(prefix: "com.myapp.hints", kind: .hints)
catalog.registerSuffixInt(prefix: "com.myapp.coins", kind: .coins)
```

---

## Custom Currencies (Gems, Energy, Tickets, Credits…)

Use:

```swift
ConsumableGrant.Kind.tokens("gems")
```

### Catalog mapping

```swift
var catalog = ConsumableCatalog()
catalog.registerSuffixInt(prefix: "com.myapp.gems", kind: .tokens("gems"))
catalog.registerSuffixInt(prefix: "com.myapp.energy", kind: .tokens("energy"))
```

### SwiftData balances

```swift
import SwiftData

@Model
final class GameProfile {
    var hintBalance: Int = 0
    var gems: Int = 0
    var energy: Int = 0
}
```

Register key paths + install:

```swift
var economy = SwiftDataEconomyStore<GameProfile>(
    context: context,
    createProfile: { GameProfile() }
)

economy.registerBalance(.hints, \GameProfile.hintBalance)
economy.registerTokenBalance("gems", \GameProfile.gems)
economy.registerTokenBalance("energy", \GameProfile.energy)

store.installConsumables(catalog: catalog, economy: economy)
```

---

## Advanced Consumables (caps, bundles, multiple fields)

Use `registerCustom` when a purchase needs more than “add to one Int”.

### Cap gems at 999

```swift
economy.registerCustom(.tokens("gems")) { profile, amount in
    profile.gems = min(profile.gems + amount, 999)
}
```

### Starter bundle (adds multiple things)

```swift
catalog.registerExact(
    "com.myapp.bundle.starter",
    grant: .init(.tokens("starterBundle"), amount: 1)
)

economy.registerCustom(.tokens("starterBundle")) { profile, _ in
    profile.gems += 50
    profile.energy += 10
}
```

---

## API Reference (high level)

### StoreKitService

Properties (selected):
- `subscriptionTier: Tier`
- `isSubscribed: Bool`
- `products: [Product]`
- `purchasedNonConsumables: Set<String>`
- `renewalStatusString: String`
- `planName: String`
- `onConsumablePurchased: ((String) -> Void)?`
- `onEconomyError: (@MainActor (Error) -> Void)?`

Methods (selected):
- `configure(productIDs:subscriptionGroupID:) async`
- `purchase(productID:) async throws`
- `restorePurchases() async`
- `refreshSubscriptionStatus(groupID:) async`

### View helper
- `View.attachStoreKit(manager:groupID:ids:)`

### UI gating
- `TierGate`
- `BlurredTierGate`

### Store UI
- `SubscriptionPassStoreView`
- `DefaultPassMarketingView`
- `FlexSubscriptionPaywall`
- `FlexPaywallFeature`
- `FlexDefaultFeatureRow`

### Buttons
- `NonConsumablePurchaseButton`
- `ConsumablePurchaseButton`
- `RestorePurchasesButton`
- `ManageSubscriptionsButton`

### Consumables / Economy
- `ConsumableGrant`
- `ConsumableCatalog`
- `EconomyStore`
- `SwiftDataEconomyStore`
- `StoreKitService.installConsumables(...)`

