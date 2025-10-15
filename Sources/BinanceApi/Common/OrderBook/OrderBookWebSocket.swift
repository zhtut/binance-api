//
//  TradeWebSocket.swift
//  BinanceTrader
//
//  Created by tutuzhou on 2024/11/14.
//
import Foundation
import CombineWebSocket
import CombineX
import LoggingKit

/// 现货的盘口
public class OrderBookWebSocket: @unchecked Sendable {
    
    public private(set) var symbol: Symbol
    public private(set) var orderBook: OrderBook
    
    /// websocket连接
    public let ws = WebSocket()
    
    public let orderBookPublisher = PassthroughSubject<OrderBook, Never>()
    
    var subscriptions = Set<AnyCancellable>()
    
    var lastUpdateTime: Date?
    
    nonisolated(unsafe) var checkTimer: Timer?
    
    public init(symbol: Symbol) {
        self.symbol = symbol
        self.orderBook = OrderBook(symbol: symbol)
        setupWebSocket()
        startTimer()
    }
    
    func setupWebSocket() {
        let baseURL = symbol.wssBaseURL
        let url = "\(baseURL)/\(symbol.symbol.lowercased())@depth@100ms"
        ws.url = URL(string: url)
        ws.open()
        
        // 监听事件
        ws.onDataPublisher
            .sink { [weak self] data in
                guard let self else { return }
                Task { [self] in
                    try processData(data)
                }
            }.store(in: &subscriptions)
    }
    
    func startTimer() {
        // 再起个定时器，定时拉取最新的订单和资产
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] timer in
            guard let self else { return }
            self.check()
        }
        checkTimer = timer
        RunLoop.main.add(timer, forMode: .common)
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
    public func processData(_ data: Data) throws {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                try update(json: json)
            }
        } catch {
            print("处理数据错误：\(error)")
        }
    }
    
    func update(json: [String: Any]) throws {
        lastUpdateTime = Date()
        let result = orderBook.update(message: json)
        if result {
            orderBookPublisher.send(orderBook)
        }
    }
    
    deinit {
        checkTimer?.invalidate()
    }
}
