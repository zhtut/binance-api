//
//  FeatureOrderBook.swift
//  binance-api
//
//  Created by tutuzhou on 2025/9/23.
//

import Foundation

/// 盘口价格
public struct FeatureOrderBookPrice : Sendable{
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

/// 盘口价格本 - 使用actor避免资源竞争
public actor FeatureOrderBook {
    
    public let symbol: String
    
    public var bids = [FeatureOrderBookPrice]()
    public var asks = [FeatureOrderBookPrice]()
    
    public var U: Int = 0
    public var E: Int = 0
    public var T: Int = 0
    
    public var u: Int = 0
    public var pu: Int = 0
    
    public var isRefreshing = false
    
    /// 中间价
    public var centerPrice: Double? {
        guard let bid = bids.first?.p.double,
              let ask = asks.last?.p.double else {
            return nil
        }
        let center = (bid + ask) / 2.0
        return center
    }
    
    public init(symbol: String) {
        self.symbol = symbol
    }
    
    /// 刷新订单簿
    public func refreshOrderBook() async throws {
        isRefreshing = true
        defer { isRefreshing = false }
        
        let path = "GET /fapi/v1/depth"
        let params = ["symbol": symbol, "limit": 100] as [String: Any]
        let response = try await RestAPI.post(path: path, params: params)
        
        if let message = response.data as? [String: Any] {
            if let a = message["asks"] as? [[String]],
               let b = message["bids"] as? [[String]] {
                updateOrderBookData(a: a, b: b, lastUpdateId: message.intFor("lastUpdateId") ?? 0)
            }
        }
    }
    
    /// 更新订单簿消息
    public func update(message: [String: Any]) async throws -> Bool {
        if isRefreshing {
            return false
        }
        
        let pu = message.intFor("pu") ?? 0
        if pu != u {
            try await refreshOrderBook()
            return false
        }
        
        if let a = message["a"] as? [[String]],
           let b = message["b"] as? [[String]] {
            updateOrderBookData(a: a, b: b, message: message)
        }
        
        return true
    }
    
    /// 获取当前订单簿的快照（非隔离的只读访问）
    public func getCurrentOrderBook() -> (bids: [FeatureOrderBookPrice], asks: [FeatureOrderBookPrice]) {
        return (bids, asks)
    }
    
    /// 获取简化的订单簿信息（非隔离访问）
    public func getOrderBookSnapshot() -> OrderBookSnapshot {
        return OrderBookSnapshot(
            symbol: symbol,
            bids: bids,
            asks: asks,
            lastUpdateId: u,
            timestamp: T
        )
    }
    
    /// 记录订单簿（非隔离方法）
    public func logOrderBook() {
        let currentBids = bids
        let currentAsks = asks
        
        logPriceArray(arr: currentAsks, count: 5, ascending: false)
        print("------")
        logPriceArray(arr: currentBids, count: 5, ascending: true)
    }
    
    // MARK: - Private Methods
    
    private func updateOrderBookData(a: [[String]], b: [[String]], lastUpdateId: Int? = nil, message: [String: Any]? = nil) {
        updateAsks(a: a)
        updateBids(b: b)
        
        if let lastUpdateId = lastUpdateId {
            self.u = lastUpdateId
        }
        
        if let message = message {
            U = message.intFor("U") ?? 0
            E = message.intFor("E") ?? 0
            T = message.intFor("T") ?? 0
            u = message.intFor("u") ?? 0
        }
        
        logOrderBook()
    }
    
    private func updateAsks(a: [[String]]) {
        for arr in a {
            let ob = FeatureOrderBookPrice(array: arr)
            var newAsks = asks.filter { $0.p != ob.p }
            if ob.v > 0 {
                newAsks.append(ob)
            }
            asks = newAsks
            asks.sort { $0.p < $1.p }
        }
    }
    
    private func updateBids(b: [[String]]) {
        for arr in b {
            let ob = FeatureOrderBookPrice(array: arr)
            var newBids = bids.filter { $0.p != ob.p }
            if ob.v > 0 {
                newBids.append(ob)
            }
            bids = newBids
            bids.sort { $0.p > $1.p }
        }
    }
    
    // MARK: - Nonisolated Helpers
    
    private nonisolated func logPriceArray(arr: [FeatureOrderBookPrice], count: Int, ascending: Bool) {
        let indices = ascending ? Array(0..<min(count, arr.count)) : Array((0..<min(count, arr.count)).reversed())
        
        for index in indices {
            let price = arr[index]
            print("\(price.p) \(price.v)")
        }
    }
}

/// 订单簿快照结构体（用于非隔离访问）
public struct OrderBookSnapshot {
    public let symbol: String
    public let bids: [FeatureOrderBookPrice]
    public let asks: [FeatureOrderBookPrice]
    public let lastUpdateId: Int
    public let timestamp: Int
    
    public init(symbol: String, bids: [FeatureOrderBookPrice], asks: [FeatureOrderBookPrice], lastUpdateId: Int, timestamp: Int) {
        self.symbol = symbol
        self.bids = bids
        self.asks = asks
        self.lastUpdateId = lastUpdateId
        self.timestamp = timestamp
    }
}
