# FlexStore

A modern, SwiftUI-first wrapper around StoreKit 2.

FlexStore gives you a clean way to:
- **Define your own subscription tiers** (Free/Pro, Bronze/Silver/Gold, etc.)
- **Attach a StoreKit service to the SwiftUI environment**
- **Gate UI** based on tier (hard gate + soft “blurred” paywall)
- Use **Apple-native** subscription purchase UI with your own marketing content
- Sell **non-consumables** and **consumables** with ergonomic SwiftUI buttons
- Handle **consumables (hints/coins/credits)** with a tiny declarative mapping, optionally backed by **SwiftData**

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
        "com.myapp.hints50"
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

Use the environment to access the store.

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

Shows `unlocked` only if the required tier is met.

```swift
TierGate(requiredTier: .pro) {
    ProFeatureView()
} locked: {
    Text("Upgrade to Pro to unlock this feature.")
}
```

### BlurredTierGate (soft gate / paywall overlay)

Blurs content and shows a paywall overlay with an upgrade button.

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

Use `SubscriptionPassStoreView` to show the system subscription purchase UI and add your own marketing view.

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

Use `NonConsumablePurchaseButton`. It automatically disables itself when already owned.

```swift
import SwiftUI
import FlexStore

struct LifetimePurchaseRow: View {
    var body: some View {
        NonConsumablePurchaseButton<AppTier>(
            productID: "com.myapp.lifetime",
            title: "Unlock Lifetime"
        )
        .buttonStyle(.borderedProminent)
    }
}
```

### Consumable purchases

Use `ConsumablePurchaseButton` for items like hints/coins/credits.

```swift
ConsumablePurchaseButton<AppTier>(
    productID: "com.myapp.hints10",
    title: "Buy 10 Hints",
    successTitle: "Added"
)
.buttonStyle(.borderedProminent)
```

You can fully customize labels with the `label:` initializer if you want:

```swift
ConsumablePurchaseButton<AppTier>(productID: "com.myapp.hints50") { state in
    switch state {
    case .idle:        Text("Buy 50 Hints")
    case .purchasing:  ProgressView()
    case .success:     Label("Added", systemImage: "checkmark.circle.fill")
    }
}
```

---

## Restore + Manage Subscriptions

### Restore Purchases

```swift
RestorePurchasesButton<AppTier>()
    .buttonStyle(.bordered)
```

### Manage Subscriptions (opens Apple subscriptions page)

```swift
ManageSubscriptionsButton()
    .buttonStyle(.bordered)
```

---

## Consumables: mapping product IDs → meaning (Catalog)

StoreKit gives you a `productID`. Your app decides what it’s worth. FlexStore makes that mapping tiny and declarative.

### Option A: Exact mapping

```swift
var catalog = ConsumableCatalog()
catalog.registerExact("com.myapp.hints10", grant: .init(.hints, amount: 10))
catalog.registerExact("com.myapp.hints50", grant: .init(.hints, amount: 50))
```

### Option B: Suffix-int mapping (recommended)

If your product IDs end with the quantity (e.g. `com.myapp.hints10`, `com.myapp.hints50`):

```swift
var catalog = ConsumableCatalog()
catalog.registerSuffixInt(prefix: "com.myapp.hints", kind: .hints)
catalog.registerSuffixInt(prefix: "com.myapp.coins", kind: .coins)
```

Now `com.myapp.hints10` → 10 hints, `com.myapp.coins500` → 500 coins, etc.

---

## Consumables + SwiftData (EconomyStore)

FlexStore includes a tiny “economy bridge” so you don’t write a giant `switch` or manual fetch/create logic.

### 1) Create a SwiftData profile model (in your app)

Example:

```swift
import SwiftData

@Model
final class GameProfile {
    var hintBalance: Int = 0
    var coinBalance: Int = 0

    init() {}
}
```

### 2) Wire StoreKit → Catalog → SwiftData balances

```swift
import SwiftUI
import SwiftData
import FlexStore

@MainActor
func wireEconomy(store: StoreKitService<AppTier>, context: ModelContext) {
    // Product ID → grant
    var catalog = ConsumableCatalog()
    catalog.registerSuffixInt(prefix: "com.myapp.hints", kind: .hints)
    catalog.registerSuffixInt(prefix: "com.myapp.coins", kind: .coins)

    // Grant → SwiftData profile
    var economy = SwiftDataEconomyStore<GameProfile>(
        context: context,
        createProfile: { GameProfile() }
    )
    economy.registerBalance(.hints, \GameProfile.hintBalance)
    economy.registerBalance(.coins, \GameProfile.coinBalance)

    // Install: StoreKit -> catalog -> economy
    store.installConsumables(catalog: catalog, economy: economy)

    // Optional: observe economy errors (surface an alert/toast if desired)
    store.onEconomyError = { error in
        print("Economy error:", error)
    }
}
```

> Tip: call `wireEconomy(...)` from a `.task {}` in a SwiftUI view that has access to `ModelContext`.

Example:

```swift
struct ContentView: View {
    @Environment(StoreKitService<AppTier>.self) private var store
    @Environment(\.modelContext) private var context

    var body: some View {
        Text("Hello")
            .task {
                wireEconomy(store: store, context: context)
            }
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

## FAQ

### Do I have to use SwiftData for consumables?
No. If you don’t use SwiftData, implement your own `EconomyStore` (or just set `store.onConsumablePurchased` directly).

### Why do I need a Catalog?
StoreKit only tells you which product was purchased. Your app defines what that purchase means (10 hints, 500 coins, etc.). The catalog keeps that mapping declarative and tiny.

---

## License

MIT (or your preferred license)
