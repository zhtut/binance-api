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

/// 现货账户和订单的websocket
open class TradeWebSocket: CombineBase, @unchecked Sendable {
    
    var symbol: String
    
    /// websocket连接
    public var ws = WebSocket()
    
    var tradePublisher = PassthroughSubject<AggTrade, Never>()
    
    init(symbol: String) {
        self.symbol = symbol
        super.init()
        ws.isPrintLog = false
        
        // 监听事件
        ws.onDataPublisher
            .sink { [weak self] data in
                self?.processData(data)
            }
            .store(in: &subscriptions)
        
        let baseURL = APIConfig.shared.spot.wsBaseURL
        let url = "\(baseURL)/\(symbol.lowercased())@aggTrade"
        ws.url = URL(string: url)
        ws.open()
    }
    
    /// 处理数据
    /// - Parameter data: 收到的数据
    open func processData(_ data: Data) {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let e = json.stringFor("e") {
                    if e == "aggTrade" {
                        let trade = try JSONDecoder().decode(AggTrade.self, from: data)
                        didReceiveAggTrade(trade)
                    }
                }
            }
        } catch {
            print("处理数据错误：\(error)")
        }
    }
    
    func didReceiveAggTrade(_ trade: AggTrade) {
//        print("收到aggTrade: \(trade)")
        if trade.q.defaultDouble() > 0.1 {
//            print("收到：\(trade.isBuyOrder ? "买入" : "卖出")\(trade.q)btc，时间：\(trade.E)，交易id：\(trade.a)，成交价格：\(trade.p)")
            tradePublisher.send(trade)
        }
    }
}
