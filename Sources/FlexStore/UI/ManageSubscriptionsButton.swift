//
//  ManageSubscriptionsButton.swift
//  FlexStore
//
//  Created by Gerard Gomez on 12/14/25.
//

import SwiftUI

public struct ManageSubscriptionsButton: View {
    @Environment(\.openURL) var openURL
    
    public init() {}
    
    public var body: some View {
        Button("Manage Subscription") {
            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                openURL(url)
            }
        }
    }
}
