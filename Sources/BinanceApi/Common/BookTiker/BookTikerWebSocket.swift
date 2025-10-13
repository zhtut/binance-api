//
//  BookTikerWebSocket.swift
//  binance-api
//
//  Created by tutuzhou on 2025/10/13.
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
public class BookTikerWebSocket: @unchecked Sendable {
    
    public private(set) var symbol: Symbol
    
    @Published
    public var bookTiker: BookTiker?
    
    /// websocket连接
    public let ws = WebSocket()
    
    var subscriptions = Set<AnyCancellable>()
    
    var lastUpdateTime: Date?
    
    nonisolated(unsafe) var checkTask: Task<Void, Never>?
    
    nonisolated(unsafe) var checkTimer: Timer?
    
    public init(symbol: Symbol) {
        self.symbol = symbol
        
        Task.detached { [self] in
            await setupWebSocket()
        }
        checkTask = Task.detached { [weak self] in
            guard let self else { return }
            startCheckTimer()
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
                Task.detached { [self] in
                    try await processData(data)
                }
            }.store(in: &subscriptions)
    }
    
    nonisolated func startCheckTimer() {
        // 再起个定时器，定时拉取最新的订单和资产
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] timer in
            guard let self else { return }
            Task.detached {
                await self.check()
            }
        }
        checkTimer = timer
        RunLoop.current.add(timer, forMode: .common)
        RunLoop.current.run()
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
        } catch {
            print("处理数据错误：\(error)")
        }
    }
    
    deinit {
        checkTask?.cancel()
        checkTimer?.invalidate()
    }
}
