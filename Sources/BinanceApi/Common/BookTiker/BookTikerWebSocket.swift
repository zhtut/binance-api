//
//  BookTikerWebSocket.swift
//  binance-api
//
//  Created by tutuzhou on 2025/10/13.
//

import Foundation
import CombineWebSocket
import CombineX
import LoggingKit
import NIOLockedValue

/// 现货的盘口
public class BookTikerWebSocket: @unchecked Sendable {
    
    public private(set) var symbol: Symbol
    
    @NIOLocked
    public var bookTiker: BookTiker?
    
    public var bookTikerPublisher = PassthroughSubject<BookTiker?, Never>()
    
    /// websocket连接
    public let ws = WebSocket()
    
    var subscriptions = Set<AnyCancellable>()
    
    @NIOLocked
    var lastUpdateTime: Date?
    
    var checkTimer: Timer?
    
    public init(symbol: Symbol) {
        self.symbol = symbol
        
        setupWebSocket()
        
        Task {
            await self.startTimer()
        }
    }
    
    func setupWebSocket() {
        let baseURL = symbol.wssBaseURL
        let url = "\(baseURL)/\(symbol.symbol.lowercased())@bookTicker"
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
    
    @MainActor
    func startTimer() {
        // 再起个定时器，定时拉取最新的订单和资产
        checkTimer = Timer(timeInterval: 1, repeats: true) { [weak self] timer in
            guard let self else { return }
            self.check()
        }
    }
    
    func check() {
        if let lastUpdateTime {
            let now = Date()
            let offset = now.timeIntervalSince(lastUpdateTime)
            if offset > 2 {
                logError("book tiker 距离最后一次ws消息已经过去：\(offset)秒，可能ws已经中断了")
            }
        }
    }
    
    /// 处理数据
    /// - Parameter data: 收到的数据
    public func processData(_ data: Data) throws {
        lastUpdateTime = Date()
        do {
            let bookTiker = try JSONDecoder().decode(BookTiker.self, from: data)
            self.bookTiker = bookTiker
            self.bookTikerPublisher.send(bookTiker)
        } catch {
            print("处理数据错误：\(error)")
        }
    }
    
    deinit {
        checkTask?.cancel()
        checkTimer?.invalidate()
    }
}
