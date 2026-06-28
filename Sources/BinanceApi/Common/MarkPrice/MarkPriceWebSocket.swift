//
//  MarkPriceWebSocket.swift
//  binance-api
//
//  合约标记价格/资金费率 WebSocket（<symbol>@markPrice@1s）
//

import Foundation
import CombineWebSocket
import CombineX
import LoggingKit
import NIOLockedValue

/// 合约标记价格订阅
public class MarkPriceWebSocket: @unchecked Sendable {

    public private(set) var symbol: Symbol

    @NIOLocked
    public var markPrice: MarkPrice?

    public var markPricePublisher = PassthroughSubject<MarkPrice, Never>()

    /// websocket连接
    public let ws = WebSocket()

    var subscriptions = Set<AnyCancellable>()

    @NIOLocked
    var lastUpdateTime: Date?

    var checkTimer: Timer?

    public init(symbol: Symbol) {
        self.symbol = symbol

        setupWebSocket()
        Task.detached {
            self.startTimer()
        }
    }

    func setupWebSocket() {
        let baseURL = symbol.wssBaseURL
        // 1s 更新一次（默认3s）
        let url = "\(baseURL)/\(symbol.symbol.lowercased())@markPrice@1s"
        ws.url = URL(string: url)
        ws.open()

        ws.onDataPublisher
            .sink { [weak self] data in
                guard let self else { return }
                Task { [self] in
                    processData(data)
                }
            }.store(in: &subscriptions)
    }

    func startTimer() {
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] timer in
            guard let self else { return }
            self.check()
        }
        checkTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func check() {
        if let lastUpdateTime {
            let offset = Date().timeIntervalSince(lastUpdateTime)
            if offset > 5 {
                logError("mark price 距离最后一次ws消息已经过去：\(offset)秒，可能ws已经中断了")
            }
        }
    }

    /// 处理数据
    public func processData(_ data: Data) {
        lastUpdateTime = Date()
        do {
            let markPrice = try JSONDecoder().decode(MarkPrice.self, from: data)
            self.markPrice = markPrice
            self.markPricePublisher.send(markPrice)
        } catch {
            logError("处理标记价格数据错误：\(error)")
        }
    }

    deinit {
        checkTimer?.invalidate()
    }
}
