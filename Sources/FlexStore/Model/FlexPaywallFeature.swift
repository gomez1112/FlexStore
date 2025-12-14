//
//  FlexPaywallFeature.swift
//  FlexStore
//
//  Created by Gerard Gomez on 12/14/25.
//


import SwiftUI

public struct FlexPaywallFeature: Identifiable, Hashable, Sendable {
    public var id: String
    public var systemImage: String
    public var title: String
    public var subtitle: String
    public var tint: Color

    public init(
        id: String = UUID().uuidString,
        systemImage: String,
        title: String,
        subtitle: String,
        tint: Color = .accentColor
    ) {
        self.id = id
        self.systemImage = systemImage
        self.title = title
        self.subtitle = subtitle
        self.tint = tint
    }
}
