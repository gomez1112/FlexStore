# FlexStore

A modern, SwiftUI-first wrapper around StoreKit 2.

FlexStore gives you a clean way to:
- **Define your own subscription tiers** (Free/Pro, Bronze/Silver/Gold, etc.)
- **Attach a StoreKit service to the SwiftUI environment**
- **Gate UI** based on tier (hard gate + soft “blurred” paywall)
- Use **Apple-native** subscription purchase UI with your own marketing content
- Sell **non-consumables** and **consumables** with ergonomic SwiftUI buttons
- Handle **consumables (hints/coins/credits/any custom currency)** with a declarative mapping, optionally backed by **SwiftData**

> Platforms: iOS 17+, macOS 14+, tvOS 17+, watchOS 10+

---

## Features

- 🧩 **Custom tiers** via `SubscriptionTier`
- 🔄 **Auto-sync** via transaction observation (updates + unfinished + entitlements)
- 🧾 **Subscription status helpers** (renewal date, billing retry, free trial, upcoming plan)
- 🔒 **UI gating**
  - `TierGate` (hard gate)
  - `BlurredTierGate` (soft gate with a paywall overlay)
- 🛍 **Pass UI** via `SubscriptionPassStoreView` (wraps Apple’s `SubscriptionStoreView`)
- 🧰 **Buttons**
  - `NonConsumablePurchaseButton`
  - `ConsumablePurchaseButton`
  - `RestorePurchasesButton`
  - `ManageSubscriptionsButton`
- 🪙 **Consumables made easy**
  - `ConsumableCatalog` maps product IDs → “what this means”
  - `EconomyStore` protocol
  - `SwiftDataEconomyStore` applies grants to a SwiftData profile using key paths
  - `StoreKitService.installConsumables(...)` wires StoreKit → catalog → economy (+ error hook)

---

## Installation

### Swift Package Manager

In Xcode:
1. **File → Add Package Dependencies…**
2. Paste your FlexStore repository URL
3. Add the **FlexStore** product to your target

---

## Quick Start

### 1) Define your tiers

Create an enum conforming to `SubscriptionTier`. FlexStore can map tiers from:
- **StoreKit subscription group level** (preferred)
- **Product IDs** (fallback / explicit control)

```swift
import FlexStore

enum AppTier: Int, SubscriptionTier {
    case free = 0
    case pro  = 1

    static var defaultTier: AppTier { .free }

    // Preferred: map from Subscription Group “level of service”
    init?(levelOfService: Int) {
        self.init(rawValue: levelOfService)
    }

    // Fallback: map by product ID
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

### 2) Attach FlexStore to your app

Create a `StoreKitService<AppTier>` and attach it to your root view using `attachStoreKit(...)`.

```swift
import SwiftUI
import FlexStore

@main
struct MyApp: App {
    @State private var store = StoreKitService<AppTier>()

    private let subscriptionGroupID = "21345678"

    private let productIDs: Set<String> = [
        // Subscriptions
        "com.myapp.pro.monthly",
        "com.myapp.pro.yearly",

        // Non-consumable
        "com.myapp.lifetime",

        // Consumables
        "com.myapp.hints10",
        "com.myapp.hints50",
        "com.myapp.gems10"
    ]

    var body: some Scene {
        WindowGroup {
            RootView()
                .attachStoreKit(
                    manager: store,
                    groupID: subscriptionGroupID,
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
        VStack(spacing: 16) {
            Text(store.isSubscribed ? "Subscribed ✅" : "Free Tier")

            Text("Plan: \(store.planName)")
                .foregroundStyle(.secondary)

            Text(store.renewalStatusString)
                .font(.footnote)
                .foregroundStyle(.secondary)
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

## Apple-native subscription purchase UI (Paywall)

Use `SubscriptionPassStoreView` to show the system subscription UI and add your own marketing view.

```swift
import SwiftUI
import FlexStore

struct PaywallView: View {
    var body: some View {
        SubscriptionPassStoreView<AppTier, DefaultPassMarketingView>(
            groupID: "21345678",
            iconProvider: { tier in
                switch tier {
                case .free: Image(systemName: "leaf.fill")
                case .pro:  Image(systemName: "star.fill")
                }
            }
        ) {
            DefaultPassMarketingView(
                title: "Go Pro",
                subtitle: "Unlock everything.",
                features: [
                    "Unlimited projects",
                    "Advanced analytics",
                    "Priority support"
                ],
                highlight: "Cancel anytime"
            )
        }
    }
}
```

---

## Purchasing

### Non-consumable purchases

```swift
NonConsumablePurchaseButton<AppTier>(
    productID: "com.myapp.lifetime",
    title: "Unlock Lifetime"
)
.buttonStyle(.borderedProminent)
```

### Consumable purchases

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
    .buttonStyle(.bordered)

ManageSubscriptionsButton()
    .buttonStyle(.bordered)
```

---

## Consumables

StoreKit gives you a `productID`. Your app decides what it’s worth (10 hints, 500 coins, 25 gems, etc.).
FlexStore keeps that mapping declarative.

### Product IDs → Grants (Catalog)

#### Option A: Exact mapping

```swift
var catalog = ConsumableCatalog()
catalog.registerExact("com.myapp.hints10", grant: .init(.hints, amount: 10))
catalog.registerExact("com.myapp.hints50", grant: .init(.hints, amount: 50))
```

#### Option B: Suffix-int mapping (recommended)

If your product IDs end with the quantity:

- `com.myapp.hints10`
- `com.myapp.hints50`
- `com.myapp.coins500`

Then:

```swift
var catalog = ConsumableCatalog()
catalog.registerSuffixInt(prefix: "com.myapp.hints", kind: .hints)
catalog.registerSuffixInt(prefix: "com.myapp.coins", kind: .coins)
```

---

## Custom Currencies (Gems, Energy, Tickets, Credits…)

You **do not need to change FlexStore** for custom currencies.

Use:

```swift
ConsumableGrant.Kind.tokens(String)
```

### Catalog mapping for custom currencies

```swift
var catalog = ConsumableCatalog()

// com.myapp.gems10 -> 10 gems
catalog.registerSuffixInt(prefix: "com.myapp.gems", kind: .tokens("gems"))

// com.myapp.energy25 -> 25 energy
catalog.registerSuffixInt(prefix: "com.myapp.energy", kind: .tokens("energy"))
```

### SwiftData balances for custom currencies

In your app:

```swift
import SwiftData

@Model
final class GameProfile {
    var gems: Int = 0
    var energy: Int = 0
}
```

Register them:

```swift
var economy = SwiftDataEconomyStore<GameProfile>(
    context: context,
    createProfile: { GameProfile() }
)

economy.registerTokenBalance("gems", \GameProfile.gems)
economy.registerTokenBalance("energy", \GameProfile.energy)

store.installConsumables(catalog: catalog, economy: economy)
```

---

## Advanced Consumables (bundles, caps, multiple fields)

If a purchase should do more than “add to one Int field”, use `registerCustom`.

### Example: cap gems at 999

```swift
economy.registerCustom(.tokens("gems")) { profile, amount in
    profile.gems = min(profile.gems + amount, 999)
}
```

### Example: starter bundle (adds multiple things)

```swift
// Map the product ID to a special “bundle” kind.
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

## SwiftData Wiring Example (end-to-end)

```swift
import SwiftUI
import SwiftData
import FlexStore

typealias Store = StoreKitService<AppTier>

@MainActor
func wireEconomy(store: Store, context: ModelContext) {
    var catalog = ConsumableCatalog()
    catalog.registerSuffixInt(prefix: "com.myapp.hints", kind: .hints)
    catalog.registerSuffixInt(prefix: "com.myapp.gems",  kind: .tokens("gems"))

    var economy = SwiftDataEconomyStore<GameProfile>(
        context: context,
        createProfile: { GameProfile() }
    )
    economy.registerBalance(.hints, \GameProfile.hintBalance)
    economy.registerTokenBalance("gems", \GameProfile.gems)

    store.installConsumables(catalog: catalog, economy: economy)

    store.onEconomyError = { error in
        print("Economy error:", error)
    }
}
```

---

## API Reference (high level)

### StoreKitService

Key properties:
- `subscriptionTier: Tier`
- `isSubscribed: Bool`
- `products: [Product]`
- `purchasedNonConsumables: Set<String>`
- `renewalStatusString: String`
- `planName: String`
- `onConsumablePurchased: ((String) -> Void)?`
- `onEconomyError: ((Error) -> Void)?`

Key methods:
- `configure(productIDs:subscriptionGroupID:) async`
- `purchase(productID:) async throws`
- `restorePurchases() async`
- `refreshSubscriptionStatus(groupID:) async`

### View helpers
- `View.attachStoreKit(manager:groupID:ids:)`

### UI gating
- `TierGate`
- `BlurredTierGate`

### Store UI
- `SubscriptionPassStoreView`
- `DefaultPassMarketingView`

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

---

## License

MIT (or your preferred license)
