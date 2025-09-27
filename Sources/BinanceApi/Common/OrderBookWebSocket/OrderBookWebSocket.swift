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
import LoggingKit

/// 现货的盘口
public actor OrderBookWebSocket {
    
    public private(set) var symbol: Symbol
    public private(set) var orderBook: OrderBook
    
    /// websocket连接
    public let ws = WebSocket()
    
    public let orderBookPublisher = PassthroughSubject<OrderBook, Never>()
    
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
    
    public init(symbol: Symbol) {
        self.symbol = symbol
        self.orderBook = OrderBook(symbol: symbol)
        Task {
            await setupWebSocket()
        }
    }
    
    func setupWebSocket() {
        ws.isPrintLog = false
        let baseURL = symbol.wssBaseURL
        let url = "\(baseURL)/\(symbol.symbol.lowercased())@depth@100ms"
        ws.url = URL(string: url)
        ws.open()
        
        // 监听事件
        subscription = ws.onDataPublisher
            .sink { [weak self] data in
                guard let self else { return }
                Task {
                    await processData(data)
                }
            }
    }
    
    /// 处理数据
    /// - Parameter data: 收到的数据
    public func processData(_ data: Data) async {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                await update(json: json)
            }
        } catch {
            print("处理数据错误：\(error)")
        }
    }
    
    func update(json: [String: Any]) {
        self.json = json
    }
}
