//
//  FlexStoreError.swift
//  FlexStore
//
//  Created by Gerard Gomez on 12/14/25.
//


import Foundation

/// User-presentable error wrapper used throughout FlexStore UI components.
public struct FlexStoreError: LocalizedError, Identifiable, Sendable {
    /// Unique identifier for alert presentation.
    public let id = UUID()

    /// Short, user-facing title for the error.
    public let title: String

    /// Descriptive message explaining the issue.
    public let message: String

    /// Creates a new FlexStore error value.
    ///
    /// - Parameters:
    ///   - title: Short title shown to the user.
    ///   - message: Detailed message suitable for an alert body.
    public init(title: String, message: String) {
        self.title = title
        self.message = message
    }

    public var errorDescription: String? { message }
}