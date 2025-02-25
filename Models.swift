// Models.swift
import Foundation

struct ExchangePrice: Identifiable, Codable {
    let id = UUID()
    let exchange: String
    let symbol: String
    let bid: Double
    let ask: Double
    let volume: Double
}

struct Opportunity: Identifiable, Codable {
    let id = UUID()
    let symbol: String
    let buyExchange: String
    let sellExchange: String
    let buyPrice: Double
    let sellPrice: Double
    let spread: Double
    let spreadPercent: Double
    let buyLink: String
    let sellLink: String
}

struct StakingOption: Identifiable, Codable {
    let id = UUID()
    let coin: String
    let apy: Double // Годовая процентная доходность
    let lockPeriod: Int // Дни блокировки
    let minimumStake: Double
}

struct PortfolioAsset: Identifiable, Codable {
    let id = UUID()
    let symbol: String
    let amount: Double
    let averagePrice: Double
    var currentPrice: Double // Изменено с let на var
    
    var profitLoss: Double { (currentPrice - averagePrice) * amount }
    var profitLossPercent: Double { ((currentPrice - averagePrice) / averagePrice) * 100 }
}

struct LiquidityPool: Identifiable, Codable {
    let id = UUID()
    let pair: String // Например, "ETH/USDT"
    let apy: Double
    let platform: String // Например, "Uniswap"
    let riskLevel: String // "Низкий", "Средний", "Высокий"
}

struct IDOOpportunity: Identifiable, Codable {
    let id = UUID()
    let projectName: String
    let token: String
    let launchDate: Date
    let minInvestment: Double
    let expectedROI: Double // Ожидаемая доходность в %
}

struct NFTStream: Identifiable, Codable {
    let id = UUID()
    let nftName: String
    let collection: String
    let dailyRate: Double // Стоимость аренды в день
    let availableDays: Int
}

struct LogEntry: Identifiable, Codable {
    let id = UUID()
    let message: String
    let timestamp: Date
    let type: LogType
    
    enum LogType: String, Codable {
        case info, warning, error, success
    }
}

struct TickerResponse: Codable {
    let symbol: String
    let bidPrice: String
    let askPrice: String
    let bidQty: String
    
    enum CodingKeys: String, CodingKey {
        case symbol
        case bidPrice = "bidPrice"
        case askPrice = "askPrice"
        case bidQty = "bidQty"
    }
}