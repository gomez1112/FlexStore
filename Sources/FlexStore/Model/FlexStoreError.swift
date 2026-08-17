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
    public let title: LocalizedStringResource

    /// Descriptive message explaining the issue.
    public let message: LocalizedStringResource

    /// Creates a new FlexStore error value.
    ///
    /// - Parameters:
    ///   - title: Short title shown to the user.
    ///   - message: Detailed message suitable for an alert body.
    public init(title: LocalizedStringResource, message: LocalizedStringResource) {
        self.title = title
        self.message = message
    }

    public var errorDescription: String? { String(localized: message) }
}
