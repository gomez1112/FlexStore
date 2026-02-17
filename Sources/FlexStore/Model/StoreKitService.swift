//
//  StoreKitManager.swift
//  FlexStore
//

import Foundation
import StoreKit
import OSLog
import Observation

/// Observable StoreKit 2 manager that fetches products, tracks entitlements, and processes purchases for your app's tiers.
@Observable
@MainActor
public final class StoreKitService<Tier: SubscriptionTier> {
    
    // MARK: - Public State
    
    /// The active entitlement tier resolved from the user's subscription or `.defaultTier` when unsubscribed.
    public private(set) var subscriptionTier: Tier = .defaultTier

    /// Product identifiers for non-consumables the user owns.
    public private(set) var purchasedNonConsumables: Set<String> = []

    /// StoreKit products loaded for the configured identifiers.
    public private(set) var products: [Product] = []

    /// Indicates whether the service is currently performing a StoreKit operation.
    public private(set) var isLoading: Bool = false
    
    // MARK: - Subscription Details (Optional UI Helpers)
    
    /// The renewal or expiration date for the current subscription, if any.
    public private(set) var renewalDate: Date?

    /// `true` when the subscription is set to auto-renew at the end of the current period.
    public private(set) var willAutoRenew: Bool = false

    /// The product identifier the subscription will renew into, if different from the current product.
    public private(set) var autoRenewPreferenceID: String?

    /// The active subscription product resolved from StoreKit status.
    public private(set) var currentSubscriptionProduct: Product?

    /// Indicates the user is currently in a free trial period.
    public private(set) var isFreeTrial: Bool = false

    /// Indicates the subscription is in a billing retry state.
    public private(set) var isBillingRetry: Bool = false

    /// Convenience flag that is `true` when the active tier is higher than `.defaultTier`.
    public var isSubscribed: Bool { subscriptionTier != Tier.defaultTier }

    /// The identifier of the active subscription product, if available.
    public var activeProductID: String? { currentSubscriptionProduct?.id }

    /// The display name of the active subscription product, or "Inactive" when no subscription is active.
    public var planName: String { currentSubscriptionProduct?.displayName ?? "Inactive" }

    /// The display name for the auto-renew target, if it differs from the current product.
    public var upcomingPlanName: String? {
        guard let nextID = autoRenewPreferenceID,
              let nextProduct = products.first(where: { $0.id == nextID })
        else { return nil }
        return nextProduct.displayName
    }
    
    /// Human-friendly description of the current renewal state for UI labels.
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
    /// Callback invoked when a consumable transaction is verified and ready to be applied.
    public var onConsumablePurchased: (@MainActor @Sendable (String) -> Void)?

    @ObservationIgnored
    /// Callback invoked to apply a consumable grant and report success. Return false to retry later.
    public var onConsumablePurchasedResult: (@MainActor @Sendable (String) async -> Bool)?

    @ObservationIgnored
    /// Callback invoked when applying a consumable grant to the app's economy throws.
    public var onEconomyError: (@MainActor @Sendable (Error) -> Void)?

    @ObservationIgnored
    private var processedConsumableTransactionIDs: Set<UInt64> = []

    // MARK: - Private
    
    @ObservationIgnored private let logger = Logger(subsystem: "FlexStore", category: "StoreKitService")
    @ObservationIgnored private let consumableLedgerKey = "FlexStore.processedConsumableTransactions"
    
    @ObservationIgnored private var configuredGroupID: String?
    @ObservationIgnored private var observingTasks: [Task<Void, Never>] = []
    
    /// Creates a new StoreKit service and immediately starts observing transaction streams.
    public init() {
        processedConsumableTransactionIDs = loadProcessedConsumables()
        startObservingTransactions()
    }
    
    deinit {
        observingTasks.forEach { $0.cancel() }
    }
    
    // MARK: - Configuration
    
    /// Configures StoreKit by loading the provided products, updating non-consumable entitlements, and refreshing subscription status when a group identifier is supplied.
    ///
    /// - Parameters:
    ///   - productIDs: The set of product identifiers to load.
    ///   - subscriptionGroupID: The subscription group identifier to query for status updates.
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
    
    /// Fetches StoreKit product metadata for the provided identifiers and sorts them by ascending price.
    ///
    /// - Parameter ids: Product identifiers to request.
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
    
    /// Returns a previously-loaded StoreKit product for the given identifier.
    ///
    /// - Parameter id: The product identifier to find.
    /// - Returns: The matching `Product` if it has been loaded.
    public func product(for id: String) -> Product? {
        products.first(where: { $0.id == id })
    }
    
    // MARK: - Purchasing
    
    /// Result states from a purchase attempt.
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
    
    /// Purchases a StoreKit product that has already been loaded.
    ///
    /// - Parameter product: The product to purchase.
    /// - Returns: The resulting `PurchaseOutcome` describing user intent or transaction status.
    @discardableResult
    public func purchase(_ product: Product) async throws -> PurchaseOutcome {
        let result = try await product.purchase()
        
        switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                let shouldFinish = await process(transaction: transaction)
                if shouldFinish {
                    await transaction.finish()
                } else {
                    logger.warning("Consumable not applied, leaving transaction unfinished for retry.")
                }
                return .success
                
            case .userCancelled:
                return .cancelled
                
            case .pending:
                return .pending
                
            @unknown default:
                return .pending
        }
    }
    
    /// Syncs with the App Store to restore purchases and refreshes known entitlements.
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
    
    /// Refreshes subscription status for the supplied App Store Connect subscription group identifier.
    ///
    /// - Parameter groupID: The group identifier to query.
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
                    let shouldFinish = await self.process(transaction: transaction)
                    if shouldFinish {
                        await transaction.finish()
                    } else {
                        self.logger.warning("Consumable not applied, leaving transaction unfinished for retry.")
                    }
                }
            }
        })
        
        // Finish unfinished transactions
        observingTasks.append(Task { [weak self] in
            guard let self else { return }
            for await unfinished in Transaction.unfinished {
                if Task.isCancelled { return }
                if let transaction = try? self.checkVerified(unfinished) {
                    let shouldFinish = await self.process(transaction: transaction)
                    if shouldFinish {
                        await transaction.finish()
                    } else {
                        self.logger.warning("Consumable not applied, leaving transaction unfinished for retry.")
                    }
                }
            }
        })
        
        // Initial entitlement refresh
        observingTasks.append(Task { [weak self] in
            await self?.updateNonConsumables()
        })
    }
    
    // MARK: - Processing
    
    private func process(transaction: Transaction) async -> Bool {
        switch transaction.productType {
            case .consumable:
                let id = transaction.id
                guard !processedConsumableTransactionIDs.contains(id) else { return true }

                guard transaction.revocationDate == nil else { return true }

                let applied: Bool
                if let handler = onConsumablePurchasedResult {
                    applied = await handler(transaction.productID)
                } else {
                    onConsumablePurchased?(transaction.productID)
                    applied = true
                }

                guard applied else { return false }
                processedConsumableTransactionIDs.insert(id)
                persistProcessedConsumables()
                return true

            case .nonConsumable, .nonRenewable:
                if transaction.revocationDate == nil {
                    purchasedNonConsumables.insert(transaction.productID)
                } else {
                    purchasedNonConsumables.remove(transaction.productID)
                }
                return true

            case .autoRenewable:
                if let groupID = configuredGroupID {
                    await refreshSubscriptionStatus(groupID: groupID)
                }
                return true

            default:
                return true
        }
    }

    
    private func updateNonConsumables() async {
        var active: Set<String> = []
        
        for await entitlement in Transaction.currentEntitlements {
            if let t = try? checkVerified(entitlement),
               t.productType == .nonConsumable || t.productType == .nonRenewable {
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

    private func loadProcessedConsumables() -> Set<UInt64> {
        let stored = UserDefaults.standard.array(forKey: consumableLedgerKey) as? [String] ?? []
        return Set(stored.compactMap { UInt64($0) })
    }

    private func persistProcessedConsumables() {
        let stored = processedConsumableTransactionIDs.map { String($0) }
        UserDefaults.standard.set(stored, forKey: consumableLedgerKey)
    }
}
