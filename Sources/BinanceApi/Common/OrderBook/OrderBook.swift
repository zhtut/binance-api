//
//  FeatureOrderBook.swift
//  binance-api
//
//  Created by tutuzhou on 2025/9/23.
//

import Foundation
import LoggingKit
#if canImport(CombineX)
import CombineX
#else
import Combine
#endif

/// 盘口价格
public struct OrderBookPrice : Sendable{
    /// 价格
    public var p: Decimal = 0
    /// 数量
    public var v: Decimal = 0
    
    public init(array: [String]) {
        if let p = Decimal(string: array[0]) {
            self.p = p
        }
        if let v = Decimal(string: array[1]) {
            self.v = v
        }
    }
}

public extension Symbol {
    var kLinePath: String {
        switch type {
        case .spot:
            return "GET /api/v3/depth"
        case .feature:
            return "GET /fapi/v1/depth"
        }
    }
}

/// 盘口价格本 - 使用actor避免资源竞争
public class OrderBook: @unchecked Sendable {
    
    public let symbol: Symbol
    
    public var bids = [OrderBookPrice]()
    public var asks = [OrderBookPrice]()
    
    public var lastUpdateId: Int = 0
    
    public var isRefreshing = false
    
    /// 是否数据正常
    @Published
    public private(set) var isReady: Bool = false
    
    /// 中间价
    public var centerPrice: Decimal? {
        guard let bid = bids.first?.p,
              let ask = asks.first?.p else {
            return nil
        }
        let center = (bid + ask) / 2.0
        return center
    }
    
    public init(symbol: Symbol) {
        self.symbol = symbol
        refreshOrderBook()
        Task.detached {
            self.startTimer()
        }
    }
    
    nonisolated func startTimer() {
        // 再起个定时器，定时拉取最新的订单和资产
        let timer = Timer(timeInterval: 10, repeats: true) { timer in
            self.refreshOrderBook()
        }
        RunLoop.current.add(timer, forMode: .common)
        RunLoop.current.run()
    }
    
    /// 刷新订单簿
    public nonisolated func refreshOrderBook() {
        Task.detached { [self] in
            logInfo("开始刷新orderBook")
            let path = symbol.kLinePath
            let params = ["symbol": symbol.symbol, "limit": 10] as [String: Any]
            do {
                let response = try await RestAPI.post(path: path, params: params)
                if let message = response.data as? [String: Any] {
                    if let a = message["asks"] as? [[String]],
                       let b = message["bids"] as? [[String]] {
                        let lastUpdateId = message.intFor("lastUpdateId") ?? 0
                        Task.detached { [self] in
                            updateOrderBookData(a: a, b: b, lastUpdateId: lastUpdateId, cover: true)
                        }
                        logInfo("刷新orderBook成功")
                    }
                }
            } catch {
                logError("刷新orderBook失败：\(error)")
            }
        }
    }
    
    /// 更新订单簿消息
    public func update(message: [String: Any]) -> Bool {
        guard let u = message.intFor("u") else {
            return false
        }
        
        // 更新操作
        if let a = message["a"] as? [[String]],
           let b = message["b"] as? [[String]] {
            updateOrderBookData(a: a, b: b, lastUpdateId: u)
        }
        
        if isReady != true {
            isReady = true
        }
        
        return true
    }
    
    /// 记录订单簿（非隔离方法）
    public func logOrderBook() {
        let currentBids = bids
        let currentAsks = asks
        print("OrderBook: =======")
        logPriceArray(arr: currentAsks, count: 5, reversed: true)
        print("------")
        logPriceArray(arr: currentBids, count: 5, reversed: false)
    }
    
    // MARK: - Private Methods
    
    /// 更新盘口
    /// - Parameters:
    ///   - a: asks
    ///   - b: bids
    ///   - lastUpdateId: u，最后一个更新id
    ///   - cover: 是否覆盖
    private func updateOrderBookData(a: [[String]], b: [[String]], lastUpdateId: Int, cover: Bool = false) {
        updateAsks(a: a, cover: cover)
        updateBids(b: b, cover: cover)
        self.lastUpdateId = lastUpdateId
//        logOrderBook()
    }
    
    private func updateAsks(a: [[String]], cover: Bool = false) {
        // 转化为对象
        let priceObjs = a.compactMap({ OrderBookPrice(array: $0) })
        if cover {
            asks = priceObjs
        } else {
            // 删除其中存在的价格
            asks.removeAll(where: { priceObjs.map { $0.p }.contains($0.p) })
            // 添加数量大于0的价格
            asks += priceObjs.filter({ $0.v > 0 })
        }
        asks.sort(by: { $0.p < $1.p })
    }
    
    private func updateBids(b: [[String]], cover: Bool = false) {
        // 转化为对象
        let priceObjs = b.compactMap({ OrderBookPrice(array: $0) })
        if cover {
            bids = priceObjs
        } else {
            // 删除其中存在的价格
            bids.removeAll(where: { priceObjs.map { $0.p }.contains($0.p) })
            // 添加数量大于0的价格
            bids += priceObjs.filter({ $0.v > 0 })
        }
        bids.sort(by: { $0.p > $1.p })
    }
    
    // MARK: - Nonisolated Helpers
    
    private func logPriceArray(arr: [OrderBookPrice], count: Int, reversed: Bool) {
        let prefixIndexes = Array(0..<min(count, arr.count))
        let indices = reversed ? prefixIndexes.reversed() : prefixIndexes
        
        for index in indices {
            let price = arr[index]
            print("\(price.p) \(price.v)")
        }
    }
}
