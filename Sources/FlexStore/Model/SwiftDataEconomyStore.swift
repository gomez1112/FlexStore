//
//  SwiftDataEconomyStore.swift
//  FlexStore
//
//  Created by Gerard Gomez on 12/14/25.
//


#if canImport(SwiftData)
import Foundation
import SwiftData

/// SwiftData-backed implementation of ``EconomyStore`` that awards consumables to a persisted profile.
@MainActor
public struct SwiftDataEconomyStore<Profile: PersistentModel>: EconomyStore {

    /// Closure type that fetches an existing profile from SwiftData.
    public typealias FetchProfile = @MainActor @Sendable () throws -> Profile?

    /// Closure type that creates a profile when none exists.
    public typealias CreateProfile = @MainActor @Sendable () -> Profile

    private let context: ModelContext
    private let fetchProfile: FetchProfile
    private let createProfile: CreateProfile
    
    private var intBalances: [ConsumableGrant.Kind: WritableKeyPath<Profile, Int>] = [:]
    private var customAppliers: [ConsumableGrant.Kind: @MainActor @Sendable (inout Profile, Int) throws -> Void] = [:]
    
    /// Creates an economy store bound to a SwiftData context.
    ///
    /// - Parameters:
    ///   - context: The `ModelContext` used for fetching and saving.
    ///   - fetchProfile: Optional closure to locate an existing profile; defaults to fetching the first available profile.
    ///   - createProfile: Closure used to create a profile when none is found.
    public init(
        context: ModelContext,
        fetchProfile: FetchProfile? = nil,
        createProfile: @escaping CreateProfile
    ) {
        self.context = context

        // ✅ build the default here (allowed)
        self.fetchProfile = fetchProfile ?? {
            let descriptor = FetchDescriptor<Profile>()
            return try context.fetch(descriptor).first
        }

        self.createProfile = createProfile
    }
    
    // MARK: - Registration
    
    /// Registers a writable key path that should be incremented for the specified consumable kind.
    ///
    /// - Parameters:
    ///   - kind: Consumable kind to map.
    ///   - keyPath: Key path pointing to the integer balance on the profile.
    public mutating func registerBalance(_ kind: ConsumableGrant.Kind, _ keyPath: WritableKeyPath<Profile, Int>) {
        intBalances[kind] = keyPath
    }

    /// Convenience helper to register a token balance using a custom token name.
    ///
    /// - Parameters:
    ///   - name: Token identifier.
    ///   - keyPath: Key path to the profile balance.
    public mutating func registerTokenBalance(_ name: String, _ keyPath: WritableKeyPath<Profile, Int>) {
        registerBalance(.tokens(name), keyPath)
    }

    /// Custom applier when keypaths aren't enough (caps, multiple fields, etc.)
    ///
    /// - Parameters:
    ///   - kind: Consumable kind to apply.
    ///   - applier: Closure invoked with the profile and amount to perform a custom mutation.
    public mutating func registerCustom(
        _ kind: ConsumableGrant.Kind,
        _ applier: @escaping @MainActor @Sendable (inout Profile, Int) throws -> Void
    ) {
        customAppliers[kind] = applier
    }
    
    // MARK: - EconomyStore
    
    /// Applies a consumable grant to the SwiftData profile, persisting the change.
    ///
    /// - Parameter grant: Consumable grant to apply.
    public func apply(_ grant: ConsumableGrant) throws {
        var profile = try fetchOrCreateProfile()
        
        if let applier = customAppliers[grant.kind] {
            try applier(&profile, grant.amount)
            try context.save()
            return
        }
        
        guard let keyPath = intBalances[grant.kind] else {
            return // unknown kind => no-op
        }
        
        profile[keyPath: keyPath] += grant.amount
        try context.save()
    }
    
    // MARK: - Helpers
    
    private func fetchOrCreateProfile() throws -> Profile {
        if let existing = try fetchProfile() {
            return existing
        }
        
        let created = createProfile()
        context.insert(created)
        return created
    }
}
#endif
