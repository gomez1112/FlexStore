import Foundation
import Testing
@testable import FlexStore

private enum TestTier: Int, SubscriptionTier {
    case free, pro, elite
    static let defaultTier: Self = .free
    init?(levelOfService: Int) { self.init(rawValue: levelOfService) }
    init?(productID: String) {
        switch productID {
        case "com.flexstore.pro.monthly", "com.flexstore.pro.yearly": self = .pro
        case "com.flexstore.elite.monthly": self = .elite
        default: return nil
        }
    }
}

@Test func subscriptionTierUsesCaseOrder() {
    #expect(TestTier.free < .pro)
    #expect(TestTier.pro < .elite)
    #expect(!(TestTier.elite < .free))
}

@Test func consumableCatalogResolution() {
    var catalog = ConsumableCatalog()
    catalog.registerExact("com.flexstore.special", grant: .init(.hints, amount: 7))
    catalog.registerSuffixInt(prefix: "com.flexstore.coins", kind: .coins)
    #expect(catalog.grant(for: "com.flexstore.special") == .init(.hints, amount: 7))
    #expect(catalog.grant(for: "com.flexstore.coins10") == .init(.coins, amount: 10))
    #expect(catalog.grant(for: "com.flexstore.coinsnope") == nil)
    #expect(catalog.grant(for: "com.flexstore.coins0") == nil)
}

#if canImport(StoreKitTest)
import StoreKitTest

@MainActor
@Test func storeKitConfigurationLoadsProducts() async throws {
    let session = try SKTestSession(configurationFileNamed: "FlexStore")
    session.disableDialogs = true
    session.clearTransactions()
    let store = StoreKitService<TestTier>()
    await store.configure(productIDs: ["com.flexstore.pro.monthly", "com.flexstore.elite.monthly"], subscriptionGroupID: "FlexStoreGroup")
    #expect(store.products.count == 2)
}
#endif
