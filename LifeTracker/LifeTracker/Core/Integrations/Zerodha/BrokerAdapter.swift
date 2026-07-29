import Foundation

/// Everything the Investments module needs from a broker, kept generic so
/// Zerodha isn't baked into the UI layer. If you later want to add another
/// broker/exchange, write a second type conforming to this protocol and pick
/// between them in Settings — nothing in Modules/Investments needs to change.
protocol BrokerAdapter {
    var isConnected: Bool { get }
    func fetchPortfolio() async throws -> BrokerPortfolio
    func disconnect()
}

struct BrokerPortfolio {
    var holdings: [BrokerHolding]
    var funds: BrokerFunds?
}

struct BrokerHolding: Identifiable {
    var id: String { symbol }
    var symbol: String
    var quantity: Double
    var averagePrice: Double
    var lastPrice: Double

    var currentValue: Double { quantity * lastPrice }
    var investedValue: Double { quantity * averagePrice }
    var pnl: Double { currentValue - investedValue }
}

struct BrokerFunds {
    var availableCash: Double
}

enum BrokerAdapterError: LocalizedError {
    case notConfigured
    case notAuthenticated
    case invalidResponse
    case api(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Add your Kite Connect API key and secret in Settings first."
        case .notAuthenticated: return "Connect your Zerodha account in Settings before fetching data."
        case .invalidResponse: return "Zerodha returned a response Life Tracker didn't understand."
        case .api(let message): return message
        }
    }
}
