# FlexStore

A flexible, modern StoreKit 2 wrapper for SwiftUI apps. FlexStore bridges the gap between complex StoreKit logic and your app's unique subscription tiers.

## Features

- 🏗 **Custom Tiers**: Define your own access levels (e.g., `Guest`, `Silver`, `Gold`) using a simple Enum.
- 🔄 **Auto-Sync**: Automatically handles transaction updates, renewals, and expirations in the background.
- 🛡 **Grace Period Support**: Respects App Store grace periods so users don't lose access during billing retries.
- 🔒 **UI Gating**: Includes `TierGate` and `BlurredTierGate` to easily lock premium features in SwiftUI.
- 🎨 **Pass UI**: Includes a pre-built `SubscriptionPassStoreView` that wraps Apple's native StoreKit views with your custom branding.
- ⚡️ **Concurrency**: Built with Swift 5.9 `async/await` and the `@Observable` macro (iOS 17+).

## Installation

Add this package to your project via Swift Package Manager.

## Quick Start

### 1. Define Your Tiers

Create an enum that conforms to `SubscriptionTier`. This maps Apple's "Group Levels" or Product IDs to your app's logic.

```swift
enum AppTier: Int, SubscriptionTier {
    case free = 0
    case pro = 1
    
    // Default for non-subscribers
    static var defaultTier: AppTier { .free }
    
    // Init from StoreKit Group Level (Preferred)
    init?(levelOfService: Int) {
        self.init(rawValue: levelOfService)
    }
    
    // Init from Product ID (Fallback)
    init?(productID: String) {
        switch productID {
        case "com.myapp.pro": self = .pro
        default: return nil
        }
    }
}
```

### 2. Configure in Your App

Create the manager and attach it to your root view.

```swift
@main
struct MyApp: App {
    @State private var store = StoreKitManager<AppTier>()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .attachStoreKit(
                    manager: store,
                    groupID: "21345678", // Your Subscription Group ID
                    ids: ["com.myapp.pro", "com.myapp.consumable"]
                )
        }
    }
}
```

### 3. Use in Views

Read the state or lock content easily.

```swift
struct ContentView: View {
    @Environment(StoreKitManager<AppTier>.self) private var store
    
    var body: some View {
        VStack {
            // Check status
            if store.subscriptionTier == .pro {
                Text("Welcome Pro Member!")
            }
            
            // Gated Content
            TierGate(requiredTier: .pro) {
                SecretProFeature()
            } locked: {
                Text("Locked")
            }
            
            // Blurred Gate (Paywall)
            BlurredTierGate(requiredTier: .pro, onUpgrade: { /* show sheet */ }) {
                AdvancedChart()
            }
        }
    }
}
```

## Requirements

- iOS 17.0+
- macOS 14.0+
- tvOS 17.0+
- watchOS 10.0+
- Xcode 15.0+
