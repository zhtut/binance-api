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
    
    var lastUpdateTime: Date?
    
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
                lastUpdateTime = Date()
            }
        }
    }
    
    public init(symbol: Symbol) {
        self.symbol = symbol
        self.orderBook = OrderBook(symbol: symbol)
        Task {
            await setupWebSocket()
        }
        Task {
            startCheckTimer()
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
    
    nonisolated func startCheckTimer() {
        // 再起个定时器，定时拉取最新的订单和资产
        let timer = Timer(timeInterval: 1, repeats: true) { timer in
            Task {
                await self.check()
            }
        }
        RunLoop.current.add(timer, forMode: .common)
        RunLoop.current.run()
    }
    
    func check() {
        if let lastUpdateTime {
            let now = Date()
            let offset = now.timeIntervalSince(lastUpdateTime)
            if offset > 3 {
                logError("order book距离最后一次ws消息已经过去：\(offset)秒，可能ws已经中断了")
            }
        }
    }
    
    /// 处理数据
    /// - Parameter data: 收到的数据
    public func processData(_ data: Data) async {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                update(json: json)
            }
        } catch {
            print("处理数据错误：\(error)")
        }
    }
    
    func update(json: [String: Any]) {
        self.json = json
    }
}
