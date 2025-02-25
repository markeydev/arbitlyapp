// ArbitrageViewModel.swift
import SwiftUI

@MainActor
final class ArbitrageViewModel: ObservableObject {
    @Published private(set) var opportunities: [Opportunity] = []
    @Published private(set) var logs: [LogEntry] = []
    @Published private(set) var isScanning = false
    @Published var selectedExchanges: Set<String>
    @Published var selectedCoins: Set<String>
    @Published var stakingOptions: [StakingOption] = []
    @Published var portfolio: [PortfolioAsset] = []
    @Published var liquidityPools: [LiquidityPool] = []
    @Published var idoOpportunities: [IDOOpportunity] = []
    @Published var nftStreams: [NFTStream] = []
    
    private let exchanges: [String] = [
        "binance", "kucoin", "kraken", "huobi", "bybit",
        "gateio", "okx", "bitget", "mexc", "bitmart"
    ]
    
    private let coins: [String] = [
        "BTC/USDT", "ETH/USDT", "XRP/USDT", "ADA/USDT", "DOGE/USDT",
        "BNB/USDT", "SOL/USDT", "LTC/USDT", "LINK/USDT", "MATIC/USDT"
    ]
    
    private let exchangeLinks: [String: String] = [
        "binance": "https://www.binance.com/ru/trade/",
        "kucoin": "https://www.kucoin.com/trade/",
        "kraken": "https://pro.kraken.com/app/trade/",
        "huobi": "https://www.htx.com/trade/",
        "bybit": "https://www.bybit.com/trade/spot/",
        "gateio": "https://www.gate.io/trade/",
        "okx": "https://www.okx.com/trade-spot/",
        "bitget": "https://www.bitget.com/spot/",
        "mexc": "https://www.mexc.com/trade/",
        "bitmart": "https://www.bitmart.com/trade/ru?symbol="
    ]
    
    private let networkManager = NetworkManager()
    
    init() {
        self.selectedExchanges = Set(exchanges.prefix(3))
        self.selectedCoins = Set(coins.prefix(3))
        loadMockData()
    }
    
    // MARK: - Общественные методы
    func scanForOpportunities() async {
        guard !isScanning else { return }
        
        isScanning = true
        opportunities.removeAll()
        addLog("Запуск сканирования арбитража...", type: .info)
        
        do {
            let prices = try await fetchAllPrices()
            let newOpportunities = calculateOpportunities(from: prices)
            opportunities = newOpportunities.sorted { $0.spread > $1.spread }
            addLog("Сканирование завершено. Найдено \(opportunities.count) возможностей", type: .success)
        } catch {
            addLog("Ошибка сканирования: \(error.localizedDescription)", type: .error)
        }
        
        isScanning = false
    }
    
    func updatePortfolioPrices() async {
        for i in portfolio.indices {
            do {
                if let price = try await networkManager.fetchTicker(exchange: "binance", symbol: portfolio[i].symbol) {
                    portfolio[i].currentPrice = (price.bid + price.ask) / 2 // Теперь работает, так как currentPrice — var
                }
            } catch {
                addLog("Ошибка обновления цены \(portfolio[i].symbol): \(error.localizedDescription)", type: .warning)
            }
        }
    }
    
    var availableExchanges: [String] { exchanges }
    var availableCoins: [String] { coins }
    
    // MARK: - Приватные методы
    private func fetchAllPrices() async throws -> [String: [ExchangePrice]] {
        var allPrices: [String: [ExchangePrice]] = [:]
        
        for exchange in selectedExchanges {
            for coin in selectedCoins {
                do {
                    if let price = try await networkManager.fetchTicker(exchange: exchange, symbol: coin) {
                        allPrices[coin, default: []].append(price)
                        addLog("Получены данные \(coin) с \(exchange): Покупка $\(price.bid.formatted()), Продажа $\(price.ask.formatted())", 
                              type: .success)
                    }
                } catch {
                    addLog("Ошибка получения \(coin) с \(exchange): \(error.localizedDescription)", 
                          type: .warning)
                }
                try await Task.sleep(nanoseconds: 200_000_000)
            }
        }
        return allPrices
    }
    
    private func calculateOpportunities(from prices: [String: [ExchangePrice]]) -> [Opportunity] {
        var opportunities: [Opportunity] = []
        
        for (symbol, exchangePrices) in prices where exchangePrices.count >= 2 {
            guard let bestBid = exchangePrices.max(by: { $0.bid < $1.bid }),
                  let bestAsk = exchangePrices.min(by: { $0.ask < $1.ask }),
                  bestBid.bid > bestAsk.ask else {
                continue
            }
            
            let spread = bestBid.bid - bestAsk.ask
            let spreadPercent = (spread / bestAsk.ask) * 100
            
            let opportunity = Opportunity(
                symbol: symbol,
                buyExchange: bestAsk.exchange,
                sellExchange: bestBid.exchange,
                buyPrice: bestAsk.ask,
                sellPrice: bestBid.bid,
                spread: spread,
                spreadPercent: spreadPercent,
                buyLink: exchangeLinks[bestAsk.exchange, default: ""] + symbol.replacingOccurrences(of: "/", with: "_"),
                sellLink: exchangeLinks[bestBid.exchange, default: ""] + symbol.replacingOccurrences(of: "/", with: "_")
            )
            
            opportunities.append(opportunity)
            addLog("Найдена возможность для \(symbol): Покупка на \(bestAsk.exchange) за $\(bestAsk.ask.formatted()), Продажа на \(bestBid.exchange) за $\(bestBid.bid.formatted())",
                  type: .success)
        }
        
        return opportunities
    }
    
    private func addLog(_ message: String, type: LogEntry.LogType) {
        let entry = LogEntry(message: message, timestamp: Date(), type: type)
        logs.append(entry)
        if logs.count > 100 { logs.removeFirst() }
    }
    
    private func loadMockData() {
        stakingOptions = [
            StakingOption(coin: "ETH", apy: 5.2, lockPeriod: 30, minimumStake: 0.1),
            StakingOption(coin: "BNB", apy: 7.8, lockPeriod: 90, minimumStake: 1.0),
            StakingOption(coin: "ADA", apy: 4.5, lockPeriod: 0, minimumStake: 10.0)
        ]
        
        portfolio = [
            PortfolioAsset(symbol: "BTC/USDT", amount: 0.5, averagePrice: 50000, currentPrice: 52000),
            PortfolioAsset(symbol: "ETH/USDT", amount: 2.0, averagePrice: 3000, currentPrice: 3100)
        ]
        
        liquidityPools = [
            LiquidityPool(pair: "ETH/USDT", apy: 12.5, platform: "Uniswap", riskLevel: "Средний"),
            LiquidityPool(pair: "BNB/BUSD", apy: 18.0, platform: "PancakeSwap", riskLevel: "Высокий"),
            LiquidityPool(pair: "ADA/USDT", apy: 8.0, platform: "SushiSwap", riskLevel: "Низкий")
        ]
        
        idoOpportunities = [
            IDOOpportunity(projectName: "CryptoGame", token: "CGT", launchDate: Date().addingTimeInterval(604800), minInvestment: 100, expectedROI: 150),
            IDOOpportunity(projectName: "DeFiHub", token: "DFH", launchDate: Date().addingTimeInterval(1209600), minInvestment: 50, expectedROI: 200)
        ]
        
        nftStreams = [
            NFTStream(nftName: "CryptoPunk #123", collection: "CryptoPunks", dailyRate: 0.05, availableDays: 7),
            NFTStream(nftName: "BoredApe #456", collection: "BAYC", dailyRate: 0.1, availableDays: 14)
        ]
    }
}