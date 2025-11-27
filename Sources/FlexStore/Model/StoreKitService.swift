//
//  File.swift
//  FlexStore
//
//  Created by Gerard Gomez on 11/27/25.
//

import Foundation
import StoreKit
import OSLog
import Observation

/// A generic StoreKit 2 manager that tracks Tier state, Entitlements, and Products.
@Observable
@MainActor
public final class StoreKitService<Tier: SubscriptionTier> {
    
    // MARK: Public State
    
    /// Current subscription tier, derived from active subscription status.
    public private(set) var subscriptionTier: Tier = .defaultTier
    
    /// Active non-consumable entitlements (product IDs).
    public private(set) var purchasedNonConsumables: Set<String> = []
    
    /// Loaded product metadata, sorted by price.
    public private(set) var products: [Product] = []
    
    /// Indicates whether a network operation is in progress.
    public private(set) var isLoading: Bool = false
    
    // MARK: Callbacks
    
    /// Called whenever a **consumable** product is successfully purchased.
    @ObservationIgnored
    public var onConsumablePurchased: ((String) -> Void)?
    
    // MARK: Private
    
    @ObservationIgnored
    private let logger = Logger(subsystem: "FlexStore", category: "StoreKitManager")
    
    @ObservationIgnored
    private var configuredGroupID: String?
    
    @ObservationIgnored
    private var transactionTask: Task<Void, Never>?
    
    // MARK: Initialization
    
    public init() {
        startObserving()
    }
    
    deinit {
        transactionTask?.cancel()
    }
    
    // MARK: Public API
    
    /// Fetch localized product information from the App Store.
    public func loadProducts(_ ids: Set<String>) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let fetched = try await Product.products(for: Array(ids))
            // Sort by price (Low -> High) for consistent UI.
            products = fetched.sorted { $0.price < $1.price }
        } catch {
            logger.error("Failed to fetch products: \(error.localizedDescription)")
        }
    }
    
    /// Purchase a specific product.
    /// Returns the result so the caller can handle .pending/.userCancelled.
    @discardableResult
    public func purchase(_ product: Product) async throws -> Product.PurchaseResult {
        let result = try await product.purchase()
        
        switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await process(transaction: transaction)
                await transaction.finish()
                
            case .userCancelled, .pending:
                break
                
            @unknown default:
                break
        }
        
        return result
    }
    
    /// Manually sync with the App Store.
    public func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        try? await AppStore.sync()
        
        await updateNonConsumables()
        
        if let groupID = configuredGroupID {
            await refreshSubscriptionStatus(groupID: groupID)
        }
    }
    
    /// Refresh the subscription status for the given subscription group.
    public func refreshSubscriptionStatus(groupID: String) async {
        configuredGroupID = groupID
        
        do {
            let statuses = try await Product.SubscriptionInfo.status(for: groupID)
            let newTier = calculateTier(from: statuses)
            
            if newTier != subscriptionTier {
                logger.info("Tier updated to: \(String(describing: newTier))")
                subscriptionTier = newTier
            }
        } catch {
            logger.error("Failed to fetch status: \(error.localizedDescription)")
        }
    }
    
    // MARK: Internal Processing
    
    private func startObserving() {
        // 1. Continuous listener for updates (renewals, external purchases)
        transactionTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { return }
                if let transaction = try? self.checkVerified(update) {
                    await self.process(transaction: transaction)
                    await transaction.finish()
                }
            }
        }
        
        // 2. Process unfinished transactions on launch
        Task { [weak self] in
            for await transaction in Transaction.unfinished {
                guard let self else { return }
                if let t = try? self.checkVerified(transaction) {
                    await self.process(transaction: t)
                    await t.finish()
                }
            }
        }
        
        // 3. Initial entitlement check
        Task { [weak self] in
            await self?.updateNonConsumables()
        }
    }
    
    private func process(transaction: Transaction) async {
        logger.info("Processing transaction: \(transaction.productID)")
        
        switch transaction.productType {
            case .consumable:
                onConsumablePurchased?(transaction.productID)
                
            case .nonConsumable, .nonRenewable:
                if transaction.revocationDate == nil {
                    purchasedNonConsumables.insert(transaction.productID)
                } else {
                    purchasedNonConsumables.remove(transaction.productID)
                }
                
            case .autoRenewable:
                if let groupID = configuredGroupID {
                    await refreshSubscriptionStatus(groupID: groupID)
                }
                
            default:
                break
        }
    }
    
    private func updateNonConsumables() async {
        var active: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if let t = try? checkVerified(result), t.productType == .nonConsumable {
                active.insert(t.productID)
            }
        }
        purchasedNonConsumables = active
    }
    
    // MARK: Tier Calculation
    
    private func calculateTier(from statuses: [Product.SubscriptionInfo.Status]) -> Tier {
        let effectiveStatus = statuses.max { lhs, rhs in
            let lhsTier = tier(for: lhs)
            let rhsTier = tier(for: rhs)
            return lhsTier < rhsTier
        }
        
        guard let effectiveStatus else { return .defaultTier }
        return tier(for: effectiveStatus)
    }
    
    private func tier(for status: Product.SubscriptionInfo.Status) -> Tier {
        // CRITICAL: Only grant access for valid states
        guard status.state == .subscribed || status.state == .inGracePeriod else {
            return .defaultTier
        }
        
        guard case .verified(let transaction) = status.transaction else {
            return .defaultTier
        }
        
        let productID = transaction.productID
        
        // 1. Try Map via Product ID (Explicit & safest)
        if let t = Tier(productID: productID) {
            return t
        }
        
        // 2. Try Map via Group Level (Requires loaded products metadata)
        if let product = products.first(where: { $0.id == productID }),
           let groupLevel = product.subscription?.groupLevel,
           let t = Tier(levelOfService: groupLevel) {
            return t
        }
        
        return .defaultTier
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
            case .unverified(_, let error): throw error
            case .verified(let safe): return safe
        }
    }
}
