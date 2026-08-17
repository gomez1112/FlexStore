# Consumables and your economy

The result-returning consumable handler must persist a grant before returning `true`. Returning `false` leaves the transaction unfinished. FlexStore retains a bounded secondary ledger and finishes successfully handled transactions.

There remains a crash window between an app economy committing a grant and FlexStore recording its transaction identifier. Fully atomic exactly-once delivery requires the balance and transaction ledger to share one transactional store; `UserDefaults` cannot provide that atomicity. Design grants to be idempotent by StoreKit transaction ID when exact-once behavior is required. Configure an App Group `UserDefaults` suite when purchases can be processed by an extension.
