import SwiftUI
import SwiftData
import Charts

struct InvestmentsView: View {
    @Query(sort: \InvestmentSnapshot.capturedAt, order: .reverse) private var snapshots: [InvestmentSnapshot]
    @Environment(\.modelContext) private var context

    private let adapter: BrokerAdapter = KiteConnectAdapter()
    @State private var isRefreshing = false
    @State private var errorMessage: String?

    private var latest: InvestmentSnapshot? { snapshots.first }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                if !adapter.isConnected {
                    Card {
                        Text("Connect your Zerodha account in Settings to pull holdings and funds.")
                            .font(Theme.Typography.body)
                        NavigationLink("Go to Settings") { IntegrationsSettingsView() }
                            .buttonStyle(.bordered)
                    }
                } else {
                    Card {
                        SectionHeader(title: "Portfolio", actionTitle: isRefreshing ? nil : "Refresh") {
                            Task { await refresh() }
                        }
                        if let latest {
                            Text(latest.totalValue.formatted(.currency(code: "INR")))
                                .font(Theme.Typography.largeTitle)
                            HStack {
                                Text("P/L: \(latest.totalPnL.formatted(.currency(code: "INR")))")
                                    .foregroundStyle(latest.totalPnL >= 0 ? Theme.ColorToken.positive : Theme.ColorToken.negative)
                                Spacer()
                                Text("as of \(latest.capturedAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(Theme.Typography.caption)
                                    .foregroundStyle(Theme.ColorToken.secondaryText)
                            }
                        } else {
                            Text("No snapshot yet — tap Refresh to pull your current holdings.")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.ColorToken.secondaryText)
                        }
                        if let errorMessage {
                            Text(errorMessage)
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.ColorToken.negative)
                        }
                    }

                    if snapshots.count > 1 {
                        Card {
                            SectionHeader(title: "Value Over Time")
                            Chart(snapshots.reversed(), id: \.id) { snapshot in
                                LineMark(x: .value("Date", snapshot.capturedAt), y: .value("Value", snapshot.totalValue))
                                    .foregroundStyle(Theme.ColorToken.accent)
                            }
                            .frame(height: 160)
                        }
                    }

                    if let latest, !latest.holdings.isEmpty {
                        Card {
                            SectionHeader(title: "Holdings")
                            ForEach(latest.holdings, id: \.id) { holding in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(holding.symbol).font(Theme.Typography.body.weight(.medium))
                                        Text("\(holding.quantity, specifier: "%.0f") qty").font(Theme.Typography.caption).foregroundStyle(Theme.ColorToken.secondaryText)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text(holding.currentValue.formatted(.currency(code: "INR")))
                                        Text(holding.pnl.formatted(.currency(code: "INR")))
                                            .font(Theme.Typography.caption)
                                            .foregroundStyle(holding.pnl >= 0 ? Theme.ColorToken.positive : Theme.ColorToken.negative)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(Theme.Spacing.md)
        }
        .background(Theme.ColorToken.background)
        .navigationTitle("Investments")
    }

    private func refresh() async {
        isRefreshing = true
        errorMessage = nil
        defer { isRefreshing = false }
        do {
            let portfolio = try await adapter.fetchPortfolio()
            let totalValue = portfolio.holdings.reduce(0) { $0 + $1.currentValue }
            let totalInvested = portfolio.holdings.reduce(0) { $0 + $1.investedValue }
            let snapshot = InvestmentSnapshot(
                totalValue: totalValue,
                totalInvested: totalInvested,
                totalPnL: totalValue - totalInvested
            )
            snapshot.holdings = portfolio.holdings.map {
                InvestmentHolding(
                    symbol: $0.symbol, quantity: $0.quantity, averagePrice: $0.averagePrice,
                    lastPrice: $0.lastPrice, currentValue: $0.currentValue, pnl: $0.pnl
                )
            }
            context.insert(snapshot)
            try context.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
