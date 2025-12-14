//
//  StoreKitService+Extension.swift
//  FlexStore
//
//  Created by Gerard Gomez on 12/14/25.
//


import Foundation

public extension StoreKitService {
    @MainActor
    func installConsumables(
        catalog: ConsumableCatalog,
        economy: some EconomyStore
    ) {
        self.onConsumablePurchased = { [weak self] productID in
            guard let grant = catalog.grant(for: productID) else { return }
            do {
                try economy.apply(grant)
            } catch {
                self?.onEconomyError?(error)
#if DEBUG
                print("FlexStore economy apply failed:", error)
#endif
            }
        }
    }
}


