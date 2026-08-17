# Migrating from 1.x

Use `SubscriptionShopProduct` in place of `AppSubscriptionTier`. `FlexStoreError` and subscription status presentation now use `LocalizedStringResource`. Configure ledger storage through `StoreKitService.init(userDefaults:consumableLedgerLimit:)`, and migrate consumables to `onConsumablePurchasedResult`.
