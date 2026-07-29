import Foundation
import SwiftData

/// Kite Connect's free/personal tier has no historical-data endpoint, so
/// "portfolio value over time" only exists because we capture a snapshot
/// each time you tap Refresh in the Investments module. `holdings` is the
/// per-symbol breakdown at that moment.
@Model
final class InvestmentSnapshot {
    @Attribute(.unique) var id: UUID
    var capturedAt: Date
    var totalValue: Double
    var totalInvested: Double
    var totalPnL: Double
    @Relationship(deleteRule: .cascade, inverse: \InvestmentHolding.snapshot)
    var holdings: [InvestmentHolding]

    init(
        id: UUID = UUID(),
        capturedAt: Date = .now,
        totalValue: Double,
        totalInvested: Double,
        totalPnL: Double,
        holdings: [InvestmentHolding] = []
    ) {
        self.id = id
        self.capturedAt = capturedAt
        self.totalValue = totalValue
        self.totalInvested = totalInvested
        self.totalPnL = totalPnL
        self.holdings = holdings
    }
}
