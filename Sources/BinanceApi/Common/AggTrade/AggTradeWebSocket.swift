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

/// 归集交易记录
public actor AggTradeWebSocket {
    
    public private(set) var symbol: Symbol
    
    /// websocket连接
    public var ws = WebSocket()
    
    /// 交易的回调
    public let tradePublisher = PassthroughSubject<Trade, Never>()
    
    var subscription: AnyCancellable?
    
    public init(symbol: Symbol) {
        self.symbol = symbol
        
        Task {
            await setupWebSocket()
        }
    }
    
    func setupWebSocket() {
        
        // 监听事件
        ws.isPrintLog = false
        let baseURL = symbol.wssBaseURL
        let url = "\(baseURL)/\(symbol.symbol.lowercased())@aggTrade"
        ws.url = URL(string: url)
        ws.open()
        
        // 监听事件
        subscription = ws.onDataPublisher
            .sink { [weak self] data in
                guard let self else { return }
                Task {
                    await self.processData(data)
                }
            }
    }
    
    /// 处理数据
    /// - Parameter data: 收到的数据
    public func processData(_ data: Data) {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let e = json.stringFor("e") {
                    if e == "aggTrade" {
                        let trade = try JSONDecoder().decode(Trade.self, from: data)
                        didReceiveAggTrade(trade)
                    }
                }
            }
        } catch {
            print("处理数据错误：\(error)")
        }
    }
    
    func didReceiveAggTrade(_ trade: Trade) {
//        print("收到aggTrade: \(trade)")
        //            print("收到：\(trade.isBuyOrder ? "买入" : "卖出")\(trade.q)btc，时间：\(trade.E)，交易id：\(trade.a)，成交价格：\(trade.p)")
        tradePublisher.send(trade)
    }
}
