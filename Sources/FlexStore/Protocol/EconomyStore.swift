//
//  EconomyStore.swift
//  FlexStore
//
//  Created by Gerard Gomez on 12/14/25.
//


import Foundation

public protocol EconomyStore: Sendable {
    @MainActor
    func apply(_ grant: ConsumableGrant) throws
}
