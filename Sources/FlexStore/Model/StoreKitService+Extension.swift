//
//  StoreKitService+Extension.swift
//  FlexStore
//
//  Created by Gerard Gomez on 12/14/25.
//


import Foundation

public extension StoreKitService {
    /// Connects consumable transaction handling to an app-defined economy store using a consumable catalog.
    ///
    /// - Parameters:
    ///   - catalog: Catalog that maps product identifiers to consumable grants.
    ///   - economy: Economy store responsible for applying each grant to persisted state.
    @MainActor
    func installConsumables(
        catalog: ConsumableCatalog,
        economy: some EconomyStore
    ) {
        self.onConsumablePurchasedResult = { [weak self] productID in
            guard let grant = catalog.grant(for: productID) else { return true }
            do {
                try economy.apply(grant)
                return true
            } catch {
                self?.onEconomyError?(error)
#if DEBUG
                print("FlexStore economy apply failed:", error)
#endif
                return false
            }
        }
    }
}


