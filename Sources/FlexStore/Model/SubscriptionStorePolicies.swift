import Foundation
import SwiftUI
import StoreKit

/// Optional policy destinations for subscription store views.
public struct SubscriptionStorePolicies: Sendable {
    public let privacyPolicyURL: URL?
    public let termsOfServiceURL: URL?

    /// Creates policy destinations for privacy policy and terms of service links.
    ///
    /// - Parameters:
    ///   - privacyPolicyURL: URL to open when the privacy policy button is tapped.
    ///   - termsOfServiceURL: URL to open when the terms of service button is tapped.
    public init(
        privacyPolicyURL: URL? = nil,
        termsOfServiceURL: URL? = nil
    ) {
        self.privacyPolicyURL = privacyPolicyURL
        self.termsOfServiceURL = termsOfServiceURL
    }

    var isEmpty: Bool {
        privacyPolicyURL == nil && termsOfServiceURL == nil
    }
}

public extension View {
    @ViewBuilder
    func flexStorePolicies(_ policies: SubscriptionStorePolicies?) -> some View {
        if let policies,
           let privacyPolicyURL = policies.privacyPolicyURL,
           let termsOfServiceURL = policies.termsOfServiceURL {
            self
                .subscriptionStorePolicyDestination(url: privacyPolicyURL, for: .privacyPolicy)
                .subscriptionStorePolicyDestination(url: termsOfServiceURL, for: .termsOfService)
        } else if let policies,
                  let privacyPolicyURL = policies.privacyPolicyURL {
            self
                .subscriptionStorePolicyDestination(url: privacyPolicyURL, for: .privacyPolicy)
        } else if let policies,
                  let termsOfServiceURL = policies.termsOfServiceURL {
            self
                .subscriptionStorePolicyDestination(url: termsOfServiceURL, for: .termsOfService)
        } else {
            self
        }
    }
}
