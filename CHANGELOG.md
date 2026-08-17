# Changelog

All notable changes follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [2.0.0] - 2026-08-17

### Added
- Four-platform warning-as-error CI, StoreKit test configuration, and Swift Testing coverage.
- Configurable, bounded consumable transaction ledger.
- Package-owned English String Catalog and DocC integration guides.

### Changed
- `FlexStoreError.title` and `.message` are `LocalizedStringResource` rather than `String`.
- `planName` and `renewalStatusString` return `LocalizedStringResource`.
- `AppSubscriptionTier` is renamed `SubscriptionShopProduct`; a deprecated alias remains for one release.
- `SubscriptionFeature` accepts a stable string identifier derived from content by default and is `Sendable`.
- Unverified transactions remain unfinished and are now logged; unmapped consumables are reported to `onEconomyError`.
- Consumable ledgers are bounded and may use an App Group `UserDefaults` suite.

### Deprecated
- `onConsumablePurchased`; use the async result-returning `onConsumablePurchasedResult` hook.

### Fixed
- Tier resolution no longer reports a subscriber as free merely because products have not loaded.
- Failed SwiftData saves roll back in-memory consumable mutations.
- tvOS compilation of `BlurredTierGate` and deprecated alert presentation.
