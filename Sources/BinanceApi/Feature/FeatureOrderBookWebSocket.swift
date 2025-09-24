//
//  TradeWebSocket.swift
//  BinanceTrader
//
//  Created by tutuzhou on 2024/11/14.
//
import Foundation
import CombineWebSocket
#if canImport(CombineX)
import CombineX
#else
import Combine
#endif

extension PassthroughSubject: @unchecked @retroactive Sendable {
    
}

/// 合约的盘口
public actor FeatureOrderBookWebSocket {
    
    public let symbol: String
    public var orderBook: FeatureOrderBook
    
    /// websocket连接
    public let ws = WebSocket()
    
    public let orderBookPublisher = PassthroughSubject<FeatureOrderBook, Never>()
    
    var subscription: AnyCancellable?
    
    public var json: [String: Any]? {
        didSet {
            guard let json else {
                return
            }
            Task {
                let result = try await orderBook.update(message: json)
                if result {
                    orderBookPublisher.send(orderBook)
                }
            }
        }
    }
    
    public init(symbol: String) {
        self.symbol = symbol
        self.orderBook = FeatureOrderBook(symbol: symbol)
        Task {
            await setupWebSocket()
        }
    }
    
    func setupWebSocket() {
        ws.isPrintLog = false
        
        let baseURL = APIConfig.shared.spot.wsBaseURL
        let url = "\(baseURL)/\(symbol.lowercased())@depth@100ms"
        ws.url = URL(string: url)
        ws.open()
        
        // 监听事件
        subscription = ws.onDataPublisher
            .sink { [weak self] data in
                self?.processData(data)
            }
    }
    
    /// 处理数据
    /// - Parameter data: 收到的数据
    public nonisolated func processData(_ data: Data) {
        Task {
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    await update(json: json)
                }
            } catch {
                print("处理数据错误：\(error)")
            }
        }
    }
    
    func update(json: [String: Any]) {
        self.json = json
    }
}
