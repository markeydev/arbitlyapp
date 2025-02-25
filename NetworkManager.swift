// NetworkManager.swift
import Foundation

final class NetworkManager {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func fetchTicker(exchange: String, symbol: String) async throws -> ExchangePrice? {
        let urlString = "https://api.binance.com/api/v3/ticker/bookTicker?symbol=\(symbol.replacingOccurrences(of: "/", with: ""))"
        guard let url = URL(string: urlString) else { throw NetworkError.invalidURL }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
        
        let ticker = try JSONDecoder().decode(TickerResponse.self, from: data)
        
        return ExchangePrice(
            exchange: exchange,
            symbol: symbol,
            bid: Double(ticker.bidPrice) ?? 0.0,
            ask: Double(ticker.askPrice) ?? 0.0,
            volume: Double(ticker.bidQty) ?? 0.0
        )
    }
}

enum NetworkError: Error, LocalizedError {
    case invalidResponse
    case invalidURL
    case decodingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid server response"
        case .invalidURL: return "Invalid URL"
        case .decodingFailed: return "Failed to decode response"
        }
    }
}