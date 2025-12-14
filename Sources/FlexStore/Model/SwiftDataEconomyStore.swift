//
//  SwiftDataEconomyStore.swift
//  FlexStore
//
//  Created by Gerard Gomez on 12/14/25.
//


#if canImport(SwiftData)
import Foundation
import SwiftData

@MainActor
public struct SwiftDataEconomyStore<Profile: PersistentModel>: EconomyStore {
    
    public typealias FetchProfile = @MainActor @Sendable () throws -> Profile?
    public typealias CreateProfile = @MainActor @Sendable () -> Profile
    
    private let context: ModelContext
    private let fetchProfile: FetchProfile
    private let createProfile: CreateProfile
    
    private var intBalances: [ConsumableGrant.Kind: WritableKeyPath<Profile, Int>] = [:]
    private var customAppliers: [ConsumableGrant.Kind: @MainActor @Sendable (inout Profile, Int) throws -> Void] = [:]
    
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
    
    public mutating func registerBalance(_ kind: ConsumableGrant.Kind, _ keyPath: WritableKeyPath<Profile, Int>) {
        intBalances[kind] = keyPath
    }
    
    public mutating func registerTokenBalance(_ name: String, _ keyPath: WritableKeyPath<Profile, Int>) {
        registerBalance(.tokens(name), keyPath)
    }
    
    /// Custom applier when keypaths aren't enough (caps, multiple fields, etc.)
    public mutating func registerCustom(
        _ kind: ConsumableGrant.Kind,
        _ applier: @escaping @MainActor @Sendable (inout Profile, Int) throws -> Void
    ) {
        customAppliers[kind] = applier
    }
    
    // MARK: - EconomyStore
    
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
