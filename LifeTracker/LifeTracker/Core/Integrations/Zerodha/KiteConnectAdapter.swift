import Foundation

/// Reads-only wrapper around the Kite Connect REST API (holdings, funds).
/// Deliberately does not call any market-data/historical endpoints — those
/// aren't part of the free Personal API tier, and this app only ever shows
/// values as of your last manual refresh (see InvestmentSnapshot).
final class KiteConnectAdapter: BrokerAdapter {
    private let baseURL = URL(string: "https://api.kite.trade")!

    var isConnected: Bool {
        KeychainService.get(KiteCredentialKey.accessToken) != nil &&
        KeychainService.get(KiteCredentialKey.apiKey) != nil
    }

    func disconnect() {
        KeychainService.remove(KiteCredentialKey.accessToken)
    }

    func fetchPortfolio() async throws -> BrokerPortfolio {
        guard let apiKey = KeychainService.get(KiteCredentialKey.apiKey) else {
            throw BrokerAdapterError.notConfigured
        }
        guard let accessToken = KeychainService.get(KiteCredentialKey.accessToken) else {
            throw BrokerAdapterError.notAuthenticated
        }

        async let holdings = fetchHoldings(apiKey: apiKey, accessToken: accessToken)
        async let funds = fetchFunds(apiKey: apiKey, accessToken: accessToken)
        return BrokerPortfolio(holdings: try await holdings, funds: try await funds)
    }

    private func fetchHoldings(apiKey: String, accessToken: String) async throws -> [BrokerHolding] {
        struct HoldingsResponse: Decodable {
            struct Holding: Decodable {
                let tradingsymbol: String
                let quantity: Double
                let average_price: Double
                let last_price: Double
            }
            let data: [Holding]
        }
        let response: HoldingsResponse = try await get("/portfolio/holdings", apiKey: apiKey, accessToken: accessToken)
        return response.data.map {
            BrokerHolding(symbol: $0.tradingsymbol, quantity: $0.quantity, averagePrice: $0.average_price, lastPrice: $0.last_price)
        }
    }

    private func fetchFunds(apiKey: String, accessToken: String) async throws -> BrokerFunds {
        struct MarginsResponse: Decodable {
            struct Segment: Decodable { let net: Double }
            struct MarginsData: Decodable { let equity: Segment? }
            let data: MarginsData
        }
        let response: MarginsResponse = try await get("/user/margins", apiKey: apiKey, accessToken: accessToken)
        return BrokerFunds(availableCash: response.data.equity?.net ?? 0)
    }

    private func get<T: Decodable>(_ path: String, apiKey: String, accessToken: String) async throws -> T {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.setValue("token \(apiKey):\(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("3", forHTTPHeaderField: "X-Kite-Version")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw BrokerAdapterError.invalidResponse }
        guard 200..<300 ~= http.statusCode else {
            if http.statusCode == 403 { throw BrokerAdapterError.notAuthenticated }
            throw BrokerAdapterError.api("Kite API returned status \(http.statusCode).")
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
