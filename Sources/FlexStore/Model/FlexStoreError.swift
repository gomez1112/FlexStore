//
//  FlexStoreError.swift
//  FlexStore
//
//  Created by Gerard Gomez on 12/14/25.
//


import Foundation

public struct FlexStoreError: LocalizedError, Identifiable, Sendable {
    public let id = UUID()
    public let title: String
    public let message: String

    public init(title: String, message: String) {
        self.title = title
        self.message = message
    }

    public var errorDescription: String? { message }
}