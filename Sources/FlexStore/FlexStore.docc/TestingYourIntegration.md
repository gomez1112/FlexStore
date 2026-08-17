# Testing your integration

Add a StoreKit configuration to the test target, create an `SKTestSession(configurationFileNamed:)`, disable dialogs, and clear transactions before each test. Exercise purchases, expirations, grace periods, billing retry, revocation, restore, and unfinished consumable retries. Use a fresh `UserDefaults` suite for ledger isolation.
