//
//  StoreKitManager.swift
//  FlexStore
//

import Foundation
import StoreKit
import OSLog
import Observation

@Observable
@MainActor
public final class StoreKitService<Tier: SubscriptionTier> {
    
    // MARK: - Public State
    
    public private(set) var subscriptionTier: Tier = .defaultTier
    public private(set) var purchasedNonConsumables: Set<String> = []
    public private(set) var products: [Product] = []
    public private(set) var isLoading: Bool = false
    
    // MARK: - Subscription Details (Optional UI Helpers)
    
    public private(set) var renewalDate: Date?
    public private(set) var willAutoRenew: Bool = false
    public private(set) var autoRenewPreferenceID: String?
    public private(set) var currentSubscriptionProduct: Product?
    
    public private(set) var isFreeTrial: Bool = false
    public private(set) var isBillingRetry: Bool = false
    
    public var isSubscribed: Bool { subscriptionTier != Tier.defaultTier }
    public var activeProductID: String? { currentSubscriptionProduct?.id }
    public var planName: String { currentSubscriptionProduct?.displayName ?? "Inactive" }
    
    public var upcomingPlanName: String? {
        guard let nextID = autoRenewPreferenceID,
              let nextProduct = products.first(where: { $0.id == nextID })
        else { return nil }
        return nextProduct.displayName
    }
    
    public var renewalStatusString: String {
        if isBillingRetry { return "Payment Failed - Update Info" }
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
    
    // MARK: - Hooks
    
    @ObservationIgnored
    public var onConsumablePurchased: (@MainActor @Sendable (String) -> Void)?
    
    @ObservationIgnored
    public var onEconomyError: (@MainActor @Sendable (Error) -> Void)?

    @ObservationIgnored
    private var processedConsumableTransactionIDs: Set<UInt64> = []

    // MARK: - Private
    
    @ObservationIgnored private let logger = Logger(subsystem: "FlexStore", category: "StoreKitService")
    
    @ObservationIgnored private var configuredGroupID: String?
    @ObservationIgnored private var observingTasks: [Task<Void, Never>] = []
    
    public init() {
        startObservingTransactions()
    }
    
    deinit {
        observingTasks.forEach { $0.cancel() }
    }
    
    // MARK: - Configuration
    
    /// Convenience configuration call.
    /// Call this from a `.task` in your app (or via `View.attachStoreKit(...)`).
    public func configure(productIDs: Set<String>, subscriptionGroupID: String?) async {
        if !productIDs.isEmpty {
            await loadProducts(productIDs)
        }
        await updateNonConsumables()
        
        if let subscriptionGroupID {
            await refreshSubscriptionStatus(groupID: subscriptionGroupID)
        }
    }
    
    // MARK: - Product Loading
    
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
    
    public func product(for id: String) -> Product? {
        products.first(where: { $0.id == id })
    }
    
    // MARK: - Purchasing
    
    public enum PurchaseOutcome: Sendable, Equatable {
        case success
        case cancelled
        case pending
    }
    
    /// Purchases a product by ID (nice for UI call sites).
    public func purchase(productID: String) async throws -> PurchaseOutcome {
        guard let product = product(for: productID) else {
            throw FlexStoreError(
                title: "Not Available",
                message: "This product isn't loaded yet."
            )
        }
        return try await purchase(product)
    }
    
    @discardableResult
    public func purchase(_ product: Product) async throws -> PurchaseOutcome {
        let result = try await product.purchase()
        
        switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await process(transaction: transaction)
                await transaction.finish()
                return .success
                
            case .userCancelled:
                return .cancelled
                
            case .pending:
                return .pending
                
            @unknown default:
                return .pending
        }
    }
    
    public func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await AppStore.sync()
        } catch {
            logger.error("AppStore.sync failed: \(error.localizedDescription)")
        }
        
        await updateNonConsumables()
        
        if let groupID = configuredGroupID {
            await refreshSubscriptionStatus(groupID: groupID)
        }
    }
    
    // MARK: - Subscription Status
    
    public func refreshSubscriptionStatus(groupID: String) async {
        configuredGroupID = groupID
        
        do {
            let statuses = try await Product.SubscriptionInfo.status(for: groupID)
            
            let newTier = calculateTier(from: statuses)
            if newTier != subscriptionTier { subscriptionTier = newTier }
            
            if let effective = findEffectiveStatus(from: statuses),
               case .verified(let transaction) = effective.transaction,
               case .verified(let renewalInfo) = effective.renewalInfo {
                
                renewalDate = transaction.expirationDate
                willAutoRenew = renewalInfo.willAutoRenew
                autoRenewPreferenceID = renewalInfo.autoRenewPreference
                currentSubscriptionProduct = products.first(where: { $0.id == transaction.productID })
                
                // Treat these states as "still active-ish" for messaging.
                isBillingRetry = (effective.state == .inBillingRetryPeriod)
                isFreeTrial = (transaction.offerType == .introductory)
                
            } else {
                renewalDate = nil
                willAutoRenew = false
                autoRenewPreferenceID = nil
                currentSubscriptionProduct = nil
                isBillingRetry = false
                isFreeTrial = false
            }
            
        } catch {
            logger.error("Failed to fetch subscription status: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Observing Transactions
    
    private func startObservingTransactions() {
        // Updates stream (new transactions)
        observingTasks.append(Task { [weak self] in
            guard let self else { return }
            for await update in Transaction.updates {
                if Task.isCancelled { return }
                if let transaction = try? self.checkVerified(update) {
                    await self.process(transaction: transaction)
                    await transaction.finish()
                }
            }
        })
        
        // Finish unfinished transactions
        observingTasks.append(Task { [weak self] in
            guard let self else { return }
            for await unfinished in Transaction.unfinished {
                if Task.isCancelled { return }
                if let transaction = try? self.checkVerified(unfinished) {
                    await self.process(transaction: transaction)
                    await transaction.finish()
                }
            }
        })
        
        // Initial entitlement refresh
        observingTasks.append(Task { [weak self] in
            await self?.updateNonConsumables()
        })
    }
    
    // MARK: - Processing
    
    private func process(transaction: Transaction) async {
        switch transaction.productType {
            case .consumable:
                let id = transaction.id
                guard !processedConsumableTransactionIDs.contains(id) else { return }
                processedConsumableTransactionIDs.insert(id)
                
                guard transaction.revocationDate == nil else { return }
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
        
        for await entitlement in Transaction.currentEntitlements {
            if let t = try? checkVerified(entitlement), t.productType == .nonConsumable {
                active.insert(t.productID)
            }
        }
        
        purchasedNonConsumables = active
    }
    
    // MARK: - Tier Calculation
    
    private func findEffectiveStatus(from statuses: [Product.SubscriptionInfo.Status]) -> Product.SubscriptionInfo.Status? {
        let activeStates: Set<Product.SubscriptionInfo.RenewalState> = [
            .subscribed, .inGracePeriod, .inBillingRetryPeriod
        ]
        
        let active = statuses.filter { activeStates.contains($0.state) }
        return active.max { tier(for: $0) < tier(for: $1) }
    }
    
    private func calculateTier(from statuses: [Product.SubscriptionInfo.Status]) -> Tier {
        guard let effective = findEffectiveStatus(from: statuses) else { return .defaultTier }
        return tier(for: effective)
    }
    
    private func tier(for status: Product.SubscriptionInfo.Status) -> Tier {
        // Consider these "still active" for gating
        let activeStates: Set<Product.SubscriptionInfo.RenewalState> = [
            .subscribed,
            .inGracePeriod,
            .inBillingRetryPeriod
        ]
        
        guard activeStates.contains(status.state) else { return .defaultTier }
        guard case .verified(let transaction) = status.transaction else { return .defaultTier }
        
        // Prefer mapping by productID (best for clarity)
        if let t = Tier(productID: transaction.productID) { return t }
        
        // Fallback: map via group level
        if let product = products.first(where: { $0.id == transaction.productID }),
           let groupLevel = product.subscription?.groupLevel,
           let t = Tier(levelOfService: groupLevel) {
            return t
        }
        
        return .defaultTier
    }
    
    // MARK: - Verification
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
            case .unverified(_, let error):
                throw error
            case .verified(let safe):
                return safe
        }
    }
}
