import Foundation
import SwiftData

@Model
final class InvestmentHolding {
    @Attribute(.unique) var id: UUID
    var symbol: String
    var quantity: Double
    var averagePrice: Double
    var lastPrice: Double
    var currentValue: Double
    var pnl: Double
    var snapshot: InvestmentSnapshot?

    init(
        id: UUID = UUID(),
        symbol: String,
        quantity: Double,
        averagePrice: Double,
        lastPrice: Double,
        currentValue: Double,
        pnl: Double
    ) {
        self.id = id
        self.symbol = symbol
        self.quantity = quantity
        self.averagePrice = averagePrice
        self.lastPrice = lastPrice
        self.currentValue = currentValue
        self.pnl = pnl
    }
}
