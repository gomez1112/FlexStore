//
//  StoreKitManager.swift
//  FlexStore
//

import Foundation
import StoreKit
import OSLog
import Observation

/// A generic StoreKit 2 manager that tracks Tier state, Entitlements, and Products.
@Observable
@MainActor
public final class StoreKitService<Tier: SubscriptionTier> {
    
    // MARK: - Public State
    public private(set) var subscriptionTier: Tier = .defaultTier
    public private(set) var purchasedNonConsumables: Set<String> = []
    public private(set) var products: [Product] = []
    public private(set) var isLoading: Bool = false
    
    // MARK: - Subscription Details
    public private(set) var renewalDate: Date?
    public private(set) var willAutoRenew: Bool = false
    public private(set) var autoRenewPreferenceID: String?
    public private(set) var currentSubscriptionProduct: Product?
    
    public private(set) var isFreeTrial: Bool = false
    public private(set) var isBillingRetry: Bool = false
    public private(set) var isGracePeriod: Bool = false
    
    // MARK: - Callbacks
    @ObservationIgnored
    public var onConsumablePurchased: ((String) -> Void)?
    
    @ObservationIgnored
    private let logger = Logger(subsystem: "FlexStore", category: "StoreKitService")
    
    @ObservationIgnored
    private var configuredGroupID: String?
    
    @ObservationIgnored
    private var transactionTask: Task<Void, Never>?
    
    // MARK: - Init
    public init() {
        startObserving()
    }
    
    deinit {
        transactionTask?.cancel()
    }
    
    // MARK: - Computed Helpers
    public var isSubscribed: Bool {
        subscriptionTier != Tier.defaultTier
    }
    
    public var activeProductID: String? {
        currentSubscriptionProduct?.id
    }
    
    public var planName: String {
        currentSubscriptionProduct?.displayName ?? "Inactive"
    }
    
    public var upcomingPlanName: String? {
        guard let nextID = autoRenewPreferenceID,
              let nextProduct = products.first(where: { $0.id == nextID })
        else { return nil }
        return nextProduct.displayName
    }
    
    public var renewalStatusString: String {
        if isBillingRetry { return "Payment Failed - Update Info" }
        if isGracePeriod { return "Payment Due - Service Active" }
        
        guard let date = renewalDate else { return "No active subscription" }
        let dateString = date.formatted(date: .abbreviated, time: .omitted)
        
        if willAutoRenew {
            if let nextName = upcomingPlanName,
               autoRenewPreferenceID != currentSubscriptionProduct?.id {
                return "Renews to \(nextName) on \(dateString)"
            }
            return isFreeTrial ? "Trial ends on \(dateString)" : "Renews on \(dateString)"
        } else {
            return "Expires on \(dateString)"
        }
    }
    
    // MARK: - Public API
    public func loadProducts(_ ids: Set<String>) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let fetched = try await Product.products(for: Array(ids))
            products = fetched.sorted { $0.price < $1.price }
        } catch {
            logger.error("Failed to fetch products: \(error.localizedDescription)")
        }
    }
    
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
    
    public func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        try? await AppStore.sync()
        await updateNonConsumables()
        if let groupID = configuredGroupID {
            await refreshSubscriptionStatus(groupID: groupID)
        }
    }
    
    public func refreshSubscriptionStatus(groupID: String) async {
        configuredGroupID = groupID
        do {
            let statuses = try await Product.SubscriptionInfo.status(for: groupID)
            
            // 1. Update Tier
            let newTier = calculateTier(from: statuses)
            if newTier != subscriptionTier {
                subscriptionTier = newTier
            }
            
            // 2. Update Details
            if let effectiveStatus = findEffectiveStatus(from: statuses),
               case .verified(let transaction) = effectiveStatus.transaction,
               case .verified(let renewalInfo) = effectiveStatus.renewalInfo {
                
                self.renewalDate = transaction.expirationDate
                self.willAutoRenew = renewalInfo.willAutoRenew
                self.autoRenewPreferenceID = renewalInfo.autoRenewPreference
                self.currentSubscriptionProduct = products.first(where: { $0.id == transaction.productID })
                
                self.isBillingRetry = effectiveStatus.state == .inBillingRetryPeriod
                self.isGracePeriod = effectiveStatus.state == .inGracePeriod
                self.isFreeTrial = transaction.offerType == .introductory
            } else {
                self.renewalDate = nil
                self.willAutoRenew = false
                self.autoRenewPreferenceID = nil
                self.currentSubscriptionProduct = nil
                self.isBillingRetry = false
                self.isGracePeriod = false
                self.isFreeTrial = false
            }
        } catch {
            logger.error("Failed to fetch status: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Internal Processing
    private func startObserving() {
        transactionTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { return }
                if let transaction = try? self.checkVerified(update) {
                    await self.process(transaction: transaction)
                    await transaction.finish()
                }
            }
        }
        
        Task { [weak self] in
            // Handle unfinished on launch
            for await transaction in Transaction.unfinished {
                guard let self else { return }
                if let t = try? self.checkVerified(transaction) {
                    await self.process(transaction: t)
                    await t.finish()
                }
            }
        }
        
        Task { [weak self] in await self?.updateNonConsumables() }
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
    
    // MARK: - Tier Calculation
    private func findEffectiveStatus(from statuses: [Product.SubscriptionInfo.Status]) -> Product.SubscriptionInfo.Status? {
        return statuses
            .filter { $0.state == .subscribed || $0.state == .inGracePeriod }
            .max { lhs, rhs in
                let lhsTier = tier(for: lhs)
                let rhsTier = tier(for: rhs)
                return lhsTier < rhsTier
            }
    }
    
    private func calculateTier(from statuses: [Product.SubscriptionInfo.Status]) -> Tier {
        guard let effectiveStatus = findEffectiveStatus(from: statuses) else { return .defaultTier }
        return tier(for: effectiveStatus)
    }
    
    private func tier(for status: Product.SubscriptionInfo.Status) -> Tier {
        guard case .verified(let transaction) = status.transaction else { return .defaultTier }
        return Tier(productID: transaction.productID) ?? .defaultTier
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
            case .unverified(_, let error): throw error
            case .verified(let safe): return safe
        }
    }
}
